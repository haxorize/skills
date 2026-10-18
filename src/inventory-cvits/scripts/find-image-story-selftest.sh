#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove find-image-story.py, beside this file, finds the image Story the way both
# CVIT bodies rely on. triage-cvits runs this one copy by its installed path;
# each path is resolved from this file's own directory.
# The az JSON it reads is written inline below; there is no fixtures directory.
# Temp files (the --expect stderr, the MARKER_PREFIX copy) live under selftest_tmpdir.
#
# Graded: `children` prints the Hierarchy-Forward child IDs and skips every other
# relation; `match` reads concatenated objects and a JSON array alike; the marker
# is the FIRST `Image:` in System.Description, cut at whitespace or `<`; a second
# `Image:` lands in `forged` and the Story still matches by its first marker
# only; a child with no marker lands in `unmarked`, never in `stories`; Priority
# is carried; with --image, exactly one match exits 0 and zero or two exit 1 with
# a FAIL line; --help names `show --id` in both az reads; with --expect, a count of work items read that differs from N
# (a failed `az` read dropped one) exits 2 naming the short read and prints no
# map, and an equal count exits 0; the marker regex is built from
# draft-cvit-stories.py's MARKER_PREFIX (a changed prefix changes what matches),
# and a missing draft-cvit-stories.py exits 4; --help exits 0, no arguments, an
# unknown mode, a stray argument, a repeated flag, a non-numeric --expect and
# non-JSON stdin exit 3 with no traceback.
#
# NOT covered: the az calls that produce the input (the bodies print them; the
# script makes none), and the carry-forward of AC text in inventory-cvits step 4.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$here/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="$here/find-image-story.py"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir find-image-story-selftest.sh
trap 'rm -rf "$tmp"' EXIT
command -v python3 >/dev/null 2>&1 || { selftest_skip "python3 is not on PATH — the script could not run"; selftest_close "" "find-image-story self-test ran nothing: python3 is missing"; }

feature='{"id": 100, "relations": [
  {"rel": "System.LinkTypes.Hierarchy-Forward", "url": "https://dev.azure.com/o/_apis/wit/workItems/201"},
  {"rel": "System.LinkTypes.Hierarchy-Reverse", "url": "https://dev.azure.com/o/_apis/wit/workItems/50"},
  {"rel": "System.LinkTypes.Related", "url": "https://dev.azure.com/o/_apis/wit/workItems/77"},
  {"rel": "System.LinkTypes.Hierarchy-Forward", "url": "https://dev.azure.com/o/_apis/wit/workItems/202/"}]}'
