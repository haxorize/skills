#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/inventory-cvits/scripts/draft-cvit-stories.py drafts the Story shape
# it claims to, against draft-cvit-stories-fixtures/ — a few-row export and a
# manifest carrying BOTH accepted forms. This is the first bundled skill script
# in the repo (ADR-0103); the fixture freezes today's Story shape as the skill's
# contract, so a later edit that regroups, reorders, or reshapes a field reds
# here rather than drifting silently against the live Stories it was built from.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk, ADR-0104's
# 2026-10-10 amendment); pre-commit runs it when the script or a fixture is staged, and
# post-merge runs it on every merge. mutation-sweep does not reach it, so mutation checks
# are hand-run. Run it after changing the script.
#
# The two transform traps that bit the peer are each pinned:
#   - DAY-TRUNCATION: the two legacy-img High rows share a day but differ by
#     seconds (21:25:59 vs 08:00:01); they must collapse to ONE group of 2, not
#     two groups of 1. The reject row below fails if either raw timestamp leaks
#     into a heading (grouping on the raw value).
#   - DUAL MANIFEST FORM: legacy-img is a legacy string (one tag, no subject);
#     object-img is an object (two tags, a subject-bearing title). Both are
#     asserted, so a reader that drops either form reds here.
# Also graded: priority-on-missed + banner (legacy P1 + banner; object P2, no
# banner — the reject row pins the banner's absence), risk ordering and prefix
# strip (2 High, 1 Medium), CVIT numeric sort (CVIT9 before CVIT10, not
# lexical), the subject title, the image marker, the AC text, and the three-way
# partition (in_scope / zero_finding / off_manifest). The &nbsp; after "vs." in
# the Out-of-scope paragraph is pinned as a raw U+00A0 byte, since a plain space
# there is an invisible content drift from the oracle.
#
# Edge fixtures (edge.csv + edge-manifest.json, renamed-header.csv) grade:
#   - the HEADER GUARD: a renamed ttr_status (which once silently dropped the P1
#     escalation) and a renamed number each exit 1 naming the column;
#   - a UTF-8 BOM (generated in a temp copy) reads as the plain header;
#   - MIXED STATUS: one (risk, day) group holding Target Missed and In-flight is
#     rendered with both counts and reported in mixed_status, never an abort;
#   - within-level date order (an earlier date later in file order sorts first),
#     a blank status labelled "No status", and exact tags per manifest form;
#   - rejected_rows: duplicate number, crafted number, unknown risk_rating,
#     non-ISO date, empty image_repository, ragged row, crafted status, each with
#     its reason, none rendered into the body (no forged second `Image:` marker),
#     and the per-image `rejected` count, including an owned image whose only row
#     is rejected (zero_finding with rejected 1, so not mistaken for clean);
#   - the CLI: --help exits 0, a wrong argument count and a missing path exit 3
#     with no traceback, a non-UTF-8 byte and a bad manifest exit 1;
#   - stdout is pure ASCII and survives a cp1252 console (PYTHONIOENCODING).
#
# NOT covered, so a clean run here is not a claim about them: the UTF-8 transcode
# the skill body runs before this script (the fixture is already UTF-8); the az
# reads and to-story writes the skill body owns (this script makes none); the
# zero-manifest and malformed-entry arms other than invalid JSON; and the exit-4
# crash arm (no fixture crashes the script). The Problem-line "reference service" vs "image" wording is covered
# through object-img's subject and legacy-img's absence of one.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="src/inventory-cvits/scripts/draft-cvit-stories.py"
fx="src/inventory-cvits/scripts/draft-cvit-stories-fixtures"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }
[ -d "$fx" ] || { selftest_fail "fixture $fx is missing"; exit 1; }
command -v python3 >/dev/null 2>&1 || { selftest_skip "python3 is not on PATH — the script could not run"; selftest_close "" "draft-cvit-stories self-test ran nothing: python3 is missing"; }

out=$(python3 "$script" "$fx/export.csv" "$fx/manifest.json"); expect_rc "a run over the fixture" 0 $?
# stdout is ASCII-escaped JSON; the text asserts below read the decoded form.
dec=$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin), ensure_ascii=False, indent=2))')
# jq-free field reader: jget <json> <python expr over d>
jget() { printf '%s' "$1" | python3 -c 'import json,sys; d=json.load(sys.stdin); v=eval(sys.argv[1]); print(v if isinstance(v,str) else json.dumps(v))' "$2"; }

