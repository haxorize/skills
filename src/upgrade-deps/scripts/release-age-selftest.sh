#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/upgrade-deps/scripts/release-age.py computes step 1's floor and
# step 2's registry lookups the way src/upgrade-deps/SKILL.md states them,
# against repo fixtures written at run time and a fake `npm` and `pnpm` on
# PATH that answer from files. No call reaches a registry.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
# Run it after changing the script.
#
# What is graded:
#   floor — pnpm 11 with no config enforces 1440 minutes (1 day) and the
#     7-day default wins; a workspace minimumReleaseAge of 20160 (14 days)
#     wins over a declared 10; an excluded package (exact and `@scope/*`
#     glob, block lists indented or not, inline lists) loses the enforced
#     operand, a block list ends at the next key, and `*` stays inside one
#     path segment (minimatch), so it never excludes `@scope/x`; pnpm 10
#     reads `.npmrc` minimum-release-age in minutes and pnpm 11 ignores it;
#     npm reads min-release-age in days and its exclude list; a declared
#     `Minimum release age:` of 30 wins and is read only under `## Registry`;
#     the pnpm major from `packageManager`, else `pnpm --version`, else the
#     row reads unknown and the exit is 2; a tie goes to the earlier of
#     default, declared, enforced; a non-numeric .npmrc value or CLAUDE.md
#     declared value exits 1.
#   lookup — the publisher of each version and same/changed, `unknown` when
#     one is absent or its lookup failed (exit 2); attestation
#     present, absent (nothing printed, exit 0) and lookup-failed (non-zero
#     exit) kept apart, exit 2 on a failure; an `npm view` timeout is
#     lookup-failed, exit 2; a target missing from `time` is absent, exit 2;
#     the target's age against --now, a date-only --now read as UTC;
#     clears_floor; the retarget as the newest release above FROM, at or below
#     TO, older than the floor, skipping prereleases, `none` when none clears.
#   usage — no subcommand, an unknown one, a missing package, a bad version:
#     exit 3; lookup with no npm on PATH: exit 4.
# The mutation table swaps the minutes-to-days divisor, drops the exclude
# match, flips the max to a min, drops the pnpm 11 default, lets pnpm 11 read
# .npmrc, reads absent attestations as lookup-failed, drops the prerelease
# skip, flips the floor comparison, and breaks each case the list above adds
# (unindented items, the list's end, `*` across `/`, the tie order, the
# CLAUDE.md parse error, same/unknown/failed publishers, the absent target's
# exit, the naive --now, the uncaught timeout); each mutant must turn its row
# red.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root" || exit 4
# shellcheck source=SCRIPTDIR/../../../scripts/selftest-lib.sh
. scripts/selftest-lib.sh
script="src/upgrade-deps/scripts/release-age.py"
[ -f "$script" ] || { selftest_fail "$script is missing"; exit 1; }
command -v python3 >/dev/null 2>&1 || { selftest_skip "python3 is not on PATH — the script could not run"; selftest_close "" "release-age self-test ran nothing: python3 is missing"; }

tmp="$(selftest_tmpdir)" || selftest_no_tmpdir release-age-selftest.sh
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/npm"
cat > "$tmp/bin/npm" <<'EOF'
#!/usr/bin/env bash
# fake npm: `npm view SPEC FIELD --json` answers from $FAKE_NPM/SPEC.FIELD;
# SPEC.FIELD.fail exits 1; no file prints nothing and exits 0.
[ "$1" = "--version" ] && { echo 10.0.0; exit 0; }
[ "$1" = view ] || exit 9
[ -n "${FAKE_NPM_SLEEP:-}" ] && sleep "$FAKE_NPM_SLEEP"
f="$FAKE_NPM/$2.$3"
[ -e "$f.fail" ] && exit 1
[ -f "$f" ] && cat "$f"
exit 0
EOF
cat > "$tmp/bin/pnpm" <<'EOF'
#!/usr/bin/env bash
[ -n "${FAKE_PNPM_VERSION:-}" ] || exit 127
echo "$FAKE_PNPM_VERSION"
EOF
chmod +x "$tmp/bin/npm" "$tmp/bin/pnpm"
export FAKE_NPM="$tmp/npm" PATH="$tmp/bin:$PATH"

