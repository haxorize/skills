#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Self-test for mutation-sweep.sh and mutation-sweep.py: a fixture tree with
# one planted silent site, graded end to end.
#
# What it grades: the roster derives every pairing the driver's header lists
# (script → selftest, git hook → selftest, Install-note hook → selftest, a
# hook without the note left out, a .py beside a .sh, a *-lib.sh and a
# *-lib.py reaching the selftests of the scripts that source them, a comment
# mention not counting as sourcing); the generator emits each operator on
# the fixture and its --max sample is the same ids twice; a planted hole (one
# alternative no fixture exercises) is reported SILENT with its file:line, id
# and description, and the run exits 1; closing the hole makes the same run
# exit 0; a target whose selftest is red unmutated is UNGRADED on stderr and
# the run exits 2; a mutant that breaks parsing is INVALID and not SILENT; a
# mutant that makes the selftest outrun --timeout is HUNG and not SILENT, and
# the timeout kills the selftest's whole process group, a grandchild included;
# --op keeps one operator, --id runs one mutant, --list runs none and exits
# 2; a --path outside the roster, --id without one --path, and an unknown
# option exit 3. Then the mutation table: three copies of the sweep, each
# with one guard removed, and each must change the verdict the rows above
# read. Not graded: the real repo's selftests — that is the sweep's run, not
# its selftest — and --jobs beyond 1 producing the same lines (xargs -P is
# not this script's to prove), and the default per-selftest timeout (3x the
# baseline, floor 60 s): observing it needs a selftest that hangs for a
# minute, so the sweep's own first run lists that arithmetic as a silent
# site and this header owns the acceptance.
#
# Exit 0 clean, 1 on any FAIL, 2 when a row was skipped, 4 when python3 is
# missing.
set -u
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root" || exit 4
. scripts/selftest-lib.sh
command -v python3 >/dev/null 2>&1 || { echo "mutation-sweep-selftest: python3 missing, nothing ran"; exit 4; }

tmp="$(selftest_tmpdir)" || { selftest_skip "mktemp gave no usable directory — nothing ran"; selftest_close "" "mutation-sweep self-test ran nothing"; }
trap 'rm -rf "$tmp"' EXIT

# --- the fixture tree: the sweep resolves its root from its own location ---------
fx="$tmp/fx"
mkdir -p "$fx/scripts/git-hooks" "$fx/global/hooks"
cp scripts/mutation-sweep.sh scripts/mutation-sweep.py "$fx/scripts/"
cat > "$fx/scripts/guard.sh" <<'G'
#!/usr/bin/env bash
# fixture: a guard with three alternatives, one uncovered by its selftest
. "$(dirname "$0")/helper-lib.sh"
v="${1:-}"
case "$v" in
  red|green|blue) echo "colour: $v"; exit 0 ;;
esac
[ -n "$v" ] || { echo "guard: empty"; exit 3; }
[ "$v" = "help" ] && { echo "guard: usage"; exit 3
}
note="$(grep -m1 '^# note: ' "$0" | sed 's/^# note: //' || true)"
echo "guard: unknown $v"; exit 2
G
cat > "$fx/scripts/guard-selftest.sh" <<'G'
#!/usr/bin/env bash
here="$(cd "$(dirname "$0")" && pwd)"
g="$here/guard.sh"
fail=0
[ "$(bash "$g" red)" = "colour: red" ] || fail=1
[ "$(bash "$g" green)" = "colour: green" ] || fail=1
bash "$g" "" >/dev/null; [ $? -eq 3 ] || fail=1
bash "$g" help >/dev/null; [ $? -eq 3 ] || fail=1
bash "$g" x >/dev/null; [ $? -eq 2 ] || fail=1
exit $fail
G
printf '# fixture lib\nhelper() { :; }\n' > "$fx/scripts/helper-lib.sh"
printf '# fixture: a python beside guard.sh\nprint("guard")\n' > "$fx/scripts/guard.py"
printf '# fixture: a python lib named only by helper-lib.sh\n' > "$fx/scripts/other-lib.py"
printf '\n# other-lib.py is prepended by helper()\n: "$(dirname "$0")/other-lib.py"\n' >> "$fx/scripts/helper-lib.sh"
printf '#!/usr/bin/env bash\n# fixture: names helper-lib.sh in a comment only\necho ok\n' > "$fx/scripts/mention.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$fx/scripts/mention-selftest.sh"
printf '#!/usr/bin/env bash\n# fixture git hook\nexit 0\n' > "$fx/scripts/git-hooks/pre-x"
printf '#!/usr/bin/env bash\nexit 0\n' > "$fx/scripts/git-hooks/pre-x-selftest.sh"
printf 'not a hook: no shebang\n' > "$fx/scripts/git-hooks/README"
printf '#!/usr/bin/env bash\n# Install note: fixture hook\nexit 0\n' > "$fx/global/hooks/noted.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$fx/global/hooks/noted-selftest.sh"
printf '#!/usr/bin/env bash\n# fixture: no Install note, so not a hook\nexit 0\n' > "$fx/global/hooks/unnoted.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$fx/global/hooks/unnoted-selftest.sh"
printf '# fixture harness, never a target\n' > "$fx/scripts/selftest-lib.sh"
printf '# fixture harness, never a target\n' > "$fx/global/hooks/selftest-lib.sh"
sweep="$fx/scripts/mutation-sweep.sh"

