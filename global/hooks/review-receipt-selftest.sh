#!/usr/bin/env bash
# Self-test for review-receipt.sh: an expect/reject table run against throwaway
# repos. The hook is fail-open, so a rule that quietly stops matching looks
# exactly like a clean push — this table is the only thing that tells the two
# apart. Run it after changing any rule: bash global/hooks/review-receipt-selftest.sh
#
# Scope, stated because the fixture used to imply more than it graded: this hook
# reads ONE line out of a `Landing:` block, `Review required:`. The other keys in
# GATED_LINES are decoration, and the `noise` and `optoutroot` repos below make
# that explicit — a block malformed in every other key still gates, and a block
# well-formed throughout whose `Review required:` reads `no` does not. Nothing
# here stages a MALFORMED `Review required:` line; the one value the hook's
# pattern does not match is the `planned` row, whose `yes (planned)` fails the
# pattern's end anchor. The `ticks` row is the other way round — a backticked
# `yes` DOES match, and gates. Whether the other keys are themselves
# well-formed is lint-skills.sh's check_landing_key, not this hook's.
#
# HOOK_SELFTEST_VERBOSE=1 shows each row's stderr. The run/expect helpers are
# selftest-lib.sh beside this file; expect_quiet is the receipt path's own
# check: "allowed because a stamp matched", "allowed because the repo is not
# opted in", and "allowed because something failed open" are all rc=0, and only
# the first two exit without a breadcrumb — review-receipt.sh's own header
# names both silent paths. So a row that must not be satisfied by a fail-open
# is expect_quiet, never expect_allow.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/review-receipt.sh"

work="$(mktemp -d "${TMPDIR:-/tmp}/review-receipt-selftest.XXXXXX")"
work="$(cd "$work" && pwd -P)"
trap 'chmod -R u+rw "$work" 2>/dev/null; rm -rf "$work"' EXIT
export REVIEW_RECEIPT_DIR="$work/zone"
mkdir -p "$REVIEW_RECEIPT_DIR"
export HOME="$work"            # `~` in a command expands here; nothing outside the sandbox is read
export TZ=UTC                  # `touch -t` is local time; the commit dates below are UTC
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

GATED_LINES='# repo\n\n## Landing\n\nLanding:\n- Branch policy: trunk\n- Push pre-authorized: yes\n- Review required: yes\n'
# mkrepo <name> <CLAUDE.md printf-format>: a clone with its own bare remote, upstream set, one
# unpushed commit dated 2026-01-01T12:00Z (epoch 1767268800) so receipts can be placed before,
# at, or after it.
mkrepo() {
  git init -q --bare "$work/$1-remote.git"
  git clone -q "$work/$1-remote.git" "$work/$1" 2>/dev/null
  ( cd "$work/$1" && git checkout -q -b main 2>/dev/null
    printf "$2" > CLAUDE.md
    git add CLAUDE.md && git commit -q -m init && git push -q -u origin main 2>/dev/null
    echo x > f && git add f && GIT_COMMITTER_DATE="2026-01-01T12:00:00Z" git commit -q -m change )
}
mkrepo gated "$GATED_LINES"
mkrepo plain '# repo\n\nLanding:\n- Branch policy: trunk\n'
mkrepo bold '# repo\n\n**Review required:** yes\n'
mkrepo boldall '# repo\n\n**Review required: yes**\n'
mkrepo boldval '# repo\n\n- **Review required:** **yes**\n'
mkrepo ticks '# repo\n\n- Review required: `yes`\n'
mkrepo planned '# repo\n\n- Review required: yes (planned)\n'
mkrepo fenced '# repo\n\n```\n- Review required: yes\n```\n'
# The scope of this hook's Landing: reading, made explicit and graded. GATED_LINES
# carries three keys under its header and the hook reads ONE — everything but `Review required:` is
# decoration here, which made the fixture look like it modeled a Landing block
# when it modeled a line. `noise` is that block with every OTHER key corrupted;
# it must still block, because the key the hook reads is intact. The corrupted
# lines are not fine, they are somebody else's gate: lint-skills.sh's
# check_landing_key FAILs each of them, and the split is deliberate — a
# pre-commit linter can refuse a malformed contract, while a fail-open push hook
# that started refusing on a key it does not use would block pushes for a reason
# it cannot explain.
mkrepo noise '# repo\n\nLanding:\n- Branch policy: squash-merge\n- Push pre-authorised: MAYBE\n- Merge policy: squash\n- Review required: yes\n'
# The same block with the one key the hook reads set to `no`: it must allow. The
# `plain` repo below covers a block with the key ABSENT; this covers it present
# and negative, which is the only other way a well-formed block opts out.
mkrepo optoutroot '# repo\n\nLanding:\n- Branch policy: trunk\n- Push pre-authorized: yes\n- Review required: no\n'
mkrepo unreadable "$GATED_LINES"
chmod 000 "$work/unreadable/CLAUDE.md"
# monorepo: the line at the root, a package CLAUDE.md without it
mkrepo mono "$GATED_LINES"
( cd "$work/mono" && mkdir -p pkg optout && printf '# pkg\n' > pkg/CLAUDE.md && printf '# optout\n\n- Review required: no\n' > optout/CLAUDE.md \
  && git add pkg optout && GIT_COMMITTER_DATE="2026-01-01T12:00:00Z" git commit -q -m pkg )
