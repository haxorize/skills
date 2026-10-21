#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/triage-cvits/scripts/classify-cvit-findings.py places each finding in the
# bucket its cascade claims, with the confirmed flag its inputs justify, against
# classify-cvit-findings-fixtures/ — one synthetic finding per branch of the three-tier
# cascade (base-image layer -> two-tree membership -> version compare). The fixture
# freezes the classification contract: a later edit that re-routes a branch, drops the
# two-tree differential, or asserts what it should flag reds here rather than drifting
# silently against the live Stories it classifies.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk, ADR-0104's
# 2026-10-10 amendment); pre-commit runs it when the script or a fixture is staged, and
# post-merge runs it on every merge. mutation-sweep does not reach it, so mutation checks
# are hand-run. Run it after changing the script.
#
# What is graded. Every row of export.csv is pinned as one whole line
# `<cve> <bucket> <confirmed> <matched_package> <sub_tag>` (fixture CVE id names the
# expected bucket), so a flipped bucket, a flipped confirmed flag, a wrong matched name,
# or a wrong sub-tag each red:
#   A x4, one per origin sub-tag: os-package (apk), tool-bundle (npm's own CLI under
#     /usr/local/lib/node_modules/npm/), runtime (the `node` binary, no PURL — flagged,
#     since a no-PURL finding with no app path could be an app component; ADR-0104's
#     2026-10-10 amendment), global-module (corepack under the global prefix — flagged,
#     since an app Dockerfile's `npm install -g` could have put it there).
#   B x2 (controlled set, incl. the multi-name cell matched on `libcrypto3`); C; D.
#   E x5: at/above the fix with the tree ahead of the scan, plus CVE-0020, where the
#     scanned version equals the tree's — flagged, since a rescan reports it again.
#   F x13: below the fix; the cssesc/css NAME-SUBSTRING trap (exact name match); the
#     pre-release, no-own-line, zero-major, no-published-fix, unparseable-install and
#     minor-keyed (release-line scheme ambiguous) flags; the nested copy judged by its
#     own row, not the hoisted copy (both ADR-0104's 2026-10-10 amendment); the
#     capitalised `Fixed in`; the hostile multi-name cell whose matched_package is the
#     tree key alone, never the raw cell.
#   null x2: pypi (no resolver built) and a no-PURL app path (unresolvable, never read
#     as a base runtime).
# The rollup is pinned per bucket (count, pct, confirmed, unconfirmed) plus total,
# needs_checkout, unresolved and unconfirmed_total, and unresolved_ecosystems exactly.
# ecosystems.csv pins every PURL_ECOSYSTEM entry, an unknown prefix, deb/rpm, the second
# npm bundle path, and each app-dependency marker with no PURL. The degraded run
# (empty-trees.json) and an empty npm tree pair (a failed `npm ls` reduced to {}) flag every app dep "?". Error paths:
# each required column renamed, an empty CSV, malformed and mistyped resolved-tree JSON
# (rejected, never coerced), a BOM before the first column, a non-UTF-8 byte, and the usage path (--help
# exits 0; a usage error exits 3; a missing file exits 3 with no traceback). Unit checks
# pin parse_dotted_numeric (a suffixed version parses unclean) and the two release-line keys.
#
# NOT covered, so a clean run here is not a claim about them: the crash path (exit 4); the
# UTF-8 transcode the skill body runs before this script; the npm ls reduction, the
# Dockerfile read, and the to-story and to-tasks writes the skill body owns.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="src/triage-cvits/scripts/classify-cvit-findings.py"
fx="src/triage-cvits/scripts/classify-cvit-findings-fixtures"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }
[ -d "$fx" ] || { selftest_fail "fixture $fx is missing"; exit 1; }
command -v python3 >/dev/null 2>&1 || { selftest_skip "python3 is not on PATH — the script could not run"; selftest_close "" "classify-cvit-findings self-test ran nothing: python3 is missing"; }