# --- roster ----------------------------------------------------------------------
out="$(bash "$sweep" --list --max 1 2>&1)"; rc=$?
expect_rc "--list exits 2 (nothing graded)" 2 "$rc"
expect_in "$out" "script pairs with its selftest" "scripts/guard.sh ← scripts/guard-selftest.sh"
expect_in "$out" "git hook pairs with its selftest" "scripts/git-hooks/pre-x ← scripts/git-hooks/pre-x-selftest.sh"
expect_in "$out" "Install-note hook pairs with its selftest" "global/hooks/noted.sh ← global/hooks/noted-selftest.sh"
reject_in "$out" "a hook without the Install note is not a target" "global/hooks/unnoted.sh"
reject_in "$out" "a git-hooks file without a shebang is not a target" "git-hooks/README"
reject_in "$out" "selftest-lib.sh is never a target" "selftest-lib.sh ←"
expect_in "$out" "a .py beside a .sh takes that script's selftest" "scripts/guard.py ← scripts/guard-selftest.sh"
expect_in "$out" "a *-lib.sh reaches the selftests of the scripts that source it" "scripts/helper-lib.sh ← scripts/guard-selftest.sh"
expect_in "$out" "a *-lib.py reaches them through the lib that names it" "scripts/other-lib.py ← scripts/guard-selftest.sh"
reject_in "$out" "a comment mention of the lib is not sourcing it" "scripts/helper-lib.sh ← scripts/guard-selftest.sh scripts/mention-selftest.sh"
expect_in "$out" "the sweep names itself ungraded rather than hiding it" "UNGRADED scripts/mutation-sweep.sh"

# --- the generator on the fixture --------------------------------------------------
gen="$fx/scripts/mutation-sweep.py"
listed="$(python3 "$gen" list "$fx/scripts/guard.sh")"
expect_in "$listed" "drop-alt emits one mutant per alternative" "drop-alt:6:3	drop-alt	6	drops the alternative 'blue'"
expect_in "$listed" "flip-test flips -n" "flip-test:8:1	flip-test	8	flips '-n' to '-z'"
expect_in "$listed" "flip-test flips = inside a test" "flips '=' to '!=' in a test"
expect_in "$listed" "drop-line targets a reporting line" "drop-line:8:1	drop-line	8	drops the reporting line"
reject_in "$listed" "a comment line is never mutated" "	2	"
reject_in "$listed" "a shell pipe inside \"\$(...)\" is not an alternative" "drop-alt:11:"
[ "$(python3 "$gen" list "$fx/scripts/guard.sh" --max 3 | cut -f1)" = "$(python3 "$gen" list "$fx/scripts/guard.sh" --max 3 | cut -f1)" ] \
  || selftest_fail "--max must sample the same ids on two runs"
[ "$(python3 "$gen" list "$fx/scripts/guard.sh" --max 3 | wc -l | tr -d ' ')" = 3 ] || selftest_fail "--max 3 must list exactly 3 mutants"
applied="$(python3 "$gen" apply "$fx/scripts/guard.sh" drop-alt:6:3)"
expect_in "$applied" "apply writes the mutated line" "  red|green) echo \"colour: \$v\"; exit 0 ;;"
python3 "$gen" apply "$fx/scripts/guard.sh" no-such:1:1 >/dev/null 2>&1; expect_rc "apply of an unknown id exits 3" 3 $?
python3 "$gen" list "$fx/scripts/guard.sh" --bogus >/dev/null 2>&1; expect_rc "list with an unknown option exits 3" 3 $?
python3 "$gen" apply "$fx/scripts/guard.sh" >/dev/null 2>&1; expect_rc "apply without an id exits 3" 3 $?
python3 "$gen" frob "$fx/scripts/guard.sh" >/dev/null 2>&1; expect_rc "an unknown subcommand exits 3" 3 $?
python3 "$gen" list "$fx/scripts/none.sh" >/dev/null 2>&1; expect_rc "an unreadable file exits 4" 4 $?