# two remotes: upstream is `other` and fully pushed there; `origin` is one commit behind
mkrepo tworemotes "$GATED_LINES"
( cd "$work/tworemotes" && git init -q --bare "$work/other-remote.git" && git remote add other "$work/other-remote.git" \
  && git push -q -u other main 2>/dev/null )
# no tracking branch, but origin/main fetched: the `origin/<branch>` fallback range
mkrepo noupstream "$GATED_LINES"
( cd "$work/noupstream" && git branch -q --unset-upstream )

. "$here/selftest-lib.sh"
G="$work/gated"; P="$work/plain"

# --- no receipt at all: block every live push shape in the gated repo ---------
expect_block "$G" "git push"                                   "bare push"
expect_block "$G" "git push origin main"                       "explicit remote"
expect_block "$G" "git push -q origin main 2>&1 | tail -2"     "push in a pipeline"
expect_block "$G" "git push origin main >out.txt"              "a redirection is not a second refspec"
expect_block "$G" "git add . && git commit -m x && git push"   "push after commit"
expect_block "$G" "/usr/bin/git push"                          "path-prefixed git"
expect_block "$G" "git -C . push"                              "-C before the subcommand"
expect_block "$G" "git -c push.default=simple push"            "-c key=value before the subcommand"
expect_block "$G" "git --git-dir .git push"                    "--git-dir <value> before the subcommand"
expect_block "$G" "git --git-dir=.git push"                    "--git-dir=<value> before the subcommand"
expect_block "$G" "git --work-tree . push"                     "--work-tree <value> before the subcommand"
expect_block "$G" "git -c alias.p=push p"                      "alias built on the command line"
expect_block "$G" "git -c 'alias.p=push origin main' p"        "alias carrying its own arguments"
expect_block "$G" "bash -c 'git push origin main'"             "nested shell"
expect_block "$G" "bash -lc 'git push'"                        "clustered -c"
expect_block "$G" "sh -c 'git push'"                           "sh -c"
expect_block "$G" "zsh -c 'git push'"                          "zsh -c"
expect_block "$G" "dash -c 'git push'"                         "dash -c"
expect_block "$G" "ksh -c 'git push'"                          "ksh -c"
expect_block "$G" 'eval "git push"'                            "eval"
expect_block "$G" "eval eval eval eval git push"               "eval nested four deep"
expect_block "$G" "env GIT_TRACE=1 git push"                   "env wrapper"
expect_block "$G" 'env -S "git push"'                          "env -S string"
expect_block "$G" "timeout 30 git push"                        "timeout wrapper"
expect_block "$G" "timeout -k 5 30 git push"                   "timeout with a value-taking option"
expect_block "$G" "nice git push"                              "nice wrapper"
expect_block "$G" "nice -n 5 git push"                         "nice with a value-taking option"
expect_block "$G" "sudo git push"                              "sudo wrapper"
expect_block "$G" "sudo -u me git push"                        "sudo with a value-taking option"
expect_block "$G" "doas git push"                              "doas wrapper"
expect_block "$G" "exec git push"                              "exec wrapper"
expect_block "$G" "exec -a x git push"                         "exec with a value-taking option"
expect_block "$G" "command git push"                           "command wrapper"
expect_block "$G" "nohup git push"                             "nohup wrapper"
expect_block "$G" "time git push"                              "time wrapper"
expect_block "$G" "stdbuf -o0 git push"                        "stdbuf wrapper"
expect_block "$G" "ionice -c 3 git push"                       "ionice wrapper"
expect_block "$G" "caffeinate -i git push"                     "caffeinate wrapper"
expect_block "$G" "echo origin main | xargs git push"          "xargs"
expect_block "$G" "echo push | xargs git"                      "xargs supplying the subcommand"
expect_block "$G" $'bash <<EOF\ngit push\nEOF'                  "shell-fed heredoc"
expect_block "$G" $'printf "git push\\n" | bash'                "string piped into a shell"
expect_block "$G" 'p=push; git $p'                             "subcommand in a variable"
expect_block "$G" 'g=git; $g push'                             "git in a variable"
expect_block "$G" 'export p=push; git $p'                      "exported variable"
expect_block "$G" "git \$'push'"                               "ANSI-C quoted subcommand"
expect_block "$G" '$(which git) push'                          "\$(which git)"
expect_block "$G" 'echo `git push`'                            "backtick substitution"
expect_block "$G" 'echo $(git push)'                           "\$() substitution"
expect_block "$G" "git push # -n"                              "dry-run flag in a comment"
expect_block "$G" 'git commit -m "#123 fix" && git push'       "quoted # is not a comment"
expect_block "$G" "echo '#'; git push"                         "single-quoted # is not a comment"
expect_block "$G" "echo foo#bar; git push"                     "mid-word # is not a comment"
expect_block "$G" "git push -- -n"                             "-n after -- is a refspec"
expect_block "$G" "git push -on origin main"                   "-o<value> is not a dry-run cluster"
expect_block "$G" "git push -o n origin main"                  "-o n is a push option"
expect_block "$G" "{ git push; }"                              "brace group"
expect_block "$G" "if true; then git push; fi"                 "compound statement"
expect_block "$G" "f(){ git push; }; f"                        "function"
expect_block "$G" "git push --force"                           "force"
expect_block "$G" "git push --mirror"                          "mirror"
expect_block "$G" "git push origin HEAD:main"                  "refspec"
expect_block "$G" "git push -o ci.skip origin main"            "value-taking option"

