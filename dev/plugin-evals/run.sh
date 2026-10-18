#!/usr/bin/env bash
# Trigger tests for model-invoked skill descriptions, run through
# `claude plugin eval` against a throwaway plugin built from src/.
#
# Development only. The plugin exists for the length of one run, in a temp
# directory: this script copies each skill named in skills.txt (and the skills
# its `requires:` line names, transitively) from src/ into
# <tmp>/skills-dev/skills/, copies evals/ beside it, and points the eval at
# that directory. Nothing here is installed, linked, or distributed:
# scripts/install.sh links src/ only, and the suite is not a plugin anyone can
# add. Copies rather than symlinks, because a plugin path that resolves outside
# the plugin root does not load (code.claude.com/docs/en/plugins-reference
# § Containment and existence).
#
# Hand-run and ungated: no lint walk reads dev/, no selftest pairs with this
# file, and no hook runs it, because each run is paid model calls on your own
# credential. Each case runs in an empty workspace with only this plugin
# loaded, so a pass or fail measures the description, not your settings.
#
# Usage: bash dev/plugin-evals/run.sh [claude plugin eval flags…]
#   e.g. bash dev/plugin-evals/run.sh --case 'grilling-*' --runs 1
# Defaults it sets: --ablation none (a trigger rate has no meaningful
# no-plugin arm), --no-publish (the report stays on this machine),
# --trust-plugin (the plugin is this repo's own src/, rebuilt every run).
# Results land in dev/plugin-evals/results/<timestamp>/ (gitignored).
# Exit: claude plugin eval's own status (1 when a case scores below
# --threshold, default 1.0); 3 on a usage error here (skills.txt missing
# included); 4 when the claude CLI is not on PATH or the temp plugin could not
# be built.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
[ -f "$here/skills.txt" ] || { echo "run.sh: $here/skills.txt is missing" >&2; exit 3; }
command -v claude >/dev/null 2>&1 || { echo "run.sh: claude CLI not on PATH" >&2; exit 4; }

# Temp-file template and guard: the skills repo's scripts/README.md § Temp files.
if ! tmp=$(mktemp -d "${TMPDIR:-/tmp}/skills-dev-plugin.XXXXXX") || [ ! -d "$tmp" ]; then
  echo "run.sh: mktemp -d ${TMPDIR:-/tmp}/skills-dev-plugin.XXXXXX failed (TMPDIR=${TMPDIR:-unset})" >&2
  exit 4
fi
trap 'rm -rf "$tmp"' EXIT
plugin="$tmp/skills-dev"
mkdir -p "$plugin/.claude-plugin" "$plugin/skills"
cat > "$plugin/.claude-plugin/plugin.json" <<'JSON'
{
  "name": "skills-dev",
  "version": "0.0.0-dev",
  "description": "Throwaway wrapper for description trigger tests; never installed.",
  "author": { "name": "skills repo (dev only)" }
}
JSON

copied=" "
add_skill() {
  local name=$1 dep deps
  case "$copied" in *" $name "*) return 0 ;; esac
  [ -f "$repo/src/$name/SKILL.md" ] || { echo "run.sh: no src/$name/SKILL.md (named in skills.txt or a requires: line)" >&2; exit 3; }
  cp -R "$repo/src/$name" "$plugin/skills/$name"
  copied="$copied$name "
  deps=$(sed -n '1,/^---$/{/^requires:/{s/^requires:[[:space:]]*//;s/[][,]/ /g;p;};}' "$repo/src/$name/SKILL.md" | head -1)
  for dep in $deps; do add_skill "$dep"; done
}
while IFS= read -r name || [ -n "$name" ]; do
  case "$name" in ''|'#'*) continue ;; esac
  add_skill "$name"
done < "$here/skills.txt"

cp -R "$here/evals" "$plugin/evals"

out="$here/results/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$out"
echo "skills under test:$copied" >&2
echo "results: $out" >&2
set +e
claude plugin eval "$plugin" --ablation none --no-publish --trust-plugin \
  --output-dir "$out" --report "$out/report.html" "$@"
rc=$?
set -e
exit "$rc"
