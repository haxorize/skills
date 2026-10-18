#!/usr/bin/env bash
# Self-test for rename-safety.sh: an expect/reject payload table, then a
# mutation table. The hook is fail-open, so a rule that quietly stops matching
# looks exactly like a clean command — these rows are the only thing that tells
# the two apart. Run it after changing any rule:
#   bash global/hooks/rename-safety-selftest.sh
#
# The mutation table at the end edits a copy of the hook once per check on the
# allow path (the one-substitution carve-out, the opt-in walk, symlink
# resolution) and requires each mutant to flip the row it names, both ways: a
# narrowed check that stops firing, and a widened one whose clean neighbour
# starts firing.
#
# The run/expect helpers are selftest-lib.sh beside this file.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/rename-safety.sh"
# Temp-file template and guard: scripts/README.md § Temp files. Spelled out
# because the libraries are sourced after this block.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/rename-safety-selftest.XXXXXX" 2>/dev/null)"
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
  echo "rename-safety-selftest: no usable temp directory (TMPDIR=${TMPDIR:-unset}) — nothing ran" >&2
  exit 4
fi
trap 'rm -rf "$tmp"' EXIT
opted="$tmp/opted"; plain="$tmp/plain"
mkdir -p "$opted/.claude" "$opted/deep" "$plain"; touch "$opted/.claude/rename-safety"

# selftest-lib.sh sources scripts/selftest-lib.sh (selftest_mutate,
# selftest_expect_killed); the path named here is what queues this selftest
# when that file is staged (pre-commit's queue_hook_selftests_naming).
. "$here/selftest-lib.sh"
export HOME="$tmp"            # the opt-in walk stops at $HOME; nothing outside the sandbox is read

# --- in-place shapes: block ---------------------------------------------------
expect_block "$opted" "sed -i 's/a/b/' f.txt"
expect_block "$opted" "sed -i'' 's/a/b/' f.txt"
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
# the tokeniser's redirection reads (hook-lib.py): the first five once hid the sed,
# the last pins that a bare background & still separates
expect_block "$opted" "echo \\>& sed -i 's/a/b/' f.txt"                       "an escaped > leaves its & a background separator"
expect_block "$opted" ">x sed -i 's/a/b/' f.txt"                                "a redirection before the program"
expect_block "$opted" "true &&>x sed -i 's/a/b/' f.txt"                         "&&>x: an and-list, then a redirection"
expect_block "$opted" "sed 's/a/b/' f.txt >| log -i"                            "the | of >| is a redirection, not a pipe"
expect_block "$opted" "sed 's/a/b/' f.txt 2> >(cat) -i"                         "a process substitution is one word"
expect_block "$opted" "sleep 1 & sed -i 's/a/b/' f.txt"                         "a bare background & separates"
expect_block "$opted" $'sed \\\n  -i \'s/a/b/\' f.txt'          # backslash-newline continuation is one line to the shell
expect_block "$opted" "perl -pi -e 's/a/b/' *.md"
expect_block "$opted" "perl -i -pe 's/a/b/' f.txt"
expect_block "$opted" "perl -pi.bak -e 's/a/b/' f.txt"
expect_block "$opted" "perl -0pi -e 's/a/b/' f.txt"
expect_block "$opted" "perl -0777 -pi -e 's/a/b/' f.txt"
expect_block "$opted" "perl -l012pi -e 's/a/b/' f.txt"
expect_block "$opted" "ruby -0pi -e 'gsub(/a/,%q(b))' f.txt"
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
expect_block "$opted" "sed -l -i 's/a/b/' f.txt"                                   "BSD sed -l takes no value"
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

