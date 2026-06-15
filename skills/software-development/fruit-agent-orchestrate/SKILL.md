---
name: fruit-agent-orchestrate
description: "Use when the user types the exact trigger '/fruit-agent-orchestrate' to triage open issues and produce copy-pasteable plain-paragraph work assignments for each fruit agent (APPLE, BANANA, CHERRY, DRAGONFRUIT, ELDERBERRY, FIG, GRAPE, HONEYDEW, INCABERRY, JACKFRUIT, KIWI). Never self-trigger. Read-only: no claims, no labels, no mutations."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [triage, assignment, orchestration, github, workflow]
    related_skills: [issue-review, puzzle-triage, puzzle-velocity, yegor-pm, guide-human-decision]

---

# Fruit Agent Orchestrate — Issue Triage & Agent Assignment

Triage the open issue queue and assign the top work to each fruit agent as copy-pasteable plain-paragraph instructions. Read-only — no claims, no labels, no mutations.

---

## Overview

This skill provides a complete workflow for triaging open GitHub issues and generating per-agent assignment paragraphs. It combines puzzle-triage ranking logic with area-based clustering and agent roster management to produce ready-to-paste work assignments.

The skill is **single-round / short-lived** by design: it captures a snapshot of open issue state at triage time, freezes it into prose, and that prose decays as agents close tickets. The output includes a freshness banner with the triage timestamp. Re-run the skill each round (or after several closes) rather than reusing one assignment list across a long session.

---

## When to Use

- User types the exact trigger: `/fruit-agent-orchestrate`
- Before a new orchestration round to assign fresh work to available agents
- When the user explicitly requests triage + assignment (not just ranking — see `puzzle-triage`)

**Don't use for:**
- Just ranking/filtering issues — use `puzzle-triage` (read-only ranking, no agent assignment)
- Mutating issues (labels, claims, edits) — this skill is read-only
- Autonomous triggering — runs ONLY on the exact verbatim trigger

---

## Configuration

Set these environment variables or pass as parameters to make the skill portable across projects:

| Variable | Default | Description |
|----------|---------|-------------|
| `ORCH_GH_CMD` | `gh` | GitHub CLI command (or wrapper) |
| `ORCH_REPO` | (auto-detected via `gh repo view`) | Repo in `owner/repo` format — auto-detected if unset |
| `ORCH_PUZZLE_STATUS_CMD` | `npm run puzzle:status` | Command to check puzzle marker status |
| `ORCH_CLAIM_CMD` | `npm run claim` | Command to claim a worktree |
| `ORCH_VELOCITY_DB` | `~/.lccjs/lccjs.db` | Path to velocity/error-logging SQLite DB |
| `ORCH_AGENTS` | `APPLE,BANANA,CHERRY,DRAGONFRUIT,ELDERBERRY,FIG,GRAPE,HONEYDEW,INCABERRY,JACKFRUIT,KIWI` | Comma-separated agent roster |
| `ORCH_WORKTREE_BASE` | `.claude/worktrees` | Base directory for agent worktrees |

In the skill body, reference as `$ORCH_GH_CMD`, `$ORCH_PUZZLE_STATUS_CMD`, etc.

---

## Algorithm

### Step 1 — Collect Data (all in parallel)

Fetch all required data in a single parallel tool-use call. Read all outputs before proceeding.

```bash
# 1. All open issues with labels (tab-separated for large lists)
$ORCH_GH_CMD issue list --state open --limit 100 \
  --json number,title,labels,createdAt \
  -q '.[] | "\(.number)\t\([.labels[].name]|join(\",\"))\t\(.title)"'

# 2. Puzzle status (stale markers, sequencing constraints)
$ORCH_PUZZLE_STATUS_CMD

# 3. Active worktrees
git worktree list

# 4. Triage timestamp (freshness contract)
date '+%Y-%m-%dT%H:%M:%S%z'
```

**Freshness contract.** This skill takes a snapshot of *open* issue state at triage time and freezes it into prose consumed asynchronously — often one agent at a time, over a long session — while those same agents are rapidly closing tickets. The snapshot decays: a later assignment can name a `#N` that closed hours earlier. To bound staleness, capture the `date` above and stamp it on the output (see Output Shape), and treat the output as **single-round / short-lived** — re-run the skill each round rather than reusing one assignment list across a multi-hour session.

---

### Step 2 — Pre-flight Cleanup

Before ranking, scan for and surface:

