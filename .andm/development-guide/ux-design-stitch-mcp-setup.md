# Stitch MCP Setup & Operations Guide

> ปฏิบัติการ Stitch MCP server (Google) สำหรับ Mode A `ux-design stitch` workflow — auth setup, recovery จาก broken state, operational quirks ที่เจอจริง, fallback เมื่อใช้ไม่ได้
>
> **ทำไมต้องมี:** ระหว่างใช้งานจริง 2026-05-02/03 เจอปัญหาหลายชั้น (auth error, broken config, Stitch agent ignoring surgical edits, download path traps) ซึ่ง prompt-template + skill SKILL.md ที่มีอยู่ไม่ครอบ. คู่มือฉบับนี้คือ runbook สำหรับครั้งหน้าจะไม่ต้อง debug ตั้งแต่ต้น

---

## 1. ภาพรวม Auth Architecture (เข้าใจก่อน fix)

Stitch MCP มี **2 transport modes**:

| Mode | URL | ใช้ได้กับ Claude Code? | Auth |
|------|-----|----------------------|------|
| **Direct HTTP** | `https://stitch.googleapis.com/mcp` | ❌ NO | ต้องการ DCR (Dynamic Client Registration) ที่ Claude Code MCP client ยังไม่ support |
| **Local proxy (stdio)** | `npx -y @_davideast/stitch-mcp proxy` | ✅ YES | ใช้ `STITCH_API_KEY` env var ; proxy คุย Direct HTTP ให้ |

> ⚠️ **อย่าใช้ Direct HTTP** — `claude mcp list` อาจขึ้น `✓ Connected` หลอกๆ (transport handshake ผ่าน) แต่พอเรียก `list_projects` จะเจอ `Incompatible auth server: does not support dynamic client registration` เพราะ token-renewal flow fail

**Auth credential 2 ตัวเลือก** (หลังเข้าใจ transport แล้ว):

| Type | ตัวอย่างค่า | อายุ | จะหาที่ไหน |
|------|------------|-----|----------|
| **API Key** (แนะนำ) | `AQ.<redacted>` | ไม่หมดอายุ (persistent) | `https://stitch.withgoogle.com/` → Settings → API Keys (UI path อาจเปลี่ยน — search "API key" ใน settings page) |
| **OAuth via gcloud** | (token หมุนใน gcloud config) | 1 ชั่วโมง — proxy refresh ให้ | `gcloud auth application-default login` |

> 💡 ถ้ามีสิทธิ์ + ความรู้ gcloud → OAuth ปลอดภัยกว่า. ส่วนใหญ่ของ MVP/POC → API Key พอ

---

## 2. Clean Install (จาก scratch)

### 2.1 Prerequisites (เช็คก่อนรัน)

```powershell
node --version       # ต้อง ≥ v20 (Stitch CLI ต้องการ)
where.exe npx        # ต้องเจอ
claude --version     # Claude Code CLI
```

### 2.2 ขอ API Key จาก Stitch

1. เปิด `https://stitch.withgoogle.com/` ใน browser (login Google)
2. หา Settings / Account → "API Keys" section → **Generate New Key**
3. copy ค่ารูปแบบ `AQ.<redacted-stitch-api-key-~50+chars>` (ขึ้นต้นด้วย `AQ.` ตามด้วย token random ~50 chars)

### 2.3 Add MCP server (PowerShell — Windows)

```powershell
# ถ้าเคยตั้งของเก่าไว้ → ลบก่อน (กันชนกัน)
claude mcp remove stitch -s user
claude mcp remove stitch -s local

# Add ใหม่ — proxy + env var
claude mcp add stitch -s user `
  -e STITCH_API_KEY=<paste-your-key-here> `
  -- npx -y "@_davideast/stitch-mcp" proxy

# Verify config
claude mcp get stitch
```

ค่าที่ถูกต้องจะเห็น:
```
stitch:
  Scope: User config
  Status: ✓ Connected
  Type: stdio
  Command: npx
  Args: -y @_davideast/stitch-mcp proxy
  Environment:
    STITCH_API_KEY=AQ.<redacted>
```

### 2.4 ⚠️ Restart Claude Code session

MCP servers spawn ตอน session start — **tool `mcp__stitch__*` จะยังไม่ available ใน session ที่ add server เข้าไป**.

```
exit Claude Code → reopen → tools available
```

หลังเปิดใหม่ลอง `list_projects` ผ่าน Stitch MCP — ถ้า return JSON projects = ✅ ใช้งานได้

