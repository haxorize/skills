#!/usr/bin/env bash
# Self-test for commit-bypass.sh: an expect/reject payload table. The hook is
# fail-open, so a rule that quietly stops matching looks exactly like a clean
# command — this table is the only thing that tells the two apart. Run it after
# changing any rule: bash global/hooks/commit-bypass-selftest.sh
#
# The run/expect helpers are selftest-lib.sh beside this file. This table is also
# where hook-lib.sh and hook-lib.py are graded (scripts/mutation-sweep.sh pairs
# them with the hook selftests): the "scanner shapes" rows below each pin one
# alternative of a lib roster, the fail-open section pins the lib's
# empty-payload breadcrumb, and the mutation table at the end grades the lib's
# script-file read (a shell given a script file reads its pipe as data), its
# here-string read, its `<<\EOF` delimiter, its command-substitution lift
# (`$(…)` and backticks), hook-lib.sh's `python3 -I`, and
# this hook's skip of git's separate-word option values.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/commit-bypass.sh"
# Temp-file template and guard: scripts/README.md § Temp files. Spelled out
# rather than selftest_tmpdir, which both selftest libs below now provide:
# this block runs before either is sourced and has not moved yet.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/commit-bypass-selftest.XXXXXX" 2>/dev/null)"
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
  echo "commit-bypass-selftest: no usable temp directory (TMPDIR=${TMPDIR:-unset}) — nothing ran" >&2
  exit 4
fi
trap 'rm -rf "$tmp"' EXIT

