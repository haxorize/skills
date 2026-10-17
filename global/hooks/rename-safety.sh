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
# whose value is only ever attached (sed `-l`, perl `-x -C -d -D -F`, ruby
# `-K -F -x`) ends the cluster and skips nothing; perl `-0 -l` and ruby `-0`
# take only digits, so the cluster goes on after them (`perl -0pi`). A GNU sed long
# option is read as getopt reads it, abbreviations included (`--in` is
# `--in-place`). Reads of a pipeline (`xargs grep | sed -n`), and a mention in
# a commit message, an echo, a grep pattern, a handoff, or a heredoc no shell
# consumes, pass.
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
# expanded by the lib's `expand()`, whose header names the variables it
# leaves unexpanded. Every path is judged with its symlinks
# resolved, both where the file really lives and where the name sits, so
# `~/.claude/skills/<skill>/…` reaching an opted-in checkout through a link is
# judged as the checkout; $HOME and the RENAME_SAFETY_DIRS entries are
# resolved the same way. When every file lies outside an opted-in directory,
# the edit runs: a handoff marker under $TMPDIR is not the repo. When a file
# list is not all literal — a glob, an unexpandable variable, `{}`, or files
# fed by `xargs` or `find -exec` — the directory the segment runs in (and a
# glob's literal parent) is what is judged. After a `cd` the lib cannot
# expand (`cd "$(…)"`, a variable unset in the hook's environment) the
# payload's cwd stands in for that directory: an edit judged opted in there
# is blocked, and one that is not runs with a breadcrumb saying it was not
# judged where it runs, unless every file it names is absolute. A file named
# through a variable the command itself rebinds (`export D="$D"`, `for D in
# …`, `D=…; sed -i … "$D/f"`) is judged by the directory it runs in and by
# the variable's value from before the command: opted in either way blocks,
# and neither runs with a breadcrumb saying the target was not known.
#
# Inside an opted-in directory one shape still runs: `sed` (not `gsed`, which
# reads `''` as the script) in the BSD form `-i ''` (or an attached suffix,
# `-i.bak`), with exactly one substitution whose only flags are a number or
# `I`, on exactly one literal file, not fed by `xargs` or `find`. That is the
# edit the harness itself suggests, and it cannot reach a file nobody listed.
# A second file, a second expression, a `-f` script, `-n` / `--quiet` (it
# empties the file), a `g`, `p`, `w` or `e` flag, the GNU `-i 's/…'` form (on
# BSD the expression becomes the backup suffix and the edit no-ops), and
# every `perl -i` / `ruby -i` are blocked, and the message points at the Edit
# tool.
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
# table and a mutation table; run it after changing a rule.
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
hook_scan '
# Short-option letters that take a value. NEXT_TOKEN: the cluster ends there
# and the next token is the value. ATTACHED: the cluster ends there and the
# next token is an argument in its own right (`sed -l -i` is in place).
NEXT_TOKEN = {"sed": set("ef"), "perl": set("eEMmI"), "ruby": set("eIrCE")}
ATTACHED = {"sed": set("l"), "perl": set("xCdDF"), "ruby": set("KFx")}
CODE = {"sed": set("e"), "perl": set("eE"), "ruby": set("e")}   # letters whose value is the program
# Letters whose attached value is only digits (`-0777`, `-0x1F`, `-l012`), so
# the cluster goes on after them: `perl -0pi` and `-lpi` are in place.
DIGITS = {"sed": set(), "perl": set("0l"), "ruby": set("0")}
# GNU sed long options, so an abbreviation (`--in`, `--expr=`) is read the way
# getopt reads it: an exact name, else the one name it is a prefix of.
SED_LONG = {"in-place": "i", "expression": "e", "file": "f", "quiet": "n", "silent": "n",
            "line-length": "l", "null-data": "", "zero-terminated": "", "separate": "",
            "sandbox": "", "debug": "", "posix": "", "regexp-extended": "", "unbuffered": "",
            "follow-symlinks": "", "binary": "", "help": "", "version": ""}
GLOB = re.compile(r"[*?\[]")
HOME = os.path.realpath(os.environ.get("HOME") or "/")
UNJUDGED = []                       # (shape, why) for in-place edits whose target the scanner could not know
CD = "after a cd the hook cannot expand, judged against the payload cwd, which is not opted in"
REBOUND = ("on a path through a variable the command rebinds, judged against the directory it runs in "
           "and the variable\x27s value before the command, neither opted in")

def sed_long(name):
    """The short letter a GNU sed long option stands for ("" for one that
    neither edits nor carries code), or None when it names no option."""
    if name in SED_LONG:
        return SED_LONG[name]
    hits = [n for n in SED_LONG if n.startswith(name)]
    return SED_LONG[hits[0]] if len(hits) == 1 else None

