# Claude Code Hooks Setup Guide

> Automated quality checks ที่รันอัตโนมัติตาม lifecycle events ของ Claude Code
> ลด manual work + ป้องกันความผิดพลาดที่ซ้ำๆ

---

## Hook Events ที่ใช้

| Event | เมื่อไร | ทำอะไรได้ |
|-------|---------|----------|
| **PreToolUse** | ก่อน tool execution | Block (exit 2) หรือ warn (stderr) |
| **PostToolUse** | หลัง tool execution | Log, analyze output (ไม่ block) |
| **Stop** | หลัง Claude ตอบแต่ละรอบ | Batch operations (format, typecheck) |
| **Notification** | เมื่อ Claude แสดง notification | React to events |

---

## 3 Profiles — เลือกตาม context

| Profile | เหมาะกับ | Hooks ที่ active |
|---------|---------|-----------------|
| **minimal** | Prototyping, early design phases | Security เท่านั้น (block secrets, block --no-verify) |
| **standard** | Development ปกติ (แนะนำ) | + lint, typecheck, commit quality, config protection |
| **strict** | Pre-release, hardening phase | + console.log warning, compact suggestion, full test |

```bash
# ตั้ง profile ผ่าน env var (default: standard)
export AINDEV_HOOK_PROFILE=standard
```

---

## Quick Setup

### วิธีที่ 1: Copy settings เข้า project

Copy hook config ด้านล่างเข้า `.claude/settings.json` ของ project:

```bash
# ถ้ายังไม่มี settings.json
cat > .claude/settings.json << 'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'CMD=$(echo $CLAUDE_TOOL_INPUT | jq -r .command 2>/dev/null); echo \"$CMD\" | grep -qE \"\\-\\-no-verify\" && echo \"BLOCKED: --no-verify is not allowed\" >&2 && exit 2; exit 0'"
          }
        ],
        "description": "Block --no-verify flag on git commands"
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'CMD=$(echo $CLAUDE_TOOL_INPUT | jq -r .command 2>/dev/null); echo \"$CMD\" | grep -qiE \"git commit\" && echo \"$CMD\" | grep -qiE \"(password|secret|token|api.?key)\" && echo \"BLOCKED: possible secret in commit message\" >&2 && exit 2; exit 0'"
          }
        ],
        "description": "Block commits with potential secrets in message"
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'FILE=$(echo $CLAUDE_TOOL_INPUT | jq -r .file_path 2>/dev/null); echo \"$FILE\" | grep -qE \"\\.(eslintrc|prettierrc|biome|markdownlint)\" && echo \"BLOCKED: Do not modify linter/formatter config — fix the code instead\" >&2 && exit 2; echo \"$FILE\" | grep -qE \"(eslint\\.config|prettier\\.config|biome\\.json)\" && echo \"BLOCKED: Do not modify linter/formatter config — fix the code instead\" >&2 && exit 2; exit 0'"
          }
        ],
        "description": "Protect linter/formatter configs from being weakened"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'CMD=$(echo $CLAUDE_TOOL_INPUT | jq -r .command 2>/dev/null); TS=$(date -u +%%Y-%%m-%%dT%%H:%%M:%%SZ); SAFE=$(echo \"$CMD\" | sed -E \"s/(password|token|secret|api.?key)[= ][^ ]*/\\1=REDACTED/gi\"); echo \"[$TS] $SAFE\" >> .claude/bash-commands.log 2>/dev/null; exit 0'"
          }
        ],
        "description": "Audit log bash commands (secrets redacted)"
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'if [ -f .claude/edited-files.tmp ]; then while IFS= read -r f; do [ -f \"$f\" ] && npx --yes biome check --write \"$f\" 2>/dev/null || npx --yes prettier --write \"$f\" 2>/dev/null; done < .claude/edited-files.tmp; rm -f .claude/edited-files.tmp; fi; exit 0'",
            "timeout": 30000
          }
        ],
        "description": "Batch format edited files after each response"
      }
    ]
  }
}
EOF
```

### วิธีที่ 2: ใช้ claude mcp add (ถ้า IDE รองรับ)

```bash
# Claude Code settings can be edited directly
claude settings set hooks.PreToolUse '[...]'
```

> **Note:** วิธีที่ 1 (copy file) ง่ายที่สุด — commit `.claude/settings.json` เข้า repo เพื่อ share กับทั้งทีม

---

## Hook Reference — ทุก hook ที่แนะนำ

### PreToolUse Hooks (ป้องกันก่อนทำ)

#### 1. Block `--no-verify` (Profile: minimal+)

ป้องกัน agent ข้าม pre-commit hooks

```json
{
  "matcher": "Bash",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'CMD=$(echo $CLAUDE_TOOL_INPUT | jq -r .command 2>/dev/null); echo \"$CMD\" | grep -qE \"\\-\\-no-verify\" && echo \"BLOCKED: --no-verify is not allowed — fix the hook issue instead\" >&2 && exit 2; exit 0'"
  }],
  "description": "Block --no-verify flag on git commands"
}
```

