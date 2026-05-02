# MCP Server Setup Guide

## Phase-to-MCP Mapping — ต้องติดตั้งอะไรเมื่อไร

> ไม่ต้องติดตั้งทุกตัวตั้งแต่แรก — ติดตั้งเมื่อถึง phase ที่ต้องใช้

| Phase | MCP Servers ที่ต้องใช้ | Optional |
|-------|----------------------|----------|
| **Phase 0: Setup** | `filesystem` | `postgres`, `docker` |
| **Phase 1A: BA** | `notebooklm`, `markitdown` | — |
| **Phase 1B: SD** | `postgres` (อ่าน existing schema) | — |
| **Phase 3: Implement** | `postgres`, `docker`, `serena` | `playwright` (smoke test) |
| **Phase 4: Harden** | `serena` (code intelligence) | `playwright` (security E2E) |
| **Phase 5: Deliver** | `notebooklm` (Knowledge Base ถาวร) | — |
| **ทุก Phase** | `pare-git`, `filesystem`, `memory`/`omega-memory`, `sequential-thinking` | `token-optimizer` |

---

## Quick Install (Claude Code CLI)

ใช้ `claude mcp add` เพื่อติดตั้ง MCP server ทีละตัว

> ⚠️ **Windows ต้อง wrap `npx` ด้วย `cmd /c`** — Claude Code (Node/spawn) บน Windows หา `npx.cmd` ไม่เจอ ทำให้ได้ warning:
> `Windows requires 'cmd /c' wrapper to execute npx`
> ตัวอย่างด้านล่างแยก **macOS/Linux** กับ **Windows (PowerShell)** — `uvx` ไม่ต้อง wrap เพราะเป็น native executable

### Core — แนะนำติดตั้งทุกโปรเจค

**macOS / Linux:**
```bash
# PostgreSQL — อ่าน schema, query database
claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres

# Filesystem — อ่านไฟล์ docs + services
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem ./docs ./services
```

**Windows (PowerShell):**
```powershell
claude mcp add postgres -- cmd /c npx -y @modelcontextprotocol/server-postgres
claude mcp add filesystem -- cmd /c npx -y @modelcontextprotocol/server-filesystem ./docs ./services
```

### Knowledge & Research

**macOS / Linux:**
```bash
# NotebookLM — Knowledge Base ถาม-ตอบจากเอกสาร
claude mcp add notebooklm -- npx notebooklm-mcp@latest

# MarkItDown — แปลงไฟล์ (PDF, DOCX, XLSX) เป็น Markdown (uvx ไม่ต้อง wrap)
claude mcp add markitdown -- uvx markitdown-mcp
```

**Windows (PowerShell):**
```powershell
claude mcp add notebooklm -- cmd /c npx notebooklm-mcp@latest
claude mcp add markitdown -- uvx markitdown-mcp
```

### Memory & Reasoning

**macOS / Linux:**
```bash
# Memory — Persistent memory ข้าม sessions (basic key-value store)
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory

# Omega Memory — Persistent agent memory + semantic search + multi-agent + knowledge graphs (uvx)
claude mcp add omega-memory -- uvx omega-memory serve

# Sequential Thinking — Chain-of-thought reasoning
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
```

**Windows (PowerShell):**
```powershell
claude mcp add memory -- cmd /c npx -y @modelcontextprotocol/server-memory
claude mcp add omega-memory -- uvx omega-memory serve
claude mcp add sequential-thinking -- cmd /c npx -y @modelcontextprotocol/server-sequential-thinking
```

> **memory vs omega-memory:** `memory` เบาและเรียบง่าย — `omega-memory` ริชกว่า (semantic search, knowledge graph). เลือกตัวใดตัวหนึ่งพอ

### Development Tools

**macOS / Linux:**
```bash
# Playwright — Browser automation สำหรับ E2E testing / smoke test
claude mcp add playwright -- npx -y @playwright/mcp --browser chrome

# Pare Git — Git operations (status, log, diff, show)
claude mcp add pare-git -e PARE_GIT_TOOLS=status,log,diff,show -- npx -y @paretools/git

# Docker — จัดการ containers จาก AI (uvx)
claude mcp add docker -- uvx docker-mcp

# Serena — Code intelligence (uvx)
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server

# Token Optimizer — ลด context 95%+ ผ่าน content deduplication + compression
claude mcp add token-optimizer -- npx -y token-optimizer-mcp
```

