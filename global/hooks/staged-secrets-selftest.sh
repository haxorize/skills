#!/usr/bin/env bash
# Self-test for staged-secrets.sh: an expect/reject table over throwaway git
# repos, then a mutation table. The hook is fail-open, so a pattern that quietly
# stops matching looks exactly like a clean commit — these rows are the only
# thing that tells the two apart. Run it after changing any rule:
#   bash global/hooks/staged-secrets-selftest.sh
#
# Every token-shaped fixture is assembled here at run time from pieces that
# are not themselves token-shaped, so this repo never holds one (the hook would
# block its own selftest's commit otherwise, and a scanner would flag the repo).
#
# What it grades: one firing instance per alternative of CONTENT_RULES and
# PATH_RULES and a clean neighbour beside each; the `secret-scan: allow` line
# marker, and a block message that does not offer it; the commit shapes
# (staged file, `-a`/`-am`, `git add <path>`, `git add .`, `git stage`, an
# unexpandable pathspec, `add -f` of an ignored file, `add -A` from a
# subdirectory, `git -C`, `cd … &&`, `--git-dir`/`--work-tree`,
# `--pathspec-from-file` in both spellings, every commit in a chain and the
# adds before the last, a `cd` the scanner cannot expand — the session
# directory's repo scanned in its place, blocking on a hit there, allowing
# with a breadcrumb when clean or not a work tree, never before the placed
# commits are scanned, an absolute `-C`, or an absolute `--git-dir` and
# `--work-tree` together in either spelling, placing the command and either of
# the two alone not — a failed `git config` read of the
# filters); a diff read
# whatever the repo's diff config says (prefixes, `diff.relative`, a `-diff`
# attribute, quoted paths, an added line starting `++`); a repo whose config
# names a program on every path the scan takes (fsmonitor, textconv, a diff
# driver, diff.external, a clean filter, a submodule's filter) running none of
# them, and a fixture check that plain git runs each; the non-commit and
# outside-a-repo allows; a deleted key file; the report never carrying the
# value; the malformed-payload fail-open table. The mutation table at the end
# narrows each content and path alternative, widens each boundary and
# exemption, and drops each neutralizer, on a copy of the hook (or of
# hook-lib), and each mutant must flip its row. `-c diff.external=` is graded
# only together with `--no-ext-diff`: with that flag git never reads the key,
# and without it an empty value makes git die before running anything. What it
# does not grade: hook-lib's command shapes (commit-bypass-selftest.sh owns
# those).
set -u
# git exports GIT_INDEX_FILE=.git/index (and more) to a pre-commit hook; inherited,
# it points each fixture's git at the cwd's index rather than the one --git-dir names.
unset $(git rev-parse --local-env-vars)
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/staged-secrets.sh"

# selftest-lib.sh sources scripts/selftest-lib.sh (selftest_mutate,
# selftest_expect_killed); the path named here is what queues this selftest
# when that file is staged (pre-commit's queue_selftests_naming).
. "$here/selftest-lib.sh"
# Temp-file template and guard: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir staged-secrets-selftest
trap 'rm -rf "$tmp"' EXIT
command -v git >/dev/null 2>&1 || { echo "staged-secrets-selftest: git not found — nothing ran" >&2; exit 4; }

rep() { printf "%${2}s" "" | tr ' ' "$1"; }   # rep <char> <n>
AWS="AK""IA$(rep Q 16)"
ASIA="AS""IA$(rep Q 16)"
GHP="gh""p_$(rep a 36)"
GHO="gh""o_$(rep a 36)"
GHPAT="github""_pat_$(rep b 22)"
SLACK_B="xo""xb-$(rep 1 12)"
SLACK_A="xo""xa-$(rep 1 12)"
SLACK_P="xo""xp-$(rep 1 12)"
SLACK_R="xo""xr-$(rep 1 12)"
PKEY="-----BEGIN RSA PRI""VATE KEY-----"
PKEY_BARE="-----BEGIN PRI""VATE KEY-----"
JWT="ey""J$(rep a 10).ey""J$(rep b 10).$(rep c 10)"
SAS="https://x.blob.core.windows.net/c/f?sv=1&s""ig=$(rep A 30)"
mix() { printf "%${2}s" "" | sed "s/ /$1/g"; }   # mix <chunk> <n> — the chunk n times
GHS="gh""s_$(rep a 36)"
GHU="gh""u_$(rep a 36)"
GHR="gh""r_$(rep a 36)"
GLPAT="gl""pat-$(rep x 20)"
ANT="sk""-ant-$(mix Ab1 11)"
ANT_LOWER="sk""-ant-$(rep a 40)"        # only the sk-ant- rule matches it: the generic sk- run needs upper case and a digit
SKPLAIN="sk""-$(mix Ab1 11)"
SKPROJ="sk""-proj-$(mix Ab1 11)"
AIZA="AI""za$(rep B 35)"
STRIPE="sk""_live_$(rep a 24)"
NPM="np""m_$(rep a 36)"
# clean neighbours: one character short, a wrong letter, a public header
AWS_SHORT="AK""IA$(rep Q 15)"
GHP_SHORT="gh""p_$(rep a 35)"
SLACK_Z="xo""xz-$(rep 1 12)"
PUBKEY="-----BEGIN PUBLIC KEY-----"
JWT_ONE="ey""J$(rep a 10)"
SAS_SHORT="https://x/f?s""ig=$(rep A 10)"
GLPAT_SHORT="gl""pat-$(rep x 19)"
ANT_SHORT="sk""-ant-$(rep a 10)"
SK_KEBAB="sk-$(mix long-kebab-2- 4)"     # lower case and digits, no upper case
SK_NOLOWER="sk""-$(mix AB1 11)"
SK_NODIGIT="sk""-$(mix AbC 11)"
AIZA_LONG="AI""za$(rep B 36)"
STRIPE_TEST="sk""_test_$(rep a 24)"
NPM_LONG="np""m_$(rep a 37)"

