# TIL Doc — Content Spec & Templates

## Document Structure
```
# TIL YYYY-MM-DD — AGENT

**Context:** 1–3 sentences: what was this session about?

---

## 1. Lesson Title

**What happened:** What you did, issue numbers, exact commands.

**What I learned:** The non-obvious insight.

**The rule:** **One bolded sentence** distilling the actionable take-away.

---

## What Landed (optional)
| Artifact | Change |
|----------|--------|
| `scripts/claim.js` | Extended readIssue (#661) |

## Open Threads (optional)
- Deferred follow-ups without tickets yet
```

## Content Guidance
- Lesson count: 1–7 per session
- Length: 400–1200 words
- Voice: First-person retrospective
- Name issue numbers, exact commands, the moment the rule crystallized
- Not: feature doc, bug report, transcript dump, or design doc

## Filename Convention
```
today-i-learned-YYYY-MM-DD-<agent>.md           # first/only session
today-i-learned-YYYY-MM-DD-<agent>-2.md         # second session same day
today-i-learned-YYYY-MM-DD-<agent>-<topic>.md   # topic-tagged
```
Agent token is lowercase fruit name: `fig`, `cherry`, `banana`, etc.

## README Index Row
```
| [TIL YYYY-MM-DD AGENT](./today-i-learned-YYYY-MM-DD-agent.md) | YYYY-MM-DD | AGENT | Themes. |
```
Always append at the **bottom** of the table.

## GitHub Issue Body Template
```markdown
**Role:** WRITER · H: 15m

Session retrospective for YYYY-MM-DD (AGENT). Topics: <themes>.
```

## Pitfalls
| Gap | Fix |
|-----|-----|
| Skipped README row | Always add — mandatory |
| BDD structure attempted | TIL is BDD-exempt — diary format only |
| Colon in title | Use em-dash: `TIL YYYY-MM-DD AGENT — theme` |
| CSV in separate commit | Stage CSV + TIL + README together with `Closes #N` |
| No start timestamp | Capture `date` before reading the issue |
| Lessons without authority path | Add to project rules or file a ticket |