# --- mentions, reads, and other commands: allow --------------------------------
expect_allow "$G" "git push --dry-run"                         "dry run"
expect_allow "$G" "git push -n origin main"                    "dry run short"
expect_allow "$G" "git push -qn origin main"                   "dry run in a cluster"
expect_allow "$G" "git status -sb"                             "read"
expect_allow "$G" "git commit -m x"                            "commit is not a push"
expect_allow "$G" "git log origin/main..HEAD"                  "range read"
expect_allow "$G" "echo 'then git push'"                       "mention in echo"
expect_allow "$G" "git commit -m 'do not git push yet'"        "mention in a message"
expect_allow "$G" $'cat <<EOF\ngit push\nEOF'                   "heredoc no shell consumes"
expect_allow "$G" "grep -rn 'git push' docs/"                  "grep pattern"
expect_allow "$G" "# git push"                                 "whole line is a comment"
expect_allow "$G" "command -v git"                             "command -v is a lookup"
expect_crumb "$G" "git push origin :feat"    "delete refspec"   "delete refspec sends no commits"
expect_crumb "$G" "git push --delete origin feat" "sends no commits" "--delete sends no commits"
expect_crumb "$G" "git push -d origin feat"  "sends no commits" "-d sends no commits"
( cd "$G" && git tag v1.0 )
expect_crumb "$G" "git push origin v1.0"     "tag push"         "a tag push sends no branch commits"

