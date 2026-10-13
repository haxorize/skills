#!/usr/bin/env bash
# staged-secrets — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks the agent's own `git commit` when what it would commit holds a
# token-shaped string or a key-shaped file. A credential that reaches a commit
# is in every clone and reflog; deleting it later un-leaks nothing.
#
# What it reads, at the moment the commit command is about to run:
#   - the staged diff's added lines (`git diff --cached -U0`);
#   - with `git commit -a`/`--all`, or a `git add` / `git stage` earlier in the
#     same command, the unstaged added lines of tracked files too (`git diff
#     -U0`, limited to the add's pathspecs, the whole tree when it names none)
#     — the add has not run yet when this hook fires;
#   - with a `git add` in the same command, the untracked files its pathspecs
#     name (the whole tree, from the top, when it names none or one the
#     scanner cannot expand: `git add -A` run from a subdirectory stages the
#     whole tree), read whole — the non-ignored ones, and with `-f`/`--force`
#     the ignored ones too.
# The diff is read as `a/` / `b/` prefixed text whatever the repo's diff
# config says (`diff.noprefix`, `diff.mnemonicPrefix`, `diff.relative`,
# `-diff` attributes, C-quoted paths), and a `+++` line is a file header only between
# `diff --git` and the first `@@`.
#
# Content shapes, chosen for near-zero false positives (the table is
# CONTENT_RULES below; it grows only on a miss):
#   aws-key        AKIA/ASIA followed by 16 upper-case letters or digits
#   github-token   ghp_, gho_, ghs_, ghu_ or ghr_ followed by 36+ characters,
#                  or github_pat_
#   gitlab-token   glpat- followed by 20+ characters
#   slack-token    xoxa-, xoxb-, xoxp-, xoxr-
#   anthropic-key  sk-ant- followed by 32+ characters
#   sk-key         sk- followed by a 32+ character run (letters, digits, _
#                  and -, so sk-proj- keys too) holding an upper-case
#                  letter, a lower-case letter and a digit — a kebab-case
#                  word run is not one
#   google-api-key AIza followed by exactly 35 characters
#   stripe-key     sk_live_ followed by 24+ characters
#   npm-token      npm_ followed by exactly 36 characters
#   private-key    a -----BEGIN … PRIVATE KEY----- line
#   jwt            eyJ….eyJ….<signature>
#   azure-sas      a sig= query parameter of 20+ characters (a signed URL)
# Path shapes (PATH_RULES): .env and .env.* (not .env.example, .env.sample,
# .env.template), *.pem, *.key, *.p12, *.pfx, .netrc, .npmrc, and an SSH
# private key id_rsa / id_dsa / id_ecdsa / id_ed25519 (not its .pub). A
# deletion of such a path is not a hit.
#
# A line carrying `secret-scan: allow` is not scanned — a fixture's author
# marks a fake token that way. The block message does not offer it: the
# agent asks the user rather than marking a line itself. A path hit has no
# marker: a fixture key file is committed by the user in their own terminal.
#
# The report names the file, the line, and the shape — never the matched
# value, so the secret does not enter the conversation.
#
# Programs the target repo configures do not run: every git call here carries
# `-c core.fsmonitor=false -c diff.external=`, a diff carries `--no-ext-diff
# --no-textconv --ignore-submodules=all`, and each clean/smudge/process filter
# the repo's config names is blanked with `-c filter.<name>.*=` (read with
# `git config`, which runs nothing). The hook fires before the permission
# prompt, so a `cd <untrusted clone> && git commit` would otherwise run that
# clone's code first.
#
# What it does not see: a commit the user runs in a terminal (no git hook
# scans for secrets), pathspecs given to `git commit` itself (`git commit -m x
# f.txt`), `git commit --amend`'s already-committed lines, which files a
# `git add "$F"` or `--pathspec-from-file` names (the whole tree is read
# instead), a git alias from a config file (`git ci` where `~/.gitconfig`
# says `ci = commit`; an alias built on the command line with `-c
# alias.ci=commit` is seen), a `GIT_DIR=` assignment pointing at a `.git`
# directory, and binary or 1 MB+ untracked files.
#
# How the commit may reach git — a quoted flag, a `bash -c` string, a wrapper,
# a compound statement, and how `cd`, `-C`, `--git-dir` and `--work-tree` move
# the repo it runs in (split_git) — is hook-lib.sh / hook-lib.py beside this
# file; this file holds only the commit and add shapes and the patterns.
#
# Fail-open: a malformed payload, a missing python3 or git, a tokeniser error,
# a git call that fails, or a directory that is not a git work tree lets the
# command through, with a one-line stderr breadcrumb. A safety hook that blocks
# on its own errors trains the user to disable it.
#
# Install note: always on — no opt-in.
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/staged-secrets.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.
# staged-secrets-selftest.sh beside this file builds its token fixtures at run
# time, so this repo never holds a token-shaped string; run it after changing
# a rule.
#
# Depends: committing (its rotate-first rule is the remedy this hook names).

