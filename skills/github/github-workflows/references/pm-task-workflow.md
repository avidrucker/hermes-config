# PM Task Workflow — Filing Multiple Issues as One Timed Task

## Pattern

When the user asks to "log N tickets as 1 task" or "file multiple issues as a single PM task":

1. **Timestamp first** — Capture wall-clock time before any `gh issue view` or `gh issue create` calls
2. **Create all issues sequentially** — Use `gh issue create` for each
3. **Apply appropriate labels** — Use project label vocabulary (area:*, severity:*, type:*)
4. **Verify all created** — List issues to confirm
5. **Report as single deliverable** — Summarize with issue numbers, URLs, and the timestamp

## Example: This Session (LCC.js #1137, #1138, #1139)

```bash
# 1. Timestamp
date +"%Y-%m-%d %H:%M:%S"
# → 2026-06-07 00:12:32

# 2. Create issues
gh issue create --title "Bug: Syntax highlighting flickering on showcase/playground page" \
  --body "..." --label "bug,enhancement,severity:medium"
# → https://github.com/avidrucker/lccjs/issues/1137

gh issue create --title "Remove \"Syntax Preview\" from showcase/playground page" \
  --body "..." --label "enhancement,cleanup,severity:low"
# → https://github.com/avidrucker/lccjs/issues/1138

gh issue create --title "Rename showcase/playground page title and route to match (with name options)" \
  --body "..." --label "enhancement,decision,severity:medium"
# → https://github.com/avidrucker/lccjs/issues/1139

# 3. Verify
gh issue list --state open --json number,title,labels --jq '.[] | "\(.number): \(.title) [\(.labels[].name)]"'
```

## Deliverable Format

Report back as a single summary:

> Done. All three issues created as a single PM task (wall clock: **2026-06-07 00:12:32**):
>
> | # | Issue | Type | Labels |
> |---|-------|------|--------|
> | **#1137** | [Bug: Syntax highlighting flickering...](https://github.com/avidrucker/lccjs/issues/1137) | Bug | `bug`, `enhancement`, `severity:medium` |
> | **#1138** | [Remove "Syntax Preview"...](https://github.com/avidrucker/lccjs/issues/1138) | Enhancement | `enhancement`, `cleanup`, `severity:low` |
> | **#1139** | [Rename showcase/playground page...](https://github.com/avidrucker/lccjs/issues/1139) | Enhancement + Decision | `enhancement`, `decision`, `severity:medium` |

## Key Principles

- **One timestamp for the batch** — Not per-issue
- **Real velocity only** — Actual wall-clock, not estimates
- **Labels from project vocabulary** — Use `gh label list` first if unsure
- **Decision issues get `decision` label** — Requires human input before work starts
- **Cleanup/enhancement issues get appropriate severity** — Usually `severity:low` for UI cleanup

## LCC.js Project Specifics

- Labels: `area:web`, `area:toolchain`, `area:process`, `area:uncategorized`, etc.
- Severity: `severity:high`, `severity:medium`, `severity:low`
- Types: `bug`, `enhancement`, `cleanup`, `research`, `decision`, `data`, `stats`, `pdd`
- Always remove `area:uncategorized` when assigning real area label