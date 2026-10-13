#!/usr/bin/env bash
# rename-safety — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks in-place edits in an opted-in directory: `sed -i` (also gsed, a
# path-prefixed sed, and options before the -i), `perl -i` / `ruby -i` (`-pi`,
# `-pi.bak`, `-i -pe`, `-Mstrict -i`), and `xargs` feeding any of those. On BSD sed, `sed -i
# 's/a/b/'` silently no-ops (the first argument is taken as the backup
# suffix); on either platform, an unanchored pattern rewrites files nobody
# listed. The fix is the same in both cases: list the matches, then use the
# edit tools on each.
#
# Only an in-place flag after sed/perl/ruby counts, and a short-option cluster
# is read left to right: an `i` before any letter that takes a value is the
# flag (`-pi.bak`, `-Ei`); a letter that takes the next token as its value
# (`-e`, `-f`; perl `-M`; ruby `-r`, `-C`) ends the cluster and skips that token
# (`perl -e '-i'` runs the program `-i`; `-Mstrict` names a module); a letter
# whose value is only ever attached (sed `-l`, perl `-l -x -C -0 -d -D -F`,
# ruby `-0 -K -F -x`) ends the cluster and skips nothing. Reads of a pipeline
# (`xargs grep | sed -n`), and a mention in a commit message, an echo, a grep
# pattern, a handoff, or a heredoc no shell consumes, pass.
#
# How the flag may reach the program — a quoted `-i`, a `bash -c` string,
# `eval`, a shell-fed heredoc, a variable, a wrapper, a compound statement,
# `find -exec`, `xargs`, and how `cd`/`pushd` move the directory the command
# runs in — is hook-lib.sh / hook-lib.py beside this file; the lib's header is
# that part of the contract. This file holds only the in-place shapes and the
# opt-in.
#
# Opt-in by directory, judged by target: an edit is judged when a file it
# names lies in a directory opted in — one that holds a
# `.claude/rename-safety` file, or has an ancestor up to $HOME that does, or
# sits under an entry of RENAME_SAFETY_DIRS (colon-separated; empty elements
# are ignored). The file arguments are read the way the program reads them,
# resolved from the directory the segment runs in (the payload's `cwd`, else
# $PWD, moved by any `cd`/`pushd` the lib could expand), with `~` and `$VAR`
# expanded from the environment. When every file lies outside an opted-in
# directory, the edit runs: a handoff marker under $TMPDIR is not the repo.
# When a file list is not all literal — a glob, an unexpandable variable,
# `{}`, or files fed by `xargs` or `find -exec` — the directory the segment
# runs in (and a glob's literal parent) is what is judged, as before.
#
# Inside an opted-in directory one shape still runs: BSD `sed -i ''` (or an
# attached suffix, `-i.bak`) with exactly one substitution and no `g` flag,
# on exactly one literal file, not fed by `xargs` or `find`. That is the edit
# the harness itself suggests, and it cannot reach a file nobody listed. A
# second file, a second expression, a `-f` script, a `g` flag, the GNU `-i
# 's/…'` form (on BSD the expression becomes the backup suffix and the edit
# no-ops), and every `perl -i` / `ruby -i` are blocked, and the message points
# at the Edit tool.
#
# Fail-open: a malformed payload, missing python3, a tokeniser error, or a
# payload cwd that is not a directory lets the command through, with a
# one-line stderr breadcrumb so drift shows in the debug log. A safety hook
# that blocks on its own errors trains the user to disable it.
#
# Install note: opt a directory in with:  touch .claude/rename-safety   (at that repo's root)
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/rename-safety.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.
# rename-safety-selftest.sh beside this file runs the expect/reject payload
# table; run it after changing a rule.
#
# Depends: implement and discoverable-code (their edit-from-a-match-list lines
# name this hook as the mechanical half where it is wired and the directory is
# opted in, and stand in for it everywhere else).

