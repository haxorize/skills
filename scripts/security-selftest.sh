#!/usr/bin/env bash
# Prove scripts/security.sh still flags what it claims to flag, and stays
# quiet on a clean skill. The rule roster is read from the scanner itself —
# every rule id its source defines must fire on scripts/lint-fixtures/security/
# injected-skill/ (wrong on purpose) and must be absent from clean-skill/
# (right on purpose), so a rule added without a fixture, or one whose fixture
# quietly stopped matching, reds here by name — and the id count is pinned,
# so a rule deleted from the source reds too. Two rules no committed file can
# trigger — scan-skipped (a file over the size cap) and scan-error (a file the
# scanner cannot open) — are graded on a throwaway copy built at run time; the
# second is skipped, and the run ends PARTIAL, where chmod 000 does not take.
#
# Also graded: the extensionless `bin/run` entrypoint reached by its shebang;
# the benign manifest (`install` and `prepare` as dependency names, `test` and
# `lint` under scripts) drawing nothing; the benign neighbours in
# clean-skill/scripts/check.sh sitting near each threshold (a 190-char hex
# string against the 200 floor, a 4,900-char line against the 5,000 cap, a
# download and a chmod six lines apart against the five-line window,
# private-range HTTP); --json parsing as JSON; and the exit codes.
#
# Last, every shipped skill under src/ must PASS. That row grades the corpus,
# not the scanner: a red there is a skill body that acquired a flagged phrase,
# or a rule that widened onto ordinary prose — its message says which file, and
# the rule rows above say whether the scanner itself moved. Run it after
# changing a rule.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh
fx="scripts/lint-fixtures/security"
[ -d "$fx/injected-skill" ] && [ -d "$fx/clean-skill" ] || { selftest_fail "fixture $fx is missing a skill directory"; exit 1; }

rules=$(grep -oE '"(inj|sh|md|bin|uni|manifest|scan)-[a-z0-9-]+"' scripts/security.sh | tr -d '"' | sort -u)
# The roster is derived, so a rule whose fixture stopped matching reds by
# name; the count is pinned, so a rule deleted from the source — and with it
# from the roster — reds too. Raise the pin when a rule lands with its fixture.
nrules=$(printf '%s\n' "$rules" | wc -l | tr -d ' ')
[ "$nrules" -eq 26 ] || selftest_fail "read $nrules rule ids out of scripts/security.sh, not 26 — a rule was added (add its fixture instance and raise this pin) or deleted (lower the pin on purpose)"

out=$(bash scripts/security.sh --path "$fx/injected-skill" 2>/dev/null); expect_rc "the scan of the injected fixture" 0 $?
expect_in "$out" "the injected fixture was not reported RISK" "[RISK] injected-skill"
for rule in $rules; do
  case "$rule" in scan-skipped|scan-error) continue ;; esac
  expect_in "$out" "rule $rule did not fire on the injected fixture" " $rule: "
done
expect_in "$out" "the extensionless bin/run was not reached by its shebang" "bin/run: "
expect_in "$out" "the manifest hook's command was not scanned by the script rules (its evidence names the key)" "package.json: postinstall: node setup.js"

clean=$(bash scripts/security.sh --path "$fx/clean-skill" 2>/dev/null); expect_rc "the scan of the clean fixture" 0 $?
expect_in "$clean" "the clean fixture did not PASS" "Scanned: 1 | RISK: 0 | REVIEW: 0 | PASS: 1"
for rule in $rules; do
  reject_in "$clean" "rule $rule fired on the clean fixture" " $rule: "
done

# The advisory line is stderr, never stdout: a consumer parsing stdout sees
# the summary first.
printf '%s\n' "$clean" | head -1 | grep -q '^Scanned:' || selftest_fail "stdout did not open with the Scanned: summary — advisory text has leaked into the data stream"

js=$(bash scripts/security.sh --json --path "$fx/clean-skill" 2>/dev/null)
printf '%s' "$js" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["scanned"]==1 and d["skills"][0]["verdict"]=="PASS", d' >/dev/null 2>&1 || selftest_fail "--json did not parse as JSON with one PASS skill; got: $(printf '%s' "$js" | head -c 200)"

if tmp="$(selftest_tmpdir)"; then
  trap 'chmod -R u+rwX "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
  if mkdir -p "$tmp/big" && cp -R "$fx/clean-skill/." "$tmp/big/"; then
    head -c 1100000 /dev/zero | tr '\0' 'a' > "$tmp/big/scripts/padded.sh"
    big=$(bash scripts/security.sh --path "$tmp/big" 2>/dev/null)
    expect_in "$big" "a file over the size cap did not draw scan-skipped" " scan-skipped: "
    reject_in "$big" "a directory with an unscanned file rendered PASS" "PASS: 1"
    chmod 000 "$tmp/big/scripts/check.sh"
    if cat "$tmp/big/scripts/check.sh" >/dev/null 2>&1; then
      selftest_skip "$tmp/big/scripts/check.sh is still readable after chmod 000 (running as root, or a filesystem that ignores modes) — the scan-error row was not exercised by this run."
    else
      err=$(bash scripts/security.sh --path "$tmp/big" 2>/dev/null)
      expect_in "$err" "an unreadable file did not draw scan-error" " scan-error: "
    fi
  else
    selftest_skip "could not copy the clean fixture into $tmp — the scan-skipped and scan-error rows were not exercised by this run."
  fi
else
  selftest_skip "mktemp -d produced no usable directory — the scan-skipped and scan-error rows were not exercised by this run."
fi

# Exit codes and --help.
bash scripts/security.sh --path "$fx/does-not-exist" >/dev/null 2>&1; expect_rc "a --path that is not a directory" 2 $?
bash scripts/security.sh >/dev/null 2>&1; expect_rc "no target" 3 $?
bash scripts/security.sh --bogus >/dev/null 2>&1; expect_rc "an unknown option" 3 $?
help_out=$(bash scripts/security.sh --help 2>&1); expect_rc "--help" 0 $?
expect_in "$help_out" "--help printed no Usage: line" "Usage:"
expect_in "$help_out" "--help lost the tail of its header (the last header line is missing)" "scripts/security-selftest.sh runs it against scripts/lint-fixtures/security/."
reject_in "$help_out" "--help ran a scan" "Scanned:"

# The shipped corpus. Counted the way --each enumerates (a glob, which skips
# dot-directories), so the two cannot disagree on what a directory is.
n=0; for d in src/*/; do n=$((n + 1)); done
shipped=$(bash scripts/security.sh --each src 2>/dev/null)
if ! printf '%s\n' "$shipped" | grep -qF "Scanned: $n | RISK: 0 | REVIEW: 0 | PASS: $n"; then
  selftest_fail "a shipped skill under src/ drew a finding ($n directories scanned) — a corpus finding (a body acquired a flagged phrase) or a rule that widened onto ordinary prose; the rule rows above say whether the scanner itself moved. Shipped output:"
  printf '%s\n' "$shipped" | head -20
fi

if [ "$fail" -ne 0 ]; then
  echo; echo "Fixture output:"; printf '%s\n' "$out"; echo "Clean output:"; printf '%s\n' "$clean"
fi
selftest_close \
  "security self-test clean — every rule the scanner defines fired on the injected fixture and stayed quiet on the clean one, the two runtime rows fired, and all $n shipped skills PASS." \
  "security self-test clean on every committed fixture and all $n shipped skills, but a runtime row was not exercised; see the SKIP line above."
