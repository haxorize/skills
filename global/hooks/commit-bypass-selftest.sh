#!/usr/bin/env bash
# Self-test for commit-bypass.sh: an expect/reject payload table. The hook is
# fail-open, so a rule that quietly stops matching looks exactly like a clean
# command — this table is the only thing that tells the two apart. Run it after
# changing any rule: bash global/hooks/commit-bypass-selftest.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/commit-bypass.sh"

fail=0
run() { # run <command-string>; prints exit code
  local payload
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1")"
  printf '%s' "$payload" | bash "$hook" >/dev/null 2>&1; echo $?
}
expect_block() { local rc; rc="$(run "$1")"; if [ "$rc" != 2 ]; then echo "FAIL (should block, rc=$rc): $1"; fail=1; fi; }
expect_allow() { local rc; rc="$(run "$1")"; if [ "$rc" != 0 ]; then echo "FAIL (should allow, rc=$rc): $1"; fail=1; fi; }

# --- bypass shapes: block -----------------------------------------------------
expect_block "git commit --no-verify -m x"
expect_block "git commit -m x --no-verify"
expect_block "git commit -n -m x"
expect_block "git commit -an -m x"
expect_block "git commit -nm x"
expect_block "git commit -a -n"
expect_block "git push --no-verify"
expect_block "git push --no-verify origin main"
expect_block "git -c core.hooksPath=/dev/null commit -m x"
expect_block "git -c core.hooksPath= commit -m x"
expect_block "git -ccore.hooksPath=/tmp/x commit -m x"
expect_block "/usr/bin/git commit --no-verify -m x"
expect_block "cd repo && git commit --no-verify -m x"
expect_block "git add . && git commit -n -m x"
expect_block $'git commit \\\n  --no-verify -m x'             # continuation is one line to the shell
expect_block $'git commit -F - --no-verify <<\'MSG\'\nfix\nMSG'
expect_block $'bash <<EOF\ngit commit --no-verify -m x\nEOF'
# quoted flags are still flags to git
expect_block 'git commit "--no-verify" -m x'
expect_block "git commit '--no-verify' -m x"
expect_block 'git -c "core.hooksPath=/dev/null" commit -m x'
# a shell handed the command as a string runs it
expect_block "bash -c 'git commit --no-verify -m x'"
expect_block 'sh -c "git commit -n -m x"'
expect_block 'eval "git commit --no-verify -m x"'
expect_block 'eval git commit --no-verify -m x'
# the flag arrives through a variable or a pipe
expect_block 'x="--no-verify"; git commit $x -m m'
expect_block 'echo --no-verify | xargs git commit -m x'
# git accepts any unique long-option prefix
expect_block "git commit --no-verif -m x"
expect_block "git commit --no-veri -m x"
expect_block "git push --no-verif"
# git config keys are case-insensitive
expect_block "git -c core.hookspath=/dev/null commit -m x"
expect_block "git -c core.HooksPath=/dev/null commit -m x"
expect_block "git -c core.hooksPath=/dev/null push"
# wrappers
expect_block "env GIT_AUTHOR_NAME=x git commit --no-verify -m x"
expect_block "GIT_AUTHOR_NAME=x git commit -n -m x"
expect_block "sudo git commit --no-verify -m x"

# --- mentions and look-alikes: allow ------------------------------------------
expect_allow "git commit -m x"
expect_allow "git commit -am x"
expect_allow "git commit -F msg.txt"
expect_allow "git commit -m 'never use --no-verify'"
expect_allow 'git commit -m "drop the -n flag"'
expect_allow "echo 'git commit -n is a bypass'"
expect_allow "grep -rn -- '--no-verify' docs/"
expect_allow "git log -n 5"
expect_allow "git log -n5 --oneline"
expect_allow "git diff --name-only"
expect_allow "git config core.hooksPath"
expect_allow "git config --local core.hooksPath scripts/git-hooks"
expect_allow "git commit -m x && git push origin main"
expect_allow "git commit --no-edit --amend"
expect_allow "git commit -s -m x"
expect_allow "git clean -n"
expect_allow "git fetch -n"
expect_allow $'git commit -F - <<\'MSG\'\nAllow --no-verify mention in a body\n\nand git commit -n too.\nMSG'
expect_allow $'cat > notes.md <<EOF\ngit commit --no-verify is blocked\nEOF'
expect_allow "gitlab-runner commit --no-verify"
expect_allow "digit commit -n"
# flags that share a prefix but skip no hook
expect_allow "git merge --no-verify-signatures x"
expect_allow "git pull --no-verify-signatures"
expect_allow "git commit --no-verbose -m x"
# a `-c core.hooksPath=` on a subcommand that runs no hook
expect_allow "git -c core.hooksPath=/x log --oneline"
expect_allow "git -c core.hooksPath=/x config --get core.hooksPath"
# the -n cluster stops at an option that takes a value, and at --
expect_allow "git commit -mnote"
expect_allow "git commit -cn"
expect_allow "git commit -m x -o file -- -n"
expect_allow "git commit -m x -- path-n"
# text inside a string a shell never runs
expect_allow "echo 'bash -c \"git commit --no-verify\"'"
expect_allow "python3 -c 'print(\"git commit --no-verify\")'"

# --- fail-open ----------------------------------------------------------------
for bad in "" "notjson" '{"tool_input":[]}' '{"tool_input":{"command":5}}' '{}'; do
  rc="$(printf '%s' "$bad" | bash "$hook" >/dev/null 2>&1; echo $?)"
  [ "$rc" = 0 ] || { echo "FAIL: malformed payload '$bad' must allow (rc=$rc)"; fail=1; }
done
# an unterminated quote is a tokeniser error: fail open, with the breadcrumb
out="$(printf '%s' '{"tool_input":{"command":"git commit -m \"unterminated --no-verify"}}' | bash "$hook" 2>&1 >/dev/null; echo "rc=$?")"
printf '%s' "$out" | grep -q 'tokeniser error' || { echo "FAIL: tokeniser error must fail open with a breadcrumb: $out"; fail=1; }
printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL: tokeniser error must allow: $out"; fail=1; }
# stderr names the shape
out="$(printf '%s' '{"tool_input":{"command":"git commit --no-verify -m x"}}' | bash "$hook" 2>&1 >/dev/null)"
printf '%s' "$out" | grep -q 'skips the repo.s hooks (--no-verify)' || { echo "FAIL: block message missing"; fail=1; }

if [ "$fail" -ne 0 ]; then echo "SELFTEST FAIL: commit-bypass"; exit 1; fi
echo "OK: commit-bypass self-test clean — every tabled bypass shape blocked, every mention and look-alike allowed, fail-open holds."
