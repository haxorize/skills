#!/usr/bin/env bash
# Self-test for rename-safety.sh: an expect/reject payload table. The hook is
# fail-open, so a rule that quietly stops matching looks exactly like a clean
# command — this table is the only thing that tells the two apart. Run it after
# changing any rule: bash global/hooks/rename-safety-selftest.sh
#
# The run/expect helpers are selftest-lib.sh beside this file.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/rename-safety.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
opted="$tmp/opted"; plain="$tmp/plain"
mkdir -p "$opted/.claude" "$opted/deep" "$plain"; touch "$opted/.claude/rename-safety"

. "$here/selftest-lib.sh"
export HOME="$tmp"            # the opt-in walk stops at $HOME; nothing outside the sandbox is read

# --- in-place shapes: block ---------------------------------------------------
expect_block "$opted" "sed -i 's/a/b/' f.txt"
expect_block "$opted" "sed -i'' 's/a/b/' f.txt"
expect_block "$opted" "sed -i.bak 's/a/b/' f.txt"
expect_block "$opted" "sed --in-place=.bak 's/a/b/' f.txt"
expect_block "$opted" "sed -E -i 's/a/b/' f.txt"
expect_block "$opted" "sed -n -i 's/a/b/' f.txt"
expect_block "$opted" "sed -Ei 's/a/b/' f.txt"
expect_block "$opted" "gsed -i 's/a/b/' f.txt"
expect_block "$opted" "/usr/bin/sed -i 's/a/b/' f.txt"
expect_block "$opted" "x=\$(sed -i 's/a/b/' f.txt)"
expect_block "$opted" "cd src && sed -i 's/a/b/' f.txt"
expect_block "$opted" $'grep -l a *.md\nsed -i \'s/a/b/\' *.md'
expect_block "$opted" "find . -name '*.md' -exec sed -i 's/a/b/' {} +"
expect_block "$opted" $'sed \\\n  -i \'s/a/b/\' f.txt'          # backslash-newline continuation is one line to the shell
expect_block "$opted" "sudo sed -i 's/a/b/' /etc/hosts"
expect_block "$opted" "perl -pi -e 's/a/b/' *.md"
expect_block "$opted" "perl -i -pe 's/a/b/' f.txt"
expect_block "$opted" "perl -pi.bak -e 's/a/b/' f.txt"
expect_block "$opted" "ruby -pi -e 'gsub(/a/,\"b\")' f.txt"
expect_block "$opted" "grep -rl a . | xargs sed -i 's/a/b/'"
expect_block "$opted" "find . -name '*.py' -print0 | xargs -0 sed -i '' 's/a/b/'"
expect_block "$opted" "ls | xargs -I{} sed -i 's/a/b/' {}"
expect_block "$opted" "git ls-files | xargs perl -pi -e 's/a/b/'"
expect_block "$opted" "ls | xargs -n 1 gsed -i 's/a/b/'"
# the flag reaches sed through a shell string, a quote, a variable, or a wrapper
expect_block "$opted" "bash -c 'sed -i s/a/b/ f.txt'"
expect_block "$opted" 'sh -c "perl -pi -e s/a/b/ f.txt"'
expect_block "$opted" "bash -lc 'sed -i s/a/b/ f.txt'"
expect_block "$opted" 'eval "sed -i s/a/b/ f.txt"'
expect_block "$opted" 'eval sed -i s/a/b/ f.txt'
expect_block "$opted" "sed '-i' 's/a/b/' f.txt"
expect_block "$opted" 'sed "-i" s/a/b/ f.txt'
expect_block "$opted" 'f=-i; sed $f s/a/b/ f.txt'
expect_block "$opted" "timeout 30 sed -i 's/a/b/' f.txt"
expect_block "$opted" "{ sed -i 's/a/b/' f.txt; }"
expect_block "$opted" "if true; then sed -i 's/a/b/' f.txt; fi"
expect_block "$opted" "perl -Mstrict -i -pe 's/a/b/' f.txt"
expect_block "$opted" "printf 'f.txt' | xargs sed -i 's/a/b/'"
expect_block "$opted" "find . -name '*.md' -exec sed -i 's/a/b/' {} \\;"           "find -exec terminated by \\;"
expect_block "$opted" "find . -exec true {} + -exec sed -i 's/a/b/' {} +"          "second -exec clause"
expect_block "$opted" "find . -exec true {} \\; -exec sed -i 's/a/b/' {} \\;"       "second -exec clause after \\;"
expect_allow "$opted" "find . -exec sed -n 1p {} \\; -exec echo -i {} \\;"        "\\; ends the clause before the next program's -i"
expect_block "$opted" "find . -name '*.md' -execdir sed -i 's/a/b/' {} +"          "find -execdir"
expect_block "$opted" "ls | xargs -I {} sed -i 's/a/b/' {}"                        "detached -I {}"
expect_block "$opted" "ls | xargs -L 1 sed -i 's/a/b/'"                            "detached -L 1"
expect_block "$opted" "\$(which sed) -i 's/a/b/' f.txt"                            "\$(which sed)"
expect_block "$opted" "env -S 'sed -i s/a/b/ f.txt'"                               "env -S string"
expect_block "$opted" "printf 'sed -i s/a/b/ f.txt' | bash"                        "string piped into a shell"
expect_block "$opted" "sed -i \$'s/\\'/x/' f.txt"                                  "ANSI-C quoted expression with an escaped quote"
expect_block "$opted" "sed \$'-i' 's/a/b/' f.txt"                                  "ANSI-C quoted flag"
expect_block "$opted" "sed -i 's/a/b/' f.txt # read only"                          "comment after the command"
expect_block "$opted" "sed -l -i '' 's/a/b/' f.txt"                                "BSD sed -l takes no value"
expect_block "$opted" "perl -l -pi -e 's/a/b/' f.txt"                              "perl -l takes no next token"
expect_block "$opted" "perl -C -i -pe 's/a/b/' f.txt"                              "perl -C takes only an attached value"
expect_block "$opted" "ruby -K -i -pe 'gsub(/a/,\"b\")' f.txt"                   "ruby -K takes only an attached value"
expect_block "$opted" 'x=-i; bash -c "sed $x s/a/b/ f.txt"'                         "variable inside a bash -c string"
expect_block "$opted" 'declare f=-i; sed $f s/a/b/ f.txt'                           "declare assignment"
expect_block "$opted" 'local f=-i; sed $f s/a/b/ f.txt'                             "local assignment"
expect_block "$opted" 'f=-i; sed ${f:-} s/a/b/ f.txt'                               "\${f:-} form"
expect_block "$opted" "if sed -i 's/a/b/' f.txt; then :; fi"                       "the if condition runs"
expect_block "$opted" "while sed -i 's/a/b/' f.txt; do :; done"                    "the while condition runs"
expect_block "$opted" "! sed -i 's/a/b/' f.txt"                                    "negated command"
expect_block "$opted" "git commit -m fi; sed -i 's/a/b/' f.txt"                    "a reserved word mid-segment is a word"
expect_block "$opted" "busybox sed -i 's/a/b/' f.txt"                              "busybox wrapper"
expect_block "$opted" "caffeinate -t 600 sed -i 's/a/b/' f.txt"                    "caffeinate with a value-taking option"

