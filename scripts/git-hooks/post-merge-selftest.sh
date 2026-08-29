#!/usr/bin/env bash
# Prove scripts/git-hooks/post-merge still runs every gate, reads all three
# statuses, and reaches the re-hoist whatever the gates return.
#
# A post-merge hook cannot abort the merge and this one discards every gate's
# output, so its only channel is the WARN lines it prints — and a hook that
# died at the first failing gate under `set -e` printed none of them and never
# re-hoisted, which is what this file was written after. It builds a throwaway
# git repository holding fake gates with known exit codes, runs the hook with
# that repository as its toplevel, and grades the lines: a gate exiting 1
# draws the failed WARN, a gate exiting 2 draws the exit-2 WARN, a gate exiting
# 0 draws nothing, a hook whose selftest is missing draws the gate-missing
# WARN, every gate after a failing one still runs (each fake gate leaves a
# marker file), and the re-hoist line and the fake install.sh both run last.
# Also graded: the roster is derived — a scripts/*-selftest.sh dropped into the
# fake repo is run without this hook naming it — and the hook never runs the
# real repo's gates (the markers are written only under the fake root).
#
# Run it after changing the hook. post-merge itself sweeps this directory for
# *-selftest.sh, so this file is on its own roster.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh
hook="$repo_root/scripts/git-hooks/post-merge"
[ -f "$hook" ] || { selftest_fail "hook $hook is missing"; exit 1; }

if ! tmp="$(selftest_tmpdir)"; then
  selftest_skip "mktemp -d produced no usable directory — nothing here could run"
  selftest_close "" "post-merge self-test ran nothing: no temp directory"
fi
trap 'rm -rf "$tmp"' EXIT
fake="$tmp/repo"
mkdir -p "$fake/scripts/git-hooks" "$fake/global/hooks" "$fake/marks"
( cd "$fake" && git init -q . ) || { selftest_fail "could not git init the fake repo under $tmp"; selftest_close "" ""; }

# gate <path> <exit code>: a fake gate that records that it ran, then exits.
gate() {
  printf '#!/usr/bin/env bash\ntouch "%s/marks/%s"\nexit %s\n' "$fake" "$(basename "$1")" "$2" > "$fake/$1"
}
gate scripts/lint-skills.sh 1                     # first in the roster, and it fails
gate scripts/lint-adrs.sh 0
gate scripts/partial-selftest.sh 2                # derived from scripts/*-selftest.sh
gate scripts/clean-selftest.sh 0
gate scripts/git-hooks/commit-msg-selftest.sh 0   # derived from the git-hooks directory
printf '#!/usr/bin/env bash\n# Install note: a fake PreToolUse hook whose selftest is missing.\nexit 0\n' > "$fake/global/hooks/orphan.sh"
printf '#!/usr/bin/env bash\n# Install note: a fake PreToolUse hook with a selftest.\nexit 0\n' > "$fake/global/hooks/paired.sh"
gate global/hooks/paired-selftest.sh 0
printf '#!/usr/bin/env bash\ntouch "%s/marks/install.sh"\nexit 0\n' "$fake" > "$fake/scripts/install.sh"

out=$( cd "$fake" && bash "$hook" 2>&1 ); rc=$?
expect_rc "the hook over a fake repo whose first gate fails" 0 "$rc"
expect_in "$out" "a gate exiting 1 did not draw the failed WARN" "post-merge: WARN scripts/lint-skills.sh failed"
expect_in "$out" "a gate exiting 2 did not draw the exit-2 WARN" "post-merge: WARN scripts/partial-selftest.sh exited 2"
reject_in "$out" "a gate exiting 0 drew a WARN" "WARN scripts/lint-adrs.sh"
reject_in "$out" "a gate exiting 0 drew a WARN" "WARN scripts/clean-selftest.sh"
expect_in "$out" "a hook with no selftest did not draw the gate-missing WARN" "post-merge: WARN gate missing: global/hooks/orphan-selftest.sh"
expect_in "$out" "the re-hoist line was not printed — the hook died before it" "post-merge: re-hoisting skills"
for m in lint-skills.sh lint-adrs.sh partial-selftest.sh clean-selftest.sh commit-msg-selftest.sh paired-selftest.sh install.sh; do
  [ -f "$fake/marks/$m" ] || selftest_fail "$m never ran — the hook stopped before it (a failing gate ended the loop, or the roster no longer derives it)"
done
reject_in "$out" "the hook ran against the real repo's gates" "$repo_root/scripts"

selftest_close \
  "post-merge self-test clean — every gate ran whatever the one before it returned, all three statuses drew their line, the derived rosters reached a dropped-in selftest and a hook with none, and the re-hoist ran last." \
  "post-merge self-test ran nothing; see the SKIP line above."