# --- one substitution in one listed file, BSD form: allow ---------------------
expect_allow "$opted" "sed -i '' 's/a/b/' f.txt"                                 "BSD empty suffix"
expect_allow "$opted" "sed -i.bak 's/a/b/' f.txt"                                "attached suffix"
expect_allow "$opted" "sed -i '' -e 's|a/b|c|' notes.md"                         "one -e, another delimiter"
expect_allow "$opted" "sed -i '' '3s/a/b/' deep/f.txt"                           "line address"
expect_allow "$opted" "sed -i '' 's/a/b/2I' f.txt"                               "a number and I are the flags that stay"
expect_allow "$opted" "sed -i '' --expression='s/a/b/' f.txt"                    "--expression=<code>"
expect_allow "$opted" "sed -i '' --expression 's/a/b/' f.txt"                    "--expression <code>"
expect_allow "$opted" "cd deep && sed -i '' 's/a/b/' f.txt"                      "after a cd inside the opted dir"
# ... and everything around it still blocks
expect_block "$opted" "sed -i '' 's/a/b/g' f.txt"                                "g flag"
expect_block "$opted" "sed -i '' '3s/a/b/p' deep/f.txt"                          "p flag prints the line twice"
expect_block "$opted" "sed -n -i '' 's/a/b/' f.txt"                              "-n empties the file"
expect_block "$opted" "sed -i '' -n 's/a/b/' f.txt"                              "-n after the suffix"
expect_block "$opted" "sed -En -i '' 's/a/b/' f.txt"                             "-n inside a cluster"
expect_block "$opted" "sed --quiet -i '' 's/a/b/' f.txt"                         "--quiet"
expect_block "$opted" "sed --sil -i '' 's/a/b/' f.txt"                           "--silent abbreviated"
expect_block "$opted" "sed -i '' -f 's:a:b:' f.txt"                              "-f names a script file, whatever its name looks like"
expect_block "$opted" "gsed -i '' 's/a/b/' f.txt"                                "gsed reads '' as the script"
expect_block "$opted" "sed -i '' --expression='s/a/b/g' f.txt"                   "--expression=<code> with a g flag"
expect_block "$opted" "sed -i '' '/x/d;s/a/b/' f.txt"                            "a command before the substitution"
expect_block "$opted" "sed -i '' 's/a/b/' {}"                                    "{} outside find is not a listed file"
NL_EXPR=$'s/a/x\nd\ns/'
expect_block "$opted" "sed -i '' '$NL_EXPR' f.txt"                               "a newline inside the substitution"
expect_block "$opted" "sed --in 's/a/b/' f.txt"                                  "--in abbreviates --in-place"
expect_allow "$opted" "sed --null-data -n 1p f.txt"                              "a long option that is not --in-place"
expect_block "$opted" "sed -i '' 's/a/b/w out.txt' f.txt"                        "w flag writes a second file"
expect_block "$opted" "sed -i '' 's/a/b/' f.txt g.txt"                           "two files"
expect_block "$opted" "sed -i '' -e 's/a/b/' -e 's/c/d/' f.txt"                  "two expressions"
expect_block "$opted" "sed -i '' 's/a/b/; s/c/d/' f.txt"                         "two commands in one expression"
expect_block "$opted" "sed -i '' '/x/d' f.txt"                                   "not a substitution"
expect_block "$opted" "sed -i '' -f script.sed f.txt"                            "script file"
expect_block "$opted" "sed -i '' 's/oldName/newName/' src/*.ts"                  "glob in the repo"
expect_block "$opted" "echo f.txt | xargs sed -i '' 's/a/b/'"                    "file fed by xargs"
expect_block "$opted" "find . -name f.txt -exec sed -i '' 's/a/b/' {} +"         "file fed by find"
expect_block "$opted" "sed -i '' 's/a/b/' \"\$RS_UNSET_VAR/f.txt\""             "unexpandable variable judges the run directory"
expect_block "$opted" "perl -pi -e 's/a/b/' f.txt"                               "perl -i on one file"
expect_block "$opted" "sed -i 's/a/b/' f.txt"                                    "GNU form no-ops on BSD"

