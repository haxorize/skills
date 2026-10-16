#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/committing/scripts/next-step.sh names the next landing act the
# review-receipt hook would agree with, against throwaway repos with their own
# bare remotes and a REVIEW_RECEIPT_DIR built at run time.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
# Run it after changing the script.
#
# What is graded (the `next:` line unless named):
#   not required — dirty: commit; clean and ahead: push; nothing ahead: none;
#     `yes (planned)` is not yes; a nested CLAUDE.md saying `no` opts its
#     directory out under a gated root; an untracked file is dirty under
#     status.showUntrackedFiles=no; the tree: and ahead: lines.
#   the push itself — no upstream: `git push -u origin <branch>`; a detached
#     HEAD and no remote: no push, named on the ahead: line; a diverged branch:
#     pull first, with the behind count.
#   required — clean and nothing ahead: none; no report: commit then review
#     when dirty, /review-changes when clean; another repo's report and a
#     `Measured-tree:` line are no receipt, and the receipt: line counts the
#     reports read; a report stamping the dirty tree: commit the whole tree,
#     then push; after that commit: push; a scratch file beside a stamped HEAD:
#     push, naming the path left out; a commit after a one-stamp report, clean
#     or dirty: /address-findings <it>; after a second stamp: review again; a
#     one-stamp report already pushed: none, then /review-changes after a new
#     commit; /address-findings only for this branch's unaddressed review —
#     a report naming an `F<n>` finding whose Reviewed-head is HEAD's
#     unpushed ancestor (or any ancestor, with no upstream), or the upstream
#     tip under a dirty-tree review (the r1 rows), and never for a
#     report with no finding, an `F<n>` line only inside a fence, a report
#     from another branch, one whose head the upstream moved past, or one
#     carrying a decline-all pass's second, equal stamp; the opt-in walks up
#     from a subdirectory; a fenced line (``` or ~~~) is not read, and a ```
#     line does not close a ~~~ fence, nor a shorter ``` run a ```` fence; a
#     staged rename is named by its new path, unquoted; a report in the TMPDIR zone with
#     REVIEW_RECEIPT_DIR unset, written by landing.sh path.
#   cadence — --mid-family under a `Review cadence:` line (bold, or
#     backticked, read from a subdirectory too): commit this batch, or the next
#     batch when clean; --mid-family with no cadence line changes nothing; the
#     family's end: commit this batch, then /review-changes; the order line
#     carries the cadence.
#   the scripts it runs — a copy laid out as a checkout runs the tree-stamp.sh
#     beside it, never one under ~/.claude/skills/; a --stamps read that fails
#     exits 4 and names the report, and one that exits 4 skips the report;
#     landing.sh list failing exits 4 with landing.sh's reason; a world-
#     writable zone exits 4.
#   parity — the review-receipt hook and this script run on one fixture each,
#     and agree on push or hold: bold, backticked and planned `Review
#     required:` lines, a fenced line of each kind, a subdirectory walk both
#     ways, a bold cadence line under --mid-family, fenced and live stamps, the
#     TMPDIR zone and an override pointing elsewhere, and HEAD's tree stamped
#     beside a scratch file. A push the hook allows here must be a quiet allow
#     (a stamp, or no opt-in), never a fail-open.
#   usage and never-ran — an unknown flag exits 3; outside a work tree, 4.
#
# Mutations run by hand on 2026-10-13, each red here: the `Reviewed-tree`
#   filter dropped (the Measured row reds); `-eq 1` loosened to `-ge 1` (the
#   second-stamp row reds); the upstream-tree check dropped (the pushed-report
#   row reds); `grep -qi yes` dropped (the opt-out row reds). And, on the
#   second pass: the clean-and-up-to-date arm dropped (the fresh gated row);
#   the stamped nothing-ahead arm dropped (the pushed row); `&& [ -n "$cadence"
#   ]` dropped from --mid-family (the no-cadence row); the walk replaced by
#   one directory (the subdirectory rows); unfenced dropped (the fence rows);
#   the HEAD-tree match dropped (the scratch-file rows); push_act's behind
#   check dropped (the diverged row); --untracked-files=normal dropped (the
#   showUntrackedFiles row). Run 2026-10-14 on `addressable`, each red here:
#   the `F<n>` test dropped (the no-finding and fenced-finding rows); the
#   ancestor-of-HEAD test dropped (the other-branch row); the upstream-tip
#   case dropped (the r1 rows); the not-reachable test dropped (the
#   moved-past row); no upstream treated as not addressable (the no-upstream
#   row). Against the script before `addressable`, the no-finding, fenced,
#   other-branch and moved-past rows red; the positive and decline-all rows
#   are green there too (the decline-all fix is address-findings' always-on
#   stamp, which the row's fixture writes).
#
# NOT covered: the stamp line shapes (tree-stamp-selftest.sh), the zone list
# itself (landing-selftest.sh), and the push gate's other rules
# (review-receipt-selftest.sh); a landing.sh missing from beside the checkout.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="$repo_root/src/committing/scripts/next-step.sh"
stamp="$repo_root/src/review-changes/scripts/tree-stamp.sh"
landing="$repo_root/src/handoff/scripts/landing.sh"
hook="$repo_root/global/hooks/review-receipt.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir next-step-selftest.sh
trap 'rm -rf "$tmp"' EXIT
tmp="$(cd "$tmp" && pwd -P)"
export REVIEW_RECEIPT_DIR="$tmp/zone"
mkdir -p "$REVIEW_RECEIPT_DIR" "$tmp/home"
# no installed suite under HOME; the scripts resolve beside this checkout either way, as the hook's do
export HOME="$tmp/home"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# mkrepo <name> <CLAUDE.md printf-format>: a clone of its own bare remote, upstream set,
# one commit pushed and nothing ahead.
mkrepo() {
  git init -q --bare "$tmp/$1-remote.git"
  git clone -q "$tmp/$1-remote.git" "$tmp/$1" 2>/dev/null
  ( cd "$tmp/$1" && git checkout -q -b main 2>/dev/null
    printf "$2" > CLAUDE.md
    git add CLAUDE.md && git commit -q -m init && git push -q -u origin main 2>/dev/null )
}
commit() { ( cd "$tmp/$1" && git add -A && git commit -q -m "${2:-change}" ); }
# mkahead <name> <CLAUDE.md printf-format>: mkrepo, then one clean commit ahead
mkahead() { mkrepo "$1" "$2"; echo a > "$tmp/$1/a"; commit "$1"; }
line_of() { local key="$1" d="$2"; shift 2; ( cd "$d" && bash "$script" "$@" ) | sed -n "s/^$key: //p"; }
next_of() { line_of next "$tmp/$1" "${@:2}"; }
treestamp() { ( cd "$tmp/$1" && bash "$stamp" ); }
rhead() { git -C "$tmp/$1" rev-parse --short HEAD; }
# report <repo> <slug> <line>...: a review report for <repo>, mtime advancing per call
n=0
report() {
  local f="$REVIEW_RECEIPT_DIR/$1-2026-01-01-$2.review.md"; shift 2
  printf '# review\n\n' > "$f"; printf '%s\n' "$@" >> "$f"
  n=$((n + 1)); touch -t "2026010100$(printf '%02d' "$n")" "$f"
  printf '%s\n' "$f"
}