# One line per finding: `<cve> <bucket> <confirmed> <matched_package> <sub_tag>`.
summarize() {
  printf '%s\n' "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f['cve'], f['bucket'], f['confirmed'], f['matched_package'], f['sub_tag']) for f in d['findings']]"
}
# One line per rollup entry, then total and unresolved_ecosystems.
summarize_rollup() {
  printf '%s\n' "$1" | python3 -c "
import sys,json; d=json.load(sys.stdin); r=d['rollup']
for b in 'ABCDEF': e=r[b]; print(b, e['count'], e['pct'], e['confirmed'], e['unconfirmed'])
print('A sub_tags', json.dumps(r['A']['sub_tags'], sort_keys=True))
for k in ('needs_checkout','unresolved','unconfirmed_total'): print(k, r[k]['count'])
print('total', d['total']); print('unresolved_ecosystems', ' '.join(d['unresolved_ecosystems']))"
}
reason_of() {
  printf '%s\n' "$1" | CVE="$2" python3 -c "import os,sys,json; d=json.load(sys.stdin); print(next((f['bucket_reason'] for f in d['findings'] if f['cve']==os.environ['CVE']), '<missing>'))"
}
expect_rows() {  # <haystack> <label> <row>...
  local hay="$1" label="$2"; shift 2
  local row
  for row in "$@"; do expect_row "$hay" "$label" "$row"; done
}

# --- Confirmed run: resolver trees + controlled set + Dockerfile read ---
out=$(python3 "$script" "$fx/export.csv" "$fx/resolver.json"); expect_rc "a confirmed run over the fixture" 0 $?
rows=$(summarize "$out")
expect_rows "$rows" "confirmed run" \
  "CVE-0001-A-APK A True None os-package" \
  "CVE-0002-A-TOOLBUNDLE A True None tool-bundle" \
  "CVE-0003-A-RUNTIME A False None runtime" \
  "CVE-0004-B-CONTROLLED B True None None" \
  "CVE-0005-C-NEITHER C True None None" \
  "CVE-0006-D-DEVONLY D True eslint None" \
  "CVE-0007-E-ATFIX E True express None" \
  "CVE-0008-F-BELOWFIX F True axios None" \
  "CVE-0009-UNRESOLVED-PYPI None False None None" \
  "CVE-0010-F-MULTINAME F True cssesc None" \
  "CVE-0011-B-MULTINAME B True None None" \
  "CVE-0012-F-PRERELEASE F False prerelease-pkg None" \
  "CVE-0013-F-MULTILINE F True undici None" \
  "CVE-0014-F-NOMATCHLINE F False stale-fix-pkg None" \
  "CVE-0015-E-SAMELINE-MULTIPATCH E True same-line-multipatch None" \
  "CVE-0016-E-LOOP-ORDER E True loop-order-check-pkg None" \
  "CVE-0017-F-MULTILINE-3WAY F True fast-uri None" \
  "CVE-0018-F-ZEROMAJOR-NOMATCHLINE F False zero-major-pkg None" \
  "CVE-0019-E-ZEROMAJOR-SAMELINE E True zero-major-sameline None" \
  "CVE-0020-E-SCANNED-EQUALS-TREE E False scanned-eq-pkg None" \
  "CVE-0021-A-GLOBALMODULE A False None global-module" \
  "CVE-0022-F-NESTED F True semver None" \
  "CVE-0023-F-NOFIX F False nofix-pkg None" \
  "CVE-0024-F-CAPFIX F True capfix-pkg None" \
  "CVE-0025-F-UNPARSEABLE-INSTALL F False vpkg None" \
  "CVE-0026-UNRESOLVED-NOPURL-APP None False None None" \
  "CVE-0027-F-MINORKEYED F False minor-keyed-pkg None" \
  "CVE-0028-F-HOSTILE-CELL F True axios None"