# --- Partition: three bins, each with its expected member ---
expect_in "$dec" "legacy-img is in scope" '"image": "legacy-img"'
expect_in "$dec" "object-img is in scope" '"image": "object-img"'
expect_in "$dec" "zero-img reported as zero-finding" '"image": "zero-img"'
expect_in "$dec" "off-manifest image reported with its count" '"image": "not-owned-img"'
expect_in "$dec" "off-manifest count is the row count" '"count": 1'

# --- Dual manifest form: legacy string vs object ---
# legacy-img (string form): one tag equal to the name, no subject, plain title.
expect_in "$dec" "legacy title has no subject" '"title": "[Legacy Product] CVIT remediation"'
expect_in "$dec" "legacy subject is null" '"subject": null'
# object-img (object form): two tags and a subject-bearing title.
expect_in "$dec" "object title carries the subject" '"title": "[Object Product] ref service CVIT remediation"'
expect_in "$dec" "object subject is set" '"subject": "ref service"'
expect_in "$dec" "object first tag" '"Object Product"'
expect_in "$dec" "object second tag (from the manifest tags[])" '"Extra Tag"'

# --- Priority on missed + banner ---
expect_in "$dec" "legacy priority escalates to 1 on a missed target" '"priority": 1'
expect_in "$dec" "object priority stays 2 with no missed target" '"priority": 2'
expect_in "$dec" "the banner fires on the missed image" "Target missed."
# any_missed is the field that drives both priority and the banner; pinning it
# per image fixes banner-presence at its source without slicing one body out of
# the JSON. legacy has a Target Missed row; object has none.
expect_in "$dec" "legacy any_missed is true (drives P1 and the banner)" '"any_missed": true'
expect_in "$dec" "object any_missed is false (no banner, P2)" '"any_missed": false'
# The banner sentence appears exactly once — on the one missed image. Two would
# mean it leaked onto object-img.
banner_hits=$(printf '%s\n' "$dec" | grep -c 'Target missed\.')
[ "$banner_hits" -eq 1 ] || selftest_fail "the banner appears $banner_hits times, not once (it leaked onto a non-missed image)"

# --- Risk ordering, prefix strip, totals ---
expect_in "$dec" "legacy risk summary: High before Medium, prefix stripped" '"risk_summary": "2 High, 1 Medium"'
expect_in "$dec" "object risk summary" '"risk_summary": "2 Medium"'
expect_in "$dec" "legacy total" '"total": 3'

# --- DAY-TRUNCATION trap: same day, different seconds -> ONE group of 2 ---
expect_in "$dec" "the two same-day High rows collapse to one group of 2" \
  "2 - High — target 2026-03-06 (2 findings; Target Missed: 2)"
reject_in "$dec" "a raw second-precision timestamp leaked into a heading (grouping on the raw value)" \
  "2026-03-06 21:25:59"
reject_in "$dec" "the second raw timestamp leaked into a heading" \
  "2026-03-06 08:00:01"

# --- CVIT numeric sort within a group: CVIT9 before CVIT10 ---
expect_in "$dec" "CVITs sort numerically, not lexically (CVIT9 before CVIT10)" "CVIT9, CVIT10"
reject_in "$dec" "CVITs sorted lexically (CVIT10 before CVIT9)" "CVIT10, CVIT9"

# --- Image marker (the idempotency key) ---
# Both the body-text form (backtick-wrapped, read back by the skill's regex) and the
# JSON `marker` field are pinned: the skill body matches an existing Story on one and
# stamps the new body with the other, so a drift between them opens a duplicate Story.
expect_in "$dec" "legacy body stamps the image marker" "\`Image: legacy-img\`"
expect_in "$dec" "object body stamps the image marker" "\`Image: object-img\`"
expect_in "$dec" "legacy JSON marker field matches the body stamp" '"marker": "Image: legacy-img"'
expect_in "$dec" "object JSON marker field matches the body stamp" '"marker": "Image: object-img"'