newrepo() { # newrepo — prints a fresh repo with one commit (called in $(…), so no counter)
  local r
  r="$(mktemp -d "$tmp/repo.XXXXXX")" || { echo "FAIL: no fixture repo" >&2; return 1; }
  { git -C "$r" init -q && printf 'seed\n' > "$r/seed.txt" &&
    git -C "$r" add seed.txt && git -C "$r" -c user.email=t@t -c user.name=t commit -qm seed; } >/dev/null 2>&1
  in_fixture "$r" || return 1
  printf '%s' "$r"
}
# in_fixture <dir> — true only for a git work tree of its own under $tmp, so a
# fixture write can never land in the checkout running this selftest
in_fixture() {
  case "$1" in "$tmp"/repo.*) ;; *) echo "FAIL: fixture path '$1' is not under $tmp — stopping" >&2; exit 1 ;; esac
  [ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$1" && pwd -P)" ] ||
    { echo "FAIL: '$1' is not its own git work tree — stopping" >&2; exit 1; }
}
staged() { # staged <relpath> <content> — a repo with that file staged
  local r; r="$(newrepo)" || exit 1
  in_fixture "$r"
  mkdir -p "$(dirname "$r/$1")" && printf '%s\n' "$2" > "$r/$1" && git -C "$r" add -- "$1"
  printf '%s' "$r"
}

# --- content shapes, staged: block --------------------------------------------
for v in AWS ASIA GHP GHO GHS GHU GHR GHPAT GLPAT SLACK_A SLACK_B SLACK_P SLACK_R ANT ANT_LOWER SKPLAIN SKPROJ AIZA STRIPE NPM PKEY PKEY_BARE JWT SAS; do
  expect_block "$(staged cfg.txt "key = ${!v}")" "git commit -m x" "$v staged"
done
# --- clean neighbours: allow --------------------------------------------------
for v in AWS_SHORT GHP_SHORT SLACK_Z PUBKEY JWT_ONE SAS_SHORT GLPAT_SHORT ANT_SHORT SK_KEBAB SK_NOLOWER SK_NODIGIT AIZA_LONG STRIPE_TEST NPM_LONG; do
  expect_quiet "$(staged cfg.txt "key = ${!v}")" "git commit -m x" "$v neighbour"
done
expect_quiet "$(staged cfg.txt "token = \"$GHP\"  # secret-scan: allow")" "git commit -m x" "allow marker"
expect_block "$(staged cfg.txt "$(printf 'a = %s  # secret-scan: allow\nb = %s' "$GHP" "$GHO")")" \
  "git commit -m x" "the marker covers its own line only"

# --- path shapes ----------------------------------------------------------------
for p in .env .env.local sub/.env.production key.pem tls.key c.p12 c.pfx .netrc .npmrc id_rsa id_dsa id_ed25519 id_ecdsa; do
  expect_block "$(staged "$p" "x=1")" "git commit -m x" "path $p"
done
for p in .env.example .env.sample .env.template .envrc id_rsa.pub id_dsa.pub notes.pem.txt keys.txt key.json c.p12.md .netrc.example npmrc.md; do
  expect_quiet "$(staged "$p" "x=1")" "git commit -m x" "path neighbour $p"
done
r="$(staged .env "x=1")"; in_fixture "$r"; git -C "$r" -c user.email=t@t -c user.name=t commit -qm env >/dev/null
git -C "$r" rm -q --cached .env
expect_quiet "$r" "git commit -m x" "a staged deletion of .env"