# Why the traps above are traps:
# - CVE-0007: scanned 4.18.0, tree 5.0.0, "fixed in 4.19.2" — the installed version must
#   come from the tree for a top-level path (installed-from-CSV would say F).
# - CVE-0010: the tree carries `css` (a substring of `cssesc`) at 2.5.0, above the 2.0.0
#   fix; substring matching would borrow it and flip F -> E. Keep the decoy so.
# - CVE-0013 undici 8.9.0 vs "8.10.2, 7.29.1": the older line's fix must not clear an install
#   below its own line's. CVE-0017 is the three-line form.
# - CVE-0015 (4.19.2/4.19.3, one line) and CVE-0016 ("4.19.5, 4.19.3": only the SECOND
#   entry clears) guard the over-flag and the stop-after-first-entry regressions.
# - CVE-0018/0019: release_line keys a 0.x version on (0, minor); keyed on the major,
#   0.4.1 would clear the 0.5.0 install (F -> E).
# - CVE-0022: semver 5.7.1 nested under old/, fixed in 5.7.2, while the flattened tree
#   says 7.6.0 — the nested copy is judged by its own row (F), not the hoisted copy (E).
# - CVE-0027: 3.11.2 vs "3.11.9, 3.10.1" — E under the major key, below under
#   (major, minor); the disagreement flags rather than asserting E.
expect_in "$(reason_of "$out" CVE-0012-F-PRERELEASE)" "a pre-release install names the suffix" "unorderable version suffix"
expect_in "$(reason_of "$out" CVE-0014-F-NOMATCHLINE)" "a multi-line Fix Status with no own-line entry says so" "no fixed-version entry for its own release line"
expect_in "$(reason_of "$out" CVE-0020-E-SCANNED-EQUALS-TREE)" "an at-fix version equal to the scanned one says a rescan will not clear it" "a rescan reports it again"
expect_in "$(reason_of "$out" CVE-0021-A-GLOBALMODULE)" "a global module names the npm install -g check" "npm install -g"
expect_in "$(reason_of "$out" CVE-0023-F-NOFIX)" "an open Fix Status is not called upgrade available" "no published fix"
reject_in "$(reason_of "$out" CVE-0023-F-NOFIX)" "an open Fix Status is not called upgrade available" "upgrade available"
expect_in "$(reason_of "$out" CVE-0025-F-UNPARSEABLE-INSTALL)" "an unparseable install is named" "unparseable installed version"
expect_in "$(reason_of "$out" CVE-0026-UNRESOLVED-NOPURL-APP)" "a no-PURL app path says so, not an empty ecosystem name" "with no PURL"
expect_in "$(reason_of "$out" CVE-0027-F-MINORKEYED)" "a minor-keyed Fix Status names the ambiguity" "release-line scheme ambiguous"
expect_in "$out" "the capitalised Fixed in is parsed" '"1.9.0"'
expect_in "$out" "the raw Packages cell still rides in package" '"package": "axios,$(touch pwned)"'

expect_rows "$(summarize_rollup "$out")" "confirmed-run rollup" \
  "A 4 14.3 2 2" "B 2 7.1 2 0" "C 1 3.6 1 0" "D 1 3.6 1 0" "E 5 17.9 4 1" "F 13 46.4 7 6" \
  'A sub_tags {"global-module": 1, "os-package": 1, "runtime": 1, "tool-bundle": 1}' \
  "needs_checkout 0" "unresolved 2" "unconfirmed_total 11" "total 28" \
  "unresolved_ecosystems none pypi"

# --- Degraded run: empty resolved-tree JSON asserts nothing (a missing input flags, never asserts) ---
# CVE-0004 is B in the confirmed run; with no controlled set and no Dockerfile it falls back
# to A, flagged. Every app dep is "?".
degraded=$(python3 "$script" "$fx/export.csv" "$fx/empty-trees.json"); expect_rc "a degraded run over the fixture" 0 $?
expect_rows "$(summarize "$degraded")" "degraded run" \
  "CVE-0001-A-APK A False None os-package" \
  "CVE-0004-B-CONTROLLED A False None os-package" \
  "CVE-0005-C-NEITHER ? False None None" \
  "CVE-0008-F-BELOWFIX ? False None None" \
  "CVE-0009-UNRESOLVED-PYPI None False None None"
reject_in "$degraded" "a base finding was asserted B with no Dockerfile read" '"bucket": "B"'
expect_in "$(reason_of "$degraded" CVE-0004-B-CONTROLLED)" "the fallback base finding asks for the Dockerfile" "no Dockerfile read this run"
expect_rows "$(summarize_rollup "$degraded")" "degraded rollup" "needs_checkout 20" "unconfirmed_total 28" "A 6 21.4 0 6"

