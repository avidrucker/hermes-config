---
name: write-til-doc
description: "Guide an agent through writing, filing, and closing a TIL (Today I Learned) entry in docs/learnings/. Use when the user says 'write a TIL', 'write up what you learned', 'add to learnings', or requests a session retrospective."
version: 1.0.0
author: Hermes Agent (ported from avidrucker/claude-config write-til-doc skill)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [til, learnings, retrospective, documentation, daily-log]
    related_skills: [log-error, next-best-action]
---

# Write TIL Doc

Guide an agent through writing, filing, and closing a TIL (Today I Learned) entry in `docs/learnings/`. TIL entries are diary-style learning notes, not bug reports or feature docs.

## Project config

Resolve these from your project's orchestration config:

- **Claim command** — how to claim a worktree (e.g. `pmtools claim <N> --as <agent>`, `npm run claim -- <N> --as <agent>`)
- **Close command** — how to close (e.g. `pmtools close <N>`, `npm run close <N>`)
- **Velocity-log command** — how to log velocity (e.g. `pmtools velocity log '<json>'`, `npm run velocity:log -- '<json>'`). **Gated on `storage.velocity.enabled`** — if disabled, skip the velocity step entirely.

## Triggers

- "write a TIL", "write up what you learned today", "add to learnings"
- End-of-session retrospective request or lesson capture
- **Not triggered by:** research findings on a single ticket (use an issue comment instead)

## Pre-flight

```bash
date '+%Y-%m-%dT%H:%M:%S%z'   # capture NOW, before reading anything
```

Confirm from conversation context (or ask briefly):
1. **Date** — today in `YYYY-MM-DD`
2. **Agent** — the terminal's fruit/agent identity
3. **Themes** — 3–5 bullet phrases summarising tickets / lessons from the session

## Step 1 — Draft the TIL doc

Write the doc per the content spec below. Proceed directly to Step 2 — no approval pause. The draft is committed as-is; corrections can be filed as a follow-up after the human reads the summary.

## Step 2 — File the GitHub issue

TIL issues are BDD-exempt — no Have/Should have/Repro required:

```bash
gh issue create \
  --title "TIL YYYY-MM-DD AGENT — one-line theme" \
  --label "severity:low" \
  --body "**Role:** WRITER · H: 15m

Session retrospective for YYYY-MM-DD (AGENT). Topics: <comma-separated themes>."
```

- Title uses an **em-dash** (`—`), not a colon or hyphen.
- No `ROLE:` prefix — `TIL` is its own identifier.

## Step 3 — Claim worktree

```bash
git status                        # verify main is clean first
<claim-cmd> <N> --as <agent>      # resolved claim command
cd <worktree-path>
```

If the CLAIMED banner shows `comments  N`, read them before proceeding:
```bash
gh issue view <N> --comments
```

## Step 4 — Write file + README index row

1. Write `docs/learnings/today-i-learned-YYYY-MM-DD-<agent>[-<session>].md` with the draft.
2. Add one row to the index table in `docs/learnings/README.md` — **mandatory, not optional**.

README row format:
```
| [TIL YYYY-MM-DD AGENT](./today-i-learned-YYYY-MM-DD-<agent>.md) | YYYY-MM-DD | AGENT | One-sentence theme summary. |
```

## Step 5 — Log velocity + commit

**If `storage.velocity.enabled` is `false`: skip the velocity-log call entirely** — there is nothing to log and no CSV mirror to stage. Commit just the TIL doc + README index row with `Closes #N`.

When velocity is enabled, capture the finish time and log the row:

```bash
date '+%Y-%m-%dT%H:%M:%S%z'   # capture finish time
<velocity-log-cmd> '{
  "ticket": N, "title": "TIL YYYY-MM-DD AGENT — theme",
  "role": "WRITER", "agent": "fig", "h_min": 15, "c_min": 10,
  "actual_min": X, "delta_h_min": Y, "delta_c_min": Z,
  "started_iso": "...", "finished_iso": "...", "model": "..."
}'
```

Stage and commit everything in **one commit** — when velocity is enabled, the CSV mirror must share the `Closes #N` commit. Drop the CSV line if velocity is disabled:

```bash
git add docs/learnings/today-i-learned-*.md \
        docs/learnings/README.md \
        <csv-mirror>                      # only if storage.velocity.enabled
git commit -m "docs(learnings): TIL YYYY-MM-DD AGENT — theme (#N)

data(velocity): log #N (AGENT, WRITER, Xm)

Closes #N"
```

## Step 6 — Close