# --- the opt-in ---------------------------------------------------------------
expect_allow "$P" "git push"                                   "no opt-in"
expect_block "$work/bold" "git push"                           "bold key"
expect_block "$work/boldall" "git push"                        "bold line"
expect_block "$work/boldval" "git push"                        "bold key and bold value"
expect_block "$work/ticks" "git push"                          "backticked value"
# expect_quiet, not expect_allow, for the same reason the optoutroot row below
# gives: both rows take the silent not-opted-in exit, and a walk that failed
# open would satisfy expect_allow while proving nothing about the read. They
# reach it differently, which is why both are here: `planned`'s line IS read
# and its value fails the pattern, while `fenced`'s line is stripped with its
# code fence and never reaches the pattern at all.
expect_quiet "$work/planned" "git push"                        "'yes (planned)' is not yes"
expect_quiet "$work/fenced" "git push"                         "line inside a fence is not read"
expect_block "$work/mono/pkg" "git push"                       "monorepo: root line gates a package dir"
expect_block "$work/mono" "git push"                           "monorepo root"
expect_allow "$work/mono/optout" "git push"                    "monorepo: nearest CLAUDE.md saying no opts a package out"
if [ "$(id -u)" != 0 ]; then
  expect_crumb "$work/unreadable" "git push" "could not read"  "unreadable CLAUDE.md fails open with a breadcrumb"
fi

# --- the repo the push runs in, not the session cwd -----------------------------
expect_block "$P" "cd ../gated && git push"                    "cd into the gated repo"
expect_block "$P" "cd -- ../gated && git push"                 "cd -- into the gated repo"
expect_block "$P" "cd -P ../gated && git push"                 "cd -P into the gated repo"
expect_block "$P" "pushd ../gated >/dev/null && git push"      "pushd into the gated repo"
expect_block "$P" "cd $G && git push origin main"              "absolute cd"
expect_block "$P" "git -C ../gated push"                       "-C into the gated repo"
expect_block "$P" "git -C $G push"                             "-C absolute"
expect_allow "$G" "git -C ../plain push"                       "-C out of the gated repo"
expect_allow "$G" "cd ../plain && git push"                    "cd out of the gated repo"
expect_block "$G" 'cd "$SOMEWHERE" && git push'                "unexpandable cd falls back to cwd"
expect_block "$G" "cd ../nope && git push"                     "cd to a missing dir falls back to cwd"
expect_block "$G" "git -C ../nope push"                        "-C to a missing dir falls back to cwd"
expect_block "$G" "cd .git && git push"                        "push from inside .git"
expect_block "$G" "git -C .git push"                           "-C .git"
expect_block "$work" "GIT_DIR=$G/.git git push"                "GIT_DIR= from outside the repo"
expect_block "$work" "GIT_DIR=$G/.git; git push"               "GIT_DIR= assigned in an earlier segment"
# The one-key reading, both directions. Neither row can pass by accident: the
# first repo's block is malformed in every key but the one that matters, and
# the second's is well-formed in every key but that one.
expect_block "$work/noise" "git push"                          "a Landing: block malformed in every key but 'Review required: yes' still gates"
# expect_quiet, not expect_allow: the opt-out path and the fail-open path both
# exit 0, and only the opt-out exits without a breadcrumb. A walk that made this
# repo's CLAUDE.md unreadable would satisfy expect_allow while proving nothing.
expect_quiet "$work/optoutroot" "git push"                     "a well-formed Landing: block whose 'Review required:' is 'no' opts the repo out"

# --- the range: the remote on the command line decides ---------------------------
expect_allow "$work/tworemotes" "git push"                     "upstream remote is fully pushed"
expect_allow "$work/tworemotes" "git push other main"          "named remote fully pushed"
expect_block "$work/tworemotes" "git push origin main"         "named remote is behind"
expect_block "$work/tworemotes" "git push --repo origin"       "--repo names the remote"
expect_block "$work/tworemotes" "git push --repo=origin"       "--repo= names the remote"
expect_block "$work/noupstream" "git push"                     "no tracking branch: origin/<branch> fallback"