# --- Both npm trees empty: a failed `npm ls` reduced to {} must not read as C ---
emptynpm=$(python3 "$script" "$fx/export.csv" "$fx/empty-npm-trees.json"); expect_rc "a run with both npm trees empty" 0 $?
expect_rows "$(summarize "$emptynpm")" "empty npm trees" \
  "CVE-0005-C-NEITHER ? False None None" \
  "CVE-0006-D-DEVONLY ? False None None" \
  "CVE-0007-E-ATFIX ? False None None" \
  "CVE-0008-F-BELOWFIX ? False None None"
# An empty production tree beside a good development tree must not put every
# production dependency in D.
halfnpm=$(python3 "$script" "$fx/export.csv" "$fx/half-empty-npm-trees.json"); expect_rc "a run with the npm production tree empty" 0 $?
expect_rows "$(summarize "$halfnpm")" "half-empty npm trees" \
  "CVE-0005-C-NEITHER ? False None None" \
  "CVE-0006-D-DEVONLY ? False None None" \
  "CVE-0007-E-ATFIX ? False None None" \
  "CVE-0008-F-BELOWFIX ? False None None"

# --- Ecosystem and path alternatives: one row per PURL_ECOSYSTEM entry, OS prefix, npm
# bundle path, and app-dependency marker ---
eco=$(python3 "$script" "$fx/ecosystems.csv" "$fx/resolver.json"); expect_rc "a run over the ecosystem fixture" 0 $?
expect_rows "$(summarize "$eco")" "ecosystem fixture" \
  "ECO-NUGET None False None None" "ECO-GRADLE None False None None" \
  "ECO-MAVEN None False None None" "ECO-PYPI None False None None" \
  "ECO-UNKNOWN-GOLANG None False None None" \
  "OS-DEB A True None os-package" "OS-RPM A True None os-package" \
  "BUNDLE-USR-LIB-NPM A True None tool-bundle" \
  "NOPURL-SITE-PACKAGES None False None None" "NOPURL-NUGET None False None None" \
  "NOPURL-M2 None False None None" "NOPURL-GRADLE None False None None" \
  "NPM-LIB-NAMED-PKG C False None None"
for e in nuget gradle maven pypi; do
  id="ECO-$(printf '%s' "$e" | tr '[:lower:]' '[:upper:]')"
  expect_in "$(reason_of "$eco" "$id")" "$id is a named-but-unbuilt ecosystem (unbuilt ecosystem flagged)" "no resolver built for ecosystem $e"
done
expect_in "$(reason_of "$eco" ECO-UNKNOWN-GOLANG)" "an unnamed PURL prefix is unknown, not unbuilt (unbuilt ecosystem flagged)" "unknown ecosystem pkg:golang"
expect_row "$(summarize_rollup "$eco")" "unresolved_ecosystems lists every unresolved label" "unresolved_ecosystems golang gradle maven none nuget pypi"

# --- A BOM before the first column still finds the column ---
bom=$(python3 "$script" "$fx/bom-first-column.csv" "$fx/resolver.json" 2>&1); expect_rc "a BOM-led export whose first column is CVE ID" 0 $?
expect_row "$(summarize "$bom")" "the BOM-led first column is read" "CVE-BOM-0001 F True axios None"

# --- Rejected inputs exit 1 naming the fault, with no traceback ---
expect_rejected() {  # <label> <needle> <csv> <json>
  local got rc
  got=$(python3 "$script" "$3" "$4" 2>&1); rc=$?
  expect_rc "$1" 1 "$rc"
  expect_in "$got" "$1 names the fault" "$2"
  reject_in "$got" "$1 printed a traceback" "Traceback"
}
expect_rejected "a renamed Package Path" "Package Path" "$fx/renamed-header.csv" "$fx/resolver.json"
expect_rejected "a non-UTF-8 byte" "is not UTF-8" "$fx/not-utf8.csv" "$fx/resolver.json"

