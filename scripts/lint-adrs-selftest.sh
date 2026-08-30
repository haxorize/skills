#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove scripts/lint-adrs.sh still catches what it claims to catch, and stays
# quiet on the forms it exempts. Points the linter at scripts/lint-fixtures/adr/
# — it never reads docs/adr/, so a real record's state is never what it grades
# (wrong on purpose: every expected FAIL is asserted by a substring only that
# check produces, and the FAIL count is pinned) and at
# scripts/lint-fixtures-clean/adr/ (right on purpose: must exit 0), then at an
# empty directory and a missing one (must exit 2), an unknown flag, an empty
# argument and two directories (3), and --help (0, no verdict line, and its
# last header line present — the truncation a hard-coded line range hides).
#
# Every check is graded in both directions. Firing: a duplicate number; a
# supersession whose successor never links back; a dangling supersession in
# lower and upper case; a forward pointer missing for the link form, the bold
# form, the unlinked prose form, and the second of two links on one line; a
# pointer below the first heading; an amend link to a missing file; a bold form
# naming a number nobody claims; an empty Revisit line in both forms; a settled
# deferral with no entry, one whose only entry is `<date>-2`, and one whose
# only entry sits under a heading other than `## Amendments`; a corrected
# Consequences bullet in all three of those shapes; a plain cross-reference to a
# record that does not exist, and the second FAIL a dangling supersession link
# and a dangling amend link each draw from that same check. Quiet: a
# well-formed link-form pair, the `[ADR N]` space form, a pair whose numbers are
# padded differently on each side, a bold-form pair with its pointer, a
# bystander's `## Amendments` entry naming an amender and a target that carries
# no pointer at all (the exemption is load-bearing: delete it and this fires),
# an inline Revisit line with text, a heading-form Revisit with a paragraph,
# the `, later` and ` — title.` settled-entry openers, both of those openers
# on a corrected Consequences bullet, a `corrected:` marker outside
# `## Consequences`, a cross-reference that resolves beside a relative path, an
# outbound URL and the `[ADR N](N-slug.md)` placeholder, the unnumbered README,
# and — in the clean tree — a well-formed supersession pair. Run it after
# changing a check.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh
fx="scripts/lint-fixtures/adr"; clean="scripts/lint-fixtures-clean/adr"
[ -d "$fx" ] || { selftest_fail "fixture $fx is missing"; exit 1; }
[ -d "$clean" ] || { selftest_fail "clean fixture $clean is missing"; exit 1; }

output=$(bash scripts/lint-adrs.sh "$fx" 2>&1); status=$?

expect() { expect_in "$output" "the $1 check did not fire on the fixture tree" "$2"; }
reject() { reject_in "$output" "the $1 check fired on a form it must exempt" "$2"; }

expect "duplicate number" "number 9001 is claimed by 2 files"
expect "supersession back-link" "9003-successor-no-backlink.md never links back to it"
expect "supersession dangling" "9004-superseded-dangling.md (line 2) is superseded by [ADR-9099](9099-does-not-exist.md), which does not exist"
expect "supersession dangling (upper case)" "9004-superseded-dangling.md (line 6) is superseded by [ADR-9098](9098-upper-case-does-not-exist.md), which does not exist"
expect "forward pointer (link form)" "9006-target-no-pointer.md carries no forward pointer above its first heading"
expect "forward pointer (bold form)" "9008-bold-target-no-pointer.md carries no forward pointer above its first heading"
expect "forward pointer (below the first heading)" "9010-pointer-below-heading.md carries no forward pointer above its first heading"
expect "forward pointer (unlinked prose form)" "9020-prose-target-no-pointer.md carries no forward pointer above its first heading"
expect "forward pointer (second link on one line)" "9022-second-target-no-pointer.md carries no forward pointer above its first heading"
expect "amend link dangling" "9018-amender-dangling-link.md (line 3) amends [ADR-9099](9099-does-not-exist.md), which does not exist"
expect "bold form naming no record" "9037-amender-bold-missing-number.md (line 3) amends ADR-9099, and no record claims number 9099"
expect "revisit inline empty" "9011-revisit-empty.md (line 5) has a 'Revisit when:' line with nothing after the colon"
expect "revisit heading empty" "9012-revisit-heading-empty.md has a '## Revisit when:' heading with no paragraph under it"
expect "settled deferral without its amendment" "9013-settled-no-amendment.md (line 7) marks a Deferred line settled by Amendments 2026-01-01"
expect "settled deferral (date-suffix entry is not a match)" "9013-settled-no-amendment.md (line 8) marks a Deferred line settled by Amendments 2026-07-07"
expect "settled deferral (entry outside ## Amendments is not a match)" "9013-settled-no-amendment.md (line 9) marks a Deferred line settled by Amendments 2026-03-03"
expect "corrected consequence without its amendment" "9038-corrected-no-amendment.md (line 7) marks a Consequences bullet corrected by Amendments 2026-01-01"
expect "corrected consequence (date-suffix entry is not a match)" "9038-corrected-no-amendment.md (line 8) marks a Consequences bullet corrected by Amendments 2026-07-07"
expect "corrected consequence (entry outside ## Amendments is not a match)" "9038-corrected-no-amendment.md (line 9) marks a Consequences bullet corrected by Amendments 2026-03-03"
expect "cross-reference to a record that does not exist" "9040-xref-dangling.md (line 3) links to 9099-does-not-exist.md, and no such file is in"
# The overlap is deliberate and pinned here: a dangling supersession or amend
# link is also a dangling citation, and each draws its own FAIL naming its own
# repair. Neither of these lines can come from the check that owns that file.
expect "cross-reference (a dangling supersession link is also one)" "9004-superseded-dangling.md (line 6) links to 9098-upper-case-does-not-exist.md"
expect "cross-reference (a dangling amend link is also one)" "9018-amender-dangling-link.md (line 3) links to 9099-does-not-exist.md"

