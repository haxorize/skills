#!/usr/bin/env bash
# Prove scripts/security.sh still flags what it claims to flag, and stays
# quiet on a clean skill. Points the scanner at scripts/lint-fixtures/security/
# (an injection phrase, a concealment phrase, a curl-pipe-to-shell script) and
# at one shipped skill that must report PASS. Run it after changing a rule.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fail=0
out=$(bash scripts/security.sh --path scripts/lint-fixtures/security/injected-skill 2>&1)
for needle in "[RISK] injected-skill" "inj-ignore" "inj-conceal" "sh-curlpipe"; do
  if ! printf '%s\n' "$out" | grep -qF "$needle"; then
    echo "SELFTEST FAIL: scanner did not report '$needle' on the fixture"
    fail=1
  fi
done

clean=$(bash scripts/security.sh --path src/grilling 2>&1)
if ! printf '%s\n' "$clean" | grep -qF "RISK: 0 | REVIEW: 0 | PASS: 1"; then
  echo "SELFTEST FAIL: scanner did not report PASS on src/grilling"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "OK: security self-test clean — fixture flagged RISK with each rule, clean skill PASS."
else
  echo; echo "Fixture output:"; printf '%s\n' "$out"; echo "Clean output:"; printf '%s\n' "$clean"
fi
exit "$fail"
