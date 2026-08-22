#!/usr/bin/env bash
# Self-test for rename-safety.sh: an expect/reject payload table. The hook is
# fail-open, so a regex that quietly stops matching looks exactly like a clean
# command — this table is the only thing that tells the two apart. Run it after
# changing any regex: bash global/hooks/rename-safety-selftest.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/rename-safety.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
opted="$tmp/opted"; plain="$tmp/plain"
mkdir -p "$opted/.claude" "$opted/deep" "$plain"; touch "$opted/.claude/rename-safety"

fail=0
run() { # run <dir> <command-string> [env...]; prints exit code
  local dir="$1" cmd="$2"; shift 2
  local payload
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd")"
  ( cd "$dir" && printf '%s' "$payload" | env "$@" HOME="$tmp" bash "$hook" >/dev/null 2>&1; echo $? )
}
expect_block() { local rc; rc="$(run "$opted" "$1")"; if [ "$rc" != 2 ]; then echo "FAIL (should block, rc=$rc): $1"; fail=1; fi; }
expect_allow() { local rc; rc="$(run "$opted" "$1")"; if [ "$rc" != 0 ]; then echo "FAIL (should allow, rc=$rc): $1"; fail=1; fi; }

# --- in-place shapes: block ---------------------------------------------------
expect_block "sed -i 's/a/b/' f.txt"
expect_block "sed -i'' 's/a/b/' f.txt"
expect_block "sed -i.bak 's/a/b/' f.txt"
expect_block "sed --in-place=.bak 's/a/b/' f.txt"
expect_block "sed -E -i 's/a/b/' f.txt"
expect_block "sed -n -i 's/a/b/' f.txt"
expect_block "sed -Ei 's/a/b/' f.txt"
expect_block "gsed -i 's/a/b/' f.txt"
expect_block "/usr/bin/sed -i 's/a/b/' f.txt"
expect_block "x=\$(sed -i 's/a/b/' f.txt)"
expect_block "cd src && sed -i 's/a/b/' f.txt"
expect_block $'grep -l a *.md\nsed -i \'s/a/b/\' *.md'
expect_block "find . -name '*.md' -exec sed -i 's/a/b/' {} +"
expect_block "sudo sed -i 's/a/b/' /etc/hosts"
expect_block "perl -pi -e 's/a/b/' *.md"
expect_block "perl -i -pe 's/a/b/' f.txt"
expect_block "perl -pi.bak -e 's/a/b/' f.txt"
expect_block "ruby -pi -e 'gsub(/a/,\"b\")' f.txt"
expect_block "grep -rl a . | xargs sed -i 's/a/b/'"
expect_block "find . -name '*.py' -print0 | xargs -0 sed -i '' 's/a/b/'"
expect_block "ls | xargs -I{} sed -i 's/a/b/' {}"
expect_block "git ls-files | xargs perl -pi -e 's/a/b/'"
expect_block "ls | xargs -n 1 gsed -i 's/a/b/'"

# --- reads and mentions: allow ------------------------------------------------
expect_allow "sed -n '1,5p' f.txt"
expect_allow "sed -e 's/i/x/' f.txt"
expect_allow "sed -E 's/i/x/' f.txt"
expect_allow "grep -i foo f.txt"
expect_allow "grep 'sed -i' f.txt"
expect_allow "echo \"use sed -i\""
expect_allow "git commit -m 'drop the sed -i call'"
expect_allow "ls | xargs grep foo | sed 's/x/y/'"
expect_allow "ls | xargs wc -l | sed -n '1p'"
expect_allow "ls | xargs grep x; sed -n 1p f"
expect_allow "ls | xargs echo sed foo"
expect_allow "ls | xargs sed -n 1p"
expect_allow "perl -ne 'print if /a/' f.txt"
expect_allow "perl -e 'print 1'"
expect_allow "python3 -c 'import sys'"
expect_allow "sedlike -i x"
expect_allow "ls -i"

# --- opt-in and fail-open ----------------------------------------------------
rc="$(run "$plain" "sed -i 's/a/b/' f.txt")"; [ "$rc" = 0 ] || { echo "FAIL: non-opted dir should allow (rc=$rc)"; fail=1; }
rc="$(run "$opted/deep" "sed -i 's/a/b/' f.txt")"; [ "$rc" = 2 ] || { echo "FAIL: subdir of opted dir should block (rc=$rc)"; fail=1; }
rc="$(run "$plain" "sed -i 's/a/b/' f.txt" RENAME_SAFETY_DIRS="$plain")"; [ "$rc" = 2 ] || { echo "FAIL: RENAME_SAFETY_DIRS should opt in (rc=$rc)"; fail=1; }
rc="$(run "$plain" "sed -i 's/a/b/' f.txt" RENAME_SAFETY_DIRS=":")"; [ "$rc" = 0 ] || { echo "FAIL: empty RENAME_SAFETY_DIRS element must opt in nothing (rc=$rc)"; fail=1; }
rc="$(run "$plain" "sed -i 's/a/b/' f.txt" RENAME_SAFETY_DIRS=":$opted")"; [ "$rc" = 0 ] || { echo "FAIL: leading colon must not opt in \$plain (rc=$rc)"; fail=1; }
# payload cwd wins over the process directory
payload="$(python3 -c 'import json,sys; print(json.dumps({"cwd":sys.argv[1],"tool_input":{"command":"sed -i s/a/b/ f"}}))' "$opted")"
rc="$( cd "$plain" && printf '%s' "$payload" | HOME="$tmp" bash "$hook" >/dev/null 2>&1; echo $? )"
[ "$rc" = 2 ] || { echo "FAIL: payload cwd in opted dir should block (rc=$rc)"; fail=1; }
for bad in "" "notjson" '{"tool_input":[]}' '{"tool_input":{"command":5}}' '{}'; do
  rc="$( cd "$opted" && printf '%s' "$bad" | HOME="$tmp" bash "$hook" >/dev/null 2>&1; echo $? )"
  [ "$rc" = 0 ] || { echo "FAIL: malformed payload '$bad' must allow (rc=$rc)"; fail=1; }
done
# stderr names the shape and the path-shaped argument
out="$( cd "$opted" && printf '%s' '{"tool_input":{"command":"sed -i s/a/b/ notes.md"}}' | HOME="$tmp" bash "$hook" 2>&1 >/dev/null )"
printf '%s' "$out" | grep -q 'blocked an in-place mass edit (sed -i)' || { echo "FAIL: block message missing"; fail=1; }
printf '%s' "$out" | grep -q '    notes.md' || { echo "FAIL: path-shaped argument notes.md not listed"; fail=1; }
printf '%s' "$out" | grep -qE '^    s/a/b' && { echo "FAIL: sed expression listed as a path"; fail=1; }

if [ "$fail" -ne 0 ]; then echo "SELFTEST FAIL: rename-safety"; exit 1; fi
echo "OK: rename-safety self-test clean — every in-place shape blocked, every read and mention allowed, opt-in and fail-open hold."