**ทำไมสำคัญ:** AI agents มักใส่ `--no-verify` เมื่อ pre-commit hook fail แทนที่จะ fix root cause — hook นี้บังคับให้แก้ปัญหาจริง

#### 2. Block Secrets in Commits (Profile: minimal+)

ป้องกัน commit message ที่มี secrets

```json
{
  "matcher": "Bash",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'CMD=$(echo $CLAUDE_TOOL_INPUT | jq -r .command 2>/dev/null); echo \"$CMD\" | grep -qiE \"git commit\" && echo \"$CMD\" | grep -qiE \"(password|secret|token|api.?key)\" && echo \"BLOCKED: possible secret in commit message\" >&2 && exit 2; exit 0'"
  }],
  "description": "Block commits with potential secrets in message"
}
```

#### 3. Protect Linter/Formatter Configs (Profile: standard+)

ป้องกัน agent แก้ config เพื่อ bypass lint errors แทนที่จะ fix code

```json
{
  "matcher": "Write|Edit",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'FILE=$(echo $CLAUDE_TOOL_INPUT | jq -r .file_path 2>/dev/null); echo \"$FILE\" | grep -qE \"\\.(eslintrc|prettierrc|biome|markdownlint)\" && echo \"BLOCKED: Do not modify linter/formatter config — fix the code instead\" >&2 && exit 2; echo \"$FILE\" | grep -qE \"(eslint\\.config|prettier\\.config|biome\\.json)\" && echo \"BLOCKED: Do not modify linter/formatter config — fix the code instead\" >&2 && exit 2; exit 0'"
  }],
  "description": "Protect linter/formatter configs from being weakened"
}
```

**ทำไมสำคัญ:** AI agents ชอบแก้ `.eslintrc` เพื่อปิด rule ที่ fail แทนที่จะ fix code — hook นี้บังคับให้แก้ code

#### 4. Block Force Push to Main (Profile: minimal+)

```json
{
  "matcher": "Bash",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'CMD=$(echo $CLAUDE_TOOL_INPUT | jq -r .command 2>/dev/null); echo \"$CMD\" | grep -qE \"git push.*(--force|-f).*main\" && echo \"BLOCKED: Force push to main is not allowed\" >&2 && exit 2; echo \"$CMD\" | grep -qE \"git push.*(--force|-f).*master\" && echo \"BLOCKED: Force push to master is not allowed\" >&2 && exit 2; exit 0'"
  }],
  "description": "Block force push to main/master"
}
```

---

### PostToolUse Hooks (log + analyze หลังทำ)

#### 5. Bash Command Audit Log (Profile: minimal+)

Log ทุก bash command ที่ agent รัน (secrets ถูก redact)

```json
{
  "matcher": "Bash",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'CMD=$(echo $CLAUDE_TOOL_INPUT | jq -r .command 2>/dev/null); TS=$(date -u +%Y-%m-%dT%H:%M:%SZ); SAFE=$(echo \"$CMD\" | sed -E \"s/(password|token|secret|api.?key)[= ][^ ]*/\\1=REDACTED/gi\"); echo \"[$TS] $SAFE\" >> .claude/bash-commands.log 2>/dev/null; exit 0'"
  }],
  "description": "Audit log bash commands (secrets redacted)"
}
```

**Output:** `.claude/bash-commands.log` — ดูย้อนหลังว่า agent รัน command อะไรบ้าง

---

### Stop Hooks (batch operations หลัง response)

#### 6. Batch Format Edited Files (Profile: standard+)

Format ไฟล์ที่ถูกแก้ไขทั้งหมดในรอบนี้ — ดีกว่า format ทุกครั้งที่ edit เพราะลด overhead

```json
{
  "matcher": "",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'if [ -f .claude/edited-files.tmp ]; then while IFS= read -r f; do [ -f \"$f\" ] && npx --yes biome check --write \"$f\" 2>/dev/null || npx --yes prettier --write \"$f\" 2>/dev/null; done < .claude/edited-files.tmp; rm -f .claude/edited-files.tmp; fi; exit 0'",
    "timeout": 30000
  }],
  "description": "Batch format edited files after each response"
}
```