# --- Acceptance criteria text ---
# AC1 carries no live count: a count in AC text changes every run and stops
# to-story --update on a changed pre-existing AC.
[ "$(jget "$out" 'd["in_scope"][0]["acceptance_markdown"].splitlines()[0]')" = '- **AC1:** A ServiceNow rescan of `legacy-img` reports zero open CVIT findings.' ] \
  || selftest_fail "AC1 is not the count-free sentence (a live count churns the AC every run)"
expect_in "$dec" "AC2 names the product image" \
  "The fix for each finding is deployed and verified in the Legacy Product image."

# --- Out-of-scope paragraph carries the non-breaking space after "vs." ---
# A plain ASCII space here is an invisible drift from the oracle. grep -F on the
# raw U+00A0 byte (printed here) fails if the script emitted a plain space.
nbsp=$(printf '\xc2\xa0')
expect_in "$dec" "the Out-of-scope paragraph keeps the non-breaking space after vs." "base-image vs.${nbsp}app dependency"

# --- Problem line wording: subject image says the subject, non-subject says "image" ---
expect_in "$dec" "object Problem line uses the subject phrasing" "backing the Object Product ref service has"
expect_in "$dec" "legacy Problem line uses the plain image phrasing" "backing the Legacy Product image has"

# --- Tags, exact per manifest form ---
[ "$(jget "$out" '[e["tags"] for e in d["in_scope"] if e["image"]=="legacy-img"][0]')" = '["Legacy Product"]' ] \
  || selftest_fail "legacy-string tags are not exactly [name]"
[ "$(jget "$out" '[e["tags"] for e in d["in_scope"] if e["image"]=="object-img"][0]')" = '["Object Product", "Extra Tag"]' ] \
  || selftest_fail "object tags are not exactly the manifest's tags[] in order"
[ "$(jget "$out" 'd["rejected_rows"]')" = '[]' ] || selftest_fail "the clean fixture rejected a row"
[ "$(jget "$out" 'd["mixed_status"]')" = '[]' ] || selftest_fail "the clean fixture reported a mixed-status group"

# --- Output encoding: pure ASCII, survives a cp1252 console ---
python3 -c 'import sys; sys.exit(0 if sys.stdin.buffer.read().isascii() else 1)' <<<"$out" \
  || selftest_fail "stdout is not pure ASCII (a cp1252 console can fail the write)"
PYTHONIOENCODING=cp1252 python3 "$script" "$fx/export.csv" "$fx/manifest.json" >/dev/null 2>&1
expect_rc "a run with a cp1252 stdout" 0 $?

# --- Header guard (D1/D2): a renamed column exits 1 and names it ---
err=$(python3 "$script" "$fx/renamed-header.csv" "$fx/manifest.json" 2>&1 >/dev/null); expect_rc "a renamed ttr_status header" 1 $?
expect_in "$err" "the renamed-header error names ttr_status" "missing required column(s): ttr_status"
# No temp dir: 4 (nothing more ran), unless a row above already failed.
tmp=$(selftest_tmpdir) || { echo "draft-cvit-stories-selftest: no usable temp directory (TMPDIR=${TMPDIR:-unset}) — the rows below did not run" >&2; [ "$fail" = 0 ] || exit 1; exit 4; }
trap 'rm -rf "$tmp"' EXIT
sed '1s/"number"/"Number"/' "$fx/export.csv" > "$tmp/renamed-number.csv"
err=$(python3 "$script" "$tmp/renamed-number.csv" "$fx/manifest.json" 2>&1 >/dev/null); expect_rc "a renamed number header" 1 $?
expect_in "$err" "the renamed-header error names number" "missing required column(s): number"

# --- UTF-8 BOM reads as the plain header ---
{ printf '\xef\xbb\xbf'; cat "$fx/export.csv"; } > "$tmp/bom.csv"
bom_out=$(python3 "$script" "$tmp/bom.csv" "$fx/manifest.json" 2>&1); expect_rc "a BOM-prefixed export" 0 $?
[ "$bom_out" = "$out" ] || selftest_fail "a BOM-prefixed export drafts differently from the plain one"

# --- Edge fixture: mixed status, date order, blank status, rejected rows ---
eout=$(python3 "$script" "$fx/edge.csv" "$fx/edge-manifest.json"); expect_rc "a run over the edge fixture" 0 $?
ebody=$(jget "$eout" 'd["in_scope"][0]["body_markdown"]')
expect_in "$ebody" "a mixed group lists both statuses with counts, missed first" \
  "2 - High — target 2026-05-01 (2 findings; Target Missed: 1, In-flight: 1)"
