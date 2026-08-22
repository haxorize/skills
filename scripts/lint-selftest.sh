#!/usr/bin/env bash
# Prove scripts/lint-skills.sh still catches what it claims to catch.
#
# A lint gate degrades silently: the run stays green whether the rule holds or
# the check quietly stopped matching, and the two are indistinguishable from
# the outside. This script points the linter at scripts/lint-fixtures/ — a tiny
# repo root whose skills are wrong on purpose — and grades it in both
# directions: every expected failure must appear, and the forms the linter
# exempts must produce no failure at all. A one-directional check would pass
# just as happily against a linter that flagged everything.
#
# Run it after changing any check in lint-skills.sh.
#
# Covered here: reference-link resolution (both directions, including the
# backtick-span and fenced-block exemptions), the ADR-citation ban, the
# description's unquoted ': ' and ' #', load-gate placement, and the global-rules
# Depends: admission check (missing line, dangling name, a dependant that never
# cites the rule, and the well-formed form that must stay quiet). NOT covered, so a clean
# run here is not a claim about them: the 200-line caps, sibling byte-identity
# (skipped under LINT_ROOT — the registry names this repo's own paths),
# description length, angle brackets, name/directory agreement, the
# requires: resolution check (existence and model-invoked), and router
# coverage. The two-way requires check is covered in both directions for the
# fixture forms (an imperative slash use; a quoted and an arrow-parenthesised
# mention that must stay quiet); its header states what it does not reach.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fixtures="scripts/lint-fixtures"
if [ ! -d "$fixtures" ]; then
  echo "SELFTEST FAIL: fixture tree $fixtures is missing"
  exit 1
fi

output=$(LINT_ROOT="$fixtures" bash scripts/lint-skills.sh 2>&1)
status=$?

fail=0

# Grading both directions. Each `expect` names a check and a substring only
# that check's message can produce; each `reject` names a form the linter must
# leave alone.
expect() {
  if ! printf '%s\n' "$output" | grep -qF "$2"; then
    echo "SELFTEST FAIL: the $1 check did not fire on the fixture — expected a line containing: $2"
    fail=1
  fi
}

reject() {
  if printf '%s\n' "$output" | grep -qF "$2"; then
    echo "SELFTEST FAIL: the $1 check fired on a form it must exempt — found a line containing: $2"
    fail=1
  fi
}

# The line number is pinned, not just the path: reporting the wrong line is the
# defect this field was added to fix. Moving that link in the fixture is meant
# to fail here until the number is updated with it.
expect "reference-link resolution" "links to 'references/does-not-exist.md' (line 14)"
expect "ADR-citation ban" "cites a repo ADR by number"
expect "description colon" "description has unquoted ': '"
expect "description hash" "description has unquoted ' #'"
expect "load-gate placement" "carries a load gate ('Launching skill'"
expect "global-rule Depends (missing)" "global/rules/no-depends.md has no 'Depends:' line"
expect "global-rule Depends (dangling)" "global/rules/dangling-depends.md Depends: names 'no-such-skill'"
expect "global-rule Depends (uncited)" "global/rules/uncited-depends.md Depends: names 'quoted-dep' but src/quoted-dep/ never cites the rule"
expect "two-way requires (undeclared)" "src/undeclared-dep/SKILL.md invokes \`/fixture-discipline\` but its requires: line does not declare"
expect "two-way requires (unused)" "src/unused-dep/SKILL.md declares requires: 'fixture-discipline' but the body never names it"

reject "reference-link resolution" "references/real-reference.md"
reject "reference-link resolution" "references/exempt-single.md"
reject "reference-link resolution" "references/exempt-double.md"
reject "reference-link resolution" "references/exempt-inner.md"
reject "reference-link resolution" "references/exempt-fenced.md"
reject "global-rule Depends" "global/rules/well-formed.md"
reject "two-way requires (quoted and parenthesised forms)" "src/quoted-dep/SKILL.md"

if [ "$status" -ne 1 ]; then
  echo "SELFTEST FAIL: lint exited $status against the fixture tree; a tree this broken must exit 1"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "OK: lint self-test clean — every fixture failure fired, every exempt form stayed quiet."
else
  echo
  echo "Linter output against $fixtures was:"
  printf '%s\n' "$output"
fi

exit "$fail"