# --- reads and mentions: allow ------------------------------------------------
expect_allow "$opted" "sed -n '1,5p' f.txt"
expect_allow "$opted" "sed -e 's/i/x/' f.txt"
expect_allow "$opted" "sed -E 's/i/x/' f.txt"
expect_allow "$opted" "grep -i foo f.txt"
expect_allow "$opted" "grep 'sed -i' f.txt"
expect_allow "$opted" "echo \"use sed -i\""
expect_allow "$opted" "git commit -m 'drop the sed -i call'"
expect_allow "$opted" "ls | xargs grep foo | sed 's/x/y/'"
expect_allow "$opted" "ls | xargs wc -l | sed -n '1p'"
expect_allow "$opted" "ls | xargs grep x; sed -n 1p f"
expect_allow "$opted" "ls | xargs echo sed foo"
expect_allow "$opted" "ls | xargs sed -n 1p"
expect_allow "$opted" "perl -ne 'print if /a/' f.txt"
expect_allow "$opted" "perl -e 'print 1'"
expect_allow "$opted" "python3 -c 'import sys'"
expect_allow "$opted" "sedlike -i x"
expect_allow "$opted" "perl -Mstrict -e 'print 1'"                  # the i in strict is a module name, not a flag
expect_allow "$opted" "perl -e '-i'"                                # -e takes the next token as its value
expect_allow "$opted" "sed -e '-i' f.txt"
expect_allow "$opted" "sed -f script.sed f.txt"
expect_allow "$opted" "sed -l 5 's/i/x/' f.txt"                                    # GNU -l takes a value, but a value is not a flag
expect_allow "$opted" "ls -i | xargs sed -n 1p f.txt"                              # a producer's flags are not what it feeds
expect_allow "$opted" "python3 -c 'import os; os.system(\"sed -i s/a/b/ f\")'"   # a string another program builds is not scanned
expect_allow "$opted" "ls -i"
expect_allow "$opted" $'git commit -F - <<\'MSG\'\nDrop the sed -i call\n\nIt no-ops on BSD.\nMSG'
expect_allow "$opted" $'cat > notes.md <<EOF\nnever run sed -i blind\nEOF'
expect_allow "$opted" $'cat <<-EOF | tee handoff.md\n\tuse perl -pi only with a file list\n\tEOF'
expect_allow "$opted" $'ls | xargs -I{} sh -c \'python3 -c "f=open(\\"{}\\"); print(\\"sed -i\\" in f.read())"\'; grep -rn "sed -i\\|xargs perl" notes.md'
expect_allow "$opted" 'echo "she said \"use sed -i\" twice"'
expect_block "$opted" $'bash <<EOF\nsed -i s/a/b/ *.md\nEOF'
expect_block "$opted" $'sh <<\'EOF\'\nperl -pi -e s/a/b/ f\nEOF'
expect_block "$opted" $'cat <<EOF > x.md\nnote\nEOF\nsed -i s/a/b/ x.md'
expect_block "$opted" $'bash \\\n<<EOF\nsed -i s/a/b/ *.md\nEOF'              # continuation before the << is still a shell-fed heredoc
expect_allow "$opted" $'cat > n.md <<EOF\nline ends \\\nsed -i s/a/b/ x\nEOF'  # a body line ending in a backslash is still body