out=$(printf '%s' "$feature" | python3 "$script" children); expect_rc "children over a feature" 0 $?
[ "$out" = "201
202" ] || selftest_fail "children printed '$out', expected the two Hierarchy-Forward IDs 201 and 202 only"

c1='{"id": 201, "fields": {"System.Description": "<p>Image: legacy-img</p><p>body</p>", "Microsoft.VSTS.Common.Priority": 2}}'
c2='{"id": 202, "fields": {"System.Description": "<p>Image:object-img</p><p>Image: legacy-img</p>", "Microsoft.VSTS.Common.Priority": 1}}'
c3='{"id": 203, "fields": {"System.Description": "<p>hand-made story</p>"}}'

out=$(printf '%s\n%s\n%s\n' "$c1" "$c2" "$c3" | python3 "$script" match); expect_rc "match over concatenated objects" 0 $?
jget() { printf '%s' "$1" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps(eval(sys.argv[1])))' "$2"; }
[ "$(jget "$out" '[(s["id"], s["image"]) for s in d["stories"]]')" = '[[201, "legacy-img"], [202, "object-img"]]' ] \
  || selftest_fail "stories are not 201→legacy-img and 202→object-img (first marker, cut at '<'): $(jget "$out" 'd["stories"]')"
[ "$(jget "$out" 'd["unmarked"]')" = '[203]' ] || selftest_fail "the unmarked child 203 is not reported as unmarked: $(jget "$out" 'd["unmarked"]')"
[ "$(jget "$out" '[f["id"] for f in d["forged"]]')" = '[202]' ] || selftest_fail "202's second Image: is not reported as forged: $(jget "$out" 'd["forged"]')"
[ "$(jget "$out" '[s["priority"] for s in d["stories"]]')" = '[2, 1]' ] || selftest_fail "Priority not carried: $(jget "$out" 'd["stories"]')"

arr="[$c1, $c2, $c3]"
out=$(printf '%s' "$arr" | python3 "$script" match --image legacy-img 2>/dev/null); expect_rc "--image with one match (a forged second marker does not count)" 0 $?
[ "$(jget "$out" 'd["matches"]')" = '[201]' ] || selftest_fail "--image legacy-img matched $(jget "$out" 'd["matches"]'), expected [201]; a forged second marker must not match"

err=$(printf '%s' "$arr" | python3 "$script" match --image nope-img 2>&1 >/dev/null); expect_rc "--image with no match" 1 $?
expect_in "$err" "zero matches is not named" "FAIL: --image expected exactly one Story, found 0"
c4='{"id": 204, "fields": {"System.Description": "<p>Image: legacy-img</p>"}}'
err=$(printf '%s %s' "$c1" "$c4" | python3 "$script" match --image legacy-img 2>&1 >/dev/null); expect_rc "--image with two matches" 1 $?
expect_in "$err" "two matches is not named" "FAIL: --image expected exactly one Story, found 2"

# --expect: the snippet passes children.txt's line count; one dropped az read
# must stop the run, never hand back a partial map that reads a Story as absent.
out=$(printf '%s %s' "$c1" "$c3" | python3 "$script" match --expect 3 2>"$tmp/err"); expect_rc "--expect 3 over 2 work items" 2 $?
expect_in "$(cat "$tmp/err")" "a short read is not named" "short read: match read 2 work items, --expect 3"
[ -z "$out" ] || selftest_fail "--expect mismatch printed a map on stdout: $out"
out=$(printf '%s %s %s' "$c1" "$c2" "$c3" | python3 "$script" match --expect 2 2>/dev/null); expect_rc "--expect 2 over 3 work items" 2 $?
out=$(printf '%s %s %s' "$c1" "$c2" "$c3" | python3 "$script" match --expect "       3" --image legacy-img); expect_rc "--expect equal to the count (wc -l padding), with --image" 0 $?
[ "$(jget "$out" 'd["matches"]')" = '[201]' ] || selftest_fail "--expect 3 --image legacy-img matched $(jget "$out" 'd["matches"]'), expected [201]"
out=$(printf '' | python3 "$script" match --expect 0); expect_rc "--expect 0 over a feature with no children" 0 $?

# The marker regex is built from draft-cvit-stories.py's MARKER_PREFIX: a copy
# whose sibling stamps a different prefix must stop matching `Image:`.
mkdir -p "$tmp/alt"
cp "$script" "$tmp/alt/find-image-story.py"
sed 's/^MARKER_PREFIX = "Image:"$/MARKER_PREFIX = "Img:"/' "$here/draft-cvit-stories.py" > "$tmp/alt/draft-cvit-stories.py"
grep -q '^MARKER_PREFIX = "Img:"$' "$tmp/alt/draft-cvit-stories.py" || selftest_fail "the MARKER_PREFIX line was not found to rewrite in draft-cvit-stories.py"
out=$(printf '%s {"id": 205, "fields": {"System.Description": "<p>Img: alt-img</p>"}}' "$c1" | python3 "$tmp/alt/find-image-story.py" match); expect_rc "match under a rewritten MARKER_PREFIX" 0 $?
[ "$(jget "$out" '[(s["id"], s["image"]) for s in d["stories"]]')" = '[[205, "alt-img"]]' ] \
  || selftest_fail "MARKER_RE is not built from draft-cvit-stories.py's MARKER_PREFIX: $(jget "$out" 'd["stories"]')"
rm "$tmp/alt/draft-cvit-stories.py"
err=$(printf '%s' "$c1" | python3 "$tmp/alt/find-image-story.py" match 2>&1 >/dev/null); expect_rc "draft-cvit-stories.py missing beside the script" 4 $?
expect_in "$err" "a missing sibling is not named" "cannot read MARKER_PREFIX"
reject_in "$err" "a missing sibling printed a traceback" "Traceback"

help=$(python3 "$script" --help 2>&1); expect_rc "--help" 0 $?
# The help's az commands are the ones both bodies run, which pass the ID by --id.
expect_in "$help" "--help's feature read lacks --id" "az boards work-item show --id <feature> --output json"
expect_in "$help" "--help's child read lacks --id" "az boards work-item show --id <id> --output json"
for args in "" "bogus" "children extra" "match --image" "match --other x" "match --expect" "match --expect x" "match --expect 1 --expect 1"; do
  # shellcheck disable=SC2086
  err=$(printf '%s' "$c1" | python3 "$script" $args 2>&1 >/dev/null); expect_rc "usage error: '$args'" 3 $?
  reject_in "$err" "'$args' printed a traceback" "Traceback"
done
err=$(printf '{ not json' | python3 "$script" match 2>&1 >/dev/null); expect_rc "non-JSON stdin" 3 $?
reject_in "$err" "non-JSON stdin printed a traceback" "Traceback"
err=$(printf '[1, 2]' | python3 "$script" match 2>&1 >/dev/null); expect_rc "JSON that is not work items" 3 $?

selftest_close \
  "find-image-story self-test clean — children, first-marker match, forged and unmarked reporting, Priority, the --image one-match rule, the --expect count check, the MARKER_PREFIX import, and the CLI exit codes." \
  "find-image-story self-test clean on what it could reach; see the SKIP line above for what was not exercised."