# --- commit shapes ----------------------------------------------------------------
r="$(newrepo)"; in_fixture "$r"; printf 'k = %s\n' "$AWS" >> "$r/seed.txt"
expect_quiet "$r" "git commit -m x" "unstaged change, plain commit"
expect_block "$r" "git commit -a -m x" "-a"
expect_block "$r" "git commit -am x" "-am"
expect_block "$r" "git commit --all -m x" "--all"
# the tokeniser's redirection reads (hook-lib.py): the first four once hid the commit
expect_block "$r" "echo \\>& git commit -a -m x" "an escaped > leaves its & a background separator"
expect_block "$r" ">x git commit -a -m x" "a redirection before the program"
expect_block "$r" "git commit -m x >| log -a" "the | of >| is a redirection, not a pipe"
expect_block "$r" "git commit -m x 2> >(cat) -a" "a process substitution is one word"
expect_block "$r" "sleep 1 & git commit -a -m x" "a bare background & separates"
expect_quiet "$r" "git commit -ma" "-ma: a is the message"
expect_block "$r" "git add seed.txt && git commit -m x" "add of a tracked path in the same command"
r="$(newrepo)"; in_fixture "$r"; printf 'k = %s\n' "$AWS" > "$r/new.txt"; printf 'ok\n' > "$r/other.txt"
expect_block "$r" "git add new.txt && git commit -m x" "add of an untracked path"
expect_block "$r" "git add . && git commit -m x" "add ."
expect_block "$r" "git add -A; git commit -m x" "add -A"
expect_quiet "$r" "git add other.txt && git commit -m x" "add names another path"
expect_quiet "$r" "git add other.txt 2> new.txt && git commit -m x" "a detached redirect target is not a pathspec"
expect_block "$r" "git add 2> log new.txt && git commit -m x" "a pathspec after a redirection is still read"
expect_block "$r" "git add new.txt>/dev/null && git commit -m x" "an attached > ends the pathspec's word"
expect_quiet "$r" "git status" "not a commit"
r="$(newrepo)"; in_fixture "$r"; printf 'id\n' > "$r/id_rsa"
expect_block "$r" "git add id_rsa && git commit -m x" "untracked key file added in the same command"
r="$(staged sub/cfg.txt "k = $GHP")"; in_fixture "$r"
expect_block "$tmp" "git -C $r commit -m x" "git -C"
expect_block "$tmp" "cd $r/sub && git commit -m x" "cd then commit"
expect_block "$r" "bash -c 'git commit -m x'" "commit inside bash -c"
r="$(newrepo)"; in_fixture "$r"; printf 'k = %s\n' "$AWS" > "$r/new.txt"
expect_block "$r" "git stage new.txt && git commit -m x" "git stage is git add"
expect_block "$r" "git add other.txt \"\$F\" && git commit -m x" "an unexpandable pathspec reads the whole tree"
# a force-added ignored file
r="$(newrepo)"; in_fixture "$r"; printf 'secret.txt\n' > "$r/.gitignore"; git -C "$r" add .gitignore
git -C "$r" -c user.email=t@t -c user.name=t commit -qm ignore; printf 'k = %s\n' "$AWS" > "$r/secret.txt"
expect_block "$r" "git add -f secret.txt && git commit -m x" "add -f of an ignored file"
expect_block "$r" "git add --force secret.txt && git commit -m x" "add --force of an ignored file"
expect_quiet "$r" "git add -A && git commit -m x" "an ignored file without -f is not added"
# git add -A from a subdirectory stages the whole tree
r="$(newrepo)"; in_fixture "$r"; mkdir -p "$r/sub"; printf 'x\n' > "$r/sub/ok.txt"; printf 'k = %s\n' "$AWS" > "$r/top.txt"
expect_block "$r/sub" "git add -A && git commit -m x" "add -A from a subdirectory reads the top"
# diff.relative would cut a tracked change outside the subdirectory out of the diff
r="$(newrepo)"; in_fixture "$r"; mkdir -p "$r/sub"; printf 'x\n' > "$r/sub/ok.txt"; git -C "$r" add sub
git -C "$r" -c user.email=t@t -c user.name=t commit -qm sub; git -C "$r" config diff.relative true
printf 'k = %s\n' "$AWS" >> "$r/seed.txt"
expect_block "$r/sub" "git add -A && git commit -m x" "diff.relative does not narrow the diff"
# --git-dir and --work-tree are honoured
r="$(staged cfg.txt "k = $GHP")"; in_fixture "$r"
expect_block "$tmp" "git --git-dir=$r/.git --work-tree=$r commit -m x" "--git-dir/--work-tree name the repo"
r="$(newrepo)"; in_fixture "$r"; printf 'k = %s\n' "$AWS" >> "$r/seed.txt"
expect_block "$tmp" "git --git-dir $r/.git --work-tree $r commit -a -m x" "--work-tree is where -a reads"
# --pathspec-from-file names files this hook does not read: the whole tree, in either spelling
r="$(newrepo)"; in_fixture "$r"; printf 'k = %s\n' "$AWS" > "$r/new.txt"; printf 'new.txt\n' > "$r/list.txt"
expect_block "$r" "git add --pathspec-from-file=list.txt && git commit -m x" "--pathspec-from-file=<file>"
expect_block "$r" "git add --pathspec-from-file list.txt && git commit -m x" "--pathspec-from-file <file>"
# every commit in the command is scanned, with the adds before the last one
expect_block "$r" "git commit --allow-empty -m a; git add new.txt; git commit -m b" "an add between two commits"
expect_quiet "$r" "git commit --allow-empty -m a; git add new.txt" "an add after the last commit stages nothing it commits"
r2="$(staged c.txt "k = $GHP")"; in_fixture "$r2"
expect_block "$tmp" "git -C $r commit --allow-empty -m a; git -C $r2 commit -m b" "a second commit in another repo"
# a cd the scanner cannot expand: the repo is unknown, so the session directory's repo is scanned in its place
r3="$(newrepo)"; in_fixture "$r3"
r4="$(newrepo)"; in_fixture "$r4"; printf 'k = %s\n' "$AWS" > "$r4/new.txt"
mkdir -p "$tmp/plain"
expect_crumb "$r3" "cd \"\$(echo $r2)\" && git commit -m x" "follows a cd the hook cannot expand" "a cd through \$(…), the session repo clean"
expect_block "$r2" "cd \"\$(echo $r3)\" && git commit -m x" "a cd through \$(…), a hit in the session repo"
expect_block "$r4" 'cd "$(git rev-parse --show-toplevel)" && git add new.txt && git commit -m x' "a cd to the top through \$(…), an add the session repo holds"
expect_block "$r2" "cd - && git commit -m x" "cd - is unknown, a hit in the session repo"
expect_crumb "$tmp/plain" "cd \"\$(echo $r2)\" && git commit -m x" "the session directory is not a git work tree" "an unknown cd from a directory that is not a repo"
out="$(crumb "$r2" "cd \"\$(echo $r3)\" && git commit -m x")"
printf '%s' "$out" | grep -q "could not follow a cd" || { echo "FAIL: a hit in the session repo should say the cd was not followed — $out"; fail=1; }
R2="$r2" expect_block "$r3" 'cd "$R2" && git commit -m x' "a cd through a variable set in the environment"
HOME="$r2" expect_block "$r3" "cd && git commit -m x" "a bare cd goes to HOME, not the session repo"
expect_block "$r3" "cd \"\$(echo x)\" && git -C $r2 commit -m x" "an absolute -C after an unknown cd"
expect_block "$r3" "cd \"\$(echo x)\" && git --git-dir=$r2/.git --work-tree=$r2 commit -m x" "an absolute --git-dir=/--work-tree= after an unknown cd"
expect_block "$r3" "cd \"\$(echo x)\" && git --git-dir $r2/.git --work-tree $r2 commit -m x" "an absolute --git-dir/--work-tree as separate words after an unknown cd"
expect_crumb "$r3" "cd \"\$(echo x)\" && git --git-dir=$r2/.git --work-tree=. commit -m x" "follows a cd the hook cannot expand" "a relative --work-tree does not place the command"
expect_crumb "$r3" "cd \"\$(echo x)\" && git --git-dir=$r2/.git commit -m x" "follows a cd the hook cannot expand" "an absolute --git-dir alone does not place the command"
expect_crumb "$r3" "cd \"\$(echo x)\" && git --work-tree=$r2 add c.txt && git --work-tree=$r2 commit -m x" "follows a cd the hook cannot expand" "an absolute --work-tree alone does not place the command"
expect_crumb "$tmp/plain" "cd \"\$(echo x)\" && git --git-dir=$r2/.git commit -m x" "the repo it runs in is unknown" "an absolute --git-dir alone from a directory that is not a repo"
# the placed commits are scanned before an unknown cd is decided, and an add after the last commit is not read
expect_block "$tmp/plain" "git -C $r2 commit -m a; cd \"\$(echo x)\" && git add f" "an unknown cd's add after a placed commit"
expect_block "$tmp/plain" "cd \"\$(echo x)\" && git commit -m a; git -C $r2 commit -m b" "an unknown cd's commit before a placed commit"
expect_block "$r4" "cd \"\$(echo x)\" && git add new.txt && git -C $r3 commit -m x" "an unknown cd's add before a placed commit"
expect_quiet "$r4" "git -C $r3 commit --allow-empty -m a; cd \"\$(echo x)\" && git add new.txt" "an unknown cd's add after the last commit is not read"
# a git config read that fails is a named fail-open, not a scan with the filters left in place
mkdir -p "$tmp/fakegit"; realgit="$(command -v git)"
printf '#!/bin/sh\ncase " $* " in *" config --name-only --get-regexp "*) exit 3 ;; esac\nexec "%s" "$@"\n' "$realgit" > "$tmp/fakegit/git"; chmod +x "$tmp/fakegit/git"
PATH="$tmp/fakegit:$PATH" expect_crumb "$(staged c.txt "k = $AWS")" "git commit -m x" "git config failed" "a git config read that fails"