# mkrepo <name> <packageManager or ""> — a repo dir with package.json.
mkrepo() {
  mkdir -p "$tmp/$1"
  if [ -n "$2" ]; then printf '{"name":"x","packageManager":"%s"}\n' "$2" > "$tmp/$1/package.json"
  else printf '{"name":"x"}\n' > "$tmp/$1/package.json"; fi
}
mkrepo p11 pnpm@11.1.0
mkrepo p11ws pnpm@11.1.0
printf 'packages:\n  - "."\nminimumReleaseAge: 20160  # two weeks\nminimumReleaseAgeExclude:\n  - left-pad\n  - "@corp/*"\n' > "$tmp/p11ws/pnpm-workspace.yaml"
printf '# x\n\n## Registry\n\n- Minimum release age: 10\n\n## Other\n' > "$tmp/p11ws/CLAUDE.md"
mkrepo p11inline pnpm@11.0.0
printf 'minimumReleaseAge: 4320\nminimumReleaseAgeExclude: [a, "b"]\n' > "$tmp/p11inline/pnpm-workspace.yaml"
mkrepo p11rc pnpm@11.2.0
printf 'minimum-release-age=43200\n' > "$tmp/p11rc/.npmrc"
mkrepo p10 pnpm@10.18.0
printf 'minimum-release-age=14400\nminimum-release-age-exclude=react\n' > "$tmp/p10/.npmrc"
mkrepo pver ""
touch "$tmp/pver/pnpm-lock.yaml"
mkrepo npmrc ""
touch "$tmp/npmrc/package-lock.json"
printf 'registry=https://example.invalid/\nmin-release-age=3\nmin-release-age-exclude[]=lodash\n' > "$tmp/npmrc/.npmrc"
printf '# x\n\nMinimum release age: 99\n\n## Registry\n\nMinimum release age: 30 days\n' > "$tmp/npmrc/CLAUDE.md"
mkrepo npmbad ""
printf 'min-release-age=soon\n' > "$tmp/npmbad/.npmrc"
mkrepo p11dash pnpm@11.1.0
printf 'minimumReleaseAge: 20160\nminimumReleaseAgeExclude:\n- left-pad\n- "@corp/*"\nonlyBuiltDependencies:\n- esbuild\n' > "$tmp/p11dash/pnpm-workspace.yaml"
mkrepo p11star pnpm@11.1.0
printf 'minimumReleaseAge: 20160\nminimumReleaseAgeExclude: ["*"]\n' > "$tmp/p11star/pnpm-workspace.yaml"
mkrepo tie ""
printf 'min-release-age=14\n' > "$tmp/tie/.npmrc"
printf '## Registry\n\n- Minimum release age: 14\n' > "$tmp/tie/CLAUDE.md"
mkrepo tie7 ""
printf '## Registry\n\n- Minimum release age: 7\n' > "$tmp/tie7/CLAUDE.md"
mkrepo claudebad ""
printf '## Registry\n\n- Minimum release age: two weeks\n' > "$tmp/claudebad/CLAUDE.md"

floor() { python3 "$script" floor --repo "$tmp/$1" "${@:2}" 2>&1; }