# --- the generator's tables, one instance per alternative that changes what is emitted --
# Each fixture line carries one alternative of REPORT, TESTY, FLIPS, or a group shape;
# the expected column is the op (and, for a flip, its description) that line must emit,
# or `none` for a line the STRUCTURAL roster must leave alone despite a test on it.
gfx="$tmp/gen-fixture.sh"; : > "$gfx"; expected=""
gline() { printf '%s\n' "$1" >> "$gfx"; expected="$expected
$(wc -l < "$gfx" | tr -d ' ')	$2	$3"; }
gline 'say_fail "x"'                              drop-line "drops the reporting line"
gline 'selftest_fail "x"'                         drop-line "drops the reporting line"
gline 'selftest_skip "x"'                         drop-line "drops the reporting line"
gline 'hook_allow "x"'                            drop-line "drops the reporting line"
gline 'allow "x"'                                 drop-line "drops the reporting line"
gline 'crumb("x")'                                drop-line "drops the reporting line"
gline 'emit(hit)'                                 drop-line "drops the reporting line"
gline 'findings.append(x)'                        drop-line "drops the reporting line"
gline 'say_warn "x"'                              drop-line "drops the reporting line"
gline 'exit 3'                                    drop-line "drops the reporting line"
gline 'return 2'                                  drop-line "drops the reporting line"
gline 'sys.exit(4)'                               drop-line "drops the reporting line"
gline 'exit 0'                                    none      ""
gline 'if x -eq 1; then'                          flip-test "flips '-eq' to '-ne'"
gline 'while a -ne 0; do'                         flip-test "flips '-ne' to '-eq'"
gline 'ok = a is True'                            flip-test "flips 'is' to 'is not'"
gline '[ -z "$a" ] || x=1'                        flip-test "flips '-z' to '-n'"
gline 'if [ "$a" != "b" ]; then'                  flip-test "flips '!=' to '=='"
gline 'if a == b:'                                flip-test "flips '==' to '!='"
gline 'if a is None:'                             flip-test "flips 'is' to 'is not'"
gline 'if a is not True:'                         flip-test "flips 'is not' to 'is'"
gline 'x && y=1'                                  flip-test "flips '&&' to '||'"
gline 'echo "a is b" || y=1'                      flip-test "flips '||' to '&&'"
gline 'elif [ -n "$v" ]; then'                    none      ""
gline 'except ValueError as e:'                   none      ""
gline 'grep -qE "^(foo|bar)$" "$f"'               drop-alt  "drops the alternative 'foo'"
gline "grep -q 'a|b' \"\$f\""                       drop-alt  "drops the alternative 'a'"
gline 'PAT = r"\b(one|two)\b"'                    drop-alt  "drops the alternative 'one'"
gline 'case "$v" in'                              none      ""
gline '  x|y) echo "a is b" ;;'                   drop-alt  "drops the alternative 'x'"
gline 'esac'                                      none      ""
gline 'v="$(a | b || c)"'                         none      ""
glisted="$(python3 "$gen" list "$gfx")"
printf '%s\n' "$expected" | sed '/^$/d' | while IFS=$'\t' read -r n op what; do
  if [ "$op" = none ]; then
    printf '%s\n' "$glisted" | grep -q "^[a-z-]*:$n:" && echo "SELFTEST FAIL: generator line $n ($(sed -n "${n}p" "$gfx")) must emit nothing; got: $(printf '%s\n' "$glisted" | grep "^[a-z-]*:$n:")"
  else
    printf '%s\n' "$glisted" | grep -qF "$op:$n:1	$op	$n	$what" || echo "SELFTEST FAIL: generator line $n ($(sed -n "${n}p" "$gfx")) must emit '$op … $what'; got: $(printf '%s\n' "$glisted" | grep "^[a-z-]*:$n:" || echo nothing)"
  fi
done | tee "$tmp/gen-rows"
grep -q 'SELFTEST FAIL' "$tmp/gen-rows" && fail=1
[ "$(python3 "$gen" list "$gfx" | grep -c '^[a-z-]*:1:')" = 1 ] || selftest_fail "a reporting line with no test emits exactly one mutant"

# --- the planted hole: found, named, and a FAIL --------------------------------------
out="$(bash "$sweep" --path scripts/guard.sh --all 2>&1)"; rc=$?
expect_rc "a silent site is exit 1" 1 "$rc"
expect_in "$out" "the silent site is named by file:line, id, and what" "SILENT	scripts/guard.sh:6	drop-alt:6:3	drops the alternative 'blue'"
expect_in "$out" "the covered alternatives are CAUGHT" "CAUGHT	scripts/guard.sh:6	drop-alt:6:1	drops the alternative 'red'"
expect_in "$out" "a mutant that breaks parsing is INVALID" "INVALID	scripts/guard.sh:9	drop-line:9:1"
expect_in "$out" "the summary counts per target" "scripts/guard.sh: CAUGHT="
expect_in "$out" "the summary counts the silent one" "SILENT=1"
expect_in "$out" "the close names the count" "mutation-sweep: FAIL (1 silent)"
[ "$(printf '%s\n' "$out" | grep -c '^SILENT	')" = 1 ] || selftest_fail "exactly one silent site was planted; got: $(printf '%s\n' "$out" | grep '^SILENT	')"

# --- the hole closed: the same run is clean ---------------------------------------------
sed -i.bak 's|^\[ "$(bash "$g" green)" = "colour: green" \] \|\| fail=1$|&\n[ "$(bash "$g" blue)" = "colour: blue" ] \|\| fail=1|' "$fx/scripts/guard-selftest.sh"
grep -q 'blue' "$fx/scripts/guard-selftest.sh" || selftest_fail "fixture edit did not land (the blue row is missing)"
out="$(bash "$sweep" --path scripts/guard.sh --all 2>&1)"; rc=$?
expect_rc "with the hole closed the run exits 0" 0 "$rc"
expect_in "$out" "the clean close" "mutation-sweep: OK — every graded mutant was caught"
reject_in "$out" "no SILENT line remains" "SILENT	"

# --- --op, --id, --list on one path --------------------------------------------------------
out="$(bash "$sweep" --path scripts/guard.sh --all --op drop-alt 2>&1)"
reject_in "$out" "--op drop-alt runs no flip-test" "flip-test:"
expect_in "$out" "--op drop-alt runs drop-alt" "drop-alt:6:2"
out="$(bash "$sweep" --path scripts/guard.sh --id flip-test:8:1 2>&1)"; rc=$?
expect_rc "--id runs one mutant and it is caught" 0 "$rc"
[ "$(printf '%s\n' "$out" | grep -c '^CAUGHT	')" = 1 ] || selftest_fail "--id must run exactly one mutant: $out"
bash "$sweep" --path scripts/guard.sh --id no-such:1:1 >/dev/null 2>&1; expect_rc "--id of an unknown mutant exits 3" 3 $?

# --- a red baseline is UNGRADED, exit 2 ---------------------------------------------------
printf '#!/usr/bin/env bash\nexit 1\n' > "$fx/scripts/broken.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$fx/scripts/broken-selftest.sh"
out="$(bash "$sweep" --path scripts/guard.sh --path scripts/broken.sh --all 2>&1)"; rc=$?
expect_rc "an ungraded target with everything else caught is exit 2" 2 "$rc"
expect_in "$out" "the ungraded target is named with its selftest's status" "UNGRADED scripts/broken.sh — scripts/broken-selftest.sh exits 1 on the unmutated tree"
expect_in "$out" "the close says PARTIAL" "mutation-sweep: PARTIAL"
rm -f "$fx/scripts/broken.sh" "$fx/scripts/broken-selftest.sh"

# --- a hung selftest is HUNG, not SILENT ----------------------------------------------------
cat > "$fx/scripts/slow.sh" <<'G'
#!/usr/bin/env bash
[ -n "${1:-}" ] || exit 1
echo ok
G
hangtok="mutation-sweep-fixture-hang-$$-$RANDOM"   # unique per run: two sweeps grading this selftest in parallel must not see each other's grandchild
cat > "$fx/scripts/slow-selftest.sh" <<G
#!/usr/bin/env bash
here="\$(cd "\$(dirname "\$0")" && pwd)"
bash "\$here/slow.sh" "" >/dev/null && bash -c 'exec -a $hangtok sleep 30'
[ "\$(bash "\$here/slow.sh" x)" = ok ] || exit 1
exit 0
G
out="$(bash "$sweep" --path scripts/slow.sh --id flip-test:2:1 --timeout 1 2>&1)"; rc=$?
expect_in "$out" "the flipped guard makes the selftest sleep past --timeout: HUNG" "HUNG	scripts/slow.sh:2	flip-test:2:1"
expect_rc "a target graded no mutant is exit 2" 2 "$rc"
reject_in "$out" "a hung mutant is not SILENT" "SILENT	"
pgrep -f "$hangtok" >/dev/null && { selftest_fail "the timeout must kill the selftest's whole process group, not the shell alone — the grandchild is still running"; pkill -f "$hangtok"; }

# --- usage errors --------------------------------------------------------------------------
bash "$sweep" --path scripts/nope.sh >/dev/null 2>&1; expect_rc "--path outside the roster exits 3" 3 $?
bash "$sweep" --id x:1:1 >/dev/null 2>&1; expect_rc "--id without --path exits 3" 3 $?
bash "$sweep" --bogus >/dev/null 2>&1; expect_rc "an unknown option exits 3" 3 $?
bash "$sweep" --op nope >/dev/null 2>&1; expect_rc "an unknown operator exits 3" 3 $?
bash "$sweep" --help >/dev/null 2>&1; expect_rc "--help exits 0" 0 $?
bash "$sweep" --max x >/dev/null 2>&1; expect_rc "--max with no number exits 3" 3 $?
bash "$sweep" --jobs 0 >/dev/null 2>&1; expect_rc "--jobs 0 exits 3" 3 $?
mkdir -p "$tmp/nogen/scripts"; cp "$sweep" "$tmp/nogen/scripts/"
out="$(bash "$tmp/nogen/scripts/mutation-sweep.sh" --list 2>&1)"; rc=$?
expect_rc "a missing generator is exit 4, nothing ran" 4 "$rc"
expect_in "$out" "the missing generator is named" "mutation-sweep.py is missing beside this script"

# --- the mutation table: each row removes one guard from a copy of the sweep and must change
# a verdict the rows above read. The fixture is reopened (blue uncovered) for the first row.
mv "$fx/scripts/guard-selftest.sh.bak" "$fx/scripts/guard-selftest.sh"
mutation() {  # <name> <file> <perl expression> <what the edit does> <check: a command that exits 0 when the mutation was NOTICED>
  local name=$1 file=$2 expr=$3 what=$4 check=$5 mut
  mut="$tmp/mut-$name"   # on its own line: `local a=$1 b=$a` expands every word before assigning any
  rm -rf "$mut"; cp -R "$fx" "$mut"
  if ! perl -0pi -e "$expr" "$mut/scripts/$file" || cmp -s "$fx/scripts/$file" "$mut/scripts/$file"; then
    selftest_skip "the edit for mutation '$name' matched nothing in scripts/$file — reword it rather than reading the row as graded"; return 0
  fi
  MUT="$mut" bash -c "$check" >/dev/null 2>&1 || selftest_fail "mutation '$name' ($what) changed no verdict — the guard it removes is not what the rows above read"
}
mutation "never-silent" mutation-sweep.sh 's/status=SILENT ;;/status=CAUGHT ;;/' \
  "a mutant no selftest catches is reported CAUGHT" \
  'out="$(bash "$MUT/scripts/mutation-sweep.sh" --path scripts/guard.sh --id drop-alt:6:3 2>&1)"; [ $? -ne 1 ] && ! grep -q "^SILENT	" <<<"$out"'
mutation "no-drop-line" mutation-sweep.py 's/\("drop-line", drop_line_mutants\)/("drop-line", lambda line: [])/' \
  "the drop-line operator emits nothing" \
  '! python3 "$MUT/scripts/mutation-sweep.py" list "$MUT/scripts/guard.sh" | grep -q "^drop-line:"'
mutation "parses-anything" mutation-sweep.sh 's/\n    \*\) bash -n "\$1" >\/dev\/null 2>&1 ;;\n/\n    *) true ;;\n/' \
  "an unparseable mutant is run instead of discarded" \
  'out="$(bash "$MUT/scripts/mutation-sweep.sh" --path scripts/guard.sh --id drop-line:9:1 2>&1)"; ! grep -q "^INVALID	" <<<"$out"'

selftest_close "mutation-sweep self-test clean — the roster derives every pairing, the generator emits each operator deterministically, the planted hole is named and closes, red baselines and hung and unparseable mutants are told from silent ones, usage errors exit 3, and every mutation in the table changed a verdict." \
  "mutation-sweep self-test PARTIAL — a row was skipped; read the SKIP lines above"
