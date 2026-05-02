//+------------------------------------------------------------------+
//| AtomicFile.mqh — Atomic file-write helper (Option A: TempRename) |
//| Purpose: Write content to <path>.tmp → flush → close →           |
//|          FileMove(.tmp → <path>); survive mid-write crashes via   |
//|          NTFS rename atomicity + orphan cleanup at OnInit         |
//| Layer:   helpers/ — pure utility, no service dependencies        |
//| Source:  TD-02 §4.4 + ADR-007 §Decision + §Spike Result          |
//|          ADR-007 §Spike Result: Option A locked (IMPL-046)        |
//|          1000/1000 phase-1 writes intact;                        |
//|          100/100 mid-write crashes left state.json untouched      |
//+------------------------------------------------------------------+
// Key contracts:
//   - Stateless: zero member fields, no Init(), logger passed per-call
//   - Sandbox-relative paths only (MQL5/Files/ prefix is MT5 implicit)
//   - ห้าม TerminalInfoString(TERMINAL_DATA_PATH) — sandbox-relative discipline
//   - ห้าม #import / external DLL (NFR-7.2)
//   - Option B (DoubleBuffered) NOT implemented — gated by ADR-007 §Revisit-when
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_HELPERS_ATOMICFILE_MQH
#define PHOENICISNEX_HELPERS_ATOMICFILE_MQH

// Forward-declare CLogger — opaque pointer; full include needed to
// call logger.Error() / logger.Warn() methods in method bodies.
// Per precedent: BootstrapValidator.mqh uses full include of Logger.mqh.
#include "../services/Logger.mqh"

//+------------------------------------------------------------------+
//| CAtomicFile — stateless atomic-write utility                     |
//|                                                                  |
//| Public API:                                                       |
//|   bool WriteAtomic_TempRename(string path, string content,       |
//|                               CLogger *logger)                   |
//|   void CleanupOrphanTmp(string path, CLogger *logger)            |
//|   bool WriteAtomic(string path, string content,                  |
//|                    CLogger *logger)  ← dispatcher (always →A)    |
//|                                                                  |
//| Caller contract:                                                  |
//|   - path = sandbox-relative destination                          |
//|             e.g. "PhoenicisNex/state/state.json"                 |
//|   - content = pre-serialised JSON string (caller's responsibility)|
//|   - logger may be NULL (guards in place)                         |
//|   - Returns false on any failure + logs Error; never throws       |
//+------------------------------------------------------------------+
class CAtomicFile
  {
public:
   //--- Constructor (stateless — no Init needed; mirrors CCommentParser)
   CAtomicFile() {}

   //+----------------------------------------------------------------+
   //| WriteAtomic_TempRename                                         |
   //| Option A primary path (ADR-007 §Decision + §Spike Result)      |
   //|                                                                |
   //| Algorithm (per ADR-007 §Option A pseudocode):                  |
   //|  1. Caller serialises content (not our concern)                |
   //|  2. Open <path>.tmp → write → flush → close                    |
   //|  3. FileMove(<path>.tmp, <path>, FILE_REWRITE)  ← NTFS atomic  |
   //|  4. Crash in step 2 → state file untouched; .tmp = orphan      |
   //|  5. Crash in step 3 → NTFS atomic rename guarantee             |
   //|                                                                |
   //| Degrade-but-continue: return false + Logger.Error on any fail  |
   //| (never blocks tick — per ea.md error handling policy)          |
   //+----------------------------------------------------------------+
   bool              WriteAtomic_TempRename(string path,
                                            string content,
                                            CLogger *logger)
     {
      string tmp_path = path + ".tmp";

      //--- Step 2a: open temp file for write (FILE_ANSI = UTF-8 compatible bytes)
      int handle = FileOpen(tmp_path, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
        {
         if(logger != NULL)
            logger.Error("system", "atomic_open_fail", 0,
                         StringFormat("path=%s err=%d", tmp_path, GetLastError()));
         return false;
        }

      //--- Step 2b: write content bytes
      uint written = FileWriteString(handle, content);
      if(written != (uint)StringLen(content))
        {
         if(logger != NULL)
            logger.Error("system", "atomic_write_short", 0,
                         StringFormat("path=%s wrote=%u expected=%d err=%d",
                                      tmp_path, written, StringLen(content), GetLastError()));
         FileClose(handle);
         FileDelete(tmp_path);   // best-effort orphan removal
         return false;
        }

      //--- Step 2c: flush + close (ensure OS buffers flushed before rename)
      FileFlush(handle);
      FileClose(handle);

      //--- Step 3: atomic rename (FILE_REWRITE = overwrite existing destination)
      if(!FileMove(tmp_path, 0, path, FILE_REWRITE))
        {
         if(logger != NULL)
            logger.Error("system", "atomic_move_fail", 0,
                         StringFormat("src=%s dst=%s err=%d",
                                      tmp_path, path, GetLastError()));
         FileDelete(tmp_path);   // best-effort cleanup of orphan tmp
         return false;
        }

      return true;
     }

   //+----------------------------------------------------------------+
   //| CleanupOrphanTmp                                               |
   //| Call at OnInit (per ADR-007 §Recovery) to delete any leftover  |
   //| <path>.tmp from a prior crashed write cycle.                    |
   //|                                                                |
   //| Semantics:                                                     |
   //|  - If .tmp does not exist → no-op (silent; normal path)        |
   //|  - If .tmp exists + deleted OK → Logger.Warn (info-level event) |
   //|  - If .tmp exists + delete fails → Logger.Error                |
   //| Degrade-but-continue: orphan tmp is non-fatal at boot          |
   //+----------------------------------------------------------------+
   void              CleanupOrphanTmp(string path, CLogger *logger)
     {
      string tmp_path = path + ".tmp";

      if(!FileIsExist(tmp_path))
         return;   // no orphan — normal happy path

      if(FileDelete(tmp_path))
        {
         if(logger != NULL)
            logger.Warn("system", "orphan_tmp_cleaned", 0,
                        StringFormat("path=%s (prior write interrupted; safe — %s was untouched)",
                                     tmp_path, path));
        }
      else
        {
         if(logger != NULL)
            logger.Error("system", "orphan_tmp_cleanup_fail", 0,
                         StringFormat("path=%s err=%d", tmp_path, GetLastError()));
         // degrade-but-continue: non-fatal at boot; next WriteAtomic will
         // overwrite the orphan via FILE_REWRITE in Step 3
        }
     }

   //+----------------------------------------------------------------+
   //| WriteAtomic — strategy dispatcher                              |
   //|                                                                |
   //| Always delegates to WriteAtomic_TempRename (Option A locked    |
   //| per IMPL-046 spike verdict; ADR-007 §Spike Result).            |
   //|                                                                |
   //| Option B (WriteAtomic_DoubleBuffered) NOT implemented —        |
   //| gated behind ADR-007 §Revisit-when triggers; no #define switch |
   //| needed until those triggers fire (IMPL-FUTURE-OPTION-B).       |
   //+----------------------------------------------------------------+
   bool              WriteAtomic(string path, string content, CLogger *logger)
     {
      // Option A locked per IMPL-046 spike (ADR-007 §Spike Result)
      return WriteAtomic_TempRename(path, content, logger);
     }

  }; // end class CAtomicFile

#endif // PHOENICISNEX_HELPERS_ATOMICFILE_MQH