GATED='# repo\n\nLanding:\n- Review required: yes\n'

# --- not required ---
mkrepo plain '# repo\n'
expect_row "$(next_of plain)" "not required, nothing ahead" "none, nothing to land"
echo x > "$tmp/plain/f"
expect_row "$(next_of plain)" "not required, dirty" "commit (or /ship for a split or a PR)"
expect_row "$(line_of tree "$tmp/plain")" "the tree line counts the dirty path" "$(treestamp plain | cut -c1-12), 1 dirty path(s)"
commit plain
expect_row "$(next_of plain)" "not required, clean and ahead" "push"
expect_row "$(line_of tree "$tmp/plain")" "the tree line says clean" "$(treestamp plain | cut -c1-12), clean"
expect_row "$(line_of ahead "$tmp/plain")" "the ahead line counts the commit" "1 of origin/main"
( cd "$tmp/plain" && git config status.showUntrackedFiles no ); echo u > "$tmp/plain/u"
expect_row "$(next_of plain)" "an untracked file is dirty whatever showUntrackedFiles says" "commit (or /ship for a split or a PR)"
rm "$tmp/plain/u"
mkrepo planned '# repo\n\nReview required: yes (planned)\n'
echo x > "$tmp/planned/f"; commit planned
expect_row "$(next_of planned)" "yes (planned) is not yes" "push"
mkrepo optout "$GATED"
mkdir -p "$tmp/optout/pkg"; printf 'Review required: no\n' > "$tmp/optout/pkg/CLAUDE.md"; commit optout
expect_row "$(line_of next "$tmp/optout/pkg")" "a nested no never opts out; the top decides" "/review-changes"