```bash
<close-cmd> <N>                   # resolved close command
```

## Close checklist

- [ ] Start timestamp captured before reading the issue
- [ ] Draft written (no approval gate — proceeds directly to git)
- [ ] GitHub issue filed: em-dash title, `severity:low`, no BDD structure
- [ ] Worktree claimed for the TIL issue number
- [ ] `today-i-learned-YYYY-MM-DD-<agent>[...].md` written to `docs/learnings/`
- [ ] README index row added (mandatory)
- [ ] Velocity logged (`WRITER` role) — *only if `storage.velocity.enabled`; skip otherwise*
- [ ] CSV mirror (if velocity enabled) + `Closes #N` in **one** commit
- [ ] Resolved close command (`<close-cmd> <N>`) completed

## TIL doc content spec

### Document structure

```
# TIL YYYY-MM-DD — AGENT [session label if >1 this day]

**Context:** 1–3 sentences: what was this session about? Name the tickets.

---

## 1. Lesson title (concrete, specific)

**What happened:** What you did or tried. Name the issue number, the exact
command that failed, the moment the assumption broke.

**What I learned:** The non-obvious insight. Why was this surprising?

**The rule:** One bolded sentence distilling the actionable take-away.

---

## 2. Another lesson title
...

---

## What landed  ← optional; include when ≥3 tickets shipped

| Artifact | Change |
|---|---|
| `scripts/claim.js` | Extended readIssue to fetch comment count (#661) |

## Open threads  ← optional; deferred follow-ups without tickets yet

- ...

## Related artifacts  ← optional; cross-links

- [Sibling TIL](./today-i-learned-2026-06-01-fig.md)
- Issue #N
```

### Content guidance

| Dimension | Guidance |
|---|---|
| Lesson count | ≥1, ≤~7 per session |
| Length | 400–1200 words; enough to be useful on a cold read ~1 week later |
| Voice | First-person, retrospective — write as the agent who did the work |
| Specificity | Name issue numbers, exact commands, the moment the rule crystallised |
| Not | A feature doc, a bug report, a transcript dump, or a design doc |

**Jargon rule:** define project-specific terms on first use, or link to the project's concept glossary. If the term isn't in the glossary, add it there first.

**Authority path:** for each rule stated in the TIL, either (a) add it to the project's RULES.md in the same commit, or (b) file a ticket to do so and reference the ticket number in the TIL. A lesson that lives only in `docs/learnings/` expires when the session ends.

### Filename convention

```
today-i-learned-YYYY-MM-DD-<agent>.md           # first or only session that day
today-i-learned-YYYY-MM-DD-<agent>-2.md         # second session same day
today-i-learned-YYYY-MM-DD-<agent>-<topic>.md   # topic-tagged variant
```

Agent token is lowercase fruit name: `fig`, `cherry`, `banana`, etc.

### README index row

The `docs/learnings/README.md` index table has this header:

```
| Doc | Date | Agent | Themes |
|---|---|---|---|
```

New row format:
```
| [TIL YYYY-MM-DD AGENT](./today-i-learned-YYYY-MM-DD-agent.md) | YYYY-MM-DD | AGENT | One-sentence theme list. |
```

Always append at the **bottom** of the table (chronological order).

### GitHub issue body template

```markdown
**Role:** WRITER · H: 15m

Session retrospective for YYYY-MM-DD (AGENT). Topics: <comma-separated one-liners>.
```

H is typically 15m for a standard single-session TIL. Adjust upward for a synthesis or multi-session retrospective.

## Pitfalls

| Gap | Symptom | Fix |
|---|---|---|
| Skipped README row | Index table missing the new file | Always add the row — it's mandatory, not optional |
| BDD structure attempted | Wrote Have/Should have/Repro | TIL is BDD-exempt — diary format only |
| Colon in issue title | `TIL 2026-06-03 FIG: theme` | Use em-dash: `TIL 2026-06-03 FIG — theme` |
| CSV in separate commit | close fails velocity guard | Stage CSV + TIL file + README together with `Closes #N` |
| Worked on main | Commit rejected or workflow miss | Always claim a worktree (no exceptions) |
| No start timestamp | `started_iso` blank in velocity row | Capture `date` before reading the issue — reconstructed t₀ is an honesty tax |
| Lessons without authority path | Rules live only in narrative | Add to RULES.md or file a ticket; reference it in the TIL |

## Source references

- Original Claude source: `skills/write-til-doc/SKILL.md` (avidrucker/claude-config)
- Content spec reference: `skills/write-til-doc/REFERENCE.md` (avidrucker/claude-config)