def parse(prog, args):
    """(in place, file arguments, program texts, BSD form, script file, quiet)
    as the program reads its arguments. BSD form: the sed in-place suffix is
    attached (`-i.bak`) or is the next word and empty, so BSD and GNU sed both
    edit in place. Quiet: sed `-n`, which drops every unprinted line."""
    inplace, pos, code, bsd, script_file, quiet, i = False, [], [], False, False, False, 0
    while i < len(args):
        a = args[i]
        if a == "--":
            pos += args[i + 1:]
            break
        if a.startswith("--"):
            if prog == "sed":
                name, eq, val = a[2:].partition("=")
                ch = sed_long(name)
                if ch == "i":
                    inplace = True
                elif ch == "n":
                    quiet = True
                elif ch in ("e", "f", "l"):
                    if not eq and i + 1 < len(args):
                        i += 1
                        val = args[i]
                    if ch == "e":
                        code.append(val)
                    elif ch == "f":
                        script_file = True
        elif re.match(r"^-[A-Za-z0-9]", a):
            j = 1
            while j < len(a):
                ch = a[j]
                if ch in DIGITS[prog]:
                    m = re.match(r"x[0-9A-Fa-f]+|[0-7]*", a[j + 1:]) if ch == "0" else re.match(r"[0-7]*", a[j + 1:])
                    j += 1 + m.end()
                    continue
                if ch == "i":
                    inplace = True
                    if prog == "sed":
                        if a[j + 1:]:
                            bsd = True
                        elif i + 1 < len(args) and args[i + 1] == "":
                            bsd, i = True, i + 1
                    break
                if prog == "sed" and ch == "n":
                    quiet = True
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
    return inplace, pos, code, bsd, script_file, quiet

def one_substitution(e):
    """One `s` command, at most a line address before it; no flag but a
    number or `I` (`g` reaches every match, `p` prints the line twice, `w`
    writes a second file, `e` runs it)."""
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
    return parts == 2 and re.fullmatch(r"[0-9I]*", e[k:]) is not None

def resolve(start, path, rebound=False):
    """The absolute path a file argument names, or None when it is not literal
    (expand() from hook-lib.py cannot expand it, or it is the find `{}`).
    rebound=True: a variable this command rebinds takes its value from before
    the command (the rebound reading of expand()), a guess at the target."""
    p = None if path == "{}" else expand(path, rebound)
    return None if p is None else os.path.join(start, p)

def guesses(start, path):
    """The paths a variable this command rebinds would give path, read with
    its value from before the command; empty when plain resolve() reads path,
    or when nothing rebound stands behind its None."""
    if path == "{}" or resolve(start, path) is not None:
        return []
    p = resolve(start, path, rebound=True)
    return [p] if p else []

def places(p):
    """The real directories an edit of path p writes into: the one holding the
    file the path resolves to, and the one holding the name itself (sed and
    perl replace a symlink there rather than write through it)."""
    return {os.path.dirname(os.path.realpath(p)), os.path.realpath(os.path.dirname(p))}

def opted(d):
    """True when directory d (real, absolute) is in an opted-in tree."""
    walk = d
    while True:
        if os.path.isfile(os.path.join(walk, ".claude", "rename-safety")):
            return True
        if walk in ("/", HOME):
            break
        walk = os.path.dirname(walk)
    for r in os.environ.get("RENAME_SAFETY_DIRS", "").split(":"):
        r = os.path.realpath(r) if r else ""                       # an empty element opts in nothing
        if r and (d == r or d.startswith(r.rstrip("/") + "/")):
            return True
    return False

def on_command(seg, curdir):
    head = progname(seg[0])
    prog = {"sed": "sed", "gsed": "sed", "perl": "perl", "ruby": "ruby"}.get(head)
    if not prog:
        return None
    inplace, files, code, bsd, script_file, quiet = parse(prog, seg[1:])
    if not inplace:
        return None
    shape = "sed -i" if prog == "sed" else "perl/ruby -i"
    cwd = base()
    unknown = curdir is None              # a cd the lib could not expand: the cwd stands in for it
    start = cwd if unknown else os.path.join(cwd, curdir)
    if not os.path.isdir(start):          # a cd to a missing dir falls back to the payload cwd
        start = cwd
    paths = [resolve(start, f) if not GLOB.search(f) else None for f in files]
    literal = files and None not in paths and not fed_by()
    if literal:
        judged = [p for p in paths if any(opted(d) for d in places(p))]
        if not judged:
            if unknown and not all(os.path.isabs(os.path.expanduser(f)) for f in files):
                UNJUDGED.append((shape, CD))    # a relative file under an unknown directory: not judged, and said so
            return None                   # every file lies outside an opted-in directory
    else:
        dirs = [os.path.realpath(start)]
        rebound = []                      # a variable this command rebinds: judged by its value from before
        for f in files:
            if GLOB.search(f):            # a glob is judged by its literal parent too
                lead = os.path.dirname(GLOB.split(f, 1)[0]) or "."
                parent = resolve(start, lead)
                if parent:
                    dirs.append(os.path.realpath(parent))
                for g in guesses(start, lead):
                    rebound.append(g)
                    dirs.append(os.path.realpath(g))
            else:
                for g in guesses(start, f):
                    rebound.append(g)
                    dirs.extend(places(g))
        if not any(opted(d) for d in dirs):
            if unknown:
                UNJUDGED.append((shape, CD))
            elif rebound:
                UNJUDGED.append((shape, REBOUND))
            return None
    if (head == "sed" and bsd and not quiet and literal and len(files) == 1 and not script_file
            and len(code) == 1 and one_substitution(code[0])):
        return None                       # one substitution in one listed file, BSD sed
    return (shape, files[:20])

def finish():
    return ("unjudged",) + UNJUDGED[0] if UNJUDGED else None

def emit(hit):
    if hit[0] == "unjudged":
        sys.stdout.write("%s %s" % hit[1:])
        sys.exit(ALLOW_EXIT)
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
  echo "  through one substitution with no g or p flag on one listed file in the BSD"
  echo "  form (sed -i '' 's/old/new/' file), and any edit whose files all lie"
  echo "  outside the opted-in directory."
} >&2
exit 2