# --- every file outside the opted-in directory: allow --------------------------
expect_allow "$opted" "sed -i 's/a/b/g' $plain/f.txt"                           "absolute path outside"
expect_allow "$opted" "sed -i 's/a/b/' ../plain/f.txt"                           "relative path outside"
expect_allow "$opted" "sudo sed -i 's/a/b/' /etc/hosts"                          "system file"
expect_allow "$opted" "perl -pi -e 's/a/b/' ~/notes.md"                          "~ outside the opted dir"
TMPDIR="$plain" expect_allow "$opted" "sed -i '' 's/x/y/' \"\$TMPDIR/claude-handoffs/h.md\""  "\$TMPDIR handoff marker"
expect_block "$opted" "sed -i '' 's/a/b/' $plain/f.txt f.txt"                    "one file outside, one inside"
expect_block "$plain" "sed -i 's/a/b/' $opted/f.txt"                             "file inside, run from outside"
expect_block "$plain" "sed -i 's/a/b/' $opted/*.md"                              "glob whose parent is opted in"
expect_allow "$plain" "sed -i 's/a/b/' *.md"                                     "glob outside, run from outside"
# symlinks: a path is judged where it really lies (~/.claude/skills/<skill> is a link into the checkout)
ln -s "$opted" "$plain/dirlink"; ln -s "$opted/f.txt" "$plain/filelink"
ln -s "$plain/g.txt" "$opted/outlink"; ln -s "$tmp/elsewhere/g.txt" "$plain/outlink"
mkdir -p "$tmp/elsewhere"; ln -s "$plain" "$tmp/plainlink"
expect_block "$plain" "sed -i '' 's/a/b/g' dirlink/f.txt"                        "a directory symlink into the opted dir"
expect_block "$plain" "sed -i '' 's/a/b/g' $plain/dirlink/f.txt"                 "the same, absolute"
expect_block "$plain" "sed -i '' 's/a/b/g' filelink"                             "a file symlink into the opted dir"
expect_block "$plain" "sed -i '' 's/a/b/g' dirlink/outlink"                      "a link inside the opted dir, pointing out"
RENAME_SAFETY_DIRS="$plain" expect_block "$tmp" "sed -i 's/a/b/' plainlink/outlink"  "the name's own directory, resolved, is judged too"
RENAME_SAFETY_DIRS="$tmp/plainlink" expect_block "$plain" "sed -i 's/a/b/' f.txt"   "a RENAME_SAFETY_DIRS entry reached through a link"
RENAME_SAFETY_DIRS="$plain" expect_block "$tmp" "cd plainlink && sed -i 's/a/b/' \"\$RS_UNSET_VAR/f.txt\""  "the run directory, resolved, is judged"

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
mkdir -p "$tmp/foo" "$tmp/foobar"
RENAME_SAFETY_DIRS="$tmp/foo" expect_allow "$tmp/foobar" "sed -i 's/a/b/' f.txt"   "an entry opts in its own tree, not a sibling sharing its prefix"
# the opt-in walk stops at $HOME: a marker above it opts nothing in below it
mkdir -p "$tmp/above/.claude" "$tmp/above/home/proj" "$tmp/above/other"; touch "$tmp/above/.claude/rename-safety"
ln -s "$tmp/above/home" "$tmp/homelink"
HOME="$tmp/homelink" expect_allow "$tmp/above/home/proj" "sed -i 's/a/b/' f.txt"   "a marker above \$HOME (reached through a link) is not read"
HOME="$tmp/homelink" expect_block "$tmp/above/other" "sed -i 's/a/b/' f.txt"       "the same marker opts in a directory outside \$HOME"
# the directory a cd moved to is the one judged
expect_block "$plain" "cd ../opted && sed -i 's/a/b/' f.txt"               "cd into an opted dir"
expect_allow "$opted" "cd ../plain && sed -i 's/a/b/' f.txt"               "cd out of an opted dir"
expect_block "$opted" "cd ../nope && sed -i 's/a/b/' f.txt"                "cd to a missing dir falls back to cwd"
expect_block "$plain" "cd ../opted; echo \"\$(sed -i 's/a/b/' f.txt)\"; cd ../plain" "a \$(…) body runs in the directory in effect where it sits"
expect_allow "$opted" "cd ../plain; echo \"\$(sed -i 's/a/b/' f.txt)\"; cd ../opted" "a later cd does not move a \$(…) body"
expect_block "$opted" 'cd "$X" && sed -i s/a/b/ f.txt'                      "unexpandable cd falls back to cwd"
RS_TARGET="$opted" expect_block "$plain" 'cd "$RS_TARGET" && sed -i s/a/b/ f.txt' "a cd through a variable set in the environment"
expect_crumb "$plain" 'cd "$RS_UNSET_VAR" && sed -i s/a/b/ f.txt' "after a cd the hook cannot expand"   "an unknown cd from a plain cwd is said, not silent"
expect_crumb "$plain" 'cd "$(git rev-parse --show-toplevel)" && sed -i s/a/b/ f.txt' "after a cd the hook cannot expand" "a cd through \$(…)"
expect_quiet "$plain" "cd \"\$RS_UNSET_VAR\" && sed -i s/a/b/ $plain/f.txt"   "an unknown cd before an absolute file judges the file"
# ${X} reads the environment; ${X:-y}, the shell's own PWD, and a name the command rebinds are not expanded
RS_TARGET="$opted" expect_block "$plain" 'cd "${RS_TARGET}" && sed -i s/a/b/ f.txt' "\${X} expands from the environment"
RS_TARGET="$opted" expect_crumb "$plain" 'cd "${RS_TARGET:-x}" && sed -i s/a/b/ f.txt' "after a cd the hook cannot expand" "\${X:-y} is not expanded"
expect_crumb "$plain" 'cd ../opted && cd "$PWD" && sed -i s/a/b/ f.txt' "after a cd the hook cannot expand" "\$PWD is the session shell's, not the hook's"
expect_allow "$opted" 'cd ../plain && sed -i s/a/b/g "$PWD/f.txt"'                "a \$PWD file argument is judged by the run directory"
RS_TARGET="$opted" expect_crumb "$plain" 'unset RS_TARGET; cd "$RS_TARGET" && sed -i s/a/b/ f.txt' "after a cd the hook cannot expand" "a name the command unsets"
RS_TARGET="$opted" expect_crumb "$plain" 'read RS_TARGET < list; cd "$RS_TARGET" && sed -i s/a/b/ f.txt' "after a cd the hook cannot expand" "a name the command reads into"
RS_TARGET="$opted" expect_crumb "$plain" 'for RS_TARGET in x; do cd "$RS_TARGET" && sed -i s/a/b/ f.txt; done' "after a cd the hook cannot expand" "a for loop variable"
# a file named through a variable the command rebinds: judged by the run directory and the value from before the command
RS_TARGET="$opted" expect_block "$plain" 'export RS_TARGET="$RS_TARGET"; sed -i s/a/b/g "$RS_TARGET/f.txt"' "an export rebinding an opted-in variable"
RS_TARGET="$opted" expect_block "$plain" 'for RS_TARGET in "$RS_TARGET"; do sed -i s/a/b/g "$RS_TARGET/f.txt"; done' "a for loop rebinding an opted-in variable"
RS_TARGET="$opted" expect_block "$plain" 'RS_TARGET="$RS_TARGET"; sed -i s/a/b/g "$RS_TARGET/f.txt"' "an assignment rebinding an opted-in variable"
RS_TARGET="$opted" expect_block "$plain" 'export RS_TARGET; sed -i s/a/b/g "$RS_TARGET"/*.txt' "a glob under a rebound opted-in variable"
RS_TARGET="$plain" expect_crumb "$plain" 'export RS_TARGET="$RS_TARGET"; sed -i s/a/b/g "$RS_TARGET/f.txt"' "a variable the command rebinds" "a rebound variable outside an opted-in tree is said, not silent"
RS_TARGET="$plain" expect_crumb "$plain" 'for RS_TARGET in "$RS_TARGET"; do sed -i s/a/b/g "$RS_TARGET/f.txt"; done' "a variable the command rebinds" "a for loop outside an opted-in tree is said"
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
printf '%s' "$out" | grep -q 'blocked an in-place edit (sed -i)' || { echo "FAIL: block message missing"; fail=1; }
printf '%s' "$out" | grep -q 'Use the Edit tool' || { echo "FAIL: block message does not point at the Edit tool"; fail=1; }
printf '%s' "$out" | grep -q '    notes.md' || { echo "FAIL: path-shaped argument notes.md not listed"; fail=1; }
printf '%s' "$out" | grep -qE '^    s/a/b' && { echo "FAIL: sed expression listed as a path"; fail=1; }