- **Stale markers**: `puzzle:status` rows flagged `[STALE]` — issue is CLOSED but marker still exists. Note the file + line.
- **Stale worktrees**: `git worktree list` entries whose branch issue number resolves to a CLOSED issue (`gh issue view N --json state -q .state`). Note the path and branch.
- **Sequencing constraints**: Tickets whose body carries `Sequenced after: #N` must not be assigned ahead of their dependency. Cheap pre-filter: only inspect bodies of tickets carrying the `sequenced` label; without the label, checking every body is too expensive at 50+ issues. For each constrained ticket:
  - **#N CLOSED** → constraint satisfied; ticket freely assignable
  - **#N OPEN and claimed/in-flight** → hold dependent ticket; annotate `⏳ waiting on #N (in-flight)`
  - **#N OPEN and unclaimed** → assign #N first (to most available agent); hold dependent for later round

  Report held tickets under `## ⏳ Sequenced — waiting on dependency`. Never assign a dependent ticket and its open predecessor to two agents in the same round.

- **Dependency-coupled grooming**: A PM/grooming/hygiene ticket whose body *is* dependency metadata about another ticket X must not be co-scheduled in the same wave that assigns X's blockers. Detect by scanning the grooming ticket's body for referenced `#N`s; if any referenced `#N` is actionable and assigned this wave, **defer the grooming ticket to a later, quieter wave** (list under held section). When deferral is unavoidable, the assignment paragraph MUST carry the execution-time referent stamp (see Step 5b exception).

Report stale markers and stale worktrees at the top of the output under `## ⚠ Pre-flight cleanup` — attributed to the owning agent (fruit name in branch/file). That agent must resolve cleanup before claiming new work.

---

### Step 3 — Triage (embedded puzzle-triage logic)

Rank actionable issues using the full puzzle-triage algorithm:

**Partition first:**
- 🧑 **Requires human routing** — has `humans-only`, `decision`, or `human-decision-required` label → separate section, not assigned to any agent. The `guide-human-decision` skill handles these when a human explicitly directs an agent.
- 💤 **Icebox** — has `proposal` or `wontfix` label → separate section, not ranked for action
- ⛔ **Blocked** — has `blocked` label → separate section, note blocker, not grabbable
- 🔵 **In-flight** — has a live worktree (from `git worktree list`) → separate section, skip for assignment

**Within Actionable, order by:**
1. Severity: 🔴 `severity:high` → 🟠 `severity:medium` → 🟡 `severity:low` → ⚪ untriaged
2. Shortest estimate first (from `@todo #N:Est` marker if present; `~` if absent)
3. Lowest issue number as tiebreak

Render the actionable queue as a compact table. Keep it scannable — one line per issue.

---

### Step 4 — Agent Roster

Fixed roster (future: dynamic detection from worktrees):

| Agent | Assumed state |
|-------|---------------|
| APPLE | available |
| BANANA | available |
| CHERRY | available |
| DRAGONFRUIT | available |
| ELDERBERRY | available |
| FIG | available |
| GRAPE | available |
| HONEYDEW | available |
| INCABERRY | available |
| JACKFRUIT | available |
| KIWI | available |

> **Future enhancement**: After running `git worktree list`, parse branch names for fruit identities, cross-reference with `npm run puzzle:status` to determine which agents are IN-PROGRESS. Mark those agents as unavailable and omit them from assignment (or flag them as "finish current work first"). For now, all eleven agents are assumed available and the user is expected to supply context about in-flight work before invoking the skill.

---

### Step 5 — Produce Assignments

#### 5a — Group Issues by Area

Before writing paragraphs, partition the actionable issue queue by `area:*` label:

1. Extract the `area:*` label(s) from each actionable issue (captured in Step 1). An issue with multiple `area:*` labels belongs to its first-listed `area:*` label.
2. Build a cluster map: `area → [issue list]`, sorted within each cluster by Yegor priority (severity → estimate → number).
3. Issues with **no `area:*` label** go into a **wildcard pool** — assignable to any agent.
4. Sort clusters by size (largest first). Assign each cluster to the agent with the fewest issues so far (greedy bin-packing). Never assign overlapping area clusters to the same agent.
5. Distribute wildcard issues to the lightest-loaded agents after cluster assignment.

Goal: each agent touches **at most one `area:*` cluster** per session. If there are more agents than clusters, some agents receive only wildcard issues — that is acceptable.

#### 5b — Write One Paragraph Per Agent

For each agent, write one plain paragraph. Rules:

- No blockquote `>` prefix, no code fences
- Name the ticket number and title
- State the agent's assigned area lane: "Your area lane: `area:X`" (or "area unlabelled" for wildcard-only agents)
- One sentence of rationale (why this agent, why this ticket now)
- If the agent has pre-flight cleanup (from Step 2), lead with that before the ticket assignment
- Format must be directly copy-pasteable as a human instruction to that agent
- **Do NOT append a per-paragraph "verify the issue is OPEN / run `npm run preflight <N>`" instruction.** The freshness re-check is surfaced **once**, globally, in the `## ⏱ Triaged as of …` banner — repeating it per agent is boilerplate that bloats assignment and undercuts its self-contained legibility.
- **Exception — execution-time referent stamp for dependency-coupled grooming**: The global OPEN banner covers the *assigned* ticket's state; it does **not** cover the `#N`s a grooming/PM ticket *references*. So when a PM/grooming/hygiene ticket whose content is another ticket's dependency metadata could not be deferred (Step 2), append exactly **one** targeted line: "Before you edit or close this, re-verify the live state of every `#N` it references (`gh issue view N --json state`) — those deps may be closing in this same wave." This is the *only* sanctioned per-paragraph freshness stamp; it targets *referents* (uncovered by the banner), not the assigned ticket, and appears only on dependency-coupled grooming assignments — never on ordinary tickets.

**Good fit heuristics:**
- Match ticket role (WRITER / RESEARCHER / ARCHITECT / DEV) to the agent's recent work domain if known from user context
- Prefer unblocking tickets (e.g. a RESEARCH that unblocks a WRITER) when an agent is free and the pair exists
- Medium-severity tickets before low when an agent is fresh
- Never assign two agents to the same `area:*` cluster (enforced by 5a; flag explicitly if unavoidable)

---

## Output Shape

The output **must** open with the freshness banner (the `date` from Step 1), then the rest:

```
## ⏱ Triaged as of <ISO triage timestamp> — re-validate before claiming
This snapshot decays as agents close tickets. `npm run claim` gates on CLOSED state (it refuses a
closed issue), but that guard skips when `gh` is offline — so verify OPEN if in doubt. Re-run this
skill each round (or after several closes); do not reuse this list across a long multi-hour session.

## ⚠ Pre-flight cleanup
[stale markers and worktrees, attributed to owning agent]

## 🎯 Actionable — Yegor priority order
[compact ranked table]

## 🧑 Requires human routing
[tickets with humans-only / decision / human-decision-required labels — not assigned to any agent]

## ⛔ Blocked  /  💤 Icebox  /  🔵 In-flight
[brief lists]

## ⏳ Sequenced — waiting on dependency
[held tickets with dependency annotations]

## 👥 Assignments

APPLE: [plain paragraph]

BANANA: [plain paragraph]

CHERRY: [plain paragraph]

DRAGONFRUIT: [plain paragraph]

ELDERBERRY: [plain paragraph]

FIG: [plain paragraph]

GRAPE: [plain paragraph]

HONEYDEW: [plain paragraph]

INCABERRY: [plain paragraph]

JACKFRUIT: [plain paragraph]

KIWI: [plain paragraph]
```

---

## Hermes Tool Mapping

| Operation | Hermes Tool | Notes |
|-----------|-------------|-------|
| Fetch issues | `terminal` with `gh issue list --json ...` | Use tab-separated `-q` format for large lists |
| Puzzle status | `terminal` with `$ORCH_PUZZLE_STATUS_CMD` | Configurable via env |
| Worktrees | `terminal` with `git worktree list` | |
| Timestamp | `terminal` with `date '+%Y-%m-%dT%H:%M:%S%z'` | |
| Issue body (sequencing) | `terminal` with `gh issue view N --json body,labels` | Only for `sequenced`-labelled tickets |
| Dynamic repo detection | `gh repo view --json nameWithOwner -q .nameWithOwner` | Never hardcode `owner/repo` |

---

## Common Pitfalls

1. **Firing on anything but `/fruit-agent-orchestrate`** — never trigger on "you are agent X, are you ready?" or similar. Respond with confirmation and wait for the exact verbatim trigger.

2. **Assigning humans-only / decision tickets to agents** — these must be partitioned out in Step 3. Agents cannot grab them; `guide-human-decision` handles them when a human directs.

3. **Ignoring in-flight worktrees** — always check `git worktree list` to avoid double-assignment. An agent with an active worktree should finish current work before receiving new assignments.

4. **Treating `@todo` estimates as exact** — estimates are ≤60m caps, not promises. Use `~` when absent.

