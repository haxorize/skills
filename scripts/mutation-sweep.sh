#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# mutation-sweep.sh — the guard-coverage sweep over the repo's own gates: does
# each selftest go red when the script it grades is quietly broken?
#
# scripts/README.md § "A check lands with its fixture and its mutation, in
# both directions" owns the contract this is the mechanical half of: a check
# lands with a mutation that reds its selftest, both ways, and the pairing
# check alone proves a selftest exists, never that it can fail. This is the
# mechanical half. For every gated script it derives the paired selftest(s),
# asks mutation-sweep.py for one-line mutants of the script (an alternative
# dropped from a pattern, a comparison flipped, a reporting line removed —
# the generator's header defines each), and for each mutant copies the
# working tree, writes the mutant over the script in the copy, and runs the
# paired selftest there. A selftest that stays green over a mutant has a hole
# at that line: the site is SILENT, and it is the finding. One SILENT site is
# a FAIL of this sweep, because the hazard it names is a gate that reads
# clean where it no longer checks.
#
# What it grades, and what it does not. Only the paired selftest runs — the
# real gate's run over the real tree is not the question, its selftest's
# ability to notice is. A mutant the paired selftest cannot even start on
# (exit 4) is BROKE: noticed, but by a crash rather than a fixture, so it is
# listed and not counted as caught. A mutant that leaves the file unparseable
# (`bash -n`, `ast.parse`) is INVALID: a real edit could not have landed it,
# so it is counted and never run. A selftest that outruns the timeout is
# HUNG, listed, not counted either way. A selftest that exits 2 (a SKIP with
# no FAIL) over a mutant is SILENT: as far as it ran, it saw nothing. A
# target whose selftest is not green over the unmutated copy is UNGRADED —
# its mutants say nothing — and the run ends 2. selftest-lib.sh (both) is
# never a target: mutating the harness tests the tests, not the gates.
#
# The roster is derived the way post-merge and lint-skills.sh derive theirs,
# plus the libraries they leave out because they are not gates themselves:
#   scripts/<name>.sh (not a selftest, a *-lib.sh, or setup-hooks.sh)
#                                        → scripts/<name>-selftest.sh
#   scripts/git-hooks/<name> (first line a shebang, not a selftest)
#                                        → scripts/git-hooks/<name>-selftest.sh
#   global/hooks/<name>.sh with `# Install note:`
#                                        → global/hooks/<name>-selftest.sh
#   <dir>/<name>.py beside a <dir>/<name>.sh
#                                        → that script's selftest
#   any other *-lib.sh or *.py under scripts/ or global/hooks/
#                                        → the selftests of every non-selftest
#                                          script in its directory that names
#                                          the file (grep -l), so hook-lib.py
#                                          is graded by the three hooks that
#                                          source it
# A target with no selftest is reported and UNGRADED; the pairing lint owns
# that failure, not this sweep.
#
# Cost: one selftest run per mutant. lint-skills-selftest.sh takes about a
# minute, review-receipt's about 45 s, most under 10 s; a large script yields
# hundreds of mutants. So the default caps each target at --max 10, sampled
# deterministically (the same ids every run, see the generator's header), and
# --path narrows to one script for a deeper pass; --all lifts the cap. --jobs
# runs mutants in parallel, each on its own copy of the tree.
#
# Usage:
#   scripts/mutation-sweep.sh [--path FILE]... [--max N | --all] [--op OP]
#                             [--id ID] [--jobs N] [--timeout S] [--list]
#                             [--help]
#   --path FILE   grade only this script (repo-relative; repeatable)
#   --max N       mutants per target (default 10); --all lifts the cap
#   --op OP       only drop-alt, flip-test, or drop-line mutants
#   --id ID       one mutant, by the id a previous run printed (needs --path)
#   --jobs N      parallel mutants (default 1)
#   --timeout S   per-selftest ceiling; default 3x the baseline, floor 60 s;
#                 also caps the baseline timing run (default 600 s)
#   --list        print the roster and the mutants that would run, run none
#
# Output: one line per mutant as it finishes — STATUS, target:line, id, what
# — then a per-target summary and the SILENT sites. stderr carries the
# reasons a target went UNGRADED.
#
# Exit: 0 every graded mutant was CAUGHT; 1 at least one SILENT site; 2 no
# SILENT site but a target was UNGRADED, or a target graded no mutant
# (every one INVALID or HUNG or BROKE), or --list ran nothing; 3 usage;
# 4 python3, perl, or the generator is missing, or the tree could not be copied —
# nothing ran.
#
# The 2026-09-04 round parked this as D2.8 until its first run found a
# silent site; ADR-0093 records the park and that run.