# --- the diff is read whatever the repo's diff config says ------------------
r="$(staged cfg.txt "k = $AWS")"; git -C "$r" config diff.mnemonicPrefix true
expect_block "$r" "git commit -m x" "diff.mnemonicPrefix"
r="$(staged cfg.txt "k = $AWS")"; git -C "$r" config diff.noprefix true
expect_block "$r" "git commit -m x" "diff.noprefix"
expect_block "$(staged "café.txt" "k = $AWS")" "git commit -m x" "a non-ASCII path git quotes"
expect_block "$(staged "$(printf 'a\tb.txt')" "k = $AWS")" "git commit -m x" "a tab in the path"
r="$(newrepo)"; in_fixture "$r"; printf '*.txt -diff\n' > "$r/.gitattributes"; git -C "$r" add .gitattributes
git -C "$r" -c user.email=t@t -c user.name=t commit -qm attr; printf 'k = %s\n' "$AWS" > "$r/cfg.txt"; git -C "$r" add cfg.txt
expect_block "$r" "git commit -m x" "a -diff attribute"
expect_block "$(staged cfg.txt "$(printf '++ x\nk = %s' "$AWS")")" "git commit -m x" "an added line starting ++ is not a header"
expect_block "$(staged "NOTREE:a.txt" "k = $AWS")" "git commit -m x" "a path that looks like the old not-a-tree sentinel"

