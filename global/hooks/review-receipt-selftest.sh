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
# The block message is graded once, on the fix-up row: over reports that carry
# stamps, it names the last stamp read. Stamps are read by tree-stamp.sh
# --stamps (its own selftest grades the line shapes); the mutation table at the
# end grades what this hook adds on top: only `Reviewed-tree` lines count, the
# reader and landing.sh are the ones beside the checkout, a missing or failing
# one blocks named (an opted-in repo is never ungated by a broken install),
# and `--git-dir` / `--work-tree` name the repo; a tag push is decided by its
# source; a negative refspec is dropped and an unresolvable source holds; a
# push with no range checks the receipt. A zone landing.sh refuses, and a
# `list` that fails, block carrying landing.sh's stderr; a report the reader
# exits 4 on is skipped. Whether next-step.sh agrees
# with this hook is next-step-selftest.sh's parity section.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/review-receipt.sh"

# Temp-file template and guard: scripts/README.md § Temp files.
work="$(mktemp -d "${TMPDIR:-/tmp}/review-receipt-selftest.XXXXXX" 2>/dev/null)"
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "review-receipt-selftest: mktemp -d \"\${TMPDIR:-/tmp}/review-receipt-selftest.XXXXXX\" gave no usable temp directory (TMPDIR=${TMPDIR:-unset}) — nothing ran" >&2
  exit 4
fi
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
mkrepo tildefenced '# repo\n\n~~~\n- Review required: yes\n~~~\n'
# a ~~~ block quoting a ``` line closes only on ~~~, so the line after it is live
mkrepo mixedfence '# repo\n\n~~~\n```\n~~~\n- Review required: yes\n'
# a ```` fence closes only on a run of four or more, so the ``` line inside it is quoted text
mkrepo longfence '# repo\n\n````\n```\n- Review required: yes\n```\n````\n'
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

# shellcheck source=../../scripts/selftest-lib.sh
. "$here/../../scripts/selftest-lib.sh"   # selftest_mutate, selftest_expect_killed
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
# a delete or a tag first in the list is dropped, not a pass for the refspecs after it
expect_block "$G" "git push origin :gone main"                 "a delete refspec first does not pass the branch after it"
expect_block "$G" "git push origin v1.0 main"                  "a tag first does not pass the branch after it"
expect_crumb "$G" "git push origin :gone v1.0" "tag push"      "a delete and a tag together send no branch commits"
# a tag push is decided by its source, never by a destination named like a tag
expect_crumb "$G" "git push origin refs/tags/v1.0" "tag push"  "a refs/tags/ source is a tag push"
expect_crumb "$G" "git push origin v1.0:refs/tags/v1.0" "tag push" "a tag sent under refs/tags/ is a tag push"
expect_block "$G" "git push origin main:v1.0"                  "a branch source sent to a name a local tag carries is a branch push"
expect_block "$G" "git push origin v1.0:main"                  "a tag source sent to a branch is gated"
# a negative refspec sends nothing and is dropped; a source git cannot resolve holds
expect_block "$G" "git push origin main ^refs/heads/nope"      "a negative refspec does not make the push unresolvable and pass"
out="$(crumb "$G" "git push origin nosuch:main")"
printf '%s' "$out" | grep -q 'git cannot resolve the tree of nosuch' && printf '%s' "$out" | grep -q 'rc=2' \
  || { echo "FAIL (a source git cannot resolve should block, naming it): $out"; fail=1; }