---

## 3. Recovery จาก Broken State

### 3.1 Symptom: `Command: \` (single backslash) ใน config

```
$ claude mcp get stitch
Status: ✗ Failed to connect
Type: stdio
Command: \
Args: 
```

**Root cause:** `npx @_davideast/stitch-mcp init` interactive wizard ถูก kill ระหว่างกลาง / non-TTY context — config file โดน escape error

**Fix:**
```powershell
claude mcp remove stitch -s local   # อาจอยู่ใน local scope
claude mcp remove stitch -s user    # หรือ user scope
# แล้ว rerun §2.3
```

### 3.2 Symptom: `Incompatible auth server: does not support dynamic client registration`

**Root cause:** ตั้งเป็น Direct HTTP `stitch.googleapis.com/mcp` แทน proxy — transport ผิด

**Fix:** Remove + re-add ผ่าน proxy ตาม §2.3 (ห้ามใช้ `--transport http` กับ stitch.googleapis.com)

### 3.3 Symptom: `✖ Proxy server error: StitchProxy requires an API key (STITCH_API_KEY)`

**Root cause:** Add MCP server แล้วแต่ลืม `-e STITCH_API_KEY=...`

**Fix:** Remove + re-add พร้อม `-e` flag

### 3.4 Symptom: `✓ Connected` แต่ tool calls ไม่ทำงาน

**Root cause:** session ยังไม่ restart หลัง add. Claude Code MCP servers ถูก spawn at session start เท่านั้น

**Fix:** `/exit` แล้วเปิด session ใหม่

### 3.5 Verify Stitch endpoint health

```powershell
npx -y "@_davideast/stitch-mcp" doctor
```

ควรขึ้น:
```
✔ API Key: Detected (AQ.<redacted>)
✔ Stitch API: Healthy (200)
All checks passed!
```

ถ้า doctor ผ่านแต่ MCP ยัง fail = ปัญหาที่ Claude Code-side (config, session restart, transport)

---

## 4. Operational Quirks (ที่เจอจริง — ครั้งหน้าระวัง)

### 4.1 `edit_screens` สร้าง screen ID ใหม่ทุกครั้ง (immutable)

```
Original: 1d5fc0d85a6c4810a8d0c39debd1e46a
After edit_screens: c633d592de7d4e548c7cbec3abf87a95   ← NEW ID
```

**Implication:**
- ของเก่ายังอยู่ใน Stitch project (ไม่ถูกลบ)
- ต้อง track "current canonical screen ID" per page เอง
- Local file naming: ใช้ slug เช่น `heartbeat-desktop.html` แล้วเขียนทับ — **อย่า** ใส่ screen ID ใน filename
- ถ้า user edit ซ้ำหลายรอบ → list_screens อาจมี 5-10 versions ของหน้าเดียว — เก็บแค่ตัวล่าสุดในเอกสาร

### 4.2 Stitch agent **มี limit ที่ surgical text edit**

ตัวอย่างจริง: ขอเปลี่ยน timestamp `2024 → 2026` ใน 10 rows. ลอง 2 ครั้งด้วย explicit instruction — ครั้งแรก agent เปลี่ยนเป็น 2024 ครั้งที่สองยังคง 2024.

**Workaround:**
- ครั้งแรก state mock data ที่ถูก year ตั้งแต่ prompt แรก (อย่ารอ edit ภายหลัง)
- ถ้าหลีกเลี่ยงไม่ได้ → ใช้ `generate_screen_from_text` ใหม่หมดแทน edit (จ่ายเครดิต+เวลามากกว่าแต่แม่นกว่า)
- ยอมรับ cosmetic miss ใน mock data — production code ใช้ real `IClock` injection อยู่แล้ว

### 4.3 Stitch agent **เพิ่ม element ที่ไม่ขอ**

ตัวอย่างจริง: ขอ Notifications page → agent เพิ่ม "Delivery Performance (24h)" chart + "Channel Health" card ที่ไม่ได้ขอ.

**Workaround:**
- ใน prompt ใช้ phrase **"END the page exactly with X"** หรือ **"DO NOT add chart/cards/sections beyond what's listed"**
- หรือ trim ผ่าน `edit_screens` ทีหลัง (จ่ายเครดิตเพิ่ม)

### 4.4 Sidebar nav drift ระหว่างหน้า

หาก project มีหลาย screens — Stitch agent อาจ render sidebar ที่ต่างกันแต่ละหน้า (เช่น 7 items vs 9 items, ลำดับสลับ).