# selftest-lib.sh sources scripts/selftest-lib.sh (selftest_mutate,
# selftest_expect_killed); the path named here is what queues this selftest
# when that file is staged (pre-commit's queue_hook_selftests_naming).
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
# the & in a redirection operator (2>&1, >&2, &>file) is not a separator
expect_block "$D" "git commit -m x 2>&1 --no-verify"
expect_block "$D" "git commit -m x >&2 --no-verify"
expect_block "$D" "git commit -m x &>log --no-verify"
expect_block "$D" "git commit -m x &>>log --no-verify"
expect_block "$D" 'echo \>& git commit --no-verify -m x'                     "an escaped > leaves its & a background separator"
expect_block "$D" 'echo \>|git commit -n -m x'                                "an escaped > leaves its | a pipe"
expect_allow "$D" 'echo \\>& git commit -n -m x'                             "an escaped backslash leaves the >& a redirection"
expect_allow "$D" "echo '>&' git commit -n -m x"                               "a quoted >& is text"
expect_block "$D" "sleep 1 & git commit --no-verify"                           "a bare background & separates"
expect_block "$D" "git commit -m x >| log --no-verify"                         "the | of >| is a redirection, not a pipe"
expect_block "$D" "git commit -m x 2> >(cat) --no-verify"                      "a >(…) process substitution is one word"
expect_block "$D" "git commit -m x < <(true) --no-verify"                      "a <(…) process substitution is one word"
expect_block "$D" "cat <(git commit --no-verify -m x)"                         "a process substitution's body runs"
# a command substitution is one word to its command, and its body runs on its own
expect_block "$D" 'git commit $(true) --no-verify'                             "a \$(…) mid-command is one word"
expect_block "$D" 'git commit `true` --no-verify'                              "a backtick mid-command is one word"
expect_block "$D" 'git commit -m "$(date)" --no-verify'                        "a quoted \$(…) message is one word"
expect_block "$D" 'echo "$(git commit --no-verify)"'                           "a \$(…) body inside double quotes runs"
expect_block "$D" 'echo "`git commit -n -m x`"'                                "a backtick body inside double quotes runs"
expect_block "$D" 'x=$(git commit -n -m x)'                                    "a \$(…) body in an assignment runs"
expect_block "$D" 'echo $(echo $(git commit -n -m x))'                         "a nested \$(…) body runs"
expect_block "$D" 'echo "$(echo ")") $(git commit -n -m x)"'                   "a quoted ) inside a body does not close it"
expect_block "$D" 'echo $(echo ")"; git commit -n -m x)'                       "a quoted ) inside a body leaves the rest of the body in it"
expect_block "$D" "echo \"it's \$(git commit -n -m x)\""                        "a ' inside double quotes is text, not a quote"
expect_block "$D" 'echo $((1 + 2)) && git commit -n -m x'                      "arithmetic \$((…)) is not a substitution"
expect_allow "$D" "echo '\$(git commit --no-verify)'"                          "a single-quoted \$(…) is text"
expect_allow "$D" "echo '\`git commit -n -m x\`'"                              "a single-quoted backtick is text"
expect_allow "$D" 'echo "\$(git commit --no-verify)"'                          "an escaped \$ inside double quotes is text"
# a redirection in command position is not the program
expect_block "$D" ">x git commit --no-verify"                                  "an attached redirection before the program"
expect_block "$D" "> x git commit --no-verify"                                 "a detached redirection and its target before the program"
expect_block "$D" "true &&>x git commit --no-verify"                           "&&>x: an and-list, then a redirection"
expect_block "$D" "2>&1 >x FOO=1 git commit -n -m x"                           "redirections around an assignment"
expect_block "$D" "FOO=1 >x git commit -n -m x"                                "a redirection after an assignment"
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
# scanner shapes: one row per hook-lib.py roster alternative no other row reaches
expect_block "$D" $'dash <<EOF\ngit commit --no-verify -m x\nEOF'            "a heredoc fed to dash (SHELL roster)"
expect_block "$D" $'cat <<EOF | bash\ngit commit --no-verify -m x\nEOF'       "a shell word ending the heredoc line (SHELL's \$ arm)"
expect_block "$D" '"$(command -v git)" commit --no-verify -m x'                "\$(command -v git) resolves to git"
expect_block "$D" "true;(git commit --no-verify -m x)"                         "a mixed punctuation run ';(' splits"
# a string piped into a shell runs unless the shell was given a script file to run instead
expect_allow "$D" "printf 'git commit --no-verify -m x' | bash hook.sh"         "a script file reads the pipe as data"
expect_allow "$D" "printf 'git commit --no-verify -m x' | bash -e -o pipefail hook.sh" "options before the script file"
expect_block "$D" "printf 'git commit --no-verify -m x' | bash -s"              "-s reads commands from the pipe"
expect_block "$D" "printf 'git commit --no-verify -m x' | bash -s hook.sh"      "-s with an argument still reads the pipe"
expect_block "$D" "printf 'git commit --no-verify -m x' | bash /dev/stdin"      "/dev/stdin is the pipe"
expect_block "$D" "printf 'git commit --no-verify -m x' | bash -"               "- is the pipe"
expect_block "$D" "printf 'git commit --no-verify -m x' | bash -o pipefail"     "-o takes a value, not a script"
expect_block "$D" "printf 'git commit --no-verify -m x' | bash --rcfile r"      "--rcfile takes a value, not a script"
expect_block "$D" "printf 'git commit --no-verify -m x' | bash \"\$X\""          "an operand the scanner cannot expand may be empty"
expect_block "$D" 'bash <<< "git commit --no-verify -m x"'                    "a here-string into a shell is its commands"
expect_block "$D" 'bash <<<"git commit -n -m x"'                               "a here-string attached to <<<"
expect_allow "$D" 'bash hook.sh <<< "git commit --no-verify -m x"'             "a here-string into a script file is its input"
expect_allow "$D" 'cat <<< "git commit --no-verify -m x"'                      "a here-string into a program that is not a shell"
expect_block "$D" $'cat <<\\EOF > notes.txt\ndon\'t\nEOF\ngit commit -n -m x'      "a backslash-quoted heredoc delimiter, an apostrophe in the body"
# the separate-word forms of git's value-taking options are skipped to reach the subcommand
expect_block "$D" "git --git-dir .git commit -n -m x"                          "--git-dir as a separate word"
expect_block "$D" "git --work-tree . commit -n -m x"                           "--work-tree as a separate word"
expect_block "$D" "git --git-dir .git -c core.hooksPath=/dev/null commit -m x" "--git-dir before -c core.hooksPath"
expect_block "$D" "git --namespace x -c core.hooksPath=/dev/null commit -m x"  "--namespace before -c core.hooksPath"
expect_allow "$D" "git --git-dir .git log -n 3"                                "--git-dir's value is not the subcommand"

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
# an empty payload is named as such, not as a payload missing its command
out="$( printf '' | bash "$hook" 2>&1 >/dev/null; echo "rc=$?" )"
printf '%s' "$out" | grep -q 'empty payload, allowing' && printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL: an empty payload must allow with its own breadcrumb: $out"; fail=1; }
# a crash in the hook's own Python is named, not mislabelled a tokeniser error
crashed="$tmp/crashed.sh"; cp "$here/hook-lib.sh" "$here/hook-lib.py" "$tmp/"
python3 -c 'import sys; s=open(sys.argv[1]).read(); open(sys.argv[2],"w").write(s.replace("def check_git(args):\n", "def check_git(args):\n    undefined_name\n", 1))' "$hook" "$crashed"
out="$( printf '%s' '{"tool_input":{"command":"git commit -m x"}}' | bash "$crashed" 2>&1 >/dev/null; echo "rc=$?" )"
printf '%s' "$out" | grep -q 'scanner crashed (NameError' && printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL: a scanner crash must allow with its exception named: $out"; fail=1; }
# a module in the session's cwd named like a standard one is never imported (python3 -I)
mkdir -p "$tmp/shadow"
for m in json re shlex os; do printf 'open("%s/PWNED-%s", "w").write("x")\n' "$tmp/shadow" "$m" > "$tmp/shadow/$m.py"; done
payload="$(_payload "$tmp/shadow" "git commit --no-verify -m x")"
rc="$( cd "$tmp/shadow" && printf '%s' "$payload" | bash "$hook" >/dev/null 2>&1; echo $? )"
[ "$rc" = 2 ] || { echo "FAIL (should block, rc=$rc) [a json.py in the cwd]: git commit --no-verify -m x"; fail=1; }
! ls "$tmp/shadow"/PWNED-* >/dev/null 2>&1 || { echo "FAIL: a module in the cwd ran as code: $(ls "$tmp/shadow")"; fail=1; }
# stderr names the shape
out="$(printf '%s' '{"tool_input":{"command":"git commit --no-verify -m x"}}' | bash "$hook" 2>&1 >/dev/null)"
printf '%s' "$out" | grep -q 'skips the repo.s hooks (--no-verify)' || { echo "FAIL: block message missing"; fail=1; }