# every push in a chained command is judged, not only the first
expect_block "$G" "git push origin :gone; git push origin main" "a delete push, then a branch push"
expect_block "$G" "git push origin v1.0 && git push"           "a tag push, then a bare push"
expect_allow "$G" "git push origin :gone; cd ../plain && git push" "a delete push, then a push from a repo not opted in"

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
expect_quiet "$work/tildefenced" "git push"                    "line inside a ~~~ fence is not read"
expect_block "$work/mixedfence" "git push"                     "a backtick fence line inside a ~~~ fence does not close it (tree-stamp.sh's fence rule)"
expect_quiet "$work/longfence" "git push"                      "a shorter backtick run inside a \`\`\`\` fence does not close it"
expect_block "$work/mono/pkg" "git push"                       "monorepo: root line gates a package dir"
expect_block "$work/mono" "git push"                           "monorepo root"
expect_block "$work/mono/optout" "git push"                    "monorepo: a subdirectory CLAUDE.md saying no never opts out; the top decides"
if [ "$(id -u)" != 0 ]; then
  expect_block "$work/unreadable" "git push"                    "an unreadable top-level CLAUDE.md holds the push"
  crumb_has "$work/unreadable" "git push" "could not read" \
    || { echo "FAIL [an unreadable top-level CLAUDE.md names the file it could not read]"; fail=1; }
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
expect_block "$work" "git --git-dir=$G/.git push"              "--git-dir from outside the repo names it"
expect_block "$work" "git --git-dir $G/.git --work-tree $G push" "--git-dir and --work-tree, detached values"
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
expect_block "$work/tworemotes" "git push other main && git push origin main" "a fully pushed remote, then a behind one: the second push decides"
expect_allow "$work/tworemotes" "git push other main; git push other main"    "two pushes with nothing to send"

# --- receipts ------------------------------------------------------------------
# tree_of <repo-dir>: the work-tree hash the skills stamp, from the script they name
tree_stamp="$here/../../src/review-changes/scripts/tree-stamp.sh"
[ -f "$tree_stamp" ] || { echo "FAIL (no tree-stamp script at $tree_stamp)"; exit 1; }
tree_of() { ( cd "$1" && bash "$tree_stamp" ); }
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
printf 'quoting the contract:\n\n~~~\nReviewed-tree: %s\n~~~\n' "$HEADTREE" > "$REVIEW_RECEIPT_DIR/gated-2026-01-01-tilde.review.md"
expect_block "$G" "git push"                                   "a ~~~ fence is a quotation too (one reader with --verify)"
rm "$REVIEW_RECEIPT_DIR/gated-2026-01-01-tilde.review.md"
stamp gated-2026-01-01-measured.review.md "Measured-tree: $HEADTREE"
expect_block "$G" "git push"                                   "a Measured-tree: stamp is not a review"
rm "$REVIEW_RECEIPT_DIR/gated-2026-01-01-measured.review.md"
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
out="$(crumb "$G" "git push")"                                 # the block names the last stamp it read — match's, not the earlier -old one
printf '%s' "$out" | grep -qF "the last stamp read (${HEADTREE:0:12}, in gated-2026-01-01-match.review.md)" || { echo "FAIL (a block over stamped reports should name the last stamp read, ${HEADTREE:0:12}): $out"; fail=1; }
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
# with no range the receipt decides, so the strip shows only in the shortcut:
# main is pushed and unstamped, and only a stripped destination finds origin/main
expect_crumb "$G" "git push origin refs/heads/main:refs/heads/main" "nothing to push" "the stripped destination finds the range, and a pushed branch sends nothing"
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
# a landing zone with a space in its path (unset the override so the TMPDIR path is searched).
# The report path comes from handoff's landing.sh, the writers' resolver, so a
# zone or filename the two disagree on reds this row.
( cd "$G" && echo q > q && git add q && git commit -q -m q )
landing="$here/../../src/handoff/scripts/landing.sh"
report="$(cd "$G" && REVIEW_RECEIPT_DIR= TMPDIR="$work/t m p" bash "$landing" path x --kind review)" \
  || { echo "FAIL (landing.sh gave no report path)"; fail=1; }
printf 'Reviewed-tree: %s\n' "$(cd "$G" && git rev-parse 'HEAD^{tree}')" > "$report"
REVIEW_RECEIPT_DIR= TMPDIR="$work/t m p" expect_quiet "$G" "git push" "TMPDIR with a space, report path from landing.sh"
( cd "$G" && git push -q origin main 2>/dev/null )

# --- fail-open -----------------------------------------------------------------
expect_crumb "$G" ""                                           "payload has no tool_input.command" "empty command (no tool_input.command)"
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
expect_block "$work/detached" "git push"                       "no remote ref to compare against: the receipt decides"
out="$(crumb "$work/detached" "git push")"
printf '%s' "$out" | grep -q 'no remote ref to compare against, so every commit is new there' \
  || { echo "FAIL (a block with no range should say there is no remote ref): $out"; fail=1; }