# --- receipts ------------------------------------------------------------------
# tree_of <repo-dir>: the work-tree hash the skills stamp (the hook header's one-liner, verbatim)
tree_of() { ( cd "$1" && T="$(mktemp -u)"; GIT_INDEX_FILE="$T" git read-tree HEAD 2>/dev/null; GIT_INDEX_FILE="$T" git add -A :/ && GIT_INDEX_FILE="$T" git write-tree; rm -f "$T" ); }
stamp() { printf '%s\n' "$2" >> "$REVIEW_RECEIPT_DIR/$1"; }   # stamp <file> <line>
HEADTREE="$(cd "$G" && git rev-parse 'HEAD^{tree}')"
[ "$(tree_of "$G")" = "$HEADTREE" ] || { echo "FAIL (tree_of on a clean tree should equal HEAD^{tree})"; fail=1; }
stamp other-2026-01-02-x.review.md "Reviewed-tree: $HEADTREE"
expect_block "$G" "git push"                                   "other repo's report"
stamp gated-archive-2026-01-02-x.review.md "Reviewed-tree: $HEADTREE"
expect_block "$G" "git push"                                   "a repo whose name starts with this one"
stamp gated-x.review.md "Reviewed-tree: $HEADTREE"
expect_block "$G" "git push"                                   "no date segment is not the handoff filename"
stamp gated-2026-01-02-x.md "Reviewed-tree: $HEADTREE"
expect_block "$G" "git push"                                   "handoff is not a receipt"
touch "$REVIEW_RECEIPT_DIR/gated-2025-12-31-empty.review.md"
expect_block "$G" "git push"                                   "a report with no stamp"
stamp gated-2025-12-31-old.review.md "Reviewed-tree: $(cd "$G" && git rev-parse 'HEAD~1^{tree}')"
expect_block "$G" "git push"                                   "a stamp of an earlier tree"
stamp gated-2026-01-01-short.review.md "Reviewed-tree: ${HEADTREE:0:12}"
expect_block "$G" "git push"                                   "an abbreviated hash is not a stamp"
stamp gated-2026-01-01-prose.review.md "the reviewed tree was $HEADTREE"
expect_block "$G" "git push"                                   "a hash in prose is not a stamp"
# a report quotes hashes — including this hook's own contract — and a quotation
# is not a receipt; the opt-in scan strips fences the same way (F8)
printf 'quoting the contract:\n\n```\nReviewed-tree: %s\n```\n' "$HEADTREE" > "$REVIEW_RECEIPT_DIR/gated-2026-01-01-fenced.review.md"
expect_block "$G" "git push"                                   "a stamp inside a fenced block is a quotation, not a receipt"
rm "$REVIEW_RECEIPT_DIR/gated-2026-01-01-fenced.review.md"
stamp gated-2026-01-01-quoted.review.md "> Reviewed-tree: $HEADTREE"
expect_block "$G" "git push"                                   "a blockquoted stamp is a quotation, not a receipt"
rm "$REVIEW_RECEIPT_DIR/gated-2026-01-01-quoted.review.md"
stamp gated-2026-01-01-nospace.review.md "Reviewed-tree:$HEADTREE"
expect_allow "$G" "git push"                                   "no space after the key still reads"
rm "$REVIEW_RECEIPT_DIR/gated-2026-01-01-nospace.review.md"
expect_block "$G" "git push"                                   "and without it the block is back"
stamp gated-2026-01-01-match.review.md "- **Reviewed-tree:** \`$HEADTREE\`"
expect_allow "$G" "git push"                                   "a stamp of HEAD's tree (bold key, backticked value)"
expect_allow "$G" "git push origin main"                       "stamped tree, explicit remote"
( cd "$G" && git commit -q --amend --no-edit -m reworded )
expect_allow "$G" "git push --force"                           "a message-only amend keeps the tree"
( cd "$G" && echo y > g && git add g && git commit -q -m fixup )
expect_block "$G" "git push"                                   "a fix-up after the stamp is a new tree"
stamp gated-2026-01-01-match.review.md "Reviewed-tree: $(cd "$G" && git rev-parse 'HEAD^{tree}')"
expect_allow "$G" "git push"                                   "re-stamped after the fix-up (second stamp in one report)"
( cd "$G" && git push -q origin main 2>/dev/null )
expect_allow "$G" "git push"                                   "nothing to push"
# the user's order: review the dirty tree, commit it whole, push
( cd "$G" && echo z > h && echo w > w )
stamp gated-2026-01-03-dirty.review.md "Reviewed-tree: $(tree_of "$G")"
expect_crumb "$G" "git push" "nothing to push"                 "dirty tree stamped, nothing committed yet: HEAD is already pushed"
( cd "$G" && git add h && git commit -q -m partial )
expect_block "$G" "git push"                                   "a partial commit of the reviewed tree is a different tree"
( cd "$G" && git add w && git commit -q -m rest )
expect_allow "$G" "git push"                                   "the whole reviewed tree committed (two commits) matches"
( cd "$G" && echo typo >> w && git commit -q -am typo )
expect_block "$G" "git push"                                   "an edit after the stamp blocks"
( cd "$G" && git push -q origin main 2>/dev/null )
# a source ref other than HEAD: the refspec's source decides the tree
( cd "$G" && git branch -q side && git checkout -q side && echo s > s && git add s && git commit -q -m side && git checkout -q main )
expect_block "$G" "git push origin side:main"                  "refspec source is an unstamped tree"
stamp gated-2026-01-04-side.review.md "Reviewed-tree: $(cd "$G" && git rev-parse 'side^{tree}')"
expect_allow "$G" "git push origin side:main"                  "refspec source stamped"
expect_allow "$G" "git push origin +side:main"                 "a leading + on the refspec is dropped"
# ...and the companions that tell a stamp match from a fail-open
expect_quiet "$G" "git push origin side:main"                  "stamped source allows silently, not by failing open"
expect_quiet "$G" "git push origin +side:main"                 "the + is stripped and the stamp matched, not an unresolvable ref"
expect_allow "$G" "git push origin refs/heads/side:refs/heads/main" "a fully-qualified refspec resolves"
expect_quiet "$G" "git push origin refs/heads/side:refs/heads/main" "and it allows on the stamp, not a fail-open"
# an unstamped source, an upper-case hash, and the src != HEAD range fallback (F13, F15)
( cd "$G" && git checkout -q -b nostamp && echo n > n && git add n && git commit -q -m nostamp && git checkout -q main )
expect_block "$G" "git push origin nostamp:main"               "an unstamped source blocks"
stamp gated-2026-01-05-upper.review.md "Reviewed-tree: $(cd "$G" && git rev-parse 'nostamp^{tree}' | tr 'a-f' 'A-F')"
expect_block "$G" "git push origin nostamp:main"               "an upper-case hash is not a stamp"
expect_block "$G" "git push origin nostamp:brandnew"           "src != HEAD with no remote dst: the range falls back to origin/<branch>..<src>, not @{upstream}..HEAD"
# the refs/heads/ strip on the destination, checked from a branch with no remote
# counterpart, where an unstripped dst loses the range entirely (F15)
( cd "$G" && git checkout -q nostamp )
expect_quiet "$G" "git push origin refs/heads/side:refs/heads/main" "the refs/heads/ prefix is stripped from the destination"
( cd "$G" && git checkout -q main )
# an unreadable report is skipped, not a fail-open — a planted chmod 000 file
# must not disable the gate the way it did before the 2026-08-22 review (F4, F14)
if [ "$(id -u)" != 0 ]; then
  : > "$REVIEW_RECEIPT_DIR/gated-2026-01-06-planted.review.md"
  chmod 000 "$REVIEW_RECEIPT_DIR/gated-2026-01-06-planted.review.md"
  expect_block "$G" "git push origin nostamp:main"             "an unreadable report does not disable the gate"
  chmod 644 "$REVIEW_RECEIPT_DIR/gated-2026-01-06-planted.review.md"
  rm -f "$REVIEW_RECEIPT_DIR/gated-2026-01-06-planted.review.md"