# a script file run by a shell reads the pipe as data, not commands
expect_allow "$opted" "printf 'sed -i s/a/b/ f.txt' | bash hook.sh"            "the pipe is the script's input"
expect_block "$opted" "printf 'sed -i s/a/b/ f.txt' | bash -s"                 "-s reads commands from the pipe"

# --- mutation table -------------------------------------------------------------
# Each row edits a copy of the hook (the libs beside it) and reruns one fixture;
# the mutant must flip that row's outcome, or the row above grades nothing.
mdir="$tmp/mut"; mkdir -p "$mdir"; cp "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
mutant() { # mutant <label> <find> <replace> <cwd> <cmd> <want rc>  (env prefixes pass through)
  selftest_mutate "$hook" "$mdir/rename-safety.sh" "$2" "$3" || return
  hook="$mdir/rename-safety.sh" selftest_expect_killed "$1" hook_rc_not "$6" "$4" "$5"
}
mutant "widen the address anchor"  'm = re.match(r"^(?:[0-9]+' 'm = re.match(r"^.*?(?:[0-9]+' "$opted" "sed -i '' '/x/d;s/a/b/' f.txt" 0
mutant "admit the p flag"          're.fullmatch(r"[0-9I]*"' 're.fullmatch(r"[0-9pI]*"' "$opted" "sed -i '' '3s/a/b/p' deep/f.txt" 0
mutant "admit the g flag"          're.fullmatch(r"[0-9I]*"' 're.fullmatch(r"[0-9gI]*"' "$opted" "sed -i '' 's/a/b/g' f.txt" 0
mutant "narrow the flags"          're.fullmatch(r"[0-9I]*"' 're.fullmatch(r"[0-9]*"' "$opted" "sed -i '' 's/a/b/2I' f.txt" 2
mutant "ignore -n"                 'bsd and not quiet and literal' 'bsd and literal' "$opted" "sed -n -i '' 's/a/b/' f.txt" 0
mutant "ignore --quiet"            'elif ch == "n":
                    quiet = True' 'elif ch == "n":
                    pass' "$opted" "sed --quiet -i '' 's/a/b/' f.txt" 0