**Windows (PowerShell):**
```powershell
claude mcp add playwright -- cmd /c npx -y @playwright/mcp --browser chrome
claude mcp add pare-git -e PARE_GIT_TOOLS=status,log,diff,show -- cmd /c npx -y @paretools/git
claude mcp add docker -- uvx docker-mcp
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server
claude mcp add token-optimizer -- cmd /c npx -y token-optimizer-mcp
```

### One-liner: Core + Dev Tools

**macOS / Linux:**
```bash
claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres && \
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem ./docs ./services && \
claude mcp add notebooklm -- npx notebooklm-mcp@latest && \
claude mcp add markitdown -- uvx markitdown-mcp && \
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory && \
claude mcp add omega-memory -- uvx omega-memory serve && \
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking && \
claude mcp add playwright -- npx -y @playwright/mcp --browser chrome && \
claude mcp add pare-git -e PARE_GIT_TOOLS=status,log,diff,show -- npx -y @paretools/git && \
claude mcp add docker -- uvx docker-mcp && \
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server && \
claude mcp add token-optimizer -- npx -y token-optimizer-mcp
```

**Windows (PowerShell):**
```powershell
claude mcp add postgres -- cmd /c npx -y @modelcontextprotocol/server-postgres `
; claude mcp add filesystem -- cmd /c npx -y @modelcontextprotocol/server-filesystem ./docs ./services `
; claude mcp add notebooklm -- cmd /c npx notebooklm-mcp@latest `
; claude mcp add markitdown -- uvx markitdown-mcp `
; claude mcp add memory -- cmd /c npx -y @modelcontextprotocol/server-memory `
; claude mcp add omega-memory -- uvx omega-memory serve `
; claude mcp add sequential-thinking -- cmd /c npx -y @modelcontextprotocol/server-sequential-thinking `
; claude mcp add playwright -- cmd /c npx -y @playwright/mcp --browser chrome `
; claude mcp add pare-git -e PARE_GIT_TOOLS=status,log,diff,show -- cmd /c npx -y @paretools/git `
; claude mcp add docker -- uvx docker-mcp `
; claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server `
; claude mcp add token-optimizer -- cmd /c npx -y token-optimizer-mcp
```

---

## MCP Server Reference

| MCP Server | ใช้ทำอะไร | Prerequisites | Phase |
|------------|----------|---------------|-------|
| **postgres** | อ่าน DB schema, run queries ผ่าน AI | PostgreSQL running, connection string ใน `.env` | Setup, SD, Impl |
| **filesystem** | อ่านไฟล์ docs/services โดยไม่ต้อง copy-paste | — | ทุก Phase |
| **notebooklm** | Knowledge Base — ถามคำถามจากเอกสาร BRD/PRD/Design Docs | Google account + NotebookLM access | BA, Deliver |
| **markitdown** | แปลง PDF/DOCX/XLSX เป็น Markdown ให้ AI อ่านได้ | Python + `uvx` | BA |
| **playwright** | Browser automation — smoke test, screenshot, E2E | Node.js, Playwright browsers (`npx playwright install`) | Impl, Harden |
| **pare-git** | Git operations — status, log, diff, show ผ่าน AI | Git repo initialized | ทุก Phase |
| **docker** | จัดการ Docker containers — build, start, stop, logs | Docker Desktop running | Impl |
| **serena** | Code intelligence — go-to-definition, find references, symbol search | Python + `uvx`, project with LSP support | Impl, Harden |
| **memory** | Persistent memory ข้าม sessions (basic key-value) | — | ทุก Phase |
| **omega-memory** | Persistent memory + semantic search + multi-agent + knowledge graph | Python + `uvx` | ทุก Phase |
| **sequential-thinking** | Chain-of-thought reasoning ช่วยคิดเป็นขั้นตอน | — | ทุก Phase |
| **token-optimizer** | ลด context 95%+ ผ่าน dedup + compression | — | ทุก Phase (optional) |

## Verify Installation

```powershell
# ดู MCP servers ที่ติดตั้งแล้ว
claude mcp list

# ตรวจสอบ MCP server ทำงานได้
claude mcp status
```

## Scope: Project vs Global

```powershell
# Project scope (default) — เฉพาะโปรเจคนี้ บันทึกใน .claude/settings.json
claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres

# Global scope — ใช้ได้ทุกโปรเจค บันทึกใน ~/.claude/settings.json
claude mcp add -s user postgres -- npx -y @modelcontextprotocol/server-postgres
```

## Environment Variables

MCP servers ที่ต้องการ env vars ให้ตั้งค่าใน `.env`:

```powershell
# PostgreSQL
POSTGRES_CONNECTION_STRING=postgresql://appuser:changeme@localhost:5432/appdb
```

หรือใส่ตอน add:

```powershell
claude mcp add postgres -e POSTGRES_CONNECTION_STRING=postgresql://appuser:changeme@localhost:5432/appdb -- npx -y @modelcontextprotocol/server-postgres
```

## Troubleshooting

| ปัญหา | วิธีแก้ |
|-------|--------|
| `Windows requires 'cmd /c' wrapper to execute npx` | ดู [Windows: `cmd /c` wrapper fix](#windows-cmd-c-wrapper-fix) ด้านล่าง |
| MCP server ไม่ start | ตรวจสอบ `npx`/`uvx` ติดตั้งแล้ว, run manually ดูก่อน |
| Connection timeout | ตรวจ firewall/proxy, ลองเพิ่ม timeout ใน config |
| Permission denied | ตรวจ file permissions, run as admin ถ้าจำเป็น |
| Server crash | ดู logs: `claude mcp logs <server-name>` |

### Windows: `cmd /c` wrapper fix

ถ้าติดตั้งแล้วเจอ warning แบบนี้ใน `claude mcp list`:

```
[Warning] [filesystem] mcpServers.filesystem: Windows requires 'cmd /c' wrapper to execute npx
[Warning] [notebooklm]  mcpServers.notebooklm:  Windows requires 'cmd /c' wrapper to execute npx
...
```

**สาเหตุ:** Node.js `spawn()` บน Windows หา `npx.cmd` ไม่เจอเมื่อ command อยู่นอก `cmd.exe` shell — ต้อง wrap ด้วย `cmd /c` เพื่อให้ shell resolve `.cmd` extension ให้

**วิธีที่ 1 — Re-add ด้วย `cmd /c` (แนะนำ):**

```powershell
# ลบตัวเก่า
claude mcp remove filesystem
claude mcp remove notebooklm
claude mcp remove memory
claude mcp remove sequential-thinking
claude mcp remove playwright
claude mcp remove pare-git
claude mcp remove token-optimizer

# Add ใหม่ด้วย cmd /c wrapper
claude mcp add notebooklm -- cmd /c npx notebooklm-mcp@latest
claude mcp add sequential-thinking -- cmd /c npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add playwright -- cmd /c npx -y @playwright/mcp --browser chrome
claude mcp add pare-git -e PARE_GIT_TOOLS=status,log,diff,show -- cmd /c npx -y @paretools/git
```

**วิธีที่ 2 — แก้ไฟล์ config โดยตรง:**

เปิดไฟล์ config ที่ warning แจ้ง (เช่น `C:\Users\<you>\.claude-pro\.claude.json` หรือ `.claude/settings.json` ใน project) หา `mcpServers` แล้วเปลี่ยนแต่ละ entry จาก:

```json
"filesystem": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "./docs", "./services"]
}
```

เป็น:

```json
"filesystem": {
  "command": "cmd",
  "args": ["/c", "npx", "-y", "@modelcontextprotocol/server-filesystem", "./docs", "./services"]
}
```

ใช้หลักเดียวกันกับ `notebooklm`, `memory`, `sequential-thinking`, `playwright`, `pare-git`, `token-optimizer`, `postgres` — ทุก entry ที่ใช้ `npx`

**ข้อยกเว้น:** `uvx`-based servers (`markitdown`, `omega-memory`, `docker`, `serena`) **ไม่ต้อง** wrap — เป็น native `.exe` ที่ Windows resolve ได้โดยตรง

**ตรวจผล:**

```powershell
claude mcp list
# Warning ควรหายหมด
```

> MCP ecosystem ยังใหม่ — อาจเจอ server crash หรือ timeout ได้ อย่าให้ MCP setup block การเริ่มงาน ใช้ fallback: dump data เป็นไฟล์ใน `docs/` แล้วให้ AI อ่านจาก file แทน