row_p11() { out=$(floor p11 react); expect_row "$out" "pnpm 11 with no config: enforced 1 day, the default wins" "react	pnpm	1	pnpm 11 default	none	7	7	default"; }
row_p11ws() {
  out=$(floor p11ws react left-pad @corp/ui)
  expect_row "$out" "a workspace 20160 minutes is 14 days and wins over a declared 10" "react	pnpm	14	pnpm-workspace.yaml minimumReleaseAge	10	7	14	enforced"
  expect_row "$out" "an exact exclude drops the enforced operand; the declared 10 wins" "left-pad	pnpm	none	excluded	10	7	10	declared"
  expect_row "$out" "a glob exclude drops the enforced operand" "@corp/ui	pnpm	none	excluded	10	7	10	declared"
}
row_inline() { out=$(floor p11inline b c); expect_row "$out" "an inline exclude list" "b	pnpm	none	excluded	none	7	7	default"; expect_row "$out" "4320 minutes is 3 days, under the default" "c	pnpm	3	pnpm-workspace.yaml minimumReleaseAge	none	7	7	default"; }
row_p11rc() { out=$(floor p11rc x); expect_row "$out" "pnpm 11 ignores .npmrc and keeps its 1-day default" "x	pnpm	1	pnpm 11 default	none	7	7	default"; }
row_p10() { out=$(floor p10 vue react); expect_row "$out" "pnpm 10 reads .npmrc minutes" "vue	pnpm	10	.npmrc minimum-release-age	none	7	10	enforced"; expect_row "$out" "pnpm 10's .npmrc exclude" "react	pnpm	none	excluded	none	7	7	default"; }
row_npm() { out=$(floor npmrc a lodash); expect_row "$out" "npm days; the declared 30 under ## Registry wins, the 99 above it is not read" "a	npm	3	.npmrc min-release-age	30	7	30	declared"; expect_row "$out" "npm's exclude[] form" "lodash	npm	none	excluded	30	7	30	declared"; }
row_dash() {
  out=$(floor p11dash left-pad @corp/ui esbuild)
  expect_row "$out" "an unindented block item is an exclude" "left-pad	pnpm	none	excluded	none	7	7	default"
  expect_row "$out" "an unindented glob item is an exclude" "@corp/ui	pnpm	none	excluded	none	7	7	default"
  expect_row "$out" "the list ends at the next key; a later key's items are not excludes" "esbuild	pnpm	14	pnpm-workspace.yaml minimumReleaseAge	none	7	14	enforced"
}
row_star() {
  out=$(floor p11star plain @scope/x)
  expect_row "$out" "a bare * excludes an unscoped package" "plain	pnpm	none	excluded	none	7	7	default"
  expect_row "$out" "a bare * does not cross / into a scoped package" "@scope/x	pnpm	14	pnpm-workspace.yaml minimumReleaseAge	none	7	14	enforced"
}
row_tie() {
  out=$(floor tie a); expect_row "$out" "declared ties enforced at 14: declared wins" "a	npm	14	.npmrc min-release-age	14	7	14	declared"
  out=$(floor tie7 a); expect_row "$out" "declared ties the default at 7: default wins" "a	npm	none	none	7	7	7	default"
}
row_claudebad() {
  out=$(floor claudebad z); rc=$?
  expect_rc "a non-numeric CLAUDE.md Minimum release age" 1 "$rc"
  expect_in "$out" "the bad declared value is named" "'two weeks' is not a number of days"
}
row_p11; row_p11ws; row_inline; row_p11rc; row_p10; row_npm; row_dash; row_star; row_tie; row_claudebad

out=$(FAKE_PNPM_VERSION=11.4.0 floor pver z); rc=$?
expect_rc "pnpm major from pnpm --version" 0 "$rc"
expect_row "$out" "pnpm --version 11 enforces the default" "z	pnpm	1	pnpm 11 default	none	7	7	default"
out=$(floor pver z); rc=$?
expect_rc "no pnpm major anywhere is not a verdict" 2 "$rc"
expect_row "$out" "an unknown pnpm major prints unknown" "z	pnpm	unknown	unknown	none	7	unknown	unknown"
out=$(floor npmbad z); rc=$?
expect_rc "a non-numeric min-release-age" 1 "$rc"
expect_in "$out" "the bad value is named, behind a literal lead" "config value is not a number: .npmrc min-release-age = 'soon'"
reject_in "$out" "a bad value printed a traceback" "Traceback"

# lookup fixtures: pkg 1.0.0 -> 2.1.0; 2.1.0 is 3 days old at --now.
printf '{"name":"alice","email":"a@x"}\n' > "$tmp/npm/pkg@1.0.0._npmUser"
printf '{"name":"mallory","email":"m@x"}\n' > "$tmp/npm/pkg@2.1.0._npmUser"
printf '{"url":"https://x","provenance":{}}\n' > "$tmp/npm/pkg@1.0.0.dist.attestations"
cat > "$tmp/npm/pkg.time" <<'EOF'
{"created":"2025-01-01T00:00:00Z","modified":"2026-10-15T00:00:00Z",
 "1.0.0":"2025-01-01T00:00:00Z","2.0.0":"2026-09-01T00:00:00Z",
 "2.0.1":"2026-10-01T00:00:00Z","2.1.0-rc.1":"2026-09-20T00:00:00Z",
 "2.1.0":"2026-10-15T00:00:00Z","3.0.0":"2026-01-01T00:00:00Z"}