mutant "-f carries code again"     'CODE = {"sed": set("e"),' 'CODE = {"sed": set("ef"),' "$opted" "sed -i '' -f 's:a:b:' f.txt" 0
mutant "gsed gets the carve-out"   'if (head == "sed" and bsd' 'if (prog == "sed" and bsd' "$opted" "gsed -i '' 's/a/b/' f.txt" 0
mutant "drop --expression code"    '                    if ch == "e":
                        code.append(val)' '                    if False:
                        code.append(val)' "$opted" "sed -i '' --expression='s/a/b/' f.txt" 2
mutant "--expression takes no next token" '                    if not eq and i + 1 < len(args):
                        i += 1
                        val = args[i]
                    if ch == "e":' '                    if ch == "e":' "$opted" "sed -i '' --expression 's/a/b/' f.txt" 2
mutant "drop the {} guard"         'p = None if path == "{}" else expand(path, rebound)' 'p = expand(path, rebound)' "$opted" "sed -i '' 's/a/b/' {}" 0
mutant "drop the newline guard"    '        if e[k] == "\n":
            return False' '        pass' "$opted" "sed -i '' '$NL_EXPR' f.txt" 0
mutant "no long-option abbreviation" 'hits = [n for n in SED_LONG if n.startswith(name)]' 'hits = []' "$opted" "sed --in 's/a/b/' f.txt" 0
mutant "every long option is in place" 'if ch == "i":
                    inplace = True
                elif ch == "n":' 'if True:
                    inplace = True
                elif ch == "n":' "$opted" "sed --null-data -n 1p f.txt" 2
