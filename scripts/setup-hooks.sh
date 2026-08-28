#!/usr/bin/env bash
set -euo pipefail

# One-time, per-clone opt-in: point this repo's git hooks at the committed
# scripts/git-hooks/ directory. Two git hooks live there, and this enables
# both: post-merge, which runs the gates and re-hoists after a merging pull,
# and commit-msg, which rejects a commit message that breaks the deterministic
# half of the house style. Git hooks can't be committed to .git/hooks/, so we
# version-control the hook bodies and set core.hooksPath here.
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
echo "Done. Two git hooks are now live in this clone:"
echo "  post-merge  — after a merging pull: runs the gates, then install.sh (re-hoist)."
echo "                Not triggered by 'git pull --rebase' — run install.sh yourself after one."
echo "  commit-msg  — rejects a commit whose message breaks the exact rules in"
echo "                src/committing/references/commit-style.md. This is the half of"
echo "                the opt-in most likely to surprise you: your next commit here"
echo "                can be blocked. The rejection names the rule and the file."