# --- the push itself: remote, upstream, branch, divergence ---
mkahead noup '# repo\n'; ( cd "$tmp/noup" && git branch -q --unset-upstream )
expect_row "$(next_of noup)" "no upstream: push -u" "git push -u origin main"
expect_row "$(line_of ahead "$tmp/noup")" "the ahead line names no upstream" "? (no upstream)"
( cd "$tmp/noup" && git checkout -q --detach )
expect_row "$(next_of noup)" "a detached HEAD is not pushed" "none until HEAD is on a branch: it is detached (git switch -c <name>)"
expect_row "$(line_of ahead "$tmp/noup")" "the ahead line names the detached HEAD" "? (detached HEAD)"
git init -q "$tmp/noremote"; ( cd "$tmp/noremote" && printf '# repo\n' > CLAUDE.md && git add -A && git commit -q -m init )
expect_row "$(next_of noremote)" "no remote: no push" "none (no remote)"
expect_row "$(line_of ahead "$tmp/noremote")" "the ahead line names no remote" "? (no remote)"
mkahead diverged '# repo\n'
git clone -q "$tmp/diverged-remote.git" "$tmp/diverged-other" 2>/dev/null
( cd "$tmp/diverged-other" && echo o > o && git add o && git commit -q -m other && git push -q origin main 2>/dev/null )
( cd "$tmp/diverged" && git fetch -q origin )
expect_row "$(next_of diverged)" "a diverged branch pulls first" "pull first: origin/main has 1 commit(s) HEAD lacks (git pull --rebase), then push"
expect_row "$(line_of ahead "$tmp/diverged")" "the ahead line counts behind" "1 of origin/main, 1 behind"

# --- required ---
mkrepo gated "$GATED"
expect_row "$(next_of gated)" "required, clean, nothing ahead, no report" "none, nothing to land"
echo x > "$tmp/gated/f"
expect_row "$(next_of gated)" "required, dirty, no report" "commit when you like; /review-changes before the push"
expect_in "$(line_of order "$tmp/gated")" "the order names the review before the push" "then /review-changes and /address-findings, then push"
report other x "Reviewed-tree: $(treestamp gated)" >/dev/null
mv "$REVIEW_RECEIPT_DIR/other-2026-01-01-x.review.md" "$REVIEW_RECEIPT_DIR/gatedx-2026-01-01-x.review.md"
expect_row "$(next_of gated)" "another repo's report is not read" "commit when you like; /review-changes before the push"
report gated measured "Measured-tree: $(treestamp gated)" >/dev/null
expect_row "$(next_of gated)" "a Measured-tree line is no receipt" "commit when you like; /review-changes before the push"
expect_row "$(line_of receipt "$tmp/gated")" "the receipt line counts the reports read" "none of 1 report(s) stamps it"
r1="$(report gated r1 "Reviewed-head: $(rhead gated)" "**F1. a finding**" "Reviewed-tree: $(treestamp gated)")"
expect_row "$(next_of gated)" "a report stamps the dirty tree" "commit the whole tree, then push"
commit gated
expect_row "$(next_of gated)" "the stamped tree committed" "push"
expect_row "$(line_of receipt "$tmp/gated")" "the receipt names the report" "stamped by $r1"
echo s > "$tmp/gated/scratch"
expect_row "$(next_of gated)" "a scratch file beside a stamped HEAD: push, naming it" \
  "push; it sends the stamped commits, not the uncommitted path(s), which need their own review: scratch"