HOME="$tmp/homelink" mutant "drop the HOME stop"   'if walk in ("/", HOME):' 'if walk == "/":' "$tmp/above/home/proj" "sed -i 's/a/b/' f.txt" 2
HOME="$tmp/homelink" mutant "HOME unresolved"      'HOME = os.path.realpath(os.environ.get("HOME") or "/")' 'HOME = os.path.normpath(os.environ.get("HOME") or "/")' "$tmp/above/home/proj" "sed -i 's/a/b/' f.txt" 2
RENAME_SAFETY_DIRS="$tmp/foo" mutant "lose the prefix boundary" 'd.startswith(r.rstrip("/") + "/")' 'd.startswith(r.rstrip("/"))' "$tmp/foobar" "sed -i 's/a/b/' f.txt" 2
RENAME_SAFETY_DIRS="$tmp/plainlink" mutant "DIRS entry unresolved" 'r = os.path.realpath(r) if r else ""' 'r = os.path.normpath(r) if r else ""' "$plain" "sed -i 's/a/b/' f.txt" 0
mutant "file symlink unresolved"   'return {os.path.dirname(os.path.realpath(p)), ' 'return {os.path.dirname(p), ' "$plain" "sed -i '' 's/a/b/g' filelink" 0
RENAME_SAFETY_DIRS="$plain" mutant "name directory unresolved" ', os.path.realpath(os.path.dirname(p))}' ', os.path.dirname(p)}' "$tmp" "sed -i 's/a/b/' plainlink/outlink" 0
# hook-lib.sh's PAYLOAD_CWD export, which base() reads: without it the scanner crashes and fails open
cp "$hook" "$mdir/rename-safety.sh"
selftest_mutate "$here/hook-lib.sh" "$mdir/hook-lib.sh" 'export PAYLOAD_CWD="$cwd"' ':' \
  && hook="$mdir/rename-safety.sh" selftest_expect_killed "drop the PAYLOAD_CWD export" hook_rc_not 0 "$opted" "sed -i 's/a/b/' f.txt"
cp "$here/hook-lib.sh" "$mdir/hook-lib.sh"
selftest_mutate "$hook" "$mdir/rename-safety.sh" '                UNJUDGED.append((shape, CD))    # a relative file' '                pass    # a relative file' \
  && hook="$mdir/rename-safety.sh" selftest_expect_killed "an unknown cd stays silent" crumb_has "$plain" 'cd "$RS_UNSET_VAR" && sed -i s/a/b/ f.txt' "cannot expand"
