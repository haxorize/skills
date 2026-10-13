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
# escape; the commit shapes (staged file, `-a`/`-am`, `git add <path>` and
# `git add .` in the same command, `git -C`, `cd … &&`); the non-commit and
# outside-a-repo allows; a deleted key file; the report never carrying the
# value; the malformed-payload fail-open table. The mutation table at the end
# narrows each content alternative and widens two exemptions on a copy of the
# hook, and each mutant must flip its row. What it does not grade: hook-lib's
# command shapes (commit-bypass-selftest.sh owns those).
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/staged-secrets.sh"
# Temp-file template and guard: scripts/README.md § Temp files.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/staged-secrets-selftest.XXXXXX" 2>/dev/null)"
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
  echo "staged-secrets-selftest: no usable temp directory (TMPDIR=${TMPDIR:-unset}) — nothing ran" >&2
  exit 4
fi
trap 'rm -rf "$tmp"' EXIT
command -v git >/dev/null 2>&1 || { echo "staged-secrets-selftest: git not found — nothing ran" >&2; exit 4; }

. "$here/selftest-lib.sh"

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
# clean neighbours: one character short, a wrong letter, a public header
AWS_SHORT="AK""IA$(rep Q 15)"
GHP_SHORT="gh""p_$(rep a 35)"
SLACK_Z="xo""xz-$(rep 1 12)"
PUBKEY="-----BEGIN PUBLIC KEY-----"
JWT_ONE="ey""J$(rep a 10)"
SAS_SHORT="https://x/f?s""ig=$(rep A 10)"

newrepo() { # newrepo — prints a fresh repo with one commit (called in $(…), so no counter)
  local r
  r="$(mktemp -d "$tmp/repo.XXXXXX")" || { echo "FAIL: no fixture repo" >&2; return 1; }
  { git -C "$r" init -q && printf 'seed\n' > "$r/seed.txt" &&
    git -C "$r" add seed.txt && git -C "$r" -c user.email=t@t -c user.name=t commit -qm seed; } >/dev/null 2>&1
  infixture "$r" || return 1
  printf '%s' "$r"
}
# infixture <dir> — true only for a git work tree of its own under $tmp, so a
# fixture write can never land in the checkout running this selftest
infixture() {
  case "$1" in "$tmp"/repo.*) ;; *) echo "FAIL: fixture path '$1' is not under $tmp — stopping" >&2; exit 1 ;; esac
  [ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$1" && pwd -P)" ] ||
    { echo "FAIL: '$1' is not its own git work tree — stopping" >&2; exit 1; }
}
staged() { # staged <relpath> <content> — a repo with that file staged
  local r; r="$(newrepo)" || exit 1
  infixture "$r"
  mkdir -p "$(dirname "$r/$1")" && printf '%s\n' "$2" > "$r/$1" && git -C "$r" add -- "$1"
  printf '%s' "$r"
}

# --- content shapes, staged: block --------------------------------------------
for v in AWS ASIA GHP GHO GHPAT SLACK_A SLACK_B SLACK_P SLACK_R PKEY PKEY_BARE JWT SAS; do
  expect_block "$(staged cfg.txt "key = ${!v}")" "git commit -m x" "$v staged"
done
# --- clean neighbours: allow --------------------------------------------------
for v in AWS_SHORT GHP_SHORT SLACK_Z PUBKEY JWT_ONE SAS_SHORT; do
  expect_quiet "$(staged cfg.txt "key = ${!v}")" "git commit -m x" "$v neighbour"
done
expect_quiet "$(staged cfg.txt "token = \"$GHP\"  # secret-scan: allow")" "git commit -m x" "allow marker"
expect_block "$(staged cfg.txt "$(printf 'a = %s  # secret-scan: allow\nb = %s' "$GHP" "$GHO")")" \
  "git commit -m x" "the marker covers its own line only"

# --- path shapes ----------------------------------------------------------------
for p in .env .env.local sub/.env.production key.pem id_rsa id_ed25519 id_ecdsa; do
  expect_block "$(staged "$p" "x=1")" "git commit -m x" "path $p"
done
for p in .env.example .env.sample .env.template .envrc id_rsa.pub notes.pem.txt; do
  expect_quiet "$(staged "$p" "x=1")" "git commit -m x" "path neighbour $p"
done
r="$(staged .env "x=1")"; infixture "$r"; git -C "$r" -c user.email=t@t -c user.name=t commit -qm env >/dev/null
git -C "$r" rm -q --cached .env
expect_quiet "$r" "git commit -m x" "a staged deletion of .env"

# --- commit shapes ----------------------------------------------------------------
r="$(newrepo)"; infixture "$r"; printf 'k = %s\n' "$AWS" >> "$r/seed.txt"
expect_quiet "$r" "git commit -m x" "unstaged change, plain commit"
expect_block "$r" "git commit -a -m x" "-a"
expect_block "$r" "git commit -am x" "-am"
expect_block "$r" "git commit --all -m x" "--all"
expect_quiet "$r" "git commit -ma" "-ma: a is the message"
expect_block "$r" "git add seed.txt && git commit -m x" "add of a tracked path in the same command"
r="$(newrepo)"; infixture "$r"; printf 'k = %s\n' "$AWS" > "$r/new.txt"; printf 'ok\n' > "$r/other.txt"
expect_block "$r" "git add new.txt && git commit -m x" "add of an untracked path"
expect_block "$r" "git add . && git commit -m x" "add ."
expect_block "$r" "git add -A; git commit -m x" "add -A"
expect_quiet "$r" "git add other.txt && git commit -m x" "add names another path"
expect_quiet "$r" "git status" "not a commit"
r="$(newrepo)"; infixture "$r"; printf 'id\n' > "$r/id_rsa"
expect_block "$r" "git add id_rsa && git commit -m x" "untracked key file added in the same command"
r="$(staged sub/cfg.txt "k = $GHP")"; infixture "$r"
expect_block "$tmp" "git -C $r commit -m x" "git -C"
expect_block "$tmp" "cd $r/sub && git commit -m x" "cd then commit"
expect_block "$r" "bash -c 'git commit -m x'" "commit inside bash -c"