# --- mutation table: hook-lib.py's script-file read ------------------------------
# Each row edits a copy of hook-lib.py (the hook beside it) and reruns one row;
# the row must pass on the real hook and flip on the mutant, or it grades
# nothing.
mdir="$tmp/mut"; mkdir -p "$mdir"; cp "$hook" "$here/hook-lib.sh" "$mdir/"
lib_mutant() { # lib_mutant <label> <find> <replace> <cmd> <want rc>
  selftest_mutate "$here/hook-lib.py" "$mdir/hook-lib.py" "$2" "$3" || return
  selftest_expect_killed --mutant hook "$mdir/commit-bypass.sh" "$1" hook_rc_not "$5" "$D" "$4"
}
lib_mutant "never a script file"   'if runs_script_file(seg):' 'if False:' "printf 'git commit --no-verify -m x' | bash hook.sh" 2
lib_mutant "drop the stdin paths"  'return not (t in STDIN_SCRIPTS or ' 'return not (' "printf 'git commit --no-verify -m x' | bash /dev/stdin" 0
lib_mutant "drop the -s check"     '                return False        # -s: commands come from stdin' '                pass' "printf 'git commit --no-verify -m x' | bash -s hook.sh" 0
lib_mutant "no value-taking options" 'k += 2 if SHELL_VALUE_OPTS.match(t) else 1' 'k += 1' "printf 'git commit --no-verify -m x' | bash -o pipefail" 0
lib_mutant "no here-string read"   'body = seg[k + 1] if t == "<<<"' 'body = "" if True' 'bash <<< "git commit --no-verify -m x"' 0
lib_mutant "no backslash delimiter" '<<-?\s*\\?[' '<<-?\s*[' $'cat <<\\EOF > notes.txt\ndon\'t\nEOF\ngit commit -n -m x' 0
lib_mutant "an unexpandable operand is a script" 'any(c in t for c in "$`<>")' 'any(c in t for c in "<>")' "printf 'git commit --no-verify -m x' | bash \"\$X\"" 0
# the tokeniser's redirection operators, one alternative at a time
lib_mutant "the & of >& separates"  'elif c in "<>" and nxt == "&":' 'elif False:' "git commit -m x 2>&1 --no-verify" 0
lib_mutant "the & of &> separates"  'elif c == "&" and nxt == ">":' 'elif False:' "git commit -m x &>log --no-verify" 0
lib_mutant "an escaped > is a redirection" 'if c == "\\":' 'if False:' 'echo \>& git commit --no-verify -m x' 0
lib_mutant "the | of >| pipes"      'elif c == ">" and nxt == "|":' 'elif False:' "git commit -m x >| log --no-verify" 0
lib_mutant "a process substitution splits" 'elif c in "<>" and nxt == "(":' 'elif False:' "git commit -m x 2> >(cat) --no-verify" 0
lib_mutant "a process substitution body is dropped" '        out += ["\n", "("] + b + [")"]' '        pass' "cat <(git commit --no-verify -m x)" 0
lib_mutant "a leading redirection is the program" '        k = skip_redirs(seg, k)' '        pass' ">x git commit --no-verify" 0
lib_mutant "a detached target is the program" 'k += 1 if m.group(2) else 2' 'k += 1' "> x git commit --no-verify" 0
# the command-substitution lift, one alternative and one boundary at a time
lib_mutant "a \$(…) is not lifted"    '        elif text.startswith("$(", i):' '        elif False:' 'git commit $(true) --no-verify' 0
lib_mutant "a backtick is not lifted" '        elif c == "`":' '        elif False:' 'echo "`git commit -n -m x`"' 0
lib_mutant "a substitution body is dropped" 'return "".join(out) + "".join(' 'return "".join(out) or "".join(' 'echo "$(git commit --no-verify)"' 0
lib_mutant "a ' inside double quotes opens a span" 'elif c == "\x27" and not dq:' 'elif c == "\x27":' "echo \"it's \$(git commit -n -m x)\"" 0
lib_mutant "a single-quoted \$(…) is lifted" 'elif c == "\x27" and not dq:' 'elif False:' "echo '\$(git commit --no-verify)'" 2
lib_mutant "an escaped \$ is lifted"  '            out.append(text[i:i + 2]); i += 2' '            out.append(c); i += 1' 'echo "\$(git commit --no-verify)"' 2
lib_mutant "a quoted ) closes a body" '            k = skip_dquoted(text, k + 1)' '            k += 1' 'echo $(echo ")"; git commit -n -m x)' 0
# hook-lib.sh's isolated Python, and the hook's own value-option skip, on copies beside the real lib
sdir="$tmp/mut-sh"; mkdir -p "$sdir"; cp "$hook" "$here/hook-lib.py" "$sdir/"
# row_no_cwd_module: green when the hook, run from the shadow dir, imported
# none of the cwd's modules.
row_no_cwd_module() {
  rm -f "$tmp/shadow"/PWNED-*
  ( cd "$tmp/shadow" && printf '%s' "$payload" | bash "$hook" >/dev/null 2>&1 )
  ! ls "$tmp/shadow"/PWNED-* >/dev/null 2>&1
}
selftest_mutate "$here/hook-lib.sh" "$sdir/hook-lib.sh" "python3 -I -c" "python3 -c" 2 \
  && selftest_expect_killed --mutant hook "$sdir/commit-bypass.sh" "no -I" row_no_cwd_module
cp "$here/hook-lib.sh" "$sdir/"
selftest_mutate "$hook" "$sdir/commit-bypass.sh" 'if a in GIT_VALUE_OPTS:      # its value' 'if a in ("-c", "-C", "--config-env"):      # its value' \
  && selftest_expect_killed --mutant hook "$sdir/commit-bypass.sh" "three value options" hook_rc_not 0 "$D" "git --git-dir .git commit -n -m x"

if [ "$fail" -ne 0 ]; then echo "SELFTEST FAIL: commit-bypass"; exit 1; fi
echo "OK: commit-bypass self-test clean — every tabled bypass shape blocked, every mention and look-alike allowed, fail-open holds."