# hook-lib.py's expand(): the shell-kept and rebound names it leaves unexpanded
cp "$hook" "$mdir/rename-safety.sh"
hooklib_mutant() { # hooklib_mutant <label> <find> <replace> <cwd> <cmd>  (the row must lose its breadcrumb)
  selftest_mutate "$here/hook-lib.py" "$mdir/hook-lib.py" "$2" "$3" \
    && hook="$mdir/rename-safety.sh" selftest_expect_killed "$1" crumb_has "$4" "$5" "cannot expand"
  cp "$here/hook-lib.py" "$mdir/hook-lib.py"
}
hooklib_mutant "read PWD from the hook"   'name in SHELL_KEPT or (name in TOUCHED and not rebound)' '(name in TOUCHED and not rebound)' "$plain" 'cd ../opted && cd "$PWD" && sed -i s/a/b/ f.txt'
RS_TARGET="$opted" hooklib_mutant "unset rebinds nothing" 'BINDERS = {"unset", "read"}' 'BINDERS = {"read"}' "$plain" 'unset RS_TARGET; cd "$RS_TARGET" && sed -i s/a/b/ f.txt'
RS_TARGET="$opted" hooklib_mutant "read rebinds nothing" 'BINDERS = {"unset", "read"}' 'BINDERS = {"unset"}' "$plain" 'read RS_TARGET < list; cd "$RS_TARGET" && sed -i s/a/b/ f.txt'
selftest_mutate "$here/hook-lib.py" "$mdir/hook-lib.py" 'hit = scan(BODIES[int(m.group(1))], curdir, depth)' 'hit = scan(BODIES[int(m.group(1))], "", depth)' \
  && hook="$mdir/rename-safety.sh" selftest_expect_killed "a \$(…) body ignores the curdir" hook_rc_not 0 "$plain" "cd ../opted; echo \"\$(sed -i 's/a/b/' f.txt)\"; cd ../plain"
cp "$here/hook-lib.py" "$mdir/hook-lib.py"
RS_TARGET="$opted" hooklib_mutant "for rebinds nothing" 'elif head in ("for", "select")' 'elif head in ("select",)' "$plain" 'for RS_TARGET in x; do cd "$RS_TARGET" && sed -i s/a/b/ f.txt; done'
# a variable the command rebinds: judged by its value from before, and said when that misses
cp "$here/hook-lib.py" "$mdir/hook-lib.py"
RS_TARGET="$opted" mutant "a rebound file judged by the run directory only" 'p = resolve(start, path, rebound=True)' 'p = None' "$plain" 'export RS_TARGET="$RS_TARGET"; sed -i s/a/b/g "$RS_TARGET/f.txt"' 0
RS_TARGET="$opted" mutant "a rebound glob parent not judged" '                for g in guesses(start, lead):' '                for g in []:' "$plain" 'export RS_TARGET; sed -i s/a/b/g "$RS_TARGET"/*.txt' 0
selftest_mutate "$hook" "$mdir/rename-safety.sh" '                UNJUDGED.append((shape, REBOUND))' '                pass' \
  && RS_TARGET="$plain" hook="$mdir/rename-safety.sh" selftest_expect_killed "a rebound miss stays silent" crumb_has "$plain" 'export RS_TARGET="$RS_TARGET"; sed -i s/a/b/g "$RS_TARGET/f.txt"' "rebinds"
cp "$hook" "$mdir/rename-safety.sh"
selftest_mutate "$here/hook-lib.py" "$mdir/hook-lib.py" '(name in TOUCHED and not rebound)' 'name in TOUCHED' \
  && RS_TARGET="$opted" hook="$mdir/rename-safety.sh" selftest_expect_killed "expand() ignores rebound" hook_rc_not 0 "$plain" 'export RS_TARGET="$RS_TARGET"; sed -i s/a/b/g "$RS_TARGET/f.txt"'
cp "$here/hook-lib.py" "$mdir/hook-lib.py"
RENAME_SAFETY_DIRS="$plain" mutant "start directory unresolved" 'dirs = [os.path.realpath(start)]' 'dirs = [start]' "$tmp" "cd plainlink && sed -i 's/a/b/' \"\$RS_UNSET_VAR/f.txt\"" 0

if [ "$fail" -ne 0 ]; then echo "SELFTEST FAIL: rename-safety"; exit 1; fi
echo "OK: rename-safety self-test clean — every in-place shape blocked, one listed substitution and every out-of-tree target allowed, every read and mention allowed, opt-in and fail-open hold."