expect_row "$(line_of receipt "$tmp/gated")" "the receipt names HEAD's tree" "HEAD's tree stamped by $r1, not the 1 uncommitted path(s)"
rm "$tmp/gated/scratch"
mkahead renamed "$GATED"
report renamed head "Reviewed-tree: $( cd "$tmp/renamed" && git rev-parse 'HEAD^{tree}' )" >/dev/null
( cd "$tmp/renamed" && git mv a "b c" )
expect_row "$(next_of renamed)" "a staged rename beside a stamped HEAD names its new path, unquoted" \
  "push; it sends the stamped commits, not the uncommitted path(s), which need their own review: b c"
echo y >> "$tmp/gated/f"; commit gated
expect_row "$(next_of gated)" "a commit after a one-stamp report" "/address-findings $r1"
echo w >> "$tmp/gated/f"
expect_row "$(next_of gated)" "and an edit after that commit" "/address-findings $r1"
printf 'Reviewed-tree: %040d\n' 0 >> "$r1"
expect_row "$(next_of gated)" "an edit after the fix pass's stamp" "commit when you like; /review-changes before the push"
commit gated
expect_row "$(next_of gated)" "clean and ahead, unstamped" "/review-changes"

mkrepo pushed "$GATED"
report pushed done "Reviewed-tree: $( cd "$tmp/pushed" && bash "$stamp" --committed HEAD )" >/dev/null
expect_row "$(next_of pushed)" "a stamped tree already pushed" "none, nothing to land"
echo z > "$tmp/pushed/g"; commit pushed
expect_row "$(next_of pushed)" "a one-stamp report already pushed" "/review-changes"

# which one-stamp report is this branch's unaddressed review
mkahead pos "$GATED"; echo x > "$tmp/pos/f"
rpos="$(report pos r "Reviewed-head: $(rhead pos)" "**F1. a finding**" "Reviewed-tree: $(treestamp pos)")"
echo y >> "$tmp/pos/f"; commit pos
expect_row "$(next_of pos)" "a one-stamp report on an unpushed head, then a commit" "/address-findings $rpos"
( cd "$tmp/pos" && git branch -q --unset-upstream )
expect_row "$(next_of pos)" "and with no upstream, an ancestor of HEAD" "/address-findings $rpos"
printf 'Reviewed-tree: %s\n' "$(sed -n 's/^Reviewed-tree: //p' "$rpos")" >> "$rpos"
expect_row "$(next_of pos)" "a decline-all pass: a second stamp equal to the first" "/review-changes"
mkrepo zero "$GATED"; echo x > "$tmp/zero/f"
report zero r "Reviewed-head: $(rhead zero)" "No findings." "Reviewed-tree: $(treestamp zero)" >/dev/null
echo y >> "$tmp/zero/f"; commit zero
expect_row "$(next_of zero)" "a one-stamp report with no F<n> finding" "/review-changes"
mkrepo fencedf "$GATED"; echo x > "$tmp/fencedf/f"
report fencedf r "Reviewed-head: $(rhead fencedf)" '```' "F1. quoted" '```' "Reviewed-tree: $(treestamp fencedf)" >/dev/null
echo y >> "$tmp/fencedf/f"; commit fencedf
expect_row "$(next_of fencedf)" "an F<n> line inside a fence is no finding" "/review-changes"
mkrepo br "$GATED"
( cd "$tmp/br" && git checkout -q -b other && echo b > b && git add b && git commit -q -m b )
report br r "Reviewed-head: $(rhead br)" "**F1. a finding**" "Reviewed-tree: $(treestamp br)" >/dev/null
( cd "$tmp/br" && git checkout -q main ); echo m > "$tmp/br/m"; commit br
expect_row "$(next_of br)" "a one-stamp report from another branch" "/review-changes"
mkrepo stale "$GATED"; echo x > "$tmp/stale/f"
report stale r "Reviewed-head: $(rhead stale)" "**F1. a finding**" "Reviewed-tree: $(treestamp stale)" >/dev/null
rm "$tmp/stale/f"
git clone -q "$tmp/stale-remote.git" "$tmp/stale-other" 2>/dev/null
( cd "$tmp/stale-other" && echo o > o && git add o && git commit -q -m other && git push -q origin main 2>/dev/null )
( cd "$tmp/stale" && git pull -q --ff-only 2>/dev/null ); echo w > "$tmp/stale/g"; commit stale
expect_row "$(next_of stale)" "a one-stamp report whose head the upstream moved past" "/review-changes"