# --- programs the target repo configures do not run -------------------------
# progrepo — a repo whose config names a program on each path the scan takes; each
# writes its own marker under $tmp/marks when it runs. 0.ext sorts first, so its
# diff driver runs before the blanked diff.external would stop a diff that lost
# --no-ext-diff (an empty diff.external is a command git cannot run, and dies).
mkdir -p "$tmp/marks"
prog() { printf '#!/bin/sh\necho ran >> "%s"\nif [ -f "${1:-}" ]; then cat "$1"; elif [ $# -eq 0 ]; then cat; fi\n' "$tmp/marks/$1" > "$tmp/marks/$1.sh"; chmod +x "$tmp/marks/$1.sh"; printf '%s' "$tmp/marks/$1.sh"; }
progrepo() {
  local r; r="$(newrepo)" || exit 1; in_fixture "$r"
  { printf '*.tc diff=tc\n*.ext diff=ext\n*.cln filter=cln\n' > "$r/.gitattributes"
    printf 'a\n' > "$r/f.tc"; printf 'a\n' > "$r/0.ext"; printf 'a\n' > "$r/f.cln"
    git -C "$r" add -A && git -C "$r" -c user.email=t@t -c user.name=t commit -qm progs
    mkdir -p "$r/S" && git -C "$r/S" init -q && printf '*.txt filter=sub\n' > "$r/S/.gitattributes" && printf 'a\n' > "$r/S/a.txt"
    git -C "$r/S" add -A && git -C "$r/S" -c user.email=t@t -c user.name=t commit -qm s
    git -C "$r" add S && git -C "$r" -c user.email=t@t -c user.name=t commit -qm sub
    git -C "$r" config core.fsmonitor "$(prog fsmonitor)"
    git -C "$r" config diff.tc.textconv "$(prog textconv)"
    git -C "$r" config diff.ext.command "$(prog extdiff)"
    git -C "$r" config diff.external "$(prog external)"
    git -C "$r" config filter.cln.clean "$(prog clean)"
    git -C "$r/S" config filter.sub.clean "$(prog subclean)"
    sleep 1                        # same-size edits below must look stat-dirty, so git hashes them
    printf 'b\n' > "$r/f.tc"; printf 'b\n' > "$r/0.ext"; printf 'b\n' > "$r/f.cln"; printf 'b\n' > "$r/S/a.txt"
    printf 'k = %s\n' "$AWS" >> "$r/seed.txt"; } >/dev/null 2>&1
  rm -f "$tmp/marks/"*[!h]   # markers only, the .sh scripts stay
  printf '%s' "$r"
}
r="$(progrepo)"
expect_block "$r" "git commit -a -m x" "a repo that configures programs still blocks"
for m in fsmonitor textconv extdiff external clean subclean; do
  [ -e "$tmp/marks/$m" ] && { echo "FAIL: the scan ran the repo's $m program"; fail=1; }
done
# the fixture can fire: plain git runs each program the hook keeps from running
r="$(progrepo)"; ( cd "$r" && { git status; git diff; git diff --no-ext-diff; } >/dev/null 2>&1 )
for m in fsmonitor textconv extdiff external clean subclean; do
  [ -e "$tmp/marks/$m" ] || { echo "FAIL: fixture check — plain git did not run $m, so the row above grades nothing"; fail=1; }
done

# --- the block message ------------------------------------------------------------
out="$(crumb "$(staged cfg.txt "k = $GHP")" "git commit -m x")"
case "$out" in *"secret-scan"*) echo "FAIL: the block message offers the agent the line marker — $out"; fail=1 ;; esac
printf '%s' "$out" | grep -q 'ask the user' || { echo "FAIL: the block message should send the agent to the user — $out"; fail=1; }

# --- the report never carries the value ---------------------------------------
out="$(crumb "$(staged cfg.txt "k = $GHP")" "git commit -m x")"
case "$out" in *"$GHP"*) echo "FAIL: the block message carries the token value"; fail=1 ;; esac
printf '%s' "$out" | grep -q 'cfg.txt:1 github-token' || { echo "FAIL: the block message should name cfg.txt:1 github-token — $out"; fail=1; }

# --- fail open ------------------------------------------------------------------
expect_crumb "$tmp/plain" "git commit -m x" "not a git work tree" "outside a repo"
expect_fail_open "$tmp/plain" "git commit -m 'unterminated"