reject "forward pointer (well-formed pair)" "9015-well-formed-target.md carries no forward pointer"
reject "forward pointer (first of two links)" "9023-two-links-first-target.md carries no forward pointer"
reject "forward pointer (space form)" "9025-space-form-target.md"
reject "forward pointer (padding differs)" "9031-overpadded-target.md"
reject "forward pointer (bold form with pointer)" "9033-bold-target-with-pointer.md"
# The log exemption: 9034's ## Amendments entry names 9035 amending 9036, and
# 9036 carries no pointer to anyone — so the only way this line appears is the
# exemption being gone.
reject "forward pointer (third-party mention in an Amendments log)" "9036-third-party-target-no-pointer.md carries no forward pointer"
reject "forward pointer (bystander amender)" "9035-third-party-amender.md"
# 9016 also carries the two settled-entry forms that must resolve: `, later`
# after the date and a title inside the bold after a dash.
reject "revisit inline with text, and both settled-entry forms" "9016-revisit-and-settled-ok.md"
reject "revisit heading with paragraph" "9017-revisit-heading-ok.md"
# 9039 carries a `corrected:` marker before its first heading whose date no
# entry claims: the only way that line appears here is the `## Consequences`
# anchoring being gone. 9041 carries the three link forms the check exempts —
# a path out of the directory, an outbound URL, and the format file's own
# `[ADR N](N-slug.md)` placeholder.
reject "corrected consequence (both entry forms, and the section anchoring)" "9039-corrected-ok.md"
reject "cross-reference (resolves, beside the exempt link forms)" "9041-xref-ok.md"
reject "unnumbered README" "README.md"
expect_rc "the lint against the fixture tree" 1 "$status"
# The count of `FAIL: `-prefixed lines is pinned: a new firing on a quiet
# form, a check that starts double-reporting, or a message that loses the
# prefix the family shares shows up here even if no substring above moves.
# Three of the 23 are the cross-reference check's deliberate overlap with the
# supersession and amend link checks, asserted by name above.
nfail=$(printf '%s\n' "$output" | grep -c '^FAIL: ')
[ "$nfail" -eq 23 ] || selftest_fail "expected exactly 23 FAIL lines against the fixture tree, got $nfail"

clean_out=$(bash scripts/lint-adrs.sh "$clean" 2>&1); clean_status=$?
if [ "$clean_status" -ne 0 ]; then
  selftest_fail "the clean fixture exited $clean_status; output was:"; printf '%s\n' "$clean_out"
fi
expect_in "$clean_out" "the clean run did not print its OK line with the record count" "OK: 5 records"

if tmp="$(selftest_tmpdir)"; then
  trap 'rm -rf "$tmp"' EXIT
  bash scripts/lint-adrs.sh "$tmp" >/dev/null 2>&1; expect_rc "an empty directory" 2 $?
  bash scripts/lint-adrs.sh "$tmp/nope" >/dev/null 2>&1; expect_rc "a missing directory" 2 $?
else
  selftest_skip "mktemp -d produced no usable directory — the empty-directory and missing-directory exit codes were not exercised by this run."
fi
bash scripts/lint-adrs.sh --bogus >/dev/null 2>&1; expect_rc "an unknown flag" 3 $?
bash scripts/lint-adrs.sh "" >/dev/null 2>&1; expect_rc "an empty directory argument" 3 $?
bash scripts/lint-adrs.sh "$fx" "$clean" >/dev/null 2>&1; expect_rc "two directories" 3 $?
help_out=$(bash scripts/lint-adrs.sh --help 2>&1); expect_rc "--help" 0 $?
expect_in "$help_out" "--help printed no Usage: line" "Usage:"
expect_in "$help_out" "--help lost the tail of its header (the last header line is missing)" "(wrong on purpose) and scripts/lint-fixtures-clean/adr/ (right on purpose)."
printf '%s\n' "$help_out" | grep -qE '^(OK|FAIL):' && selftest_fail "--help ran the lint"

if [ "$fail" -ne 0 ]; then
  echo; echo "Linter output against $fx was:"; printf '%s\n' "$output"
fi
selftest_close \
  "lint-adrs self-test clean — every fixture failure fired, every exempt form stayed quiet, the clean tree exited 0, and the four exit codes hold." \
  "lint-adrs self-test clean on both fixture trees, but the two temp-directory exit-code rows were not exercised; see the SKIP line above."