mkahead walk "$GATED"; mkdir -p "$tmp/walk/pkg"; printf '# pkg\n' > "$tmp/walk/pkg/CLAUDE.md"; commit walk
expect_row "$(line_of next "$tmp/walk/pkg")" "the opt-in walks up from a subdirectory" "/review-changes"
mkahead fenced '# repo\n\n```\n- Review required: yes\n```\n'
expect_row "$(next_of fenced)" "a line inside a backtick fence is not read" "push"
mkahead tilde '# repo\n\n~~~\n- Review required: yes\n~~~\n'
expect_row "$(next_of tilde)" "a line inside a ~~~ fence is not read" "push"
mkahead mixed '# repo\n\n~~~\n```\n~~~\n- Review required: yes\n'
expect_row "$(next_of mixed)" "a backtick line does not close a ~~~ fence" "/review-changes"
mkahead longf '# repo\n\n````\n```\n- Review required: yes\n```\n````\n'
expect_row "$(next_of longf)" "a shorter backtick run does not close a four-backtick fence" "push"

mkahead tmpzone "$GATED"
tz_report="$( cd "$tmp/tmpzone" && REVIEW_RECEIPT_DIR= TMPDIR="$tmp/t" bash "$landing" path done --kind review )"
printf 'Reviewed-tree: %s\n' "$(treestamp tmpzone)" > "$tz_report"
out="$( cd "$tmp/tmpzone" && REVIEW_RECEIPT_DIR= TMPDIR="$tmp/t" bash "$script" | sed -n 's/^next: //p' )"
expect_row "$out" "a report in the TMPDIR zone, written by landing.sh path" "push"
expect_row "$(next_of tmpzone)" "and REVIEW_RECEIPT_DIR elsewhere does not see it" "/review-changes"

# --- cadence ---
mkrepo round '# repo\n\nLanding:\n- Review required: yes\n\nRound:\n- **Review cadence:** per batch family\n'
expect_row "$(next_of round --mid-family)" "mid-family, clean, under a cadence" "the next batch; the cadence reviews at the family's end"
echo x > "$tmp/round/f"
expect_row "$(next_of round --mid-family)" "mid-family under a bold cadence line" "commit this batch"
expect_row "$(next_of round)" "the family's end under a cadence" "commit this batch, then /review-changes"
expect_in "$(line_of order "$tmp/round")" "the order carries the cadence" "(Review cadence: per batch family)"
expect_in "$(line_of order "$tmp/round")" "and a commit per batch" "commit at the end of every batch"
mkdir -p "$tmp/round/sub"
expect_row "$(line_of next "$tmp/round/sub" --mid-family)" "the cadence line read from a subdirectory" "commit this batch"
mkrepo ticked '# repo\n\n- Review required: yes\n- `Review cadence:` per family\n'
echo x > "$tmp/ticked/f"
expect_row "$(next_of ticked --mid-family)" "a backticked cadence key" "commit this batch"
expect_row "$(next_of gated --mid-family)" "--mid-family with no cadence line changes nothing" "/review-changes"

