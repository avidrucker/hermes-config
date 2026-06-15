#!/usr/bin/env bash
# install.sh — symlink this repo's Hermes skills into the runtime(s) that use them.
#
# This repo (hermes-config) is the single source of truth for the user's authored
# Hermes agent skills. It is the Hermes-runtime sibling of `claude-config` (which
# does the same for Claude Code skills). Per-item symlinks, idempotent, so it
# coexists with the bundled/upstream Hermes skills without touching them.
#
# UNLIKE claude-config (flat skills/), Hermes uses CATEGORY subdirs, so this
# installer preserves them: skills/<category>/<skill> -> <target>/<category>/<skill>.
# Category dirs in the target are REAL dirs; only the leaf skill dirs are symlinks
# (so the Hermes curator's archive op, if it ever fires on an unpinned skill, only
# moves a leaf link, never a whole category).
#
# Targets:
#   runtime  -> ~/.hermes/skills              (the Hermes agent loads skills here)
#   lccjs    -> $LCCJS_ROOT/hermes-skills     (gitignored; lets lccjs agents edit/test)
#
# Usage:
#   ./install.sh                      # default: --target both
#   ./install.sh --target runtime     # only the Hermes runtime
#   ./install.sh --target lccjs       # only the lccjs checkout
#   ./install.sh --dry-run            # show what would happen, change nothing
#   ./install.sh --copy               # fallback: copy instead of symlink (breaks auto-sync)
#   LCCJS_ROOT=/path ./install.sh     # override the lccjs checkout location
#
# After symlinking into the runtime, PIN each skill so the curator never archives
# it:  hermes curator pin <skill-name>   (see README).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LCCJS_ROOT="${LCCJS_ROOT:-$HOME/Documents/Study/JavaScript/lccjs}"

TARGET=both
MODE=symlink
DRY_RUN=false

while [ $# -gt 0 ]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --copy)   MODE=copy; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

case "$TARGET" in
    runtime|lccjs|both) ;;
    *) echo "--target must be runtime|lccjs|both (got: $TARGET)" >&2; exit 1 ;;
esac

install_item() {
    local source="$1" target="$2" name
    name="$(basename "$source")"
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            echo "  [skip] $name (already linked)"; return
        fi
        echo "  [WARN] $target exists and is NOT a symlink to our source."
        if [ "$MODE" != copy ]; then
            echo "         Move it aside before rerunning, OR pass --copy to overwrite."; return
        fi
    fi
    if [ "$DRY_RUN" = true ]; then echo "  [dry] would $MODE: $name"; return; fi
    if [ "$MODE" = copy ]; then
        rm -rf "$target"; cp -R "$source" "$target"; echo "  [copy] $name"
    else
        ln -snf "$source" "$target"; echo "  [link] $name"
    fi
}

install_into() {
    local target_root="$1" label="$2"
    echo "→ $label: $target_root"
    if [ "$DRY_RUN" = false ]; then mkdir -p "$target_root"; fi
    for cat_dir in "$REPO_ROOT/skills"/*/; do
        [ -d "$cat_dir" ] || continue
        local category; category="$(basename "$cat_dir")"
        if [ "$DRY_RUN" = false ]; then mkdir -p "$target_root/$category"; fi
        for skill_dir in "$cat_dir"*/; do
            [ -d "$skill_dir" ] || continue
            local skill="${skill_dir%/}"
            install_item "$skill" "$target_root/$category/$(basename "$skill")"
        done
    done
}

[ "$DRY_RUN" = true ] && echo "(dry-run — no changes)"
if [ "$TARGET" = runtime ] || [ "$TARGET" = both ]; then
    install_into "$HOME/.hermes/skills" "Hermes runtime"
fi
if [ "$TARGET" = lccjs ] || [ "$TARGET" = both ]; then
    install_into "$LCCJS_ROOT/hermes-skills" "lccjs checkout"
fi
echo "Done."