# --- mutation table -------------------------------------------------------------
# Each row edits a copy of the hook (hook-lib beside it) and reruns one fixture;
# the mutant must flip that row's outcome, or the row above grades nothing.
mdir="$tmp/mut"; mkdir -p "$mdir"; cp "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
mutant() { # mutant <label> <python find> <python replace> <fixture repo> <cmd> <want rc> [file to mutate]
  local label="$1" from="$2" to="$3" repo="$4" c="$5" want="$6" file="${7:-staged-secrets.sh}"
  cp "$hook" "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
  selftest_mutate "$here/$file" "$mdir/$file" "$from" "$to" || return
  hook="$mdir/staged-secrets.sh" selftest_expect_killed "$label" hook_rc_not "$want" "$repo" "$c"
}
mutant "drop ASIA"        '(?:AKIA|ASIA)' '(?:AKIA)'          "$(staged c.txt "k = $ASIA")" "git commit -m x" 0
mutant "drop AKIA"        '(?:AKIA|ASIA)' '(?:ASIA)'          "$(staged c.txt "k = $AWS")" "git commit -m x" 0
mutant "drop gho"         'gh[pousr]_' 'gh[pusr]_'            "$(staged c.txt "k = $GHO")" "git commit -m x" 0
mutant "drop ghs"         'gh[pousr]_' 'gh[pour]_'            "$(staged c.txt "k = $GHS")" "git commit -m x" 0
mutant "drop ghu"         'gh[pousr]_' 'gh[posr]_'            "$(staged c.txt "k = $GHU")" "git commit -m x" 0
mutant "drop ghr"         'gh[pousr]_' 'gh[pous]_'            "$(staged c.txt "k = $GHR")" "git commit -m x" 0
mutant "drop glpat"       '\bglpat-' '\bglpatX-'              "$(staged c.txt "k = $GLPAT")" "git commit -m x" 0
mutant "widen glpat"      'glpat-[A-Za-z0-9_-]{20,}' 'glpat-[A-Za-z0-9_-]{19,}' "$(staged c.txt "k = $GLPAT_SHORT")" "git commit -m x" 2
mutant "drop sk-ant"      'r"\bsk-ant-' 'r"\bsk-antX-'        "$(staged c.txt "k = $ANT_LOWER")" "git commit -m x" 0
mutant "drop sk-"         '("sk-key",         re.compile(r"\bsk-' '("sk-key",         re.compile(r"\bskX-' "$(staged c.txt "k = $SKPLAIN")" "git commit -m x" 0
mutant "sk- needs no upper case" '(?=[\w-]*[A-Z])' '' "$(staged c.txt "k = $SK_KEBAB")" "git commit -m x" 2
mutant "sk- needs no lower case" '(?=[\w-]*[a-z])' '' "$(staged c.txt "k = $SK_NOLOWER")" "git commit -m x" 2
mutant "sk- needs no digit"      '(?=[\w-]*[0-9])' '' "$(staged c.txt "k = $SK_NODIGIT")" "git commit -m x" 2
mutant "drop AIza"        'r"\bAIza' 'r"\bAIzX'               "$(staged c.txt "k = $AIZA")" "git commit -m x" 0
mutant "widen AIza"       '{35}(?![0-9A-Za-z_-])' '{35}'     "$(staged c.txt "k = $AIZA_LONG")" "git commit -m x" 2
mutant "drop sk_live"     'r"\bsk_live_' 'r"\bsk_liveX_'      "$(staged c.txt "k = $STRIPE")" "git commit -m x" 0
mutant "drop npm"         'r"\bnpm_' 'r"\bnpmX_'              "$(staged c.txt "k = $NPM")" "git commit -m x" 0
mutant "widen npm"        '{36}(?![A-Za-z0-9])' '{36}'        "$(staged c.txt "k = $NPM_LONG")" "git commit -m x" 2
mutant "drop github_pat"  '|\bgithub_pat_' '|\bnever_pat_'    "$(staged c.txt "k = $GHPAT")" "git commit -m x" 0
mutant "drop xoxr"        'xox[abpr]' 'xox[abp]'              "$(staged c.txt "k = $SLACK_R")" "git commit -m x" 0
mutant "drop private key" 'r"-----BEGIN [A-Z ]*PRIVATE KEY-----"' 'r"-----BEGIN [A-Z ]*PRIVATE KEYS-----"' "$(staged c.txt "$PKEY")" "git commit -m x" 0
mutant "drop jwt"         '\beyJ[A-Za-z0-9_-]{8,}\.eyJ' '\beyJ[A-Za-z0-9_-]{8,}\.eyX' "$(staged c.txt "k = $JWT")" "git commit -m x" 0
mutant "drop sas"         '[?&]sig=' '[?&]sigX=' "$(staged c.txt "u = $SAS")" "git commit -m x" 0
mutant "drop pem path"    '("pem-file",     re.compile(r"\.pem$")' '("pem-file",     re.compile(r"\.pemX$")' "$(staged k.pem "x")" "git commit -m x" 0
mutant "drop untracked add" 'for p in git(ga, *others, *spec).split("\0"):' 'for p in []:' "$(r="$(newrepo)" && in_fixture "$r" && printf 'k = %s\n' "$AWS" > "$r/n.txt" && printf '%s' "$r")" "git add n.txt && git commit -m x" 0
mutant "widen aws length" '[0-9A-Z]{16}\b' '[0-9A-Z]{15}' "$(staged c.txt "k = $AWS_SHORT")" "git commit -m x" 2
mutant "drop .pub exemption" 're.compile(r"\.pub$")' 'None' "$(staged id_rsa.pub "x")" "git commit -m x" 2
mutant "drop .env.example exemption" 're.compile(r"^\.env\.(example|sample|template)$")' 'None' "$(staged .env.example "x")" "git commit -m x" 2
mutant "drop the allow marker" 'if ALLOW in text:' 'if False:' "$(staged c.txt "k = $GHP  # secret-scan: allow")" "git commit -m x" 2
mutant "drop key path"    '("key-file",     re.compile(r"\.key$")' '("key-file",     re.compile(r"\.keyX$")' "$(staged t.key "x")" "git commit -m x" 0
mutant "drop p12 path"    'r"\.(p12|pfx)$"' 'r"\.(pfx)$"'     "$(staged c.p12 "x")" "git commit -m x" 0
mutant "drop pfx path"    'r"\.(p12|pfx)$"' 'r"\.(p12)$"'     "$(staged c.pfx "x")" "git commit -m x" 0
mutant "drop netrc path"  'r"^\.netrc$"' 'r"^\.netrcX$"'      "$(staged .netrc "x")" "git commit -m x" 0
mutant "drop npmrc path"  'r"^\.npmrc$"' 'r"^\.npmrcX$"'      "$(staged .npmrc "x")" "git commit -m x" 0
mutant "drop id_dsa path" 'id_(rsa|dsa|ecdsa|ed25519)' 'id_(rsa|ecdsa|ed25519)' "$(staged id_dsa "x")" "git commit -m x" 0
mutant "drop git stage"   'if sub in ("add", "stage"):' 'if sub in ("add",):' "$(r="$(newrepo)" && in_fixture "$r" && printf 'k = %s\n' "$AWS" > "$r/n.txt" && printf '%s' "$r")" "git stage n.txt && git commit -m x" 0
mutant "narrow on an unexpandable pathspec" 'ADDS.append(Add(target, [] if wide else specs, force))' 'ADDS.append(Add(target, specs, force))' "$(r="$(newrepo)" && in_fixture "$r" && printf 'k = %s\n' "$AWS" > "$r/n.txt" && printf '%s' "$r")" "git add o.txt \"\$F\" && git commit -m x" 0
mutant "ignore -f"        '([] if force else ["--exclude-standard"])' '["--exclude-standard"]' "$(r="$(newrepo)" && in_fixture "$r" && printf 's.txt\n' > "$r/.gitignore" && printf 'k = %s\n' "$AWS" > "$r/s.txt" && printf '%s' "$r")" "git add -f s.txt && git commit -m x" 0
mutant "-A reads only the subdirectory" '(specs or [":/"])' '(specs or [])' "$(r="$(newrepo)" && in_fixture "$r" && mkdir -p "$r/sub" && printf 'k = %s\n' "$AWS" > "$r/top.txt" && printf '%s' "$r/sub")" "git add -A && git commit -m x" 0
mutant "diff.relative narrows"  '"--no-relative", ' '' "$(r="$(newrepo)" && in_fixture "$r" && mkdir -p "$r/sub" && git -C "$r" config diff.relative true && printf 'k = %s\n' "$AWS" >> "$r/seed.txt" && printf '%s' "$r/sub")" "git add -A && git commit -m x" 0
r="$(staged c.txt "k = $GHP")"
mutant "drop the git-dir"  'argv.append("--git-dir=" + gd)' 'pass' "$tmp" "git --git-dir=$r/.git --work-tree=$r commit -m x" 0
r="$(newrepo)"; in_fixture "$r"; printf 'k = %s\n' "$AWS" >> "$r/seed.txt"
mutant "drop the work-tree" 'argv.append("--work-tree=" + wt)' 'pass' "$tmp" "git --git-dir $r/.git --work-tree $r commit -a -m x" 0
mutant "honour no prefix config" '"--src-prefix=a/", "--dst-prefix=b/"' '"--no-color"' "$(r="$(staged c.txt "k = $AWS")" && git -C "$r" config diff.noprefix true && printf '%s' "$r")" "git commit -m x" 0
mutant "binary by attribute" '"--no-color", "--text",' '"--no-color",' "$(r="$(newrepo)" && in_fixture "$r" && printf '*.txt -diff\n' > "$r/.gitattributes" && git -C "$r" add .gitattributes && printf 'k = %s\n' "$AWS" > "$r/c.txt" && git -C "$r" add c.txt && printf '%s' "$r")" "git commit -m x" 0
mutant "quoted path not unquoted" 'p = unquote(p) if p.startswith("\"") else p' 'p = p' "$(staged "$(printf 'a\tb.txt')" "k = $AWS")" "git commit -m x" 0
mutant "+++ is a header anywhere" 'elif header and line.startswith("+++ "):' 'elif line.startswith("+++ "):' "$(staged c.txt "$(printf '++ x\nk = %s' "$AWS")")" "git commit -m x" 0
mutant "split_git skips -C"  '            if name == "-C":
                d = joined(d, v) or d' '            if False:
                pass' "$tmp" "git -C $(staged c.txt "k = $GHP") commit -m x" 0 hook-lib.py