# --- the scripts it runs ---
# A copy laid out as a checkout reads the two scripts beside it, as the hook
# reads its own, and never a copy under ~/.claude/skills/ (HOME points at a
# decoy that records any run).
mkco() { # mkco <dir> <tree-stamp body or 'real'> <landing body or 'real'>
  mkdir -p "$1/src/committing/scripts" "$1/src/review-changes/scripts" "$1/src/handoff/scripts"
  cp "$script" "$1/src/committing/scripts/"
  if [ "$2" = real ]; then cp "$stamp" "$1/src/review-changes/scripts/"; else printf '%s\n' "$2" > "$1/src/review-changes/scripts/tree-stamp.sh"; fi
  if [ "$3" = real ]; then cp "$landing" "$1/src/handoff/scripts/"; else printf '%s\n' "$3" > "$1/src/handoff/scripts/landing.sh"; fi
}
mkdir -p "$tmp/fakehome/.claude/skills/review-changes/scripts" "$tmp/fakehome/.claude/skills/handoff/scripts"
printf 'touch "%s/installed-used"; exit 1\n' "$tmp" > "$tmp/fakehome/.claude/skills/review-changes/scripts/tree-stamp.sh"
printf 'touch "%s/installed-used"; exit 1\n' "$tmp" > "$tmp/fakehome/.claude/skills/handoff/scripts/landing.sh"
mkco "$tmp/co" "touch \"$tmp/beside-used\"
[ \"\${1:-}\" = --stamps ] && [ -n \"\${FAKE_STAMPS_RC:-}\" ] && exit \"\$FAKE_STAMPS_RC\"
exec bash \"$stamp\" \"\$@\"" real
co_script="$tmp/co/src/committing/scripts/next-step.sh"
out="$( cd "$tmp/gated" && HOME="$tmp/fakehome" bash "$co_script" | sed -n 's/^next: //p' )"
expect_row "$out" "the tree-stamp.sh beside the checkout gives the same answer" "/review-changes"
[ -f "$tmp/beside-used" ] || selftest_fail "the tree-stamp.sh beside the checkout copy was not the one run"
[ -f "$tmp/installed-used" ] && selftest_fail "a decoy script under the fake HOME was run in place of the one beside the checkout"
selftest_rows=$((selftest_rows + 1))
out="$( cd "$tmp/gated" && HOME="$tmp/fakehome" FAKE_STAMPS_RC=1 bash "$co_script" 2>&1 )"; rc=$?
expect_rc "a --stamps read that fails" 4 "$rc"
expect_in "$out" "and it names the report" "tree-stamp.sh --stamps failed on $REVIEW_RECEIPT_DIR/gated-2026-01-01-"
# a --stamps exit 4 (a report it could not read) skips that report, as the hook does
out="$( cd "$tmp/gated" && HOME="$tmp/fakehome" FAKE_STAMPS_RC=4 bash "$co_script" 2>&1 )"; rc=$?
expect_rc "a --stamps read that exits 4" 0 "$rc"
expect_in "$out" "skips the report, naming it" "next-step.sh: skipping unreadable report $REVIEW_RECEIPT_DIR/gated-2026-01-01-"
expect_in "$out" "and counts no report read" "receipt: none of 0 report(s) stamps it"
# landing.sh list failing exits 4, carrying landing.sh's own reason
mkco "$tmp/co2" real "[ \"\$1\" = list ] && { echo 'landing.sh: list refused here' >&2; exit 4; }; exec bash \"$landing\" \"\$@\""
out="$( cd "$tmp/gated" && bash "$tmp/co2/src/committing/scripts/next-step.sh" 2>&1 )"; rc=$?
expect_rc "landing.sh list failing" 4 "$rc"
expect_in "$out" "names landing.sh's reason" "landing.sh: list refused here"
expect_in "$out" "and its own" "next-step.sh: landing.sh list failed (exit 4)"
# a zone landing.sh refuses is a never-ran, not "none of 0 reports"
mkdir -p "$tmp/wzone"; chmod o+w "$tmp/wzone"
out="$( cd "$tmp/gated" && REVIEW_RECEIPT_DIR="$tmp/wzone" bash "$script" 2>&1 )"; rc=$?
expect_rc "a world-writable zone" 4 "$rc"
expect_in "$out" "names the refused zone" "is not this user's alone"

# --- parity with the review-receipt hook ---
# parity <label> <push|hold> <dir> [next-step args]: the hook judges a bare
# `git push` from <dir>, next-step.sh prints its next act from there, and the
# two must agree with <want> and with each other. A hook allow must be quiet.
parity() {
  local label="$1" want="$2" d="$3" hrc herr ns; shift 3
  herr="$( cd "$d" && python3 -c 'import json,sys; print(json.dumps({"cwd":sys.argv[1],"tool_input":{"command":"git push"}}))' "$d" \
    | bash "$hook" 2>&1 >/dev/null )"; hrc=$?
  ns="$( cd "$d" && bash "$script" "$@" | sed -n 's/^next: //p' )"
  selftest_rows=$((selftest_rows + 1))
  case "$want" in
    push) [ "$hrc" = 0 ] && [ -z "$herr" ] && [ "${ns%%;*}" = push ] \
            || selftest_fail "parity, $label — want push: hook rc=$hrc ${herr:+($herr) }next-step '$ns'" ;;
    hold) [ "$hrc" = 2 ] && [ "${ns%%;*}" != push ] \
            || selftest_fail "parity, $label — want hold: hook rc=$hrc, next-step '$ns'" ;;
  esac
}
mkahead pbold '# repo\n\n**Review required:** yes\n'
parity "a bold key" hold "$tmp/pbold"
mkahead pboldall '# repo\n\n**Review required: yes**\n'
parity "a bold line" hold "$tmp/pboldall"
mkahead pticks '# repo\n\n- Review required: `yes`\n'
parity "a backticked value" hold "$tmp/pticks"
parity "yes (planned)" push "$tmp/planned"
parity "a line in a backtick fence" push "$tmp/fenced"
parity "a line in a ~~~ fence" push "$tmp/tilde"
parity "a backtick line inside a ~~~ fence" hold "$tmp/mixed"
parity "a shorter backtick run inside a four-backtick fence" push "$tmp/longf"
parity "a subdirectory walks up to the gated root" hold "$tmp/walk/pkg"
parity "a subdirectory saying no" hold "$tmp/optout/pkg"
mkahead pcad '# repo\n\n- Review required: yes\n- **Review cadence:** per batch family\n'
parity "a bold cadence line, mid-family" hold "$tmp/pcad" --mid-family
parity "a bold cadence line, the family's end" hold "$tmp/pcad"
mkahead pstamp "$GATED"
report pstamp fenced 'quoting:' '```' "Reviewed-tree: $(treestamp pstamp)" '```' >/dev/null
parity "a stamp inside a fence is a quotation" hold "$tmp/pstamp"
report pstamp live '~~~' '```' '~~~' "Reviewed-tree: $(treestamp pstamp)" >/dev/null
parity "a stamp after a closed ~~~ fence is live" push "$tmp/pstamp"
REVIEW_RECEIPT_DIR= TMPDIR="$tmp/t" parity "a report in the TMPDIR zone" push "$tmp/tmpzone"
parity "REVIEW_RECEIPT_DIR elsewhere" hold "$tmp/tmpzone"
mkahead phead "$GATED"
report phead head "Reviewed-tree: $( cd "$tmp/phead" && git rev-parse 'HEAD^{tree}' )" >/dev/null
echo s > "$tmp/phead/scratch"
parity "HEAD's tree stamped beside a scratch file" push "$tmp/phead"

# --- usage and never-ran ---
( cd "$tmp/plain" && bash "$script" --bogus ) >/dev/null 2>&1; rc=$?
expect_rc "an unknown flag" 3 "$rc"
mkdir -p "$tmp/outside"
( cd "$tmp/outside" && GIT_CEILING_DIRECTORIES="$tmp" bash "$script" ) >/dev/null 2>&1; rc=$?
expect_rc "outside a work tree" 4 "$rc"

selftest_close "next-step self-test passed" ""