fi
# git sends every refspec, and --all/--mirror/a wildcard send every branch; the
# gate derived everything from the first token until the 2026-08-22 review
# (F2, F3, F6). side is stamped here, nostamp and main are not.
expect_block "$G" "git push origin side:main nostamp:other"    "a second refspec is gated too, not just the first"
expect_block "$G" "git push origin nostamp:other side:main"    "and in either order"
expect_block "$G" "git push --all origin"                      "--all sends every branch, and every branch is gated"
expect_block "$G" "git push --mirror origin"                   "--mirror likewise"
expect_block "$G" "git push origin refs/heads/*:refs/heads/*"  "a wildcard refspec is the --all shape, not an unresolvable ref"
stamp gated-2026-01-07-all.review.md "Reviewed-tree: $(cd "$G" && git rev-parse 'nostamp^{tree}')"
expect_allow "$G" "git push origin side:main nostamp:other"    "every source stamped allows the multi-refspec push"
expect_allow "$G" "git push --all origin"                      "and --all allows once every branch ahead of the remote is stamped"
rm "$REVIEW_RECEIPT_DIR/gated-2026-01-07-all.review.md"
( cd "$G" && git branch -q -D nostamp )
( cd "$G" && git branch -q -D side )
# a landing zone with a space in its path (unset the override so the TMPDIR path is searched)
( cd "$G" && echo q > q && git add q && git commit -q -m q )
mkdir -p "$work/t m p/claude-handoffs"
printf 'Reviewed-tree: %s\n' "$(cd "$G" && git rev-parse 'HEAD^{tree}')" > "$work/t m p/claude-handoffs/gated-2026-12-31-x.review.md"
REVIEW_RECEIPT_DIR= TMPDIR="$work/t m p" expect_allow "$G" "git push" "TMPDIR with a space"
( cd "$G" && git push -q origin main 2>/dev/null )