r="$(newrepo)"; in_fixture "$r"; printf 'k = %s\n' "$AWS" > "$r/new.txt"; printf 'new.txt\n' > "$r/list.txt"
mutant "--pathspec-from-file narrows" '                    wide = True             # the pathspecs are in a file' '                    pass             # the pathspecs are in a file' "$r" "git add --pathspec-from-file list.txt && git commit -m x" 0
mutant "only the first commit" '        COMMITS.append(Commit(target, any(commits_all(a) for a in rest), len(ADDS)))' '        COMMITS.append(Commit(target, any(commits_all(a) for a in rest), len(ADDS))) if not COMMITS else None' "$r" "git commit --allow-empty -m a; git add new.txt; git commit -m b" 0
mutant "an add after the last commit read" 'adds = ADDS[:COMMITS[-1].adds]' 'adds = ADDS' "$r" "git commit --allow-empty -m a; git add new.txt" 2
r3="$(newrepo)"; in_fixture "$r3"; r2="$(staged c.txt "k = $GHP")"
r4="$(newrepo)"; in_fixture "$r4"; printf 'k = %s\n' "$AWS" > "$r4/new.txt"
mutant "a hit in the session repo dropped" 'if blind_found:' 'if False:' "$r2" "cd \"\$(echo $r3)\" && git commit -m x" 0
mutant "an unknown cd allowed before the placed scan" '    targets = []
    for c in COMMITS:' '    if any(c.target.blind for c in COMMITS) or any(a.target.blind for a in ADDS):
        sys.exit(ALLOW_EXIT)
    targets = []
    for c in COMMITS:' "$tmp/plain" "cd \"\$(echo x)\" && git commit -m a; git -C $r2 commit -m b" 0