EOF
lookup() { python3 "$script" lookup --now 2026-10-18T00:00:00Z "$@" 2>&1; }

row_lookup() {
  out=$(lookup --floor 7 pkg 1.0.0 2.1.0); rc=$?
  expect_rc "a full lookup" 0 "$rc"
  expect_row "$out" "from publisher" "from_publisher=alice"
  expect_row "$out" "to publisher" "to_publisher=mallory"
  expect_row "$out" "a changed publisher" "publisher=changed"
  expect_row "$out" "an attested from version" "from_attestation=present"
  expect_row "$out" "npm printing nothing is absent" "to_attestation=absent"
  expect_row "$out" "the target's age" "to_age_days=3"
  expect_row "$out" "3 days does not clear 7" "clears_floor=no"
  expect_row "$out" "the retarget is the newest cleared release in range, past the prerelease" "retarget=2.0.1"
}
row_clears() { out=$(lookup --floor 2 pkg 1.0.0 2.1.0); expect_row "$out" "3 days clears 2" "clears_floor=yes"; expect_row "$out" "the target itself is the retarget when it clears" "retarget=2.1.0"; }
row_none() { out=$(lookup --floor 60 pkg 2.0.0 2.1.0); expect_row "$out" "nothing above FROM clears 60 days" "retarget=none"; }
printf '{"name":"alice","email":"a@x"}\n' > "$tmp/npm/pkg@2.0.1._npmUser"
row_same() { out=$(lookup pkg 1.0.0 2.0.1); expect_row "$out" "one account on both versions" "publisher=same"; }
row_pub_unknown() {
  out=$(lookup pkg 1.0.0 2.0.0); rc=$?
  expect_rc "an absent publisher is still a read value" 0 "$rc"
  expect_row "$out" "no _npmUser printed is absent" "to_publisher=absent"
  expect_row "$out" "an absent publisher makes the comparison unknown" "publisher=unknown"
}
row_pub_failed() {
  touch "$tmp/npm/pkg@2.1.0._npmUser.fail"
  out=$(lookup pkg 1.0.0 2.1.0); rc=$?
  rm "$tmp/npm/pkg@2.1.0._npmUser.fail"
  expect_rc "a failed publisher lookup is not a verdict" 2 "$rc"
  expect_row "$out" "a failed _npmUser lookup is lookup-failed" "to_publisher=lookup-failed"
  expect_row "$out" "a failed publisher lookup makes the comparison unknown" "publisher=unknown"
}
row_absent() {
  out=$(lookup pkg 1.0.0 2.2.0); rc=$?
  expect_rc "a target missing from time is not a verdict" 2 "$rc"
  expect_row "$out" "a target missing from time is absent" "to_published=absent"
}
row_naive_now() {
  out=$(python3 "$script" lookup --now 2026-10-18 pkg 1.0.0 2.1.0 2>&1); rc=$?
  expect_rc "a date-only --now" 0 "$rc"
  expect_row "$out" "a date-only --now is midnight UTC" "to_age_days=3"
}
# The 120-second timeout is cut to 0.2 on a copy, so a sleeping npm trips it fast.
row_timeout() {
  sed 's/timeout=120/timeout=0.2/' "$script" > "$tmp/short.py"
  out=$(FAKE_NPM_SLEEP=1 python3 "$tmp/short.py" lookup pkg 1.0.0 2.1.0 2>&1); rc=$?
  expect_rc "an npm view timeout is not a verdict" 2 "$rc"
  expect_row "$out" "an npm view timeout is lookup-failed" "to_published=lookup-failed"
  reject_in "$out" "a timeout crashed the script" "crashed"
}
row_lookup; row_clears; row_none; row_same; row_pub_unknown; row_pub_failed; row_absent; row_naive_now; row_timeout

touch "$tmp/npm/pkg@2.1.0.dist.attestations.fail"
out=$(lookup pkg 1.0.0 2.1.0); rc=$?
expect_rc "a failed lookup is not a verdict" 2 "$rc"
expect_row "$out" "a non-zero npm exit is lookup-failed, never absent" "to_attestation=lookup-failed"
rm "$tmp/npm/pkg@2.1.0.dist.attestations.fail"