# --- fail-open -----------------------------------------------------------------
expect_allow "$G" ""                                           "empty command (no tool_input.command)"
rc="$(printf 'not json' | bash "$hook" >/dev/null 2>&1; echo $?)"
[ "$rc" = 0 ] || { echo "FAIL (malformed payload should allow, rc=$rc)"; fail=1; }
expect_crumb "$G" 'git push "unterminated'   "tokeniser error" "unterminated quote is a tokeniser error"
expect_crumb "$G" "eval eval eval eval eval git push" "tokeniser error" "more than four nested shells is a tokeniser error"
# a PATH with cat but no python3, then one with python3 but no git
payload="$(python3 -c 'import json,sys; print(json.dumps({"cwd":sys.argv[1],"tool_input":{"command":"git push"}}))' "$G")"
mkdir -p "$work/nopy" "$work/nogit" && ln -s "$(command -v cat)" "$work/nopy/cat" \
  && ln -s "$(command -v cat)" "$work/nogit/cat" && ln -s "$(command -v python3)" "$work/nogit/python3"
out="$(printf '%s' "$payload" | PATH="$work/nopy" /bin/bash "$hook" 2>&1 >/dev/null; echo "rc=$?")"
printf '%s' "$out" | grep -q 'python3 not found' && printf '%s' "$out" | grep -q 'rc=0' \
  || { echo "FAIL (no python3 should allow with a breadcrumb): $out"; fail=1; }
out="$(printf '%s' "$payload" | PATH="$work/nogit" /bin/bash "$hook" 2>&1 >/dev/null; echo "rc=$?")"
printf '%s' "$out" | grep -q 'git not found' && printf '%s' "$out" | grep -q 'rc=0' \
  || { echo "FAIL (no git should allow with a breadcrumb): $out"; fail=1; }
( cd "$work" && git init -q detached && cd detached && printf "$GATED_LINES" > CLAUDE.md && git add . && git commit -q -m init )
expect_crumb "$work/detached" "git push" "no remote ref"      "no remote ref: fail-open"
( cd "$work/detached" && git remote add origin "$work/gated-remote.git" && git fetch -q origin && git checkout -q --detach )
expect_block "$work/detached" "git push origin HEAD:main"      "detached HEAD with a refspec still resolves a range"
( cd "$G" && git checkout -q -b feat && echo w > w && git add w && git commit -q -m feat )
expect_crumb "$G" "git push -u origin feat" "no remote ref"    "first push of a new branch is ungated (by design, header)"
expect_block "$G" "git push origin feat:main"                  "new branch pushed onto a tracked one is gated"
( cd "$G" && git checkout -q main )
expect_crumb "$work" "git push" "not inside a git work tree"  "outside a git work tree"

if [ "$fail" -ne 0 ]; then echo "SELFTEST FAIL: review-receipt"; exit 1; fi
echo "OK: review-receipt self-test clean — every gated push blocked, every exempt form and receipt allowed, fail-open holds."
