---
name: eli5
description: "Re-explain the agent's most recent substantive answer in plain, accessible, jargon-free English. Use when the user types /eli5, says 'explain that simply', 'ELI5 that', 'in plain English', or 're-explain your last answer'. This is a re-render of existing content — it does not introduce new analysis, new options, or a different recommendation."
version: 1.0.0
author: Hermes Agent (ported from avidrucker/claude-config eli5 skill design spec)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [eli5, explain, plain-language, rephrase, productivity]
    related_skills: []
---

# ELI5 — Re-explain in Plain English

Re-explain the agent's **most recent substantive answer** in plain, accessible, jargon-free English. This is a **re-render, not a re-do** — do not introduce new analysis, new options, or a different recommendation. Only re-explain what is already in the conversation.

## Invocation and targeting

- `/eli5` → re-explain the **whole** of the agent's most recent substantive answer.
- `/eli5 <focus>` → narrow to a specific piece of it (e.g. `/eli5 the register allocation part`). The focus may point at an earlier answer if that is clearly what the user means.

## Style

- **Literal and plain.** Short sentences, everyday words, no jargon.
- When a technical term is genuinely unavoidable, define it in one clause.
- **No forced analogies or metaphors** — explain the real thing directly.
- Keep full technical accuracy underneath the plain words. "ELI5" is the spirit, not literal toddler-speak.

## Output structure (adaptive)

Open with a **one-sentence plain-English TL;DR**, then the body.

- **Decision-shaped original answer** (tradeoffs / a fork / "should I do A or B") → hit the three beats:
  1. **What the problem is** — restated plainly.
  2. **The options** — each in plain terms.
  3. **What I recommend and why** — the recommendation plus its reasoning.
- **Not decision-shaped** original answer (explains how something works, walks through a bug, etc.) → fall back to a plain-English walkthrough of whatever the answer actually was. No empty "Options: N/A" sections.

## Edge cases

- **No prior substantive answer yet** — say so, ask what to explain.
- **Focus arg matches nothing in the conversation** — ask for clarification rather than inventing content.

## Out of scope (YAGNI)

- No script, no config, no per-project gating.
- Does not re-run analysis or change the recommendation.
- Not literal toddler-speak.

## Source reference

Design spec: `docs/superpowers/specs/2026-06-16-eli5-skill-design.md` (avidrucker/claude-config).