mutant "an unknown cd add scanned after the last commit" 'adds = ADDS[:COMMITS[-1].adds]' 'adds = ADDS[:COMMITS[-1].adds] + [a for a in ADDS[COMMITS[-1].adds:] if a.target.blind]' "$r4" "git -C $r3 commit --allow-empty -m a; cd \"\$(echo x)\" && git add new.txt" 2
mutant "an absolute --git-dir/--work-tree does not place" 'out.placed = known or (gd_abs and wt_abs)' 'out.placed = known' "$r3" "cd \"\$(echo x)\" && git --git-dir=$r2/.git --work-tree=$r2 commit -m x" 0 hook-lib.py
mutant "a relative --work-tree places" 'wt_abs = v is not None and os.path.isabs(v)' 'wt_abs = v is not None' "$r3" "cd \"\$(echo x)\" && git --git-dir=$r2/.git --work-tree=. commit -m x" 2 hook-lib.py
mutant "an absolute --git-dir alone places" 'out.placed = known or (gd_abs and wt_abs)' 'out.placed = known or gd_abs' "$r3" "cd \"\$(echo x)\" && git --git-dir=$r2/.git commit -m x" 2 hook-lib.py
mutant "an absolute --work-tree alone places" 'out.placed = known or (gd_abs and wt_abs)' 'out.placed = known or wt_abs' "$r3" "cd \"\$(echo x)\" && git --work-tree=$r2 add c.txt && git --work-tree=$r2 commit -m x" 2 hook-lib.py
mutant "a detached redirect target is a pathspec" $'            k += 1 if m.group(2) else 2\n        else:' $'            k += 1\n        else:' "$(r="$(newrepo)" && in_fixture "$r" && printf 'k = %s\n' "$AWS" > "$r/n.txt" && printf '%s' "$r")" "git add o.txt 2> n.txt && git commit -m x" 2 hook-lib.py
mutant "an absolute -C does not place" 'known = known or (v is not None and os.path.isabs(v))' 'pass' "$r3" "cd \"\$(echo x)\" && git -C $r2 commit -m x" 0 hook-lib.py
mutant "the separate-word spelling ignored" '            if not eq:
                if i + 1 >= len(args):' '            if False:
                if i + 1 >= len(args):' "$r3" "cd \"\$(echo x)\" && git --git-dir $r2/.git --work-tree $r2 commit -m x" 0 hook-lib.py
cp "$hook" "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
selftest_mutate "$hook" "$mdir/staged-secrets.sh" 'if blind.subs and blind.top is None:' 'if False:' \
  && hook="$mdir/staged-secrets.sh" selftest_expect_killed "a session directory outside a repo not named" crumb_has "$tmp/plain" "cd \"\$(echo $r2)\" && git commit -m x" "not a git work tree"
PATH="$tmp/fakegit:$PATH" mutant "a failed config read ignored" 'if rc not in (0, 1):' 'if False:' "$(staged c.txt "k = $AWS")" "git commit -m x" 2
# the scan's own breadcrumb rides exit 5, not the findings channel
cp "$hook" "$here/hook-lib.py" "$mdir/"
selftest_mutate "$here/hook-lib.sh" "$mdir/hook-lib.sh" '[ "$rc" -ne 5 ] || hook_allow "$hook_result"' ':' \
  && hook="$mdir/staged-secrets.sh" selftest_expect_killed "drop exit 5" crumb_has "$tmp/plain" "git commit -m x" "not a git work tree"
# each neutralizer, dropped, lets its program run on the progrepo fixture
mark_mutant() { # mark_mutant <label> <find> <replace> <marker>
  local label="$1" r m
  cp "$hook" "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
  selftest_mutate "$hook" "$mdir/staged-secrets.sh" "$2" "$3" || return
  r="$(progrepo)"; hook="$mdir/staged-secrets.sh" run "$r" "git commit -a -m x" >/dev/null
  selftest_expect_killed "$label ($4 did not run)" [ ! -e "$tmp/marks/$4" ]
}
mark_mutant "keep fsmonitor"     '"-c", "core.fsmonitor=false", ' '' fsmonitor
mark_mutant "keep textconv"      'DIFF = ["--no-ext-diff", "--no-textconv", ' 'DIFF = ["--no-ext-diff", ' textconv
mark_mutant "keep diff drivers"  'DIFF = ["--no-ext-diff", ' 'DIFF = [' extdiff
mark_mutant "keep diff.external" 'SAFE = ["--no-pager", "-c", "core.fsmonitor=false", "-c", "diff.external="]
DIFF = ["--no-ext-diff", ' 'SAFE = ["--no-pager", "-c", "core.fsmonitor=false"]
DIFF = [' external
mark_mutant "keep clean filters" '            argv += ["-c", "filter.%s.%s=%s" % (drv, key, val)]' '            pass' clean
mark_mutant "look into submodules" ', "--ignore-submodules=all"]' ']' subclean

selftest_close "staged-secrets-selftest: all rows pass" "staged-secrets self-test clean on what it could reach; see the SKIP line above."