set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
gen="$here/mutation-sweep.py"

usage() { sed -n '/^# Usage:/,/^# nothing ran\.$/p' "$0" | sed 's/^# \{0,1\}//'; }
die_usage() { echo "mutation-sweep: $1" >&2; usage >&2; exit 3; }

paths=""; cap=10; op=""; only_id=""; jobs=1; timeout_s=""; list_only=0
baseline_ceiling=600   # the unmutated baseline selftest may not outrun this (also narrowed by --timeout); a slower one makes its target UNGRADED
while [ $# -gt 0 ]; do
  case "$1" in
    --path) [ $# -ge 2 ] || die_usage "--path needs a file"; paths="$paths ${2#./}"; shift 2 ;;
    --max) [ $# -ge 2 ] && [ "$2" -ge 0 ] 2>/dev/null || die_usage "--max needs a number"; cap=$2; shift 2 ;;
    --all) cap=""; shift ;;
    --op) [ $# -ge 2 ] || die_usage "--op needs an operator"; case "$2" in drop-alt|flip-test|drop-line) op=$2 ;; *) die_usage "--op is drop-alt, flip-test, or drop-line" ;; esac; shift 2 ;;
    --id) [ $# -ge 2 ] || die_usage "--id needs a mutant id"; only_id=$2; shift 2 ;;
    --jobs) [ $# -ge 2 ] && [ "$2" -ge 1 ] 2>/dev/null || die_usage "--jobs needs a number of 1 or more"; jobs=$2; shift 2 ;;
    --timeout) [ $# -ge 2 ] && [ "$2" -ge 1 ] 2>/dev/null || die_usage "--timeout needs seconds"; timeout_s=$2; shift 2 ;;
    --list) list_only=1; shift ;;
    --help|-h) usage; exit 0 ;;
    _one) shift; one_mode=1; break ;;
    *) die_usage "unknown option '$1'" ;;
  esac
done
[ -z "$only_id" ] || [ "$(echo $paths | wc -w)" -eq 1 ] || die_usage "--id needs exactly one --path"

command -v python3 >/dev/null 2>&1 || { echo "mutation-sweep: python3 not found — nothing ran" >&2; exit 4; }
command -v perl >/dev/null 2>&1 || { echo "mutation-sweep: perl not found — the per-selftest timeout is perl; nothing ran" >&2; exit 4; }
[ -f "$gen" ] || { echo "mutation-sweep: mutation-sweep.py is missing beside this script ($gen) — nothing ran" >&2; exit 4; }

# --- helpers --------------------------------------------------------------------

# copy_tree <dest> — the working tree without .git, untracked files included:
# the selftest graded is the one on disk, not the one at HEAD.
copy_tree() {
  mkdir -p "$1" || return 1
  # pipefail (scoped to this subshell) so a failure in the producing tar is not
  # masked by the extracting tar's 0; then assert the copy is non-empty.
  ( set -o pipefail; (cd "$root" && tar --exclude=.git -cf - .) | (cd "$1" && tar -xf -) ) || return 1
  [ -n "$(ls -A "$1" 2>/dev/null)" ] || return 1
}

# parses <file> — the mutant is a file a shell or python could load
parses() {
  case "$1" in
    *.py) python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "$1" >/dev/null 2>&1 ;;   # ast, not py_compile: no bytecode written beside the source
    *) bash -n "$1" >/dev/null 2>&1 ;;
  esac
}