set -u
hook_name="rename-safety"
[[ ${BASH_SOURCE[0]} == */* ]] && hook_dir="${BASH_SOURCE[0]%/*}" || hook_dir=.
. "$hook_dir/hook-lib.sh" 2>/dev/null || { echo "$hook_name: hook-lib.sh not found beside the hook, allowing" >&2; exit 0; }
hook_read_payload
[ -d "$cwd" ] || hook_allow "directory $cwd unreadable"

# --- shape and opt-in check ---------------------------------------------------
# on_command sees each program that runs; sed/gsed, perl, and ruby segments
# are read for an in-place flag, then judged by where their files lie. A
# segment that may run returns None, so the scan reads on to the next one.
# emit prints the shape name, then the file arguments of the blocked segment,
# one per line.
RENAME_SAFETY_CWD="$cwd"; export RENAME_SAFETY_CWD
hook_scan '
# Short-option letters that take a value. NEXT_TOKEN: the cluster ends there
# and the next token is the value. ATTACHED: the cluster ends there and the
# next token is an argument in its own right (`sed -l -i` is in place).
NEXT_TOKEN = {"sed": set("ef"), "perl": set("eEMmI"), "ruby": set("eIrCE")}
ATTACHED = {"sed": set("l"), "perl": set("lxC0dDF"), "ruby": set("0KFx")}
CODE = {"sed": set("ef"), "perl": set("eE"), "ruby": set("e")}   # letters whose value is the program
ENVVAR = re.compile(r"\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))")
GLOB = re.compile(r"[*?\[]")
HOME = os.path.normpath(os.environ.get("HOME") or "/")

def inplace(prog, args):
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--":
            return False
        if prog == "sed" and a.startswith("--in-place"):
            return True
        if re.match(r"^-[A-Za-z]", a):
            for ch in a[1:]:
                if ch == "i":
                    return True
                if ch in NEXT_TOKEN[prog]:
                    if ch == a[-1]:          # value is the next token
                        i += 1
                    break
                if ch in ATTACHED[prog] or not ch.isalpha():
                    break
        i += 1
    return False

def operands(prog, args):
    """(file arguments, program texts, BSD form, script file) as the program
    reads them. BSD form: the sed in-place suffix is attached (`-i.bak`) or is
    the next word and empty, so BSD and GNU sed both edit in place."""
    pos, code, bsd, script_file, i = [], [], False, False, 0
    while i < len(args):
        a = args[i]
        if a == "--":
            pos += args[i + 1:]
            break
        if a.startswith("--"):
            if prog == "sed" and a.startswith("--expression"):
                code.append(a.partition("=")[2])
            elif prog == "sed" and a.startswith("--file"):
                script_file = True
        elif re.match(r"^-[A-Za-z]", a):
            j = 1
            while j < len(a):
                ch = a[j]
                if ch == "i":
                    if prog == "sed":
                        if a[j + 1:]:
                            bsd = True
                        elif i + 1 < len(args) and args[i + 1] == "":
                            bsd, i = True, i + 1
                    break
                if ch in NEXT_TOKEN[prog]:
                    val = a[j + 1:]
                    if not val and i + 1 < len(args):
                        i += 1
                        val = args[i]
                    if ch in CODE[prog]:
                        code.append(val)
                    elif prog == "sed":
                        script_file = True
                    break
                if ch in ATTACHED[prog] or not ch.isalpha():
                    break
                j += 1
        else:
            pos.append(a)
        i += 1
    if not code and not script_file and pos:   # the first word is the program
        code.append(pos[0])
        pos = pos[1:]
    return pos, code, bsd, script_file

def one_substitution(e):
    """One `s` command, at most a line address before it, no `g` and no `w`."""
    m = re.match(r"^(?:[0-9]+(?:,[0-9]+)?)?s([^\\\n])", e)
    if not m:
        return False
    d, k, parts = m.group(1), m.end(), 0
    while k < len(e) and parts < 2:
        if e[k] == "\\":
            k += 2
            continue
        if e[k] == "\n":
            return False
        parts += e[k] == d
        k += 1
    return parts == 2 and re.fullmatch(r"[0-9pI]*", e[k:]) is not None

def resolve(base, path):
    """The absolute path a file argument names, or None when it is not literal."""
    if "`" in path or path == "{}":
        return None
    def env(m):
        v = os.environ.get(m.group(1) or m.group(2))
        if v is None:
            raise KeyError
        return v
    try:
        path = ENVVAR.sub(env, path)
    except KeyError:
        return None
    if "$" in path:
        return None
    return os.path.normpath(os.path.join(base, os.path.expanduser(path)))

def opted(d):
    """True when directory d is in an opted-in tree."""
    walk = d
    while True:
        if os.path.isfile(os.path.join(walk, ".claude", "rename-safety")):
            return True
        if walk in ("/", HOME):
            break
        walk = os.path.dirname(walk)
    for r in os.environ.get("RENAME_SAFETY_DIRS", "").split(":"):
        r = os.path.normpath(r) if r else ""                       # an empty element opts in nothing
        if r and (d == r or d.startswith(r.rstrip("/") + "/")):
            return True
    return False

def on_command(seg, curdir):
    head = progname(seg[0])
    prog = {"sed": "sed", "gsed": "sed", "perl": "perl", "ruby": "ruby"}.get(head)
    if not prog or not inplace(prog, seg[1:]):
        return None
    shape = "sed -i" if prog == "sed" else "perl/ruby -i"
    cwd = os.path.normpath(os.environ.get("RENAME_SAFETY_CWD") or os.getcwd())
    start = cwd if curdir is None else os.path.normpath(os.path.join(cwd, curdir))
    if not os.path.isdir(start):          # a cd to a missing dir falls back to the payload cwd
        start = cwd
    files, code, bsd, script_file = operands(prog, seg[1:])
    paths = [resolve(start, f) if not GLOB.search(f) else None for f in files]
    literal = files and None not in paths and not fed_by()
    if literal:
        judged = [p for p in paths if opted(os.path.dirname(p))]
        if not judged:
            return None                   # every file lies outside an opted-in directory
    else:
        dirs = [start]
        for f in files:                   # a glob is judged by its literal parent too
            if GLOB.search(f):
                parent = resolve(start, os.path.dirname(GLOB.split(f, 1)[0]) or ".")
                if parent:
                    dirs.append(parent)
        if not any(opted(d) for d in dirs):
            return None
    if (prog == "sed" and bsd and literal and len(files) == 1 and not script_file
            and len(code) == 1 and one_substitution(code[0])):
        return None                       # one substitution in one listed file
    return (shape, files[:20])

def emit(hit):
    shape, files = hit
    sys.stdout.write(shape + "".join("\n" + f for f in files))
'
[ -n "$hook_result" ] || exit 0
shape="${hook_result%%$'\n'*}"
files=""; [ "$hook_result" != "$shape" ] && files="${hook_result#*$'\n'}"

# --- report and block -------------------------------------------------------
# The file arguments the command names. Files that arrive through find, xargs,
# or a glob are not visible here, so an empty list is not an empty edit.
{
  echo "rename-safety: blocked an in-place edit ($shape) in a directory opted in to rename-safety."
  echo "  command: $cmd"
  if [ -n "$files" ]; then
    echo "  file arguments (files from find, xargs, or a glob are not listed):"
    printf '%s\n' "$files" | sed 's/^/    /'
  fi
  echo "  Use the Edit tool on each file instead: list the matches (grep -rn), edit"
  echo "  each one, and re-search the old name to zero afterwards. The hook lets"
  echo "  through one substitution with no g flag on one listed file in the BSD"
  echo "  form (sed -i '' 's/old/new/' file), and any edit whose files all lie"
  echo "  outside the opted-in directory."
} >&2
exit 2