( cd "$work/detached" && git remote add origin "$work/gated-remote.git" && git fetch -q origin && git checkout -q --detach )
expect_block "$work/detached" "git push origin HEAD:main"      "detached HEAD with a refspec still resolves a range"
( cd "$G" && git checkout -q -b feat && echo w > w && git add w && git commit -q -m feat )
expect_block "$G" "git push -u origin feat"                    "first push of a new branch: no range, so the receipt decides"
expect_block "$G" "git push $work/gated-remote.git feat"       "a push to a URL: no range, so the receipt decides"
expect_block "$G" "git push origin feat:main"                  "new branch pushed onto a tracked one is gated"
( cd "$G" && git checkout -q main )
expect_crumb "$work" "git push" "not inside a git work tree"  "outside a git work tree"

# --- the stamp reader is tree-stamp.sh, found from the hook's own path ---------------
mkrepo mutrepo "$GATED_LINES"
M="$work/mutrepo"; MTREE="$(cd "$M" && git rev-parse 'HEAD^{tree}')"
stamp mutrepo-2026-01-01-m.review.md "Measured-tree: $MTREE"
expect_block "$M" "git push"                                   "the mutation fixture: a Measured-tree: stamp alone blocks"
mkdir -p "$work/lonely"; cp "$hook" "$here/hook-lib.sh" "$here/hook-lib.py" "$work/lonely/"
out="$(hook="$work/lonely/review-receipt.sh" crumb "$M" "git push")"
printf '%s' "$out" | grep -q 'stamp reader is not at' && printf '%s' "$out" | grep -q 'rc=2' \
  || { echo "FAIL (a hook with no tree-stamp.sh beside its checkout should block, naming it): $out"; fail=1; }
# a checkout copy with the stamp reader but no landing.sh, then each script failing
fakeco() { # fakeco <dir> <stamp-reader body or 'real'> <landing body or 'real' or 'none'>
  mkdir -p "$1/global/hooks" "$1/src/review-changes/scripts" "$1/src/handoff/scripts"
  cp "$hook" "$here/hook-lib.sh" "$here/hook-lib.py" "$1/global/hooks/"
  if [ "$2" = real ]; then cp "$here/../../src/review-changes/scripts/tree-stamp.sh" "$1/src/review-changes/scripts/"
  else printf '%s\n' "$2" > "$1/src/review-changes/scripts/tree-stamp.sh"; fi
  case "$3" in
    real) cp "$here/../../src/handoff/scripts/landing.sh" "$1/src/handoff/scripts/" ;;
    none) ;;
    *) printf '%s\n' "$3" > "$1/src/handoff/scripts/landing.sh" ;;
  esac
}
fakeco "$work/nolanding" real none
out="$(hook="$work/nolanding/global/hooks/review-receipt.sh" crumb "$M" "git push")"
printf '%s' "$out" | grep -q 'landing.sh is not at' && printf '%s' "$out" | grep -q 'rc=2' \
  || { echo "FAIL (a checkout with no landing.sh should block, naming it): $out"; fail=1; }
fakeco "$work/badlanding" real 'exit 1'
out="$(hook="$work/badlanding/global/hooks/review-receipt.sh" crumb "$M" "git push")"
printf '%s' "$out" | grep -q 'landing.sh zones failed' && printf '%s' "$out" | grep -q 'rc=2' \
  || { echo "FAIL (a failing landing.sh should block, naming it): $out"; fail=1; }
fakeco "$work/badreader" 'exit 1' real
out="$(hook="$work/badreader/global/hooks/review-receipt.sh" crumb "$M" "git push")"
printf '%s' "$out" | grep -q 'the stamp reader failed on' && printf '%s' "$out" | grep -q 'rc=2' \
  || { echo "FAIL (a stamp reader that fails on a readable report should block, naming it): $out"; fail=1; }