**Workaround:**
- ในทุก prompt ระบุ **canonical sidebar list verbatim** (item names, order, active item)
- พิจารณาเขียน sidebar spec ลง `designMd` field ใน design system → Stitch จะอ่านทุกครั้ง (แต่ก็ไม่ guarantee 100%)
- ใช้ `edit_screens` fix sidebar drift เป็น targeted edit หลัง bulk-generate

### 4.5 `roundness` field รับค่าเดียว

Stitch DesignSystem schema:
- `roundness: ROUND_FOUR | ROUND_EIGHT | ROUND_TWELVE | ROUND_FULL` — **เลือกได้แค่ 1 ค่า**
- แต่ design system จริงต้องการ buttons 8px + cards 12px + pills full

**Workaround:**
- เลือกค่าหลัก (e.g., `ROUND_EIGHT` สำหรับ buttons เพราะใช้บ่อยสุด)
- ระบุค่า off-default ใน `designMd` field เช่น `"### Card: rounded.lg = 12px"` + `"### Status Pill: rounded-full"`
- Stitch agent จะอ่าน designMd และ apply per-component roundness ตามที่ระบุ (most of the time)

### 4.6 Screenshot PNG = thumbnail เท่านั้น (~512×410)

`screenshot.downloadUrl` คืน **thumbnail** (ไม่ใช่ full 1440px design). ดูภาพรวมได้ แต่อ่าน detail เล็กๆ ไม่ได้.

**Workaround:**
- เปิด `htmlCode.downloadUrl` HTML ใน browser ที่ window 1440px เพื่อดู full fidelity
- ใน docs/ux/03-page-layouts.md → link HTML file (`.stitch/designs/heartbeat-desktop.html`) เป็น primary, PNG เป็น preview

### 4.7 Download URLs **มี expiry**

`htmlCode.downloadUrl` + `screenshot.downloadUrl` เป็น signed URLs (Google Cloud Storage style) อายุประมาณ 1-24 ชั่วโมง.

**Workaround:**
- Download ทันทีหลัง generate/edit ก่อนที่ URL จะหมดอายุ
- ถ้า miss → call `get_screen` ใหม่ จะได้ fresh URL

---

## 5. Download Pattern Pitfall (Windows-specific)

### 5.1 ❌ Anti-pattern (ที่เจอ + แก้)

```bash
# ผิด: cd ไม่ propagate to background subshells consistently
cd .stitch/designs && \
  curl -sL <url-1> -o file-1.html & \
  curl -sL <url-2> -o file-2.html & \
  wait
```

ผลที่เจอ: บางไฟล์ตกที่ project root, บางไฟล์ตกที่ `.stitch/designs/`, บาง URL silently fail.

### 5.2 ✅ Pattern ที่ใช้ได้แน่

```bash
# ใช้ absolute output path ตรงๆ (ไม่พึ่ง cd)
curl -sL <url-1> -o .stitch/designs/heartbeat-desktop.html
curl -sL <url-2> -o .stitch/designs/heartbeat-desktop.png
```

หรือ batch parallel ได้ปลอดภัย:

```bash
curl -sL <url-1> -o .stitch/designs/file-1.html & \
curl -sL <url-2> -o .stitch/designs/file-2.html & \
curl -sL <url-3> -o .stitch/designs/file-3.html & \
wait
```

(ใช้ absolute path; ไม่ใช้ `cd` ใน chain)

### 5.3 Naming convention

```
.stitch/designs/
  heartbeat-desktop.html
  heartbeat-desktop.png
  heartbeat-mobile.html       ← ถ้ามี mobile variant
  packs-desktop.html
  packs-desktop.png
  pack-detail-desktop.html    ← detail view
  ...
```

- Slug = page slug (ไม่ใช่ Stitch screen ID — IDs เปลี่ยนทุก edit)
- Suffix = device type (`-desktop`, `-mobile`, `-tablet`)
- เขียนทับเสมอเมื่อ `edit_screens` (latest only)

---

## 6. Fallback เมื่อ Stitch MCP ใช้ไม่ได้

ถ้าเจอกรณีต่อไปนี้ + ไม่มีเวลา/สิทธิ์ debug:
- Stitch API quota เต็ม
- Google Cloud project ไม่ accessible
- API key ถูก revoke
- Proxy package เสีย (npm registry issue)
- Browser ไม่ได้ → ขอ API key ใหม่ไม่ได้

