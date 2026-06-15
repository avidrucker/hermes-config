---
name: error-telemetry
description: "Error logging and session learning capture. Covers structured error logging to SQLite (error types, context shapes, de-duplication) and TIL (Today I Learned) document workflow for session retrospectives. Use when a tool call fails, a hook blocks, a claim fails, or when the user says 'write a TIL' or 'write up what you learned'. Both use configurable DB paths and commands for portability."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [error-logging, debugging, retrospective, learning, workflow, sqlite, telemetry, til]
    related_skills: [puzzle-workflow, issue-lifecycle]
---

# Error Telemetry — Logging & Learnings

Two complementary telemetry systems:
1. **Error Logging** — structured error recording to SQLite for pattern detection
2. **TIL Documents** — session retrospectives as permanent learning documents

---

## A. Error Logging Protocol

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ERROR_LOG_DB` | `~/.lccjs/lccjs.db` | SQLite database path |
| `ERROR_LOG_CMD` | `npm run error:log` | Log command (receives JSON) |
| `ERROR_LOG_AGENT` | (required) | Agent identifier (e.g., `HONEYDEW`) |
| `ERROR_LOG_MODEL` | (required) | Model short-form |

### Triggers — Log When
- Command exits non-zero with work impact
- Tool call returns error result
- `npm run claim` fails
- Git operation fails
- `gh` CLI returns error
- Hook exits non-zero and blocks commit
- SQLite/velocity log call fails

### Always Log
Every error, misfire, glitch — including immediately resolved ones. A single resolved conflict is noise; ten in a week is a pattern.

### Skip When (De-duplication Only)
- Purely informational warning with no work-plan impact (e.g., `[MODULE_TYPELESS_PACKAGE_JSON]`)
- Same error already logged for this ticket in this session

### Log Command
```bash
<ERROR_LOG_CMD> -- '{
  "occurred_iso": "<ISO8601>",
  "agent": "<NAME>",
  "model": "<model>",
  "ticket": <N>,
  "error_type": "<TYPE>",
  "message": "<raw message>",
  "context": "<JSON>",
  "notes": "<annotation>"
}'
```

Capture `occurred_iso` with `date '+%Y-%m-%dT%H:%M:%S%z'` at the moment of failure.

### error_type Vocabulary

| Code | When to use |
|------|-------------|
| `TOOL_DENIED` | User rejected tool permission |
| `HOOK_BLOCK` | pre-commit/pre-push hook blocked |
| `CLAIM_FAIL` | `npm run claim` failed |
| `BASH_FAIL` | Command exited non-zero |
| `GIT_FAIL` | git push/rebase/commit failed |
| `GIT_STATE` | Git state mismatch (cwd deleted, etc.) |
| `GH_FAIL` | gh CLI / API error |
| `GH_INFO` | gh revealed wrong workflow assumption |
| `DB_FAIL` | SQLite operation failed |
| `FILE_FAIL` | Read/Write/Edit tool failure |
| `EDIT_PRECOND` | old_string not found, file not read |
| `SKILL_FAIL` | Skill invocation errored |
| `NETWORK_FAIL` | Timeout or connectivity error |
| `VALIDATION_FAIL` | Schema validation error |
| `OTHER` | Fallback |

### context JSON Shapes
```jsonc
// BASH_FAIL / GIT_FAIL
{"cmd": "git push", "exit_code": 1, "stderr": "first ~100 chars"}

// HOOK_BLOCK
{"hook": "pre-push", "stderr": "first ~100 chars"}

// CLAIM_FAIL
{"cmd": "npm run claim -- 880 --as CHERRY", "reason": "already claimed by GRAPE"}

// FILE_FAIL
{"tool": "patch", "path": "/src/core/assembler.js", "error": "ENOENT"}
```

### Querying Logged Errors
```bash
sqlite3 "$ERROR_LOG_DB" "SELECT id, occurred_iso, agent, error_type, message FROM errors ORDER BY id DESC LIMIT 10"
sqlite3 "$ERROR_LOG_DB" "SELECT error_type, COUNT(*) as n FROM errors GROUP BY error_type ORDER BY n DESC"
sqlite3 "$ERROR_LOG_DB" "SELECT id, error_type, message FROM errors WHERE ticket = 880"
```

### Pitfalls
1. Log even if "fixed immediately" — pattern matters
2. Don't use `OTHER` when a specific code fits
3. Capture `occurred_iso` at moment of failure, not after resolution
4. Don't log informational warnings as errors
5. De-duplicate within session — same error 3x = log once with `notes: "occurred 3x"`

---

## B. TIL (Today I Learned) Documents

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `TIL_DOCS_DIR` | `docs/learnings/` | Directory for TIL markdown files |
| `TIL_INDEX_FILE` | `docs/learnings/README.md` | Index file to update |
| `VELOCITY_CMD` | `npm run velocity:log` | Velocity log command |
| `CLOSE_CMD` | `npm run close` | Close command |
| `TIL_AGENT` | (required) | Agent identifier |
| `TIL_MODEL` | (required) | Model short-form |

### When to Use
- "write a TIL", "write up what you learned", "add to learnings"
- End-of-session retrospective

### Workflow
1. **Pre-flight** — capture `date` before reading anything
2. **Draft** — write per `references/til-content-spec.md`
3. **File GitHub issue** — `gh issue create --title "TIL YYYY-MM-DD AGENT — theme" --label "severity:low"`
4. **Claim worktree** — `npm run claim -- <N> --as <fruit>`
5. **Write file + README index row** — mandatory, not optional
6. **Log velocity + commit** — CSV + TIL file + README in ONE commit with `Closes #N`
7. **Close** — `$CLOSE_CMD <N>`

### Issue Title Format
```
TIL YYYY-MM-DD AGENT — theme
```
Uses **em-dash** (`—`), not colon or hyphen. No BDD structure (TIL is BDD-exempt).

### README Index Row
```
| [TIL YYYY-MM-DD AGENT](./today-i-learned-YYYY-MM-DD-<agent>.md) | YYYY-MM-DD | AGENT | One-sentence theme. |
```

### Commit Pattern
```bash
git add $TIL_DOCS_DIR/today-i-learned-*.md $TIL_INDEX_FILE docs/puzzle-velocity.csv
git commit -m "docs(learnings): TIL YYYY-MM-DD AGENT — theme (#N)

data(velocity): log #N (AGENT, WRITER, Xm)

Closes #N"
```

### Pitfalls
1. **Skipping README row** — always add the row, it's mandatory
2. **BDD structure** — TIL is exempt, diary format only
3. **Colon in title** — use em-dash
4. **CSV in separate commit** — must share the `Closes #N` commit
5. **No start timestamp** — capture before reading the issue

---

## @todo — generalize beyond lccjs

lccjs is the only consumer today, so these defaults are intentionally hardcoded. To use this skill on another project, override via the Configuration table:
- `ERROR_LOG_DB` default `~/.lccjs/lccjs.db` and `ERROR_LOG_CMD` default `npm run error:log` are lccjs-specific — point them at the new project's telemetry store/command.
- Example agent identifiers (`HONEYDEW`, etc.) reflect the lccjs fruit-agent roster.