> **Note:** ต้องใช้คู่กับ PostToolUse Edit hook ที่ record edited files (hook #7)

#### 7. Record Edited Files for Batch Processing (Profile: standard+)

```json
{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'FILE=$(echo $CLAUDE_TOOL_INPUT | jq -r .file_path 2>/dev/null); echo \"$FILE\" | grep -qE \"\\.(ts|tsx|js|jsx|json|css|md)$\" && echo \"$FILE\" >> .claude/edited-files.tmp; exit 0'"
  }],
  "description": "Record edited files for batch format at Stop"
}
```

---

## Profile Matrix

| # | Hook | Event | minimal | standard | strict |
|---|------|-------|:-------:|:--------:|:------:|
| 1 | Block --no-verify | PreToolUse | ✅ | ✅ | ✅ |
| 2 | Block secrets in commits | PreToolUse | ✅ | ✅ | ✅ |
| 3 | Protect linter configs | PreToolUse | — | ✅ | ✅ |
| 4 | Block force push main | PreToolUse | ✅ | ✅ | ✅ |
| 5 | Bash command audit log | PostToolUse | ✅ | ✅ | ✅ |
| 6 | Batch format edited files | Stop | — | ✅ | ✅ |
| 7 | Record edited files | PostToolUse | — | ✅ | ✅ |

---

## Phase-Specific Hook Recommendations

| Phase | แนะนำ Profile | เหตุผล |
|-------|--------------|--------|
| Phase 0: Setup | minimal | กำลัง scaffold ยังไม่มี code ให้ lint |
| Phase 1: Design | minimal | สร้าง docs ไม่ต้อง typecheck |
| Phase 2: Design QA | minimal | Review/rebuttal ไม่แก้ code |
| Phase 3: Implement | **standard** | เขียน code จริง — ต้อง lint + format + protect config |
| Phase 4: Harden | **strict** | Security phase — ทุก hook active |
| Phase 5: Deliver | minimal | สรุปเอกสาร ไม่แก้ code |

```bash
# เปลี่ยน profile ตาม phase
export AINDEV_HOOK_PROFILE=standard  # Phase 3
export AINDEV_HOOK_PROFILE=strict    # Phase 4
```

---

## Optional Hooks

### Simplify-Ignore (Protected Code Blocks)

ป้องกัน code ที่ intentionally complex (performance-critical, platform workaround) จากการถูก agent "simplify" โดยไม่ตั้งใจ

**วิธีใช้:** Developer annotate code ที่ต้องการปกป้อง:

```javascript
/* simplify-ignore-start: performance-critical hot loop — O(1) lookup via bitwise */
const idx = (hash >>> 0) & (buckets.length - 1);
/* simplify-ignore-end */
```

**Hook (PreToolUse — Profile: standard+):**

```json
{
  "matcher": "Edit",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'FILE=$(echo $CLAUDE_TOOL_INPUT | jq -r .file_path 2>/dev/null); OLD=$(echo $CLAUDE_TOOL_INPUT | jq -r .old_string 2>/dev/null); [ -f \"$FILE\" ] && grep -q \"simplify-ignore-start\" \"$FILE\" && echo \"$OLD\" | grep -q \"simplify-ignore\" && echo \"BLOCKED: This code block is protected by simplify-ignore — do not modify without explicit approval\" >&2 && exit 2; exit 0'",
    "timeout": 5000
  }],
  "description": "Protect simplify-ignore annotated code blocks from modification"
}
```

**ทำไมสำคัญ:** AI agents มีแนวโน้มจะ "simplify" code ที่ดู complex — แต่บาง code complex ด้วยเหตุผล (performance, platform quirks, legacy compatibility) annotation นี้ให้ developer ปกป้อง code เหล่านี้อย่างชัดเจน

**Supported annotations:**
- `/* simplify-ignore-start: reason */` ... `/* simplify-ignore-end */`
- `# simplify-ignore-start: reason` ... `# simplify-ignore-end` (Python)
- `// simplify-ignore-start: reason` ... `// simplify-ignore-end` (C#, TypeScript)

---

## Customization

### เพิ่ม hook ของตัวเอง

Hook format คือ JSON ใน `.claude/settings.json`:

```json
{
  "matcher": "ToolName",
  "hooks": [{
    "type": "command",
    "command": "bash -c '...your script...'",
    "timeout": 10000
  }],
  "description": "What this hook does"
}
```

**Exit codes:**
- `0` = success (tool proceeds)
- `2` = block tool execution (PreToolUse only)
- อื่นๆ = error (logged, ไม่ block)

**Matchers:** `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep` หรือ `Edit|Write` (combine ด้วย `|`)

### ปิด hook ชั่วคราว

```bash
# ปิดทุก hook ชั่วคราว
export AINDEV_HOOKS_DISABLED=1

# ปิดเฉพาะบาง hook
# → comment out ใน .claude/settings.json
```

---

## Troubleshooting

| ปัญหา | วิธีแก้ |
|-------|--------|
| Hook block tool ที่ไม่ควร block | ตรวจ regex ใน command — อาจ match กว้างเกินไป |
| Hook ไม่ทำงาน | ตรวจว่า `jq` ติดตั้งแล้ว (`which jq`) |
| Format hook ช้า | เพิ่ม timeout หรือ filter เฉพาะ file types ที่ต้องการ |
| Hook error ทุก command | ตรวจ JSON syntax ใน settings.json (`jq . .claude/settings.json`) |

---

## Credits

Hook patterns adapted from [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — simplified สำหรับ AI-Native Development methodology
