# Type-Specific Issue Rubrics

For each issue type, this file defines required checks, recommended checks, and diagnostic questions.

## `bug` — Bug Report / Fix

### Required Checks
- [ ] Reproduction steps — exact commands or sequence
- [ ] Observed behavior — what actually happens
- [ ] Expected behavior — what should happen
- [ ] Affected file(s) — which files contain the defect

### Red Flags
- No reproduction steps → BLOCK
- "Fix the bug" with no info about what the bug is → BLOCK

---

## `dev` — Feature / Implementation

### Required Checks
- [ ] Have/Should have framing
- [ ] Acceptance criteria (verifiable)
- [ ] Affected files named
- [ ] Role tag (DEV, DEV+WRITER, etc.)

### Red Flags
- Subjective acceptance criteria → require rewrite
- Bundles code + docs + rename → flag as compound

---

## `research` — Investigation / Scoping

### Required Checks
- [ ] Research questions listed (numbered, distinct)
- [ ] Expected output format (comment, doc file, etc.)
- [ ] Termination condition

### Red Flags
- Contains implementation instructions → split into research + DEV
- "Figure out how to do X" with no scoping → too open-ended

---

## `architect` / `ARC` — Architecture / Design

### Required Checks
- [ ] Design questions listed
- [ ] Constraints explicit
- [ ] Deliverable type and path
- [ ] "Design only" boundary

### Red Flags
- Ends with "implement it" → split into ARCHITECT + DEV

---

## `docs` — Documentation

### Required Checks
- [ ] Target file(s) named
- [ ] Content description
- [ ] Audience
- [ ] Insertion point

### Red Flags
- "Update the docs" with no file named → BLOCK

---

## `refactor` — Code Refactoring

### Required Checks
- [ ] Source location (file + line numbers)
- [ ] Target location
- [ ] Behavioral contract (tests that should still pass)
- [ ] Motivation

### Red Flags
- Also adds new behavior → split
- No safety check → require one

---

## `test` — Test Addition

### Required Checks
- [ ] What to test (specific function/module)
- [ ] Test type (unit, integration, e2e)
- [ ] Expected behavior to assert
- [ ] Test file location

### Red Flags
- "Add more tests" with no target → BLOCK

---

## Cross-Type: Compound Issue Detection

Flag as **compound** when:
1. Title contains `+` between role tags with independent deliverables
2. Body contains unrelated "Should have" sections
3. Acceptance criteria has independent verifiable conditions
