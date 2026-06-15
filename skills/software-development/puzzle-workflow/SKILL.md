---
name: puzzle-workflow
description: "Puzzle-based development workflow: triage/backlog ranking and velocity/time tracking. Use when asked 'what should I work on next?', 'triage the backlog', 'rank the issues', or when picking up/closing a ticket that needs time tracking. Covers severity-based prioritization, wall-clock logging, H/C estimates, and velocity CSV export."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [puzzle, triage, velocity, time-tracking, estimation, workflow, prioritization, backlog]
    related_skills: [yegor-pm, log-error, next-best-action]
---

# Puzzle Workflow — Triage & Velocity

Two tightly coupled tools for puzzle-based development:
1. **Triage** — rank open issues by severity, split out blocked/iceboxed/in-flight work
2. **Velocity** — track wall-clock time per ticket with H/C estimates and calibration

---

## A. Triage — Backlog Ranking

### Algorithm

**Fetch all data in parallel:**
```bash
gh issue list --state open --limit 100 \
  --json number,title,labels,createdAt \
  -q '.[] | "\(.number)\t\([.labels[].name]|join(","))\t\(.title)"'
npm run puzzle:status
git worktree list
```

**Partition (in order):**

| Partition | Criteria | Emoji |
|-----------|----------|-------|
| Humans-only | Labels: `humans-only`, `decision`, `human-decision-required` | 🧑 |
| Icebox | Labels: `proposal`, `wontfix` | 💤 |
| Blocked | Label: `blocked` | ⛔ |
| In-flight | Live worktree exists | 🔵 |
| Actionable | Everything else | 🎯 |

**Rank actionable by:** severity (high→medium→low→untriaged) → shortest estimate → lowest issue number.

### Output Format
```
## 🎯 Actionable — Yegor Priority Order
| # | Title | Severity | Est | Labels |
|---|-------|----------|-----|--------|
| 880 | Fix parser crash | 🔴 | 30m | bug,area:core |

## 🧑 Requires Human Routing
## ⛔ Blocked
## 💤 Icebox
## 🔵 In-Flight
```

### Sequencing Constraints
Tickets with `Sequenced after: #N` must not be assigned ahead of their dependency.
- #N CLOSED → freely assignable
- #N OPEN + in-flight → hold, annotate `⏳ waiting on #N`
- #N OPEN + unclaimed → assign #N first

### Pitfalls
1. Never trigger on agent-readiness greetings
2. Read-only — no mutations
3. Always partition out humans-only first
4. Check worktrees to avoid double-assignment
5. For large backlogs (>200), use tab-separated format to avoid JSON truncation
6. **Worktree file writes need absolute paths** — `write_file` and `patch` inside a worktree can resolve `~` to the main checkout's `$HOME`, not the worktree. Always use absolute paths (e.g., `/home/avi/.hermes/skills/...`) when writing outside the worktree directory. Verify the resolved path is under `.claude/worktrees/<name>/` before editing.
---

## B. Velocity — Time Tracking

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `VELOCITY_DB` | `~/.lccjs/lccjs.db` | SQLite database path |
| `VELOCITY_CMD` | `npm run velocity:log` | Log command (receives JSON) |
| `VELOCITY_CSV` | `docs/puzzle-velocity.csv` | CSV export path |
| `VELOCITY_AGENT` | (required) | Agent identifier (e.g., `HONEYDEW`) |
| `VELOCITY_MODEL` | (required) | Model short-form |

### Dual-Estimate System

| Field | Meaning |
|-------|---------|
| `h_min` | Human estimate (minutes) |
| `c_min` | Agent calibration estimate (minutes) |
| `actual_min` | Wall-clock minutes spent |
| `delta_h_min` | `h_min - actual_min` (positive = under budget) |
| `delta_c_min` | `c_min - actual_min` (agent calibration error) |

### Workflow

**Start of work** — capture timestamp BEFORE reading the issue:
```bash
STARTED=$(date '+%Y-%m-%dT%H:%M:%S%z')
```

**End of work** — capture finish, then log:
```bash
FINISHED=$(date '+%Y-%m-%dT%H:%M:%S%z')
$VELOCITY_CMD -- '{
  "ticket": N, "title": "Issue title",
  "role": "DEV", "agent": "HONEYDEW",
  "h_min": 30, "c_min": 20, "actual_min": 25,
  "delta_h_min": 5, "delta_c_min": -5,
  "started_iso": "'$STARTED'", "finished_iso": "'$FINISHED'",
  "model": "owl-alpha"
}'
```

### Querying Velocity Data
```bash
sqlite3 "$VELOCITY_DB" "SELECT id, ticket, actual_min, delta_c_min FROM velocity ORDER BY id DESC LIMIT 10"
sqlite3 "$VELOCITY_DB" "SELECT agent, AVG(ABS(delta_c_min)) as mean_abs_error FROM velocity GROUP BY agent"
```

### Skip When
- No project-level velocity files exist AND user hasn't asked to set them up
- Sub-minute clarification turns
- Pure tracker/epic umbrella issues (children log the work)

### Pitfalls
1. Capture start timestamp BEFORE `gh issue view N`
2. Log agent name in UPPERCASE (e.g., `HONEYDEW`)
3. CSV rebase conflicts from parallel agents — resolve manually
4. `model` field is required — use session's active model short-form
5. All fields are minutes — `H: 1h` = `h_min: 60`

---

## @todo — generalize beyond lccjs

lccjs is the only consumer today. When porting, override the Configuration defaults:
- `npm run puzzle:status` / `npm run velocity:log`, `VELOCITY_DB` (`~/.lccjs/lccjs.db`), and `docs/puzzle-velocity.csv` are all lccjs-specific.