# --- opt-in and fail-open ----------------------------------------------------
rc="$(run "$plain" "sed -i 's/a/b/' f.txt")"; [ "$rc" = 0 ] || { echo "FAIL: non-opted dir should allow (rc=$rc)"; fail=1; }
rc="$(run "$opted/deep" "sed -i 's/a/b/' f.txt")"; [ "$rc" = 2 ] || { echo "FAIL: subdir of opted dir should block (rc=$rc)"; fail=1; }
RENAME_SAFETY_DIRS="$plain" expect_block "$plain" "sed -i 's/a/b/' f.txt"   "RENAME_SAFETY_DIRS opts in"
RENAME_SAFETY_DIRS=":" expect_allow "$plain" "sed -i 's/a/b/' f.txt"        "empty RENAME_SAFETY_DIRS element opts in nothing"
RENAME_SAFETY_DIRS=":$opted" expect_allow "$plain" "sed -i 's/a/b/' f.txt"  "leading colon does not opt in \$plain"
# the directory a cd moved to is the one judged
expect_block "$plain" "cd ../opted && sed -i 's/a/b/' f.txt"               "cd into an opted dir"
expect_allow "$opted" "cd ../plain && sed -i 's/a/b/' f.txt"               "cd out of an opted dir"
expect_block "$opted" "cd ../nope && sed -i 's/a/b/' f.txt"                "cd to a missing dir falls back to cwd"
expect_block "$opted" 'cd "$X" && sed -i s/a/b/ f.txt'                      "unexpandable cd falls back to cwd"
# payload cwd wins over the process directory
payload="$(python3 -c 'import json,sys; print(json.dumps({"cwd":sys.argv[1],"tool_input":{"command":"sed -i s/a/b/ f"}}))' "$opted")"
rc="$( cd "$plain" && printf '%s' "$payload" | HOME="$tmp" bash "$hook" >/dev/null 2>&1; echo $? )"
[ "$rc" = 2 ] || { echo "FAIL: payload cwd in opted dir should block (rc=$rc)"; fail=1; }
expect_fail_open "$opted" 'sed -i "unterminated s/a/b/ f'
# a payload cwd that is not a directory fails open with a breadcrumb, not a block
payload="$(python3 -c 'import json,sys; print(json.dumps({"cwd":sys.argv[1],"tool_input":{"command":"sed -i s/a/b/ f"}}))' "$tmp/nonexistent")"
out="$( cd "$opted" && printf '%s' "$payload" | HOME="$tmp" bash "$hook" 2>&1 >/dev/null; echo "rc=$?" )"
printf '%s' "$out" | grep -q 'unreadable, allowing' || { echo "FAIL: nonexistent payload cwd must fail open with a breadcrumb: $out"; fail=1; }
printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL: nonexistent payload cwd must allow: $out"; fail=1; }
# a newline in the payload cwd cannot splice into the command
payload="$(python3 -c 'import json,sys; print(json.dumps({"cwd":sys.argv[1],"tool_input":{"command":"sed -i s/a/b/ f"}}))' "$opted"$'\n'"x")"
rc="$( cd "$opted" && printf '%s' "$payload" | HOME="$tmp" bash "$hook" >/dev/null 2>&1; echo $? )"
[ "$rc" = 0 ] || { echo "FAIL: a newline in cwd is an unreadable directory, not a block (rc=$rc)"; fail=1; }
# run by bare name from its own directory, the hook still finds its lib
rc="$( cd "$here" && printf '%s' "$(python3 -c 'import json,sys; print(json.dumps({"cwd":sys.argv[1],"tool_input":{"command":"sed -i s/a/b/ f"}}))' "$opted")" | HOME="$tmp" bash rename-safety.sh >/dev/null 2>&1; echo $? )"
[ "$rc" = 2 ] || { echo "FAIL: bare-name invocation should still block (rc=$rc)"; fail=1; }
# a hook copied without its lib allows with a breadcrumb, never dies
cp "$hook" "$tmp/lonely.sh"
out="$( cd "$opted" && printf '%s' '{"tool_input":{"command":"sed -i s/a/b/ f"}}' | bash "$tmp/lonely.sh" 2>&1 >/dev/null; echo "rc=$?" )"
printf '%s' "$out" | grep -q 'hook-lib.sh not found' && printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL: a hook without its lib must allow with a breadcrumb: $out"; fail=1; }
# stderr names the shape and the path-shaped argument
out="$( cd "$opted" && printf '%s' '{"tool_input":{"command":"sed -i s/a/b/ notes.md"}}' | HOME="$tmp" bash "$hook" 2>&1 >/dev/null )"
printf '%s' "$out" | grep -q 'blocked an in-place mass edit (sed -i)' || { echo "FAIL: block message missing"; fail=1; }
printf '%s' "$out" | grep -q '    notes.md' || { echo "FAIL: path-shaped argument notes.md not listed"; fail=1; }
printf '%s' "$out" | grep -qE '^    s/a/b' && { echo "FAIL: sed expression listed as a path"; fail=1; }

if [ "$fail" -ne 0 ]; then echo "SELFTEST FAIL: rename-safety"; exit 1; fi
echo "OK: rename-safety self-test clean — every in-place shape blocked, every read and mention allowed, opt-in and fail-open hold."