# run_selftest <copy> <selftest> <timeout> — exit status of the selftest in the
# copy; 142 on timeout. The selftest runs in its own process group and the
# whole group is killed at the alarm: a plain `alarm; exec bash` is not enough,
# because bash defers a signal until its foreground child exits, and a mutant
# that sends a script into an endless loop (a flipped tokeniser test did, on
# the first run) holds the bash, the alarm, and the sweep for as long as the
# loop runs.
run_selftest() {
  ( cd "$1" 2>/dev/null || exit 125; perl -e '   # 125: the copy could not be entered — a distinct code so _one does not read a failed cd as CAUGHT (rc 1)
    my $t = shift; my $pid = fork;
    defined($pid) or exit 126;                    # fork failed: never let the parent fall into the child branch and exec with no alarm
    if (!$pid) { setpgrp(0, 0); exec @ARGV or exit 127 }
    local $SIG{ALRM} = sub { kill "KILL", -$pid; waitpid($pid, 0); exit 142 };
    alarm $t; waitpid($pid, 0); alarm 0;
    exit(($? & 127) ? 128 + ($? & 127) : $? >> 8)' "$3" bash "$2" ) >/dev/null 2>&1; echo $?
}

# selftests_for <target> — the space-separated selftests that grade it, or nothing
selftests_for() {
  local t=$1 d stem base st out="" f
  d="${t%/*}"; base="${t##*/}"
  case "$t" in
    scripts/git-hooks/*) st="$t-selftest.sh"; [ -f "$root/$st" ] && echo "$st"; return ;;
    *-lib.py) ;;
    *.py) stem="${t%.py}"; if [ -f "$root/$stem.sh" ]; then st="$stem-selftest.sh"; [ -f "$root/$st" ] && echo "$st"; return; fi ;;
    *-lib.sh) ;;
    *.sh) st="${t%.sh}-selftest.sh"; [ -f "$root/$st" ] && echo "$st"; return ;;
  esac
  # a library: the selftests of the non-selftest scripts in its directory that
  # name it, plus those of any script naming a library that names it (one hop:
  # hook-lib.py is named only by hook-lib.sh, which the three hooks source)
  local names="$base" f2
  for f in "$root/$d"/*-lib.sh; do
    [ -f "$f" ] && [ "${f##*/}" != "$base" ] && grep -v '^[[:space:]]*#' "$f" | grep -q -F -- "$base" && names="$names ${f##*/}"
  done
  for f in "$root/$d"/*.sh; do
    [ -f "$f" ] || continue
    case "$f" in *-selftest.sh|*-lib.sh) continue ;; esac
    for f2 in $names; do grep -v '^[[:space:]]*#' "$f" | grep -q -F -- "$f2" && break; done || continue   # a mention in a comment is not a source
    st="${f%.sh}-selftest.sh"; st="${st#$root/}"
    [ -f "$root/$st" ] && case " $out " in *" $st "*) ;; *) out="$out $st" ;; esac
  done
  echo "${out# }"
}

# roster — every target, one per line
roster() {
  local f
  for f in "$root"/scripts/*.sh; do
    [ -f "$f" ] || continue
    case "${f##*/}" in *-selftest.sh|setup-hooks.sh|selftest-lib.sh) continue ;; esac
    echo "scripts/${f##*/}"
  done
  for f in "$root"/scripts/*.py; do [ -f "$f" ] && echo "scripts/${f##*/}"; done
  for f in "$root"/scripts/git-hooks/*; do
    [ -f "$f" ] || continue
    case "${f##*/}" in *-selftest.sh) continue ;; esac
    case "$(head -n 1 "$f" 2>/dev/null)" in '#!'*) echo "scripts/git-hooks/${f##*/}" ;; esac
  done
  for f in "$root"/global/hooks/*.sh; do
    [ -f "$f" ] || continue
    case "${f##*/}" in *-selftest.sh) continue ;; esac   # selftest-lib.sh is already excluded below (no Install note, not hook-lib.sh)
    if grep -q '^# Install note: ' "$f" || [ "${f##*/}" = hook-lib.sh ]; then echo "global/hooks/${f##*/}"; fi
  done
  for f in "$root"/global/hooks/*.py; do [ -f "$f" ] && echo "global/hooks/${f##*/}"; done
}