python3 "$script" >/dev/null 2>&1; expect_rc "no subcommand" 3 $?
python3 "$script" bogus >/dev/null 2>&1; expect_rc "an unknown subcommand" 3 $?
python3 "$script" floor --repo "$tmp/p11" >/dev/null 2>&1; expect_rc "floor with no package" 3 $?
python3 "$script" floor --repo "$tmp/nope" x >/dev/null 2>&1; expect_rc "a --repo that is not a directory" 3 $?
lookup pkg 1.0 2.1.0 >/dev/null; expect_rc "a version that is not x.y.z" 3 $?
# The interpreter's own path under an empty PATH, so no npm on the machine can answer.
py=$(python3 -c 'import sys; print(sys.executable)')
mkdir -p "$tmp/empty"
PATH="$tmp/empty" "$py" "$script" lookup pkg 1.0.0 2.1.0 >/dev/null 2>&1
expect_rc "lookup with no npm on PATH" 4 $?
python3 "$script" --help >/dev/null 2>&1; expect_rc "--help" 0 $?

# Mutation table: each mutant must turn its row red.
m="$tmp/mutant.py"
mutant() { # <label> <from> <to> <row>
  selftest_mutate "$script" "$m" "$2" "$3" || return 0
  selftest_expect_killed --mutant script "$m" "$1" "$4"
}
mutant "minutes-to-days divisor" "minutes / 1440" "minutes / 60" row_p11ws
mutant "exclude match dropped" "if any(glob_match(pkg, pat) for pat in excludes):" "if False:" row_p11ws
mutant "max read as min" "floor = max(" "floor = min(" row_p11ws
mutant "pnpm 11 default dropped" "minutes, source = PNPM_DEFAULT_MINUTES" "minutes, source = None" row_p11
mutant "pnpm 11 reads .npmrc" "elif major is not None and major < 11:" "elif major is not None:" row_p11rc
mutant "absent read as lookup-failed" "return None, True" "return None, False" row_lookup
mutant "prerelease skip dropped" 'r"^(\d+)\.(\d+)\.(\d+)$"' 'r"^(\d+)\.(\d+)\.(\d+)"' row_lookup
mutant "floor comparison flipped" "'yes' if age >= floor" "'yes' if age < floor" row_clears
mutant "unindented list item dropped" 'r"^\s*-\s+(.+)$"' 'r"^\s+-\s+(.+)$"' row_dash
mutant "block list never ends" "            in_list = False" "            pass" row_dash
mutant "* crosses /" '"\\*": "[^/]*"' '"\\*": ".*"' row_star
mutant "tie goes to enforced" '[("default", float(DEFAULT_DAYS)), ("declared", declared), ("enforced", e)]' '[("enforced", e), ("declared", declared), ("default", float(DEFAULT_DAYS))]' row_tie
mutant "non-numeric declared ignored" 'raise ConfigError(f"CLAUDE.md ## Registry' 'return None  # (f"CLAUDE.md ## Registry' row_claudebad
mutant "publisher always changed" "'same' if names['from'] == names['to']" "'changed' if names['from'] == names['to']" row_same
mutant "unknown publisher read as same" 'print("publisher=unknown")' 'print("publisher=same")' row_pub_unknown
mutant "failed publisher read as absent" "('lookup-failed' if not ok else 'absent')" "('absent' if not ok else 'absent')" row_pub_failed
mutant "absent target exits 0" $'print("to_published=absent")\n        return 2' $'print("to_published=absent")\n        return 0' row_absent
mutant "naive --now not read as UTC" "return t if t.tzinfo is not None else t.replace(tzinfo=datetime.timezone.utc)" "return t" row_naive_now
mutant "npm view timeout uncaught" $'except subprocess.TimeoutExpired:\n        return None, False' $'except ZeroDivisionError:\n        return None, False' row_timeout

selftest_close \
  "release-age self-test clean — the floor's three operands and its winner per package across pnpm 11, pnpm 10 and npm, both exclude-list forms with minimatch's segment-bound *, the declared floor under ## Registry only, the tie order, the pnpm major's two sources and the unknown case; the lookup's publishers same, changed and unknown, attestation absent vs failed, a timeout, an absent target, age against a naive or zoned --now, floor, and retarget; the usage exits; every mutant killed." \
  "release-age self-test clean on what it could reach; see the SKIP line above for what was not exercised."
