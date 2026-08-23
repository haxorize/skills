#!/usr/bin/env bash
# Self-test for commit-bypass.sh: an expect/reject payload table. The hook is
# fail-open, so a rule that quietly stops matching looks exactly like a clean
# command — this table is the only thing that tells the two apart. Run it after
# changing any rule: bash global/hooks/commit-bypass-selftest.sh
#
# The run/expect helpers are selftest-lib.sh beside this file.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/commit-bypass.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

. "$here/selftest-lib.sh"
D="$PWD"

# --- bypass shapes: block -----------------------------------------------------
expect_block "$D" "git commit --no-verify -m x"
expect_block "$D" "git commit -m x --no-verify"
expect_block "$D" "git commit -n -m x"
expect_block "$D" "git commit -an -m x"
expect_block "$D" "git commit -nm x"
expect_block "$D" "git commit -a -n"
expect_block "$D" "git push --no-verify"
expect_block "$D" "git push --no-verify origin main"
expect_block "$D" "git -c core.hooksPath=/dev/null commit -m x"
expect_block "$D" "git -c core.hooksPath= commit -m x"
expect_block "$D" "git -ccore.hooksPath=/tmp/x commit -m x"
expect_block "$D" "/usr/bin/git commit --no-verify -m x"
expect_block "$D" "cd repo && git commit --no-verify -m x"
expect_block "$D" "git add . && git commit -n -m x"
expect_block "$D" $'git commit \\\n  --no-verify -m x'             # continuation is one line to the shell
expect_block "$D" $'git commit -F - --no-verify <<\'MSG\'\nfix\nMSG'
expect_block "$D" $'bash <<EOF\ngit commit --no-verify -m x\nEOF'
# quoted flags are still flags to git
expect_block "$D" 'git commit "--no-verify" -m x'
expect_block "$D" "git commit '--no-verify' -m x"
expect_block "$D" 'git -c "core.hooksPath=/dev/null" commit -m x'
# a shell handed the command as a string runs it
expect_block "$D" "bash -c 'git commit --no-verify -m x'"
expect_block "$D" 'sh -c "git commit -n -m x"'
expect_block "$D" 'eval "git commit --no-verify -m x"'
expect_block "$D" 'eval git commit --no-verify -m x'
# the flag arrives through a variable or a pipe
expect_block "$D" 'x="--no-verify"; git commit $x -m m'
expect_block "$D" 'echo --no-verify | xargs git commit -m x'
# git accepts any unique long-option prefix
expect_block "$D" "git commit --no-verif -m x"
expect_block "$D" "git commit --no-veri -m x"
expect_block "$D" "git push --no-verif"
# git config keys are case-insensitive
expect_block "$D" "git -c core.hookspath=/dev/null commit -m x"
expect_block "$D" "git -c core.HooksPath=/dev/null commit -m x"
expect_block "$D" "git -c core.hooksPath=/dev/null push"
# wrappers
expect_block "$D" "env GIT_AUTHOR_NAME=x git commit --no-verify -m x"
expect_block "$D" "GIT_AUTHOR_NAME=x git commit -n -m x"
expect_block "$D" "sudo git commit --no-verify -m x"
expect_block "$D" "timeout 30 git commit --no-verify -m x"
expect_block "$D" "nice git commit -n -m x"
expect_block "$D" "bash -lc 'git commit --no-verify -m x'"
# compound forms
expect_block "$D" "{ git commit --no-verify -m x; }"
expect_block "$D" "if true; then git commit --no-verify -m x; fi"
expect_block "$D" "find . -name '*.c' -exec git commit --no-verify -m x {} +"
expect_block "$D" 'x=--no-verify; git commit $x -m m'
expect_block "$D" "git commit -m done -n"                                      "a message equal to a reserved word"
expect_block "$D" "git commit -m fi --no-verify"                               "another reserved word as the message"
expect_block "$D" "if git commit --no-verify -m x; then :; fi"                "the if condition runs"
expect_block "$D" "while git commit -n -m x; do :; done"                       "the while condition runs"
expect_block "$D" "! git commit --no-verify -m x"                              "negated command"
expect_block "$D" 'x=--no-verify; bash -c "git commit $x -m m"'                 "variable inside a bash -c string"
expect_block "$D" 'm=msg; bash -c "git commit -m $m --no-verify"'               "variable beside the flag in a bash -c string"
expect_block "$D" 'declare x=--no-verify; git commit $x'                        "declare assignment"
expect_block "$D" 'local x=--no-verify; git commit $x'                          "local assignment"
expect_block "$D" 'typeset -x x=--no-verify; git commit $x'                     "typeset with an option"
expect_block "$D" 'env x=--no-verify bash -c "git commit \$x"'                 "env assignment read by a nested shell"
expect_block "$D" 'x=--no-verify; git commit ${x:-}'                            "\${x:-} form"
expect_block "$D" 'x=--no-verify; git commit "${x[0]}"'                         "\${x[0]} form"
expect_block "$D" "git -c alias.ci='commit --no-verify' ci -m x"               "alias built on the command line"
expect_block "$D" "git -c alias.ci='!git commit -n' ci"                        "shell alias built on the command line"
expect_block "$D" "git --config-env=core.hooksPath=X commit -m x"              "--config-env=core.hooksPath"
expect_block "$D" "git --config-env core.hooksPath=X commit -m x"              "--config-env core.hooksPath"
expect_block "$D" "find . -name '*.c' -exec git commit --no-verify -m x {} \\;" "find -exec terminated by \\;"
expect_block "$D" "echo -n --no-verify | xargs git commit -m x"                "echo -n's flag is not fed"
expect_block "$D" "caffeinate -t 600 git commit -n -m x"                       "caffeinate with a value-taking option"
expect_block "$D" "busybox git commit -n -m x"                                 "busybox wrapper"