# --- _one: grade one mutant on its own copy (the unit --jobs parallelises) ----------
# _one <target> <id> <timeout> <selftests...> → STATUS<TAB>target:line<TAB>id<TAB>what
if [ "${one_mode:-0}" = 1 ]; then
  target=$1; id=$2; tmo=$3; shift 3
  # _one is internal, but it is parsed off the public CLI and its target reaches
  # both a read ($root/$target) and a truncating write ($copy/$target); reject a
  # path that could escape the tree before either resolves (see F18).
  case "$target" in /*|../*|*/../*|*/..) echo "mutation-sweep: _one refuses target '$target' — must be a repo-relative path inside the tree" >&2; exit 3 ;; esac
  line="${id#*:}"; line="${line%%:*}"
  what="$(python3 "$gen" list "$root/$target" | awk -F'\t' -v id="$id" '$1==id{print $4}')"
  copy="$(mktemp -d 2>/dev/null)" || { printf 'BROKE\t%s:%s\t%s\tno temp directory\n' "$target" "$line" "$id"; exit 0; }
  trap 'rm -rf "$copy"' EXIT
  copy_tree "$copy" || { printf 'BROKE\t%s:%s\t%s\tcould not copy the tree\n' "$target" "$line" "$id"; exit 0; }
  python3 "$gen" apply "$root/$target" "$id" > "$copy/$target" || { printf 'BROKE\t%s:%s\t%s\tgenerator could not apply it\n' "$target" "$line" "$id"; exit 0; }
  if ! parses "$copy/$target"; then printf 'INVALID\t%s:%s\t%s\t%s\n' "$target" "$line" "$id" "$what"; exit 0; fi
  status=UNKNOWN                                    # never the finding by default: SILENT is a code the loop must see, not where it starts
  for st in "$@"; do
    rc="$(run_selftest "$copy" "$st" "$tmo")"
    case "$rc" in
      1) status=CAUGHT; break ;;
      0|2) [ "$status" = BROKE ] || [ "$status" = HUNG ] || status=SILENT ;;
      4) status=BROKE ;;
      142) [ "$status" = BROKE ] || status=HUNG ;;
      *) status=BROKE ;;                             # any other exit (failed cd/exec/fork at :136, or 3/5/127/128+signal): fail toward BROKE, never silently SILENT
    esac
  done
  printf '%s\t%s:%s\t%s\t%s\n' "$status" "$target" "$line" "$id" "$what"
  exit 0
fi

# --- main -----------------------------------------------------------------------
targets="$(roster)"
if [ -n "$paths" ]; then
  sel=""
  for p in $paths; do
    printf '%s\n' "$targets" | grep -qx -- "$p" || die_usage "--path $p is not a target the roster derives (run --list to see it)"
    sel="$sel
$p"
  done
  targets="${sel#
}"
fi

results="$(mktemp 2>/dev/null)" || { echo "mutation-sweep: no temp file — nothing ran" >&2; exit 4; }
trap 'rm -f "$results"' EXIT
ungraded=0; nothing_graded=0; ran_any=0