[ "$(jget "$eout" 'd["mixed_status"]')" = '[{"image": "edge-img", "risk_rating": "2 - High", "target": "2026-05-01", "statuses": {"Target Missed": 1, "In-flight": 1}}]' ] \
  || selftest_fail "mixed_status does not report the one mixed group exactly"
[ "$(jget "$eout" 'str(d["in_scope"][0]["body_markdown"].index("target 2026-04-15") < d["in_scope"][0]["body_markdown"].index("target 2026-05-01"))')" = True ] \
  || selftest_fail "within a risk level, the earlier target date does not come first"
expect_in "$ebody" "a blank status is labelled No status" "3 - Medium — target 2026-06-01 (1 finding; No status: 1)"
reject_in "$ebody" "a blank status was labelled In-flight" "2026-06-01 (1 finding; In-flight: 1)"
[ "$(jget "$eout" 'd["in_scope"][0]["total"]')" = 4 ] || selftest_fail "edge-img total is not 4 (a duplicate or rejected row was counted)"
[ "$(jget "$eout" 'd["in_scope"][0]["rejected"]')" = 6 ] || selftest_fail "edge-img rejected count is not 6"
[ "$(jget "$eout" 'd["zero_finding"]')" = '[{"image": "only-bad-img", "name": "Only Bad Product", "rejected": 1}]' ] \
  || selftest_fail "an owned image whose only row is rejected does not carry rejected 1 in zero_finding"
reasons=$(jget "$eout" '"\n".join(str(r["line"]) + " " + r["reason"].split(" (")[0] for r in d["rejected_rows"])')
for want in "6 duplicate number" "7 invalid number" "8 unknown risk_rating" "9 invalid ttr_target_date" \
            "10 empty image_repository" "11 ragged row" "12 invalid ttr_status" "13 unknown risk_rating"; do
  expect_row "$reasons" "rejected_rows carries line+reason: $want" "$want"
done
[ "$(printf '%s\n' "$ebody" | grep -c 'Image:')" -eq 1 ] || selftest_fail "a crafted number forged a second Image: marker into the body"
reject_in "$ebody" "a crafted status reached the body raw" "<b>"
reject_in "$ebody" "an unknown risk_rating reached the body" "Severe"

# --- CLI contract ---
help=$(python3 "$script" --help 2>&1); expect_rc "--help" 0 $?
expect_in "$help" "--help prints the usage line" "usage: draft-cvit-stories.py <utf8-export-csv> <manifest-json>"
err=$(python3 "$script" 2>&1); expect_rc "no arguments (usage error)" 3 $?
expect_in "$err" "a usage error prints the usage line" "<utf8-export-csv> <manifest-json>"
err=$(python3 "$script" "$tmp/does-not-exist.csv" "$fx/manifest.json" 2>&1); expect_rc "a missing export path" 3 $?
reject_in "$err" "a missing path printed a traceback" "Traceback"
expect_in "$err" "a missing path is named" "does-not-exist.csv"
printf '"number","image_repository","risk_rating","ttr_target_date","ttr_status"\n"CVIT1","legacy-img","2 - High","2026-01-01","caf\xe9"\n' > "$tmp/latin1.csv"
err=$(python3 "$script" "$tmp/latin1.csv" "$fx/manifest.json" 2>&1); expect_rc "a non-UTF-8 byte" 1 $?
reject_in "$err" "a non-UTF-8 byte printed a traceback" "Traceback"
printf '{ not json' > "$tmp/bad.json"
err=$(python3 "$script" "$fx/export.csv" "$tmp/bad.json" 2>&1); expect_rc "an invalid manifest" 1 $?
reject_in "$err" "an invalid manifest printed a traceback" "Traceback"

if [ "$fail" -ne 0 ]; then
  echo; echo "Script output was:"; printf '%s\n' "$dec"
fi
selftest_close \
  "draft-cvit-stories self-test clean — both manifest forms, day-truncation, CVIT numeric sort, priority-on-missed, the banner, the marker, the ACs, the partition, the header guard, mixed status, rejected rows, and the CLI exit codes all as the oracle shape." \
  "draft-cvit-stories self-test clean on what it could reach; see the SKIP line above for what was not exercised."