# a reader exiting 4 (it could not read the report) skips that report, as
# next-step.sh does; with no other report the push still holds
fakeco "$work/reader4" 'exit 4' real
out="$(hook="$work/reader4/global/hooks/review-receipt.sh" crumb "$M" "git push")"
printf '%s' "$out" | grep -q 'skipping unreadable report' && printf '%s' "$out" | grep -q 'rc=2' \
  || { echo "FAIL (a report the reader exits 4 on should be skipped, and the push still held): $out"; fail=1; }
# a zone landing.sh refuses: the hold carries landing.sh's reason, not the install text
mkdir -p "$work/wzone"; chmod o+w "$work/wzone"
out="$(REVIEW_RECEIPT_DIR="$work/wzone" crumb "$M" "git push")"
printf '%s' "$out" | grep -q 'landing.sh zones printed no zone (landing.sh: ' && printf '%s' "$out" | grep -q 'not owned by uid' \
  && printf '%s' "$out" | grep -q 'rc=2' && ! printf '%s' "$out" | grep -q 'scripts/install.sh wires it' \
  || { echo "FAIL (a refused zone should block with landing.sh's reason, not the install text): $out"; fail=1; }
fakeco "$work/listfail" real '[ "$1" = zones ] && { echo "/nonexistent-zone"; exit 0; }; echo "landing.sh: list refused here" >&2; exit 4'
out="$(hook="$work/listfail/global/hooks/review-receipt.sh" crumb "$M" "git push")"
printf '%s' "$out" | grep -q 'landing.sh list --kind review failed (landing.sh: list refused here)' && printf '%s' "$out" | grep -q 'rc=2' \
  || { echo "FAIL (a failing landing.sh list should block, carrying its stderr): $out"; fail=1; }
# ...and a repo not opted in never reaches either script
out="$(hook="$work/nolanding/global/hooks/review-receipt.sh" crumb "$P" "git push")"
[ "$out" = "rc=0" ] || { echo "FAIL (a repo not opted in should allow silently with landing.sh missing): $out"; fail=1; }
# the mutation fixture's companion: a Reviewed-tree stamp, which the real hook accepts quietly
mkrepo mutok "$GATED_LINES"
MOK="$work/mutok"
stamp mutok-2026-01-01-m.review.md "Reviewed-tree: $(cd "$MOK" && git rev-parse 'HEAD^{tree}')"
expect_quiet "$MOK" "git push"                                 "the mutation companion: a Reviewed-tree stamp allows quietly"

# --- mutation table -------------------------------------------------------------
# Each row edits a copy of the hook, laid out as a checkout so the copy finds the
# real tree-stamp.sh, and reruns one row; the mutant must flip it.
# The fixture each row runs on must make the real hook give the other answer, or
# the row grades nothing: by this point $G's main is pushed ("nothing to push")
# and $work is not a repo, so every row aimed at $G would allow either way. An
# unpushed, unstamped commit on $G's main makes each of those block on the real
# hook; the rows below pin that before the table relies on it.
( cd "$G" && echo u > u && git add u && git commit -q -m unstamped )
expect_block "$work" "git --git-dir=$G/.git push"              "the mutation fixture: --git-dir names an unstamped repo"
expect_block "$work" "git --work-tree=$G push"                 "the mutation fixture: --work-tree names an unstamped repo"
expect_block "$G" "git push origin :gone; git push origin main" "the mutation fixture: the second push is unstamped"
expect_block "$G" "git push origin :gone main"                 "the mutation fixture: the branch after a delete is unstamped"
expect_block "$G" "git push origin v1.0 main"                  "the mutation fixture: the branch after a tag is unstamped"
( cd "$G" && git tag v2.0 )
expect_block "$G" "git push origin v2.0:main"                  "the mutation fixture: a tag at the unstamped commit, sent to a branch"
expect_block "$G" "git push origin main:v2.0"                  "the mutation fixture: a branch sent to a name the tag carries"
expect_quiet "$MOK" "git push origin main ^refs/heads/nope"    "the mutation fixture: a stamped push beside a negative refspec"
expect_block "$MOK" "git push origin main nosuch:other"        "the mutation fixture: a stamped source beside an unresolvable one"
( cd "$work" && git init -q norem && cd norem && printf "$GATED_LINES" > CLAUDE.md && git add . && git commit -q -m init )
expect_block "$work/norem" "git push"                          "the mutation fixture: a repo with no remote ref has no range"
mdir="$work/mut"; mkdir -p "$mdir/global/hooks"; ln -s "$here/../../src" "$mdir/src"
cp "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/global/hooks/"
mutant() { # mutant <label> <find> <replace> <cwd> <cmd> <want rc>
  selftest_mutate "$hook" "$mdir/global/hooks/review-receipt.sh" "$2" "$3" || return
  hook="$mdir/global/hooks/review-receipt.sh" selftest_expect_killed "$1" hook_rc_not "$6" "$4" "$5"
}
mutant "accept a Measured-tree stamp" "s/^Reviewed-tree " "s/^[A-Za-z]*-tree " "$M" "git push" 0
# the missing-reader check, dropped: a copy with no checkout around it no longer names the missing script
mkdir -p "$work/lonely2"; cp "$here/hook-lib.sh" "$here/hook-lib.py" "$work/lonely2/"
selftest_mutate "$hook" "$work/lonely2/review-receipt.sh" '[ -f "$stamp_reader" ] || hold' ': ||' \
  && hook="$work/lonely2/review-receipt.sh" selftest_expect_killed "drop the missing-reader check" crumb_has "$M" "git push" 'stamp reader is not at'