# --- the report never carries the value ---------------------------------------
out="$(crumb "$(staged cfg.txt "k = $GHP")" "git commit -m x")"
case "$out" in *"$GHP"*) echo "FAIL: the block message carries the token value"; fail=1 ;; esac
printf '%s' "$out" | grep -q 'cfg.txt:1 github-token' || { echo "FAIL: the block message should name cfg.txt:1 github-token — $out"; fail=1; }

# --- fail open ------------------------------------------------------------------
mkdir -p "$tmp/plain"
expect_crumb "$tmp/plain" "git commit -m x" "not a git work tree" "outside a repo"
expect_fail_open "$tmp/plain" "git commit -m 'unterminated"

# --- mutation table -------------------------------------------------------------
# Each row edits a copy of the hook (hook-lib beside it) and reruns one fixture;
# the mutant must flip that row's outcome, or the row above grades nothing.
mdir="$tmp/mut"; mkdir -p "$mdir"; cp "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
mutant() { # mutant <label> <python find> <python replace> <fixture repo> <cmd> <want rc>
  local label="$1" from="$2" to="$3" repo="$4" c="$5" want="$6" rc
  python3 - "$hook" "$mdir/staged-secrets.sh" "$from" "$to" <<'PY' || { echo "FAIL (mutant '$label': pattern not found in the hook)"; fail=1; return; }
import sys
src, dst, a, b = sys.argv[1:]
s = open(src).read()
if a not in s:
    sys.exit(1)
open(dst, "w").write(s.replace(a, b, 1))
PY
  rc="$(hook="$mdir/staged-secrets.sh" run "$repo" "$c")"
  [ "$rc" = "$want" ] || { echo "FAIL (mutant '$label' survived: rc=$rc, the row should flip to $want)"; fail=1; }
}
mutant "drop ASIA"        '(?:AKIA|ASIA)' '(?:AKIA)'          "$(staged c.txt "k = $ASIA")" "git commit -m x" 0
mutant "drop AKIA"        '(?:AKIA|ASIA)' '(?:ASIA)'          "$(staged c.txt "k = $AWS")" "git commit -m x" 0
mutant "drop gho"         'gh[po]_' 'gh[p]_'                  "$(staged c.txt "k = $GHO")" "git commit -m x" 0
mutant "drop github_pat"  '|\bgithub_pat_' '|\bnever_pat_'    "$(staged c.txt "k = $GHPAT")" "git commit -m x" 0
mutant "drop xoxr"        'xox[abpr]' 'xox[abp]'              "$(staged c.txt "k = $SLACK_R")" "git commit -m x" 0
mutant "drop private key" 'r"-----BEGIN [A-Z ]*PRIVATE KEY-----"' 'r"-----BEGIN [A-Z ]*PRIVATE KEYS-----"' "$(staged c.txt "$PKEY")" "git commit -m x" 0
mutant "drop jwt"         '\beyJ[A-Za-z0-9_-]{8,}\.eyJ' '\beyJ[A-Za-z0-9_-]{8,}\.eyX' "$(staged c.txt "k = $JWT")" "git commit -m x" 0
mutant "drop sas"         '[?&]sig=' '[?&]sigX=' "$(staged c.txt "u = $SAS")" "git commit -m x" 0
mutant "drop pem path"    '("pem-file",     re.compile(r"\.pem$")' '("pem-file",     re.compile(r"\.pemX$")' "$(staged k.pem "x")" "git commit -m x" 0
mutant "drop untracked add" 'for p in git(ad, "ls-files", "--others", "--exclude-standard", "-z", *spec).split("\0"):' 'for p in []:' "$(r="$(newrepo)" && infixture "$r" && printf 'k = %s\n' "$AWS" > "$r/n.txt" && printf '%s' "$r")" "git add n.txt && git commit -m x" 0
mutant "widen aws length" '[0-9A-Z]{16}\b' '[0-9A-Z]{15}' "$(staged c.txt "k = $AWS_SHORT")" "git commit -m x" 2
mutant "drop .pub exemption" 're.compile(r"\.pub$")' 'None' "$(staged id_rsa.pub "x")" "git commit -m x" 2
mutant "drop .env.example exemption" 're.compile(r"^\.env\.(example|sample|template)$")' 'None' "$(staged .env.example "x")" "git commit -m x" 2
mutant "drop the allow marker" 'if ALLOW in text:' 'if False:' "$(staged c.txt "k = $GHP  # secret-scan: allow")" "git commit -m x" 2

[ "$fail" = 0 ] && echo "staged-secrets-selftest: all rows pass"
exit "$fail"