tmp=$(selftest_tmpdir) || selftest_no_tmpdir classify-cvit-findings-selftest.sh
trap 'rm -rf "$tmp"' EXIT
header=$(head -n 1 "$fx/export.csv")
for col in "CVE ID" "Packages" "Package Version" "PURL" "Package Path" "Fix Status"; do
  { printf '%s\n' "${header/,$col,/,Renamed Column,}"; tail -n +2 "$fx/export.csv"; } > "$tmp/renamed.csv"
  expect_rejected "a renamed $col column" "missing required column(s): $col" "$tmp/renamed.csv" "$fx/resolver.json"
done
: > "$tmp/empty.csv"
expect_rejected "an empty export" "missing required column(s): CVE ID" "$tmp/empty.csv" "$fx/resolver.json"
printf '{"trees": {"npm": {"prod": {}}}}' > "$tmp/no-dev.json"
expect_rejected "a tree with no dev map" "must carry both 'prod' and 'dev' maps" "$fx/export.csv" "$tmp/no-dev.json"
printf '{"trees": {"npm": {"prod": {"axios": 1}, "dev": {}}}}' > "$tmp/int-version.json"
expect_rejected "a non-string tree version" "map of {name: version} strings" "$fx/export.csv" "$tmp/int-version.json"
printf '{"dockerfile_read": "false"}' > "$tmp/str-bool.json"
expect_rejected "a string dockerfile_read (rejected, never coerced)" "'dockerfile_read' must be true or false" "$fx/export.csv" "$tmp/str-bool.json"
printf '{"controlled_packages": "expat"}' > "$tmp/str-list.json"
expect_rejected "a bare-string controlled_packages (rejected, never coerced)" "'controlled_packages' must be a list" "$fx/export.csv" "$tmp/str-list.json"
printf '{"trees": ' > "$tmp/truncated.json"
expect_rejected "truncated JSON" "is malformed" "$fx/export.csv" "$tmp/truncated.json"
printf '[]' > "$tmp/array.json"
expect_rejected "a JSON array" "must be an object" "$fx/export.csv" "$tmp/array.json"

# --- Usage path: --help exits 0; usage errors exit 3 with no traceback ---
help=$(python3 "$script" --help 2>&1); expect_rc "--help" 0 $?
expect_in "$help" "--help prints the usage line" "usage: classify-cvit-findings.py <utf8-export-csv> <resolved-tree-json>"
expect_in "$help" "--help states the exit roster" "3  usage error"
noargs=$(python3 "$script" 2>&1); expect_rc "no arguments" 3 $?
expect_in "$noargs" "no arguments prints the usage" "usage:"
python3 "$script" "$fx/export.csv" "$fx/resolver.json" extra >/dev/null 2>&1; expect_rc "three arguments" 3 $?
python3 "$script" --bogus "$fx/resolver.json" >/dev/null 2>&1; expect_rc "an unknown option" 3 $?
missing=$(python3 "$script" "$tmp/does-not-exist.csv" "$fx/resolver.json" 2>&1); expect_rc "a missing export path" 3 $?
expect_in "$missing" "a missing path is named" "not a readable file"
reject_in "$missing" "a missing path printed a traceback" "Traceback"

# --- Unit checks: parse_dotted_numeric (a suffixed version parses unclean) and the two release-line keys ---
# -B: importing the script would otherwise write a __pycache__/*.pyc beside it,
# which the security scanner flags as shipped bytecode.
units=$(python3 -B - "$script" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("classify", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
for v in ("1.0.0-rc.1", "3.5.7-r0", "v1.0.0", "1.2.3", "1..2"):
    print("parse", v, m.parse_dotted_numeric(v))
for c in ([0, 4, 2], [4, 19, 2], [3]):
    print("lines", c, m.release_line(c), m.minor_line(c))
PY
)
expect_rows "$units" "unit checks" \
  "parse 1.0.0-rc.1 ([1, 0, 0], False)" "parse 3.5.7-r0 ([3, 5, 7], False)" \
  "parse v1.0.0 ([], False)" "parse 1.2.3 ([1, 2, 3], True)" "parse 1..2 ([1], False)" \
  "lines [0, 4, 2] (0, 4) (0, 4)" "lines [4, 19, 2] (4,) (4, 19)" "lines [3] (3,) (3, 0)"

selftest_close "classify-cvit-findings: 28 export rows, 13 ecosystem rows, rollup, rejected inputs, usage path and unit checks all as pinned" ""