set -u
hook_name="staged-secrets"
[[ ${BASH_SOURCE[0]} == */* ]] && hook_dir="${BASH_SOURCE[0]%/*}" || hook_dir=.
. "$hook_dir/hook-lib.sh" 2>/dev/null || { echo "$hook_name: hook-lib.sh not found beside the hook, allowing" >&2; exit 0; }
hook_read_payload
command -v git >/dev/null 2>&1 || hook_allow "git not found"

# --- commit shape, then the scan --------------------------------------------
# on_command records each `git add` and returns at the first `git commit`;
# emit runs the scan in the commit's repo and prints one finding a line, or
# exits ALLOW_EXIT with the breadcrumb when that is not a git work tree.
hook_scan '
import subprocess
ADDS = []
ALLOW = "secret-scan: allow"
CONTENT_RULES = [
    ("aws-key",        re.compile(r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b")),
    ("github-token",   re.compile(r"\bgh[pousr]_[A-Za-z0-9]{36,}|\bgithub_pat_[A-Za-z0-9_]{22,}")),
    ("gitlab-token",   re.compile(r"\bglpat-[A-Za-z0-9_-]{20,}")),
    ("slack-token",    re.compile(r"\bxox[abpr]-[A-Za-z0-9-]{10,}")),
    ("anthropic-key",  re.compile(r"\bsk-ant-[A-Za-z0-9_-]{32,}")),
    ("sk-key",         re.compile(r"\bsk-(?=[\w-]*[A-Z])(?=[\w-]*[a-z])(?=[\w-]*[0-9])[A-Za-z0-9_-]{32,}")),
    ("google-api-key", re.compile(r"\bAIza[0-9A-Za-z_-]{35}(?![0-9A-Za-z_-])")),
    ("stripe-key",     re.compile(r"\bsk_live_[0-9A-Za-z]{24,}")),
    ("npm-token",      re.compile(r"\bnpm_[A-Za-z0-9]{36}(?![A-Za-z0-9])")),
    ("private-key",    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("jwt",            re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}")),
    ("azure-sas",      re.compile(r"[?&]sig=[A-Za-z0-9%/+=]{20,}")),
]
PATH_RULES = [
    ("env-file",     re.compile(r"^\.env(\..+)?$"), re.compile(r"^\.env\.(example|sample|template)$")),
    ("pem-file",     re.compile(r"\.pem$"), None),
    ("key-file",     re.compile(r"\.key$"), None),
    ("pkcs12-file",  re.compile(r"\.(p12|pfx)$"), None),
    ("netrc-file",   re.compile(r"^\.netrc$"), None),
    ("npmrc-file",   re.compile(r"^\.npmrc$"), None),
    ("ssh-key-file", re.compile(r"^id_(rsa|dsa|ecdsa|ed25519)"), re.compile(r"\.pub$")),
]
SAFE = ["--no-pager", "-c", "core.fsmonitor=false", "-c", "diff.external="]
DIFF = ["--no-ext-diff", "--no-textconv", "--no-renames", "--no-relative", "--ignore-submodules=all"]
PATCH = DIFF + ["-U0", "--no-color", "--text", "--src-prefix=a/", "--dst-prefix=b/"]
NAMES = DIFF + ["--name-only", "--diff-filter=d", "-z"]

def on_command(seg, curdir):
    args = git_args(seg)
    if args is None:
        return None
    d, sub, rest, gd, wt = split_git(args, curdir)
    if sub in ("add", "stage"):
        specs, force, wide, dashdash = [], False, False, False
        for a in rest:
            if dashdash or not a.startswith("-") or a == "-":
                p = expand(a)
                if p is None:
                    wide = True             # a pathspec the scanner cannot read: the whole tree
                else:
                    specs.append(p)
            elif a == "--":
                dashdash = True
            elif a.startswith("--"):
                name = a.split("=", 1)[0]
                if len(name) > 2 and "--force".startswith(name):
                    force = True            # --pathspec-from-file takes no other pathspec: the whole tree
            elif "f" in a[1:]:
                force = True
        ADDS.append((d, gd, wt, [] if wide else specs, force))
        return None
    if sub == "commit":
        return (d, gd, wt, any(commits_all(a) for a in rest))
    return None

def commits_all(a):
    """`-a`/`--all`, or `a` in a short-option cluster before an option that
    takes the rest of the word as its value (`-am msg` is all, `-ma` is not)."""
    if a in ("-a", "--all"):
        return True
    if not re.match(r"^-[A-Za-z]+$", a):
        return False
    for ch in a[1:]:
        if ch == "a":
            return True
        if ch in "mFCctS":
            return False
    return False

def run(argv):
    r = subprocess.run(argv, capture_output=True, stdin=subprocess.DEVNULL)
    return r.returncode, r.stdout.decode("utf-8", "replace")

def gitopts(d, gd, wt):
    """`git -C d` plus the options that keep the repo from running its own
    programs, and the repo location the command named."""
    argv = ["git", "-C", d] + SAFE
    if gd:
        argv.append("--git-dir=" + gd)
    if wt:
        argv.append("--work-tree=" + wt)
    rc, out = run(argv + ["config", "--name-only", "--get-regexp", r"^filter\..*\.(clean|smudge|process)$"])
    for drv in sorted({n[len("filter."):].rsplit(".", 1)[0] for n in out.split("\n") if n.startswith("filter.")}):
        for key, val in (("clean", ""), ("smudge", ""), ("process", ""), ("required", "false")):
            argv += ["-c", "filter.%s.%s=%s" % (drv, key, val)]
    return argv

def git(g, *argv):
    rc, out = run(g + list(argv))
    if rc != 0:
        raise OSError("git %s failed" % argv[0])
    return out

def unquote(s):
    """A C-quoted path as git writes one, unquoted."""
    body, out, i = s[1:-1] if s.endswith("\"") else s[1:], bytearray(), 0
    esc = {"a": 7, "b": 8, "t": 9, "n": 10, "v": 11, "f": 12, "r": 13}
    while i < len(body):
        c = body[i]
        if c == "\\" and i + 1 < len(body):
            n = body[i + 1]
            if re.match(r"[0-7]{3}", body[i + 1:i + 4]):
                out.append(int(body[i + 1:i + 4], 8))
                i += 4
                continue
            out.append(esc.get(n, ord(n) if ord(n) < 256 else 63))
            i += 2
            continue
        out += c.encode("utf-8")
        i += 1
    return out.decode("utf-8", "replace")

def added_lines(diff):
    """(path, line number in the new file, text) for each added line. A `+++`
    line is a header only between `diff --git` and the first `@@`; after that
    it is an added line whose text begins `++`."""
    path, n, header = None, 0, False
    for line in diff.split("\n"):
        if line.startswith("diff --git "):
            path, header = None, True
        elif header and line.startswith("+++ "):
            p = line[4:]
            p = unquote(p) if p.startswith("\"") else p
            path = p[2:] if p.startswith("b/") else None   # /dev/null: a deletion
        elif line.startswith("@@"):
            header = False
            m = re.match(r"^@@ -\S+ \+(\d+)", line)
            n = int(m.group(1)) if m else 0
        elif not header and line.startswith("+") and path:
            yield path, n, line[1:]
            n += 1

def content_hits(path, n, text):
    if ALLOW in text:
        return
    for name, rx in CONTENT_RULES:
        if rx.search(text):
            yield "%s:%d %s" % (path, n, name)
            return

def path_hit(path):
    base = os.path.basename(path)
    for name, rx, unless in PATH_RULES:
        if rx.search(base) and not (unless and unless.search(base)):
            return "%s %s" % (path, name)
    return None

def emit(hit):
    try:
        scan_commit(*hit)
    except (OSError, ValueError) as e:
        sys.stdout.write(str(e))
        sys.exit(4)

def scan_commit(d, gd, wt, commit_all):
    g = gitopts(d, gd, wt)
    rc, top = run(g + ["rev-parse", "--show-toplevel"])   # fails inside .git and in a bare repo
    top = top.strip()
    if rc != 0 or not top:
        sys.stdout.write("not a git work tree (%s)" % d)
        sys.exit(ALLOW_EXIT)
    g = gitopts(top, gd, wt)
    out = []
    paths = set(git(g, "diff", "--cached", *NAMES).split("\0")) - {""}
    diffs = [git(g, "diff", "--cached", *PATCH)]
    if commit_all:
        diffs.append(git(g, "diff", *PATCH))
        paths |= set(git(g, "diff", *NAMES).split("\0")) - {""}
    for ad, agd, awt, specs, force in ADDS:
        ga = gitopts(ad, agd, awt)
        atop = git(ga, "rev-parse", "--show-toplevel").strip()
        spec = ["--"] + (specs or [":/"])
        diffs.append(git(ga, "diff", *PATCH, *spec))
        paths |= set(git(ga, "diff", *NAMES, *spec).split("\0")) - {""}
        others = ["ls-files", "--others", "--full-name", "-z"] + ([] if force else ["--exclude-standard"])
        for p in git(ga, *others, *spec).split("\0"):
            if not p:
                continue
            paths.add(p)
            full = os.path.join(atop, p)
            try:
                if os.path.getsize(full) > 1 << 20:
                    continue
                data = open(full, "rb").read()
            except OSError:
                continue
            if b"\0" in data:
                continue
            for i, text in enumerate(data.decode("utf-8", "replace").split("\n"), 1):
                out.extend(content_hits(p, i, text))
    for diff in diffs:
        for path, n, text in added_lines(diff):
            out.extend(content_hits(path, n, text))
    for p in sorted(paths):
        h = path_hit(p)
        if h:
            out.append(h)
    seen = []
    for h in out:
        if h not in seen:
            seen.append(h)
    sys.stdout.write("\n".join(seen))
'
findings="$hook_result"
[ -n "$findings" ] || exit 0

{
  echo "staged-secrets: blocked a git commit — what it would commit holds a credential shape."
  printf '%s\n' "$findings" | sed 's/^/  /'
  echo "  The value is not shown here. Unstage it (git restore --staged <path>) and move it"
  echo "  to an environment variable or the secret store. If it was ever pushed, shared or"
  echo "  committed before, it is leaked: ask the user to rotate it first (committing's"
  echo "  rotate-first rule). If you believe the value is a fake one, stop and ask the user;"
  echo "  do not change the file to get past this check."
} >&2
exit 2
