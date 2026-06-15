---
name: issue-lifecycle
description: "GitHub issue lifecycle: quality review before work, human decision facilitation during work, and pre-close checklist after work. Use when reviewing an issue for agent-readiness, walking through a human-required decision ticket, or running the pre-close finding checklist before committing. Covers structured rubrics, ruling comment shapes, and the 5-question close checklist."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [github, issue-quality, decision-facilitation, human-in-the-loop, pre-close, workflow, ticket-management]
    related_skills: [github-workflows, log-error]
---

# Issue Lifecycle

Three phases of the GitHub issue lifecycle:
1. **Issue Review** — quality/clarity review before work begins
2. **Guide Human Decision** — structured walkthrough for human-required decisions
3. **Next Best Action** — pre-close checklist to catch findings before committing

---

## A. Issue Review (Pre-Work Quality Gate)

### When to Use
- "review this issue", "is this ticket ready?", "improve this issue"
- Before claiming a worktree for a new issue
- During backlog grooming

### Workflow
1. **Identify type** from labels/title/body: bug, dev, research, architect, docs, refactor, test
2. **Apply universal rubric** (5 dimensions, 1-3 each):
   - Scope clarity
   - Success criteria (machine-verifiable or behaviorally unambiguous)
   - File/path specificity
   - Single deliverable
   - Context sufficiency
3. **Apply type-specific rubric** from `references/type-rubrics.md`
4. **Generate review** with verdict: READY (13-15), NEEDS WORK (9-12), BLOCK (5-8)
5. **Offer to rewrite** if verdict < READY

### Key Principles
- Score what's *written*, not what was *meant*
- Agent-first lens: can an agent open this and begin with zero follow-up questions?
- One deliverable per issue — bundling is the most common flaw
- Acceptance criteria must be machine-verifiable: "`npm test` passes" not "works correctly"

### Output Structure
```
## Issue Review: #N — Title
**Type:** bug | dev | research | architect | docs | refactor | test
**Verdict:** READY | NEEDS WORK | BLOCK

### Universal Rubric (score each 1-3)
### Type-Specific Checks
### What's Working
### Required Changes (blocks work starting)
### Suggested Improvements (non-blocking)
### Rewrite Hints (before → after for weakest sections)
```

---

## B. Guide Human Decision (During Work)

### When to Use
- Ticket labeled `humans-only` or `human-decision-required`
- User says "walk me through" or "address together" a decision issue

### Workflow
1. **Pull context** — read issue body AND all referenced issue comments
2. **Surface each decision point** separately:
   - Options table with recommendation, evidence, tradeoff
   - Reformat pre-existing analyses (don't re-derive)
3. **Surface housekeeping questions last** — side bugs, companion tickets
4. **Receive decisions** — handle approve/reject/conditional/amend/defer
5. **Side-dependency check** — land trivial deps (≤5 min) before posting ruling
6. **Execute** — post rulings on affected tickets, file implementation tickets, close parent if all resolved
7. **Report** — what was posted, filed, and what remains open

### Ruling Comment Shape
```
## Ruling — <topic>
**Q1 — <question>:** <chosen option> [— rationale]
**Q2 — <question>:** <chosen option>
Implementer may [proceed]. [Any dependency note.]
```

### Pitfalls
1. Don't bundle multiple decisions into one question
2. Don't file implementation ticket before user confirms ruling
3. Don't close parent while any decision is conditional
4. Land trivial side-deps before writing "once X happens" in rulings
5. When creating a new label, sweep open issues for candidates immediately

---

## C. Next Best Action (Pre-Close Checklist)

### When to Use
- **Before** `npm run close N` on any substantive puzzle
- When user says "run next-best-action" or "pre-close checklist"

**Critical timing:** Run BEFORE the close command, not after.

### The 5 Questions

**Q1 — Bug or Regression:** Did you encounter a bug NOT in this ticket's scope?
- Yes → `gh issue create --title "bug: ..." --label "bug,severity:medium"`

**Q2 — Process Recurrence:** Did a known failure mode recur? Did you state intent to file and not follow through?
- Yes → file process-improvement ticket

**Q3a — Doc Contradiction:** Does your output contradict an existing doc/TIL/ticket?
- Yes → file WRITER ticket or post correction comment

**Q3b — Closing Loop:** Did you post a closing comment? Do child tickets have `**Parent:** #N`?
- Missing → post comment or edit child ticket now

**Q4 — Deferred Decision:** Did you defer a technical/process decision with no tracking ticket?
- Yes → file decision or DEV ticket

**Q5 — External Routing:** Is there a follow-up for a human with no `waiting-on-external` ticket?
- Yes → file ticket labeled `waiting-on-external`

### Output
```
✅ GREEN — all clear. Proceed with npm run close N.
```
or
```
⚠ AMBER — file before closing:
  • Q1: <finding> → bug: <title stub>
  • Q3b: no closing comment posted on #N
```

Only proceed to close after GREEN or after filing all AMBER items.