for target in $targets; do
  sts="$(selftests_for "$target")"
  if [ -z "$sts" ]; then
    echo "mutation-sweep: UNGRADED $target — no selftest pairs with it (the pairing lint owns that)" >&2
    ungraded=1; continue
  fi
  listargs=""
  [ -z "$cap" ] || listargs="--max $cap"
  [ -z "$op" ] || listargs="$listargs --op $op"
  if [ "$list_only" = 1 ]; then
    echo "$target ← $sts"
    python3 "$gen" list "$root/$target" $listargs | sed 's/^/  /'
    continue
  fi
  ids="$(python3 "$gen" list "$root/$target" $listargs | cut -f1)"
  [ -z "$only_id" ] || ids="$(printf '%s\n' "$ids" | grep -x -F -- "$only_id" || true)"
  if [ -z "$ids" ]; then
    echo "mutation-sweep: $target — no mutant to run${only_id:+ (no such id $only_id)}" >&2
    [ -z "$only_id" ] || exit 3
    continue
  fi
  # baseline: the paired selftest is green on an unmutated copy, and its runtime sets the timeout
  base="$(mktemp -d 2>/dev/null)" || { echo "mutation-sweep: no temp directory — nothing ran" >&2; exit 4; }
  copy_tree "$base" || { rm -rf "$base"; echo "mutation-sweep: could not copy the tree — nothing ran" >&2; exit 4; }
  tmo="${timeout_s:-}"; ok=1
  for st in $sts; do
    t0=$(date +%s); rc="$(run_selftest "$base" "$st" "${timeout_s:-$baseline_ceiling}")"; t1=$(date +%s)
    if [ "$rc" != 0 ]; then echo "mutation-sweep: UNGRADED $target — $st exits $rc on the unmutated tree, so its mutants say nothing; fix the selftest first" >&2; ok=0; break; fi
    if [ -z "$timeout_s" ]; then want=$(( (t1 - t0) * 3 )); [ "$want" -ge 60 ] || want=60; [ -n "$tmo" ] && [ "$tmo" -ge "$want" ] || tmo=$want; fi
  done
  rm -rf "$base"
  [ "$ok" = 1 ] || { ungraded=1; continue; }
  ran_any=1
  printf '%s\n' "$ids" | xargs -P "$jobs" -I '{}' bash "$0" _one "$target" '{}' "$tmo" $sts | tee -a "$results"
  graded="$(grep -c "^CAUGHT	$target:\|^SILENT	$target:" "$results" || true)"
  [ "$graded" -gt 0 ] || { echo "mutation-sweep: $target graded no mutant — every one was INVALID, HUNG, or BROKE" >&2; nothing_graded=1; }
done

if [ "$list_only" = 1 ]; then exit 2; fi
[ "$ran_any" = 1 ] || { echo "mutation-sweep: nothing ran" >&2; exit 2; }

echo
echo "mutation-sweep: summary"
for target in $targets; do
  grep -q "	$target:" "$results" || continue
  printf '  %s: ' "$target"
  for s in CAUGHT SILENT BROKE HUNG INVALID; do
    c="$(grep -c "^$s	$target:" "$results" || true)"; [ "$c" = 0 ] || printf '%s=%s ' "$s" "$c"
  done
  echo
done
silent="$(grep '^SILENT	' "$results" || true)"
if [ -n "$silent" ]; then
  echo "mutation-sweep: SILENT sites — the paired selftest stayed green over each:"
  printf '%s\n' "$silent" | awk -F'\t' '{printf "  %s  %s  %s\n", $2, $3, $4}'
  echo "mutation-sweep: fix each — add a selftest row that reds the mutant, OR record it in ADR-0093 § Deferred as an accepted-equivalent mutant (an edit with no observable effect)"
  echo "mutation-sweep: FAIL ($(printf '%s\n' "$silent" | wc -l | tr -d ' ') silent)"
  exit 1
fi
if [ "$nothing_graded" = 1 ]; then echo "mutation-sweep: PARTIAL — every graded mutant was caught, but a target graded no mutant (every one INVALID, HUNG, or BROKE; see stderr)"; exit 2; fi
if [ "$ungraded" = 1 ]; then echo "mutation-sweep: PARTIAL — every graded mutant was caught, but a target was UNGRADED (its selftest was not green unmutated; see stderr)"; exit 2; fi
echo "mutation-sweep: OK — every graded mutant was caught"
exit 0
