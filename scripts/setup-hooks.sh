#!/usr/bin/env bash
set -euo pipefail

# One-time, per-clone opt-in: point this repo's hooks at the committed
# scripts/git-hooks/ directory. From then on `git pull` runs scripts/install.sh
# automatically via the post-merge hook. Hooks themselves can't be committed to
# .git/hooks/, so we version-control the hook body and set core.hooksPath here.
#
# TRUST NOTE: after this runs, any hook committed under scripts/git-hooks/ —
# now or added by a future pulled commit — executes automatically on its git
# event. Enable only on a repo whose commits you trust. See README → Install.

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

echo "core.hooksPath → $hooks_path"
echo "Done. 'git pull' will now re-hoist skills automatically (post-merge)."
echo "Note: not triggered by 'git pull --rebase' — run 'bash scripts/install.sh' manually after a rebase pull."