→ **Fallback Mode D (`reference`)** — ดู `.andm/development-guide/ux-design-workflow.md` Mode D + `ux-design-reference-acquisition.md`

```
Stitch MCP unreachable
    ↓
ดู design-reference/<name>-DESIGN.md ที่มีอยู่
    ↓
ถ้ามี → /ux-design reference (skip Stitch entirely)
ถ้าไม่มี → acquire DESIGN.md per acquisition guide → /ux-design reference
```

**Tradeoff:**
- ✅ ไม่ต้องพึ่ง online service / API quota
- ✅ ไม่ต้อง auth setup
- ❌ ไม่มี high-fidelity mockups (text spec only)
- ❌ visual review รอบ stakeholder ยากกว่า (ต้องเห็น text + จินตนาการ)

ก่อน fallback บันทึกที่ `docs/state/overview.md` ว่าทำไมเปลี่ยน mode (Stitch unavailable → Mode D)

---

## 7. CLAUDE.md Drift Watch

> ตรงนี้ไม่ใช่ Stitch-specific แต่เป็น operational lesson ที่เจอตอน entry — กระทบเลือก Stitch หรือไม่

**ก่อนรัน `/ux-design <mode>`** ตรวจ:
1. CLAUDE.md §2 บอก Frontend stack ว่าอะไร
2. **Cross-check** `docs/technical-design/03-frontend-design.md` — ถ้า doc มี `**Date:** YYYY-MM-DD (rewritten YYYY-MM-DD per BT-NNN)` ใหม่กว่า CLAUDE.md → trust TD
3. ถ้า CLAUDE.md บอก "no GUI / N/A" แต่ TD-03 มี frontend stack → CLAUDE.md ล้าหลัง (เกิดได้ระหว่าง BT-NNN backtrack ที่ rewrite TD แต่ยังไม่ rerun `/project-init`)

ดู `docs/state/backtrack-log.md` เพื่อดู in-flight scope changes

---

## 8. Quick Reference

| Task | Command / Tool |
|------|----------------|
| ดู MCP servers ทั้งหมด | `claude mcp list` |
| ดู Stitch config | `claude mcp get stitch` |
| ลบ Stitch config | `claude mcp remove stitch -s user` |
| Add Stitch (proxy + API key) | `claude mcp add stitch -s user -e STITCH_API_KEY=<key> -- npx -y "@_davideast/stitch-mcp" proxy` |
| ตรวจ Stitch API health | `npx -y "@_davideast/stitch-mcp" doctor` |
| รัน proxy ตรงๆ (debug) | `npx -y "@_davideast/stitch-mcp" proxy` |
| Generate screen | `mcp__stitch__generate_screen_from_text` (ดู prompt structure §3 ของ `ux-design-stitch-prompt.md`) |
| Edit existing screen | `mcp__stitch__edit_screens` (selectedScreenIds = ล่าสุด ของหน้านั้น ไม่ใช่ original) |
| Download HTML/PNG | `curl -sL <htmlCode.downloadUrl> -o .stitch/designs/<slug>-desktop.html` (absolute path เสมอ) |

---

## 9. Lessons Logged 2026-05-03 (history — ลบได้หลัง revisit ครั้งแรกที่ใช้ guide นี้)

- **18:00** ใช้ `/ux-design stitch` ครั้งแรก — refused เพราะ CLAUDE.md บอก "no GUI" → user ชี้ TD-03 → realize CLAUDE.md drift → save memory `feedback_check_td_before_claude_md.md` → §7 ของ guide
- **22:30** Stitch MCP ตั้งเป็น Direct HTTP + static Bearer → DCR error → §1 + §3.2
- **23:30** ลอง `init` wizard interactive → fail → broken `Command: \` → §3.1
- **00:10** เข้าใจว่าต้องใช้ proxy + API key env var → §2.3 working
- **00:32** Bash `cd .stitch/designs && curl &` ทำให้ overview-desktop.html missing → §5.1 anti-pattern
- **00:53** `edit_screens` 2 รอบ ขอแก้ year `2024 → 2026` — agent เมินทั้ง 2 รอบ → §4.2 surgical-edit limit

> เมื่อ guide นี้ถูก revisit ครั้งแรกในงานจริง — ถ้าทุกข้อใน §9 ยัง relevant ก็คงไว้ ; ถ้าแก้ไขใน Stitch หรือ Claude Code แล้วก็ลบหรือ archive