mutant "ignore --git-dir"             'd = gd or wt or d' 'd = wt or d' "$work" "git --git-dir=$G/.git push" 0
mutant "ignore --work-tree"           'd = gd or wt or d' 'd = gd or d' "$work" "git --work-tree=$G push" 0
mutant "the reader is not the one beside the checkout" 'stamp_reader="$hook_real/../../src/' 'stamp_reader="$hook_real/../src/' "$MOK" "git push" 2
mutant "landing.sh is not the one beside the checkout" 'landing="$hook_real/../../src/' 'landing="$hook_real/../src/' "$MOK" "git push" 2
# the missing-reader hold, turned into an allow: graded from a copy with no
# checkout around it (the $mdir copy finds the real reader and never reaches the
# hold), pushing the opted-in $M, whose real-hook answer is the hold's rc 2
selftest_mutate "$hook" "$work/lonely2/review-receipt.sh" 'hold "the stamp reader is not at' '{ rec_allow "x"; return 0; }; : "' \
  && hook="$work/lonely2/review-receipt.sh" selftest_expect_killed "a missing reader allows" hook_rc_not 0 "$M" "git push"
mutant "judge only the first push"    'judge "${records[$((ri - 1))]}"' 'judge "${records[0]}"' "$G" "git push origin :gone; git push origin main" 0
mutant "a delete first passes the rest" 'case "$r" in :*|+:*) dropped=1; continue ;; esac' 'case "$r" in :*|+:*) rec_allow x; return 0 ;; esac' "$G" "git push origin :gone main" 0
mutant "a tag first passes the rest"  'is_tag "$r" && continue;' 'is_tag "$r" && { rec_allow x; return 0; };' "$G" "git push origin v1.0 main" 0
mutant "the destination decides a tag" 's="${r%%:*}" d="${r#*:}"' 's="${r#*:}" d=""' "$G" "git push origin main:v2.0" 0
mutant "a tag sent to a branch is a tag push" 'case "$d" in ""|refs/tags/*) ;; *) return 1 ;; esac' ':' "$G" "git push origin v2.0:main" 0
mutant "a negative refspec is a source" 'case "$r" in ^*) continue ;; esac' ':' "$MOK" "git push origin main ^refs/heads/nope" 2
mutant "an unresolvable source allows" '[ -n "$t" ] || hold "git cannot resolve' '[ -n "$t" ] || { rec_allow x; return 0; }; : "git cannot resolve' "$MOK" "git push origin main nosuch:other" 0
mutant "no range is nothing to push" '[ -z "$wide" ] && [ -n "$range" ]; then' '[ -z "$wide" ]; then [ -n "$range" ] || { rec_allow x; return 0; };' "$work/norem" "git push" 0

if [ "$fail" -ne 0 ]; then echo "SELFTEST FAIL: review-receipt"; exit 1; fi
echo "OK: review-receipt self-test clean — every gated push blocked, every exempt form and receipt allowed, fail-open holds."