5. **Large issue lists truncate output** — `gh issue list --json` on 100+ issues produces 50K+ chars with embedded control characters that exceed context. Use the tab-separated `-q` format and process in a script (`execute_code`) to partition/rank, rather than processing raw JSON in the LLM context.

6. **Hardcoding lccjs-specific paths/commands** — use the Configuration env vars (`$ORCH_PUZZLE_STATUS_CMD`, `$ORCH_CLAIM_CMD`, `$ORCH_VELOCITY_DB`, `$ORCH_WORKTREE_BASE`) so the skill works in other projects.

7. **Skipping the freshness banner** — the `date` timestamp is mandatory. Without it, assignments become stale silently.

8. **Per-paragraph boilerplate** — do not append "verify OPEN" to each assignment. The global banner covers the assigned ticket; only dependency-coupled grooming gets a targeted referent stamp.

---

## Verification Checklist

- [ ] All open issues fetched with labels (tab-separated format for large lists)
- [ ] Puzzle status checked for stale markers
- [ ] Worktrees checked for in-flight assignments
- [ ] Partitions correctly applied (humans-only, icebox, blocked, in-flight, actionable)
- [ ] Actionable issues ranked by severity → estimate → issue number
- [ ] Pre-flight cleanup surfaced (stale markers, stale worktrees, sequencing constraints)
- [ ] Area-based clustering applied (greedy bin-packing, no overlapping clusters per agent)
- [ ] One plain paragraph per agent with: ticket #/title, area lane, rationale, cleanup lead-in
- [ ] Freshness banner present with ISO timestamp
- [ ] No per-paragraph "verify OPEN" boilerplate (only dependency-coupled grooming exception)
- [ ] No mutations performed (read-only — no claims, labels, edits)
- [ ] Configurable env vars used for all project-specific paths/commands
- [ ] Dynamic repo detection used (no hardcoded `owner/repo`)
- [ ] Skill loads via `skill_view(name='fruit-agent-orchestrate')` without error

---

## One-Shot Recipe

```bash
# 1. Capture start timestamp
TS_START=$(date '+%Y-%m-%dT%H:%M:%S%z')

# 2. Run the skill (this skill's algorithm)
#    - Fetch issues: gh issue list --state open --limit 100 --json number,title,labels,createdAt -q ...
#    - Puzzle status: npm run puzzle:status
#    - Worktrees: git worktree list
#    - Triage timestamp: date '+%Y-%m-%dT%H:%M:%S%z'
#    - Partition, rank, cluster, assign per algorithm above
#    - Produce output with banners and paragraphs

# 3. Present output to user
cat << 'EOF'
## ⏱ Triaged as of <timestamp> — re-validate before claiming
...
## 👥 Assignments
APPLE: ...
BANANA: ...
...
EOF

# 4. User copies desired assignment(s) and pastes to target agent(s)
#    (this skill does NOT claim or mutate — it produces copy-paste instructions)
```

### Large Issue Lists (>200 issues)

When `gh issue list` output is too large for direct JSON parsing, use the tab-separated format:

```bash
gh issue list --state open --limit 200 --json number,title,labels,createdAt \
  -q '.[] | "\(.number)\t\([.labels[].name]|join(\",\"))\t\(.title)"'
```

Then parse with `split('\t', 2)` → `(num, labels, title)`. This avoids JSON control-char truncation issues.

---

## Related

- `puzzle-triage` — ranking algorithm used in Step 3 (this skill embeds its logic)
- `issue-review` — run on top-ranked issues before claiming to verify quality
- `yegor-pm` / `yegor-microtasks` — XDSD prioritization methodology (source of severity/estimate ordering)
- `guide-human-decision` — handles `humans-only` / `decision` tickets surfaced in Step 3
- `docs/skills.md` — authoritative source for fruit-agent-orchestrate description in this project
- `docs/learnings/today-i-learned-2026-06-05-dragonfruit.md` §3 — sequencing protocol
---

## @todo — generalize beyond lccjs

This skill is heavily coupled to the lccjs multi-agent workflow. lccjs is the only consumer today; when porting, parameterize:
- `ORCH_AGENTS` — the fruit-agent roster (APPLE/BANANA/…) is lccjs-specific.
- `ORCH_PUZZLE_STATUS_CMD` / `ORCH_CLAIM_CMD` (`npm run puzzle:status` / `claim`), `ORCH_VELOCITY_DB`, `ORCH_WORKTREE_BASE` (`.claude/worktrees`) — all lccjs conventions.
- The `area:*` label scheme and the `Sequenced after: #N` issue-body parsing are lccjs conventions.
- Example issue numbers in the text are lccjs tickets.
