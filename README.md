# hermes-config

Single source of truth for my authored **Hermes agent skills** — the Hermes-runtime
sibling of [`claude-config`](https://github.com/avidrucker/claude-config) (which does
the same for Claude Code skills).

The Hermes runtime keeps skills as plain dirs under `~/.hermes/skills/<category>/<skill>/`,
version-controlled nowhere — so edits are lost on re-install, and the Hermes **curator**
(a background job that auto-archives idle agent-created skills) can move them out from
under you. This repo holds the real files; `install.sh` symlinks them back into the
runtime (and optionally into a project checkout for editing/testing).

## Skills (8)

Authored skills, by Hermes category:

- **software-development/**: `error-telemetry`, `fruit-agent-orchestrate`,
  `next-best-action`, `puzzle-workflow`, `issue-lifecycle`,
  `codemirror-editor-themes`, `debugging`
- **github/**: `github-workflows`

> These were developed against the **lccjs** project and several still hard-code
> lccjs-specific paths/commands. Each such skill carries a bottom-of-file
> `## @todo — generalize beyond lccjs` note listing what to parameterize before
> using it elsewhere. lccjs is the only consumer today, so those are intentionally
> left hardcoded for now.

## Install

```bash
./install.sh                  # symlink into both the Hermes runtime and the lccjs checkout (default)
./install.sh --target runtime # Hermes runtime only (~/.hermes/skills)
./install.sh --target lccjs    # lccjs checkout only ($LCCJS_ROOT/hermes-skills)
./install.sh --dry-run         # preview
```

Idempotent and per-item: it skips skills already linked to this repo and warns (never
clobbers) if a non-symlink exists at the target. Category dirs in the target are real
dirs; only the leaf skill dirs are symlinks.

## Pin against the curator (important)

After symlinking into the runtime, **pin** each skill so the Hermes curator never
archives it (an archived symlink would sever the runtime link):

```bash
for s in error-telemetry fruit-agent-orchestrate next-best-action puzzle-workflow \
         issue-lifecycle codemirror-editor-themes debugging github-workflows; do
  hermes curator pin "$s"
done
```

`hermes curator status` should then show `pinned=yes` for all 8; `hermes curator run --dry-run`
should list none of them as archive candidates.

## Relation to the other skill repos

- **`claude-config`** — Claude Code skills (`~/.claude/skills`).
- **`~/.agents/skills`** — Codex skills.
- **`hermes-config`** (this repo) — Hermes skills (`~/.hermes/skills`).

Same skill *concept* may exist as a per-runtime port in more than one repo (different
frontmatter/format per runtime); they are not redundant copies. A future single-source
pipeline that renders one canonical skill into all three formats is the longer-term goal.
