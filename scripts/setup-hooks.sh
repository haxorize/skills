#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
set -euo pipefail

# One-time, per-clone opt-in: point this repo's git hooks at the committed
# scripts/git-hooks/ directory. Every hook there — every file that is not a
# *-selftest.sh — becomes live at once, and the banner below lists them from
# the directory, never from a count kept here: each hook's `# Gate map:`
# header lines say what it does, the way `# Install note:` does for the
# PreToolUse hooks. Git hooks can't be committed to .git/hooks/, so we
# version-control the hook bodies and set core.hooksPath here.
#
# TRUST NOTE: after this runs, any hook committed under scripts/git-hooks/ —
# now or added by a future pulled commit — executes automatically on its git
# event. And the surface is wider than the hook files: with this opt-in,
# pulled code runs not only on a merge (post-merge) but on every commit that
# touches a mapped path, because pre-commit invokes the working-tree
# scripts/lint-*.sh and *-selftest.sh a pull has already replaced — so the
# trust extends to every repo script a hook invokes, not only the hooks
# (ADR-0049's 2026-08-30 amendment records it). Enable only on a repo whose
# commits you trust. See README → Install.

repo_root="$(git rev-parse --show-toplevel)"
hooks_path="$repo_root/scripts/git-hooks"

# Don't silently clobber an existing hooks path (another framework, Husky, a
# team --global setting). Warn and leave the decision to a re-run if it differs.
existing="$(git config --local --get core.hooksPath 2>/dev/null || true)"
if [ -n "$existing" ] && [ "$existing" != "$hooks_path" ]; then
  echo "WARN: core.hooksPath is already set to '$existing'." >&2
  echo "      Not overwriting. Unset it first if you want to point at scripts/git-hooks/:" >&2
  echo "      git config --local --unset core.hooksPath && bash scripts/setup-hooks.sh" >&2
  exit 1
fi

git config --local core.hooksPath "$hooks_path"

# The roster is the directory: a hook is a file under scripts/git-hooks/ that
# is not a selftest. lint-skills.sh holds each to a selftest beside it, and
# post-merge derives its gate roster from the same pairing.
hooks=""
count=0
for h in "$hooks_path"/*; do
  [ -f "$h" ] || continue
  case "$h" in *-selftest.sh) continue ;; esac
  hooks="$hooks $(basename "$h")"
  count=$((count + 1))
done

echo "core.hooksPath → $hooks_path"
echo "Done. $count git hook(s) now live in this clone:"
for hook in $hooks; do
  # Every `# Gate map:` line the hook carries, indented under its name; a hook
  # with none points at its own header rather than getting a blurb kept here.
  if grep -q '^# Gate map: ' "$hooks_path/$hook"; then
    grep '^# Gate map: ' "$hooks_path/$hook" | sed "s/^# Gate map: /  $hook — /"
  else
    echo "  $hook — see the header of scripts/git-hooks/$hook"
  fi
done