# --- mentions and look-alikes: allow ------------------------------------------
expect_allow "$D" "git commit -m x"
expect_allow "$D" "git commit -am x"
expect_allow "$D" "git commit -F msg.txt"
expect_allow "$D" "git commit -m 'never use --no-verify'"
expect_allow "$D" 'git commit -m "drop the -n flag"'
expect_allow "$D" "echo 'git commit -n is a bypass'"
expect_allow "$D" "grep -rn -- '--no-verify' docs/"
expect_allow "$D" "git log -n 5"
expect_allow "$D" "git log -n5 --oneline"
expect_allow "$D" "git diff --name-only"
expect_allow "$D" "git config core.hooksPath"
expect_allow "$D" "git config --local core.hooksPath scripts/git-hooks"
expect_allow "$D" "git commit -m x && git push origin main"
expect_allow "$D" "git commit --no-edit --amend"
expect_allow "$D" "git commit -s -m x"
expect_allow "$D" "git clean -n"
expect_allow "$D" "git fetch -n"
expect_allow "$D" $'git commit -F - <<\'MSG\'\nAllow --no-verify mention in a body\n\nand git commit -n too.\nMSG'
expect_allow "$D" $'cat > notes.md <<EOF\ngit commit --no-verify is blocked\nEOF'
expect_allow "$D" "gitlab-runner commit --no-verify"
expect_allow "$D" "digit commit -n"
# flags that share a prefix but skip no hook
expect_allow "$D" "git merge --no-verify-signatures x"
expect_allow "$D" "git pull --no-verify-signatures"
expect_allow "$D" "git commit --no-verbose -m x"
# a `-c core.hooksPath=` on a subcommand that runs no hook
expect_allow "$D" "git -c core.hooksPath=/x log --oneline"
expect_allow "$D" "git -c core.hooksPath=/x config --get core.hooksPath"
expect_allow "$D" "git --config-env=core.hooksPath=X log --oneline"
expect_allow "$D" "X=--no-verify git commit -m x \$X"                          # a prefix assignment is not yet set when \$X expands
# the -n cluster stops at an option that takes a value, and at --
expect_allow "$D" "git commit -mnote"
expect_allow "$D" "git commit -cn"
expect_allow "$D" "git commit -m x -o file -- -n"
expect_allow "$D" "git commit -m x -- path-n"
# text inside a string a shell never runs
expect_allow "$D" "echo 'bash -c \"git commit --no-verify\"'"
expect_allow "$D" "python3 -c 'print(\"git commit --no-verify\")'"

# --- fail-open ----------------------------------------------------------------
expect_fail_open "$D" 'git commit -m "unterminated --no-verify'
# a crash in the hook's own Python is named, not mislabelled a tokeniser error
crashed="$tmp/crashed.sh"; cp "$here/hook-lib.sh" "$here/hook-lib.py" "$tmp/"
python3 -c 'import sys; s=open(sys.argv[1]).read(); open(sys.argv[2],"w").write(s.replace("def check_git(args):\n", "def check_git(args):\n    undefined_name\n", 1))' "$hook" "$crashed"
out="$( printf '%s' '{"tool_input":{"command":"git commit -m x"}}' | bash "$crashed" 2>&1 >/dev/null; echo "rc=$?" )"
printf '%s' "$out" | grep -q 'scanner crashed (NameError' && printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL: a scanner crash must allow with its exception named: $out"; fail=1; }
# stderr names the shape
out="$(printf '%s' '{"tool_input":{"command":"git commit --no-verify -m x"}}' | bash "$hook" 2>&1 >/dev/null)"
printf '%s' "$out" | grep -q 'skips the repo.s hooks (--no-verify)' || { echo "FAIL: block message missing"; fail=1; }

if [ "$fail" -ne 0 ]; then echo "SELFTEST FAIL: commit-bypass"; exit 1; fi
echo "OK: commit-bypass self-test clean — every tabled bypass shape blocked, every mention and look-alike allowed, fail-open holds."
