# hook-lib.py — the command-line scanner shared by the PreToolUse hooks beside
# it, and the segmenter repeat-failure.py loads. Not run on its own; it has two
# kinds of consumer.
#   - A PreToolUse hook: hook-lib.sh's `hook_scan` prepends this file to the
#     hook's own Python, which defines `on_command(seg, curdir)` and
#     `emit(hit)`, and may define `finish()` (called once after a scan in
#     which no `on_command` returned a hit; what it returns is the hit), then
#     appends `run_scanner(on_command, emit, finish)`, the process entry: it
#     reads the command from stdin and owns the exit codes below.
#   - A loader by path (repeat-failure.py, through importlib): it calls
#     `program_segments(cmd)`, which returns every program segment the command
#     runs, in order — each one `on_command` would be handed, plus each
#     segment the scanner reads itself and hands to no hook (a shell given a
#     script file, a `find` with no `-exec` clause), as written — and raises
#     `TokeniseError` on a tokeniser error. It reads no stdin and never exits.
# Besides those names, a hook may use `re`, `sys`, `os`, `shlex`, `progname`,
# `git_args`, `split_git`, `expand`, `joined`, `base`, `fed_by`, `REDIR`,
# `drop_redirs`, and `ALLOW_EXIT`; everything else here is the scanner's own
# and may be renamed.
# `REDIR` matches a redirection word as the tokeniser hands it over; its group
# 2 is the attached target, empty when the target is the next word;
# `drop_redirs(words)` returns the words with each redirection and its target
# taken out, so a hook reading file arguments never reads `> log` as one.
# `fed_by()` names the feeders (`xargs`, `find`) the current segment runs
# under, so a hook can tell that its file list arrives from outside the
# segment. `base()` is the payload's cwd as an absolute path (hook_scan exports
# it as PAYLOAD_CWD; a scanner run without it crashes, which fails open with
# the exception named, rather than silently judging the hook process's own
# directory). An `emit` that decides to allow with a breadcrumb writes the
# breadcrumb to stdout and exits `ALLOW_EXIT` (5); hook_scan turns that into
# hook_allow, so an allow never shares the channel a finding travels in.
#
# The contract, which every hook inherits: the command is tokenised the way a
# shell would (`shlex`), split into segments at `; && || | & ( )` and newlines
# (the `&` of a redirection — `2>&1`, `>&2`, `&>file` — and the `|` of `>|`
# are part of its word, unless the `<`/`>` is backslash-escaped, where bash
# reads it as text and the `&` or `|` as a separator; a `<(…)` /
# `>(…)` process substitution is the one word `<(…)`, its body scanned as
# segments of its own after the rest; a `$(…)` or backtick command
# substitution, bare or in double quotes, is `$(…)` inside its word, its body
# scanned just before the segment holding it, under the curdir in effect
# there, with its own comments and `case` patterns), and `on_command` is
# called once per
# segment with the tokens of the program that actually runs — a reserved word
# in command position (`if`, `then`, `do`, `{`, `!`, …) dropped, a
# redirection there (`>x git …`, with a detached target) dropped, wrappers
# (`env`, `sudo`, `timeout 30`, `nice`, …) peeled, a leading `FOO=bar`
# assignment (bare, or after `export`, `declare`, `local`, `typeset`,
# `readonly`, or a wrapper) dropped, `$var` /
# `${var…}` replaced with a value assigned earlier in the same command,
# `$(which git)` resolved to `git`, and any other program word holding a
# substitution (`$(echo git)`) replaced by `git`, so the words after it are
# judged as git's (fail closed). A string handed to `bash -c` / `-lc`,
# `eval`, `env -S`, a literal string piped into a
# shell, a shell-fed heredoc, or each `find -exec` clause is scanned in turn,
# four nested shells at most; `xargs <prog>` sees the words of a feeding
# `echo`/`printf` as trailing arguments (any other producer's argv is not its
# output). A `# comment` starts only at the beginning of a word outside
# quotes; a backslash-newline continuation is joined first. Text inside quotes
# is still tokens — a quoted flag is still a flag to the program — but a
# heredoc no shell consumes, and a string a program other than a shell
# receives (`echo '…'`, `python3 -c '…'`, `grep '…'`), is never scanned, so a
# mention passes. The wrappers are a roster (`WRAPPERS` below), not a
# heuristic: a program not on it that runs another program (`busybox` is on
# it; `docker exec`, `script`, `setsid -w` are not) hides the command. `cd`,
# `pushd`, and `GIT_DIR=` move `curdir`, which starts empty and is None where
# the hook cannot expand the target; hooks that care read it. `expand(path)`
# expands `~`, and `$X` / `${X}` from the hook's environment (the one the
# session's shell inherits); a variable that is unset there, one the shell
# keeps itself (`PWD`, `OLDPWD`), one this command line assigned, declared,
# unset, or read into (`unset`, `read`, `for`) before the use, any other
# `${…}` form (`${X:-y}`), a `$(…)`, or a backtick makes the path
# unexpandable (None). `expand(path, rebound=True)` expands a name this
# command rebinds from the hook's environment anyway — its value before the
# command — so a hook that gets None from the plain call can still judge
# that guess, and should say the target was not known.
# `git_args(seg)` returns the tokens after the `git` word with a `-c
# alias.X=…` built on the command line expanded into X's place, or None when
# the segment is not git. `split_git(args, curdir)` reads those tokens the way
# git does: (dir, subcommand, args after it, git_dir, work_tree), where dir is
# base() moved by `curdir` and each `-C`, and `--git-dir` / `--work-tree`
# (either spelling) are honoured as absolute paths resolved from that dir, or
# None when absent or unexpandable; its `.placed` is False after a cd the
# scanner could not expand unless an absolute `-C`, or an absolute
# `--git-dir` and `--work-tree` together, name the repo.
#
# A shell given a script file (`… | bash hook.sh`) runs the file, and what is
# piped in is that script's input, not commands; a shell with no operand, `-s`,
# `-`, `/dev/stdin`, `/dev/fd/0`, or an operand the scanner cannot expand reads
# its commands from the pipe, and the piped string is scanned. A here-string
# into a shell with no script file (`bash <<< "…"`) is its commands too, and
# is scanned. A heredoc's delimiter may be quoted (`<<'EOF'`, `<<"EOF"`) or
# backslash-escaped (`<<\EOF`).
#
# In run_scanner, a tokeniser error (an unterminated quote, more than four
# nested shells) is exit 3; any other exception is exit 4 with its name on
# stdout. hook-lib.sh turns both, and a hook's own exit 5, into a fail-open
# allow with a breadcrumb.

import os, re, shlex, sys

SHELL = re.compile(r"(^|[;&|(\s])(bash|sh|zsh|dash|ksh|eval|source|\.)(\s|$)")
HEREDOC = re.compile(r"<<-?\s*\\?[\x27\"]?([A-Za-z_][A-Za-z0-9_]*)[\x27\"]?[^\n]*\n.*?\n\t*\1(?=\n|$)", re.S)
SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
WRAPPERS = {                       # wrapper -> its options whose value is skipped, not scanned
    "env": {"-u", "-C"}, "command": set(), "exec": {"-a"}, "nohup": set(),
    "time": set(), "sudo": {"-u", "-g", "-p", "-C", "-D", "-h", "-r", "-t", "-T", "-U"},
    "nice": {"-n"}, "ionice": {"-c", "-n", "-p"}, "caffeinate": {"-t", "-w"},
    "stdbuf": {"-i", "-o", "-e"}, "timeout": {"-k", "-s"}, "doas": {"-u", "-C"},
    "setsid": set(), "busybox": set(), "chronic": set(), "unbuffer": set(),
    "flock": {"-w", "-E"},
}
TAKES_ONE = {"timeout", "flock"}   # one positional (the duration, the lock file) before the command
KEYWORDS = {"if", "then", "else", "elif", "fi", "while", "until", "do", "done",
            "case", "esac", "!", "{", "}"}   # reserved words: dropped in command position only
SEPS = {";", "&&", "||", "|", "&", "(", ")", "\n"}
ESCAPED_SEMI = "\\;"               # `find … \;` survives tokenising as this word, never a separator
AMP = "\x01"                       # stands in for a redirection's & while shlex splits, restored in the word after
PIPE = "\x02"                      # likewise the | of `>|`, which pipes nothing
REDIR = re.compile(r"^[0-9]*(&>>|&>|>>|>\||>&|<<<|<<-|<<|<>|<&|>|<)(?!\()(.*)$", re.S)   # group 2 empty: the target is the next word
PROCSUB = "\x03"                   # opens a `<(`/`>(` body in the text shlex splits
CMDSUB = "\x04"                    # opens a lifted `$(…)` / backtick's reference: CMDSUB, its BODIES index, CMDEND
CMDEND = "\x05"
SUBREF = re.compile("\x04([0-9]+)\x05")
BODIES = []                        # lifted substitution bodies; scan() runs each where its segment runs
META = " \t\r\n;&|()"               # ends a word: a `#` after one starts a comment
LEAD_WORDS = KEYWORDS - {"case", "esac", "fi", "done", "}"} | {"time"}   # the word after one is still in command position
FIND_EXEC = {"-exec", "-execdir", "-ok", "-okdir"}
FIND_END = {";", ESCAPED_SEMI, "+"}
XARGS_VALUE_OPTS = {"-n", "-I", "-L", "-P", "-s", "-d", "-E", "-a", "-J", "-R", "-S"}
DECLARERS = {"export", "declare", "local", "typeset", "readonly"}
ASSIGN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", re.S)
VAR = re.compile(r"\$(?:\{([A-Za-z_][A-Za-z0-9_]*)[^}]*\}|([A-Za-z_][A-Za-z0-9_]*))")
NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
SHELL_KEPT = {"PWD", "OLDPWD"}     # the session shell maintains these; the hook's copies name the hook's own directory
BINDERS = {"unset", "read"}        # every name after them is rebound; `for`/`select` rebind the one word after
ENV_VAR = re.compile(r"\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))")   # expand(): no ${x:-…} forms
GIT_VALUE_OPTS = {"-c", "-C", "--git-dir", "--work-tree", "--namespace", "--exec-path",
                  "--super-prefix", "--config-env"}
ALIAS = re.compile(r"^alias\.([^=\s]+)=(.*)$", re.S)
SHELL_VALUE_OPTS = re.compile(r"^(--rcfile|--init-file|[-+][A-Za-z]*[oO])$")   # its next word is a value, not a script
STDIN_SCRIPTS = {"-", "/dev/stdin", "/dev/fd/0", "/proc/self/fd/0"}
ALLOW_EXIT = 5
VARS = {}
TOUCHED = set()                    # names this command rebinds; expand() leaves them unexpanded
VIA = []                           # feeders of the segment being scanned; read through fed_by()
MAX_DEPTH = 4
_on_command = None
_on_opaque = None                  # program_segments' collector for the segments no hook is handed


class TokeniseError(Exception):
    """An unterminated quote, or more than four nested shells."""


def drop_heredocs(s):
    """Keep a heredoc body as command lines when a shell consumes it; drop it
    otherwise (it is text). Then join backslash-newline continuations."""
    def drop(m):
        line = re.sub(r"\\\n", " ", s[:m.start()]).rsplit("\n", 1)[-1]
        head = m.group(0).split("\n", 1)[0]
        if SHELL.search(line + head):
            body = m.group(0).split("\n", 1)[1].rsplit("\n", 1)[0]
            return head + "\n" + body + "\n"
        return head + "\n"
    s = HEREDOC.sub(drop, s)
    return re.sub(r"\\\n", " ", s)


def strip_comments(text):
    """Drop `# …` to end of line where `#` begins a word outside quotes — the
    shell rule; a `#` inside quotes or mid-word is text. A `$(…)` body,
    bare or in double quotes, is a fresh shell context: its own comments are
    dropped and a quote inside one of them opens nothing. `{` and `}` are not
    metacharacters, so the `#` of `${#x}` is mid-word."""
    out, i, n, q, word_start = [], 0, len(text), None, True
    while i < n:
        c = text[i]
        if q != "\x27" and text.startswith("$(", i):
            j = close_paren(text, i + 2)
            out.append("$(" + strip_comments(text[i + 2:j]) + text[j:j + 1]); i = j + 1; word_start = False
            continue
        if q:
            if c == "\\" and q == "\"" and i + 1 < n:
                out.append(c); i += 1; c = text[i]
            elif c == q:
                q = None
            out.append(c); i += 1
            continue
        if c == "\\" and i + 1 < n:
            out.append(c); out.append(text[i + 1]); i += 2; word_start = False
            continue
        if c in "\x27\"":
            q = c; out.append(c); i += 1; word_start = False
            continue
        if c == "#" and word_start:
            j = text.find("\n", i)
            if j < 0:
                break
            i = j
            continue
        out.append(c)
        word_start = c in META
        i += 1
    return "".join(out)


def ansi_c(m):
    """$'…' → a plain single-quoted string shlex reads the same way: \\' is an
    escaped quote inside $'…', so unescape it and re-quote the body."""
    body = m.group(1).replace("\\'", "'")
    return "'" + body.replace("'", "'\\''") + "'"


def mark_redirs(text):
    """Swap the `&` of `>&`, `<&`, `&>` and the `|` of `>|` for AMP / PIPE
    where bash reads a redirection operator: the `<`/`>` (or the `&` of `&>`)
    not backslash-escaped. `\\>&` is an escaped `>` and then a background
    `&`. Quotes need no tracking: shlex reads a quoted `&` or `|` as text
    either way, and the stand-in is restored inside the word; a `\\` inside
    single quotes that pairs here with the closing quote changes nothing
    after it. A `<(` / `>(` gets PROCSUB between its two characters, so
    lift_procsubs can tell it from a `> (`."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if c == "\\":                         # an escaped character is text, never an operator
            out.append(c + nxt); i += 2
        elif c in "<>" and nxt == "&":
            out.append(c + AMP); i += 2
        elif c == ">" and nxt == "|":
            out.append(c + PIPE); i += 2
        elif c in "<>" and nxt == "(":
            out.append(c + PROCSUB); i += 1
        elif c == "&" and nxt == ">":       # `&&>x`: `&` then `&>x`, which separates the same
            out.append(AMP); i += 1
        else:
            out.append(c); i += 1
    return "".join(out)


def lift_procsubs(toks):
    """A `<(…)` / `>(…)` process substitution is one word to the command it
    sits in, and its body runs as commands of its own: leave the word `<(…)`
    in place and append each body, as a `( … )` group, after the rest."""
    out, bodies, i = [], [], 0
    while i < len(toks):
        t = toks[i]
        if t in ("<" + PROCSUB, ">" + PROCSUB) and i + 1 < len(toks) and toks[i + 1] == "(":
            depth, j = 1, i + 2
            while j < len(toks) and depth:
                depth += {"(": 1, ")": -1}.get(toks[j], 0)
                j += 1
            bodies.append(lift_procsubs(toks[i + 2:j - 1 if depth == 0 else j]))
            out.append(t[0] + "(…)")
            i = j
            continue
        out.append(t.replace(PROCSUB, ""))
        i += 1
    for b in bodies:
        out += ["\n", "("] + b + [")"]
    return out


def skip_dquoted(text, k):
    """The index past the `"` closing the double-quoted span whose body starts
    at k; a `$(…)` inside it is skipped whole, so its quotes stay its own."""
    n = len(text)
    while k < n and text[k] != "\"":
        if text[k] == "\\":
            k += 2
        elif text.startswith("$(", k):
            k = close_paren(text, k + 2) + 1
        else:
            k += 1
    return k + 1


def skip_backticks(text, k):
    """The index of the backtick closing the span whose body starts at k."""
    while k < len(text) and text[k] != "`":
        k += 2 if text[k] == "\\" else 1
    return k


def close_paren(text, k):
    """The index of the `)` closing a `$(` whose body starts at k, or
    len(text) when none does. Quotes, a nested `$(…)` and backticks inside the
    body are skipped whole, a `#` beginning a word comments to the end of the
    line, and a bare `(` nests. A `case` in command position is tracked to its
    `esac`: the `)` ending each pattern (and a pattern's optional leading `(`)
    belongs to the case, not to the substitution. A case whose last
    branch ends without `;;` stays on the stack; nothing after it reads the
    stale entry but a `;;`, which only an enclosing case can hold."""
    depth, n = 0, len(text)
    word_start, cmdpos = True, True
    cases = []                      # per open case: "subj" (before `in`), "pat", "body"
    pat_start, pdepth = False, 0
    while k < n:
        c = text[k]
        top = cases[-1] if cases else None
        if c in " \t\r":
            word_start = True
            k += 1
            continue
        if c == "#" and word_start:
            j = text.find("\n", k)
            k = n if j < 0 else j
            continue
        if word_start and c not in META:
            m = re.match(r"[^\s;&|()<>\x27\"`\\$]+", text[k:])
            w = m.group(0) if m else ""
            after = text[k + len(w):k + len(w) + 1]
            if w and (after == "" or after in META or after in "<>"):
                if top == "pat" and pat_start and w == "esac":
                    cases.pop()
                elif top == "subj" and w == "in":
                    cases[-1], pat_start, pdepth = "pat", True, 0
                elif cmdpos and w == "case":
                    cases.append("subj")
                if top == "pat":
                    pat_start = False
                cmdpos = w in LEAD_WORDS and top != "pat"
                word_start = False
                k += len(w)
                continue
        word_start = False
        if c == "\\":
            k += 2
            cmdpos = False
            continue
        if c == "\x27":
            j = text.find("\x27", k + 1)
            k = n if j < 0 else j + 1
            cmdpos = False
            continue
        if c == "\"":
            k = skip_dquoted(text, k + 1)
            cmdpos = False
            continue
        if c == "`":
            k = skip_backticks(text, k + 1) + 1
            cmdpos = False
            continue
        if text.startswith("$(", k):
            k = close_paren(text, k + 2) + 1
            cmdpos = False
            continue
        if c in META:
            word_start = True
        if top == "pat":
            if c == "(":
                if pat_start:
                    pat_start = False
                else:
                    pdepth += 1
            elif c == ")":
                if pdepth:
                    pdepth -= 1
                else:
                    cases[-1], cmdpos = "body", True
            elif c not in "\n":
                pat_start = False
            k += 1
            continue
        if top == "body" and text.startswith(";;", k) or top == "body" and text.startswith(";&", k):
            cases[-1], pat_start, pdepth = "pat", True, 0
            k += 3 if text.startswith(";;&", k) else 2
            word_start = True
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            if depth == 0:
                return k
            depth -= 1
        cmdpos = c in META
        k += 1
    return n


def lift_cmdsubs(text):
    """A `$(…)` or backtick command substitution is part of one word to the
    command it sits in, and its body runs as commands of its own, whether
    unquoted or inside double quotes; single quotes or a backslash make it
    text. Each body goes into BODIES and leaves a CMDSUB<index>CMDEND
    reference in its word; scan() runs the body when it reaches the segment
    holding the reference, with the curdir in effect there, and only then
    reads the word as `$(…)`. The body's own substitutions lift when it is
    scanned. An arithmetic `$((…))` is lifted too: its body scans as a
    harmless group, and a `$(…)` inside it still runs."""
    out, i, n, dq = [], 0, len(text), False
    while i < n:
        c = text[i]
        if c == "\\":
            out.append(text[i:i + 2]); i += 2
        elif c == "\x27" and not dq:
            j = text.find("\x27", i + 1)
            j = n if j < 0 else j + 1
            out.append(text[i:j]); i = j
        elif c == "\"":
            dq = not dq; out.append(c); i += 1
        elif text.startswith("$(", i):
            j = close_paren(text, i + 2)
            out.append(subref(text[i + 2:j])); i = j + 1
        elif c == "`":
            j = skip_backticks(text, i + 1)
            out.append(subref(text[i + 1:j].replace("\\`", "`"))); i = j + 1
        else:
            out.append(c); i += 1
    return "".join(out)


def subref(body):
    BODIES.append(body)
    return CMDSUB + str(len(BODIES) - 1) + CMDEND


def tokens(text):
    text = strip_comments(text)
    text = re.sub(r"\$\x27((?:[^\x27\\]|\\.)*)\x27", ansi_c, text)            # ANSI-C $'…' quoting
    text = re.sub(r"\$\((?:which|command -v|type -P)\s+(\w+)\)", r"\1", text)
    text = re.sub(r"`(?:which|command -v|type -P)\s+(\w+)`", r"\1", text)
    text = lift_cmdsubs(text)                                                   # `$(…)`, backticks: one word, body run by scan()
    text = text.replace("\\;", "\\\\" + ESCAPED_SEMI)                           # `\\\;` reads back as the word `\;`
    text = mark_redirs(text)                                                    # `2>&1`, `&>f`, `>|f`: one word, not a split
    lex = shlex.shlex(text, posix=True, punctuation_chars=";&|()\n")
    lex.whitespace_split = True
    lex.whitespace = " \t\r"
    lex.commenters = ""
    out = []
    for t in lex:
        if t and all(c in ";&|()\n" for c in t):       # an empty word (`sed -i ''`) is still a word
            out.extend(re.findall(r"&&|\|\||[;&|()\n]", t))
        else:
            out.append(t.replace(AMP, "&").replace(PIPE, "|"))
    return lift_procsubs(out)


def segments(toks):
    seg = []
    for t in toks:
        if t in SEPS:
            if seg:
                yield seg
            seg = []
        elif not seg and t in KEYWORDS:
            continue                # a reserved word heads no program
        else:
            seg.append(t)
    if seg:
        yield seg


def progname(tok):
    return tok.rsplit("/", 1)[-1]


def subst(seg):
    """Replace $name / ${name…} with a value assigned earlier in this command.
    A token that is only the variable is word-split as the shell would; a
    variable inside a longer word (a `bash -c "… $x …"` string) is replaced in
    place and the nested scan tokenises the result."""
    out = []
    for t in seg:
        n = VAR.sub(lambda m: VARS.get(m.group(1) or m.group(2), m.group(0)), t)
        if n == t:
            out.append(t)
        elif VAR.fullmatch(t):
            try:
                out.extend(shlex.split(n))
            except ValueError:
                out.append(n)
        else:
            out.append(n)
    return out


def expand(path, rebound=False):
    """`~` and `$X` / `${X}` from the environment expanded; None when the
    path holds anything else the hook cannot expand. rebound=True reads a
    name this command rebinds from the environment too: the value it had
    before the command, a guess at the target rather than the target."""
    if path is None or "`" in path:
        return None
    def env(m):
        name = m.group(1) or m.group(2)
        v = None if name in SHELL_KEPT or (name in TOUCHED and not rebound) else os.environ.get(name)
        if v is None:
            raise KeyError(m.group(0))
        return v
    try:
        path = ENV_VAR.sub(env, path)
    except KeyError:
        return None                 # unset here, or the session shell's own: the caller treats the path as unknown
    if "$" in path:
        return None                 # `$(…)`, `${x:-…}`: cannot expand
    return os.path.expanduser(path) if path.startswith("~") else path


def joined(base, path):
    if path is None:
        return None
    if base is None:
        return None if not os.path.isabs(path) else path
    return path if os.path.isabs(path) else os.path.join(base, path)


def take_assignments(seg, curdir):
    """Record leading NAME=value tokens (after an optional declarer and its
    options) into VARS, and every name they or the declarer bind into
    TOUCHED; drop a redirection among them (`>x git …`: the word, and its
    target when that is the next word); return the rest of the segment and
    the curdir."""
    k = 0
    if seg and seg[0] in DECLARERS:
        k = 1
        while k < len(seg) and seg[k].startswith("-"):
            k += 1
        TOUCHED.update(t.split("=", 1)[0] for t in seg[k:] if NAME.fullmatch(t.split("=", 1)[0]))
    while True:
        k = skip_redirs(seg, k)
        if k >= len(seg) or not ASSIGN.match(seg[k]):
            break
        name, value = ASSIGN.match(seg[k]).groups()
        VARS[name] = value
        TOUCHED.add(name)
        if name == "GIT_DIR":
            curdir = joined(curdir, expand(value))
        k += 1
    return seg[k:], curdir


def skip_redirs(seg, k):
    """The index past the redirection words at seg[k:], each with its target."""
    while k < len(seg):
        m = REDIR.match(seg[k])
        if not m:
            break
        k += 1 if m.group(2) else 2
    return k


def drop_redirs(words):
    """The words with every redirection taken out, each with its target: a
    program never sees `2> log`, so neither word is a file argument."""
    out, k = [], 0
    while k < len(words):
        m = REDIR.match(words[k])
        if m:
            k += 1 if m.group(2) else 2
        else:
            out.append(words[k]); k += 1
    return out


def scan(text, curdir, depth=0):
    if depth > MAX_DEPTH:
        raise RuntimeError("more than four nested shells")
    prev = None
    for seg in segments(tokens(text)):
        for t in seg:               # a substitution runs as its segment expands: before it, after the one before
            for m in SUBREF.finditer(t):
                hit = scan(BODIES[int(m.group(1))], curdir, depth)
                if hit:
                    return hit
        seg = [SUBREF.sub("$(…)", t) for t in seg]
        seg, curdir = take_assignments(subst(seg), curdir)
        head = progname(seg[0]) if seg else ""
        if head in BINDERS:
            TOUCHED.update(t for t in seg[1:] if NAME.fullmatch(t))
        elif head in ("for", "select") and len(seg) > 1:
            TOUCHED.add(seg[1])
        if head in ("cd", "pushd"):
            rest = [t for t in seg[1:] if t == "-" or not t.startswith("-")]
            target = rest[0] if rest else ("$HOME" if head == "cd" else None)
            curdir = joined(curdir, expand(target)) if target and target != "-" else None
            prev = seg
            continue
        hit = scan_segment(seg, prev, curdir, depth)
        if hit:
            return hit
        prev = seg
    return None


def scan_segment(seg, prev, curdir, depth, fed=None):
    seg, curdir = take_assignments(seg, curdir)   # `env FOO=bar git …`: a wrapper's assignments
    if not seg:
        return None
    if "$(…)" in seg[0]:            # `$(echo git) commit -n`: the program is unknown, so judge it as git
        seg = ["git"] + seg[1:]
    head = progname(seg[0])
    if head in WRAPPERS:
        vals = WRAPPERS[head]
        k = 1
        while k < len(seg) and seg[k].startswith("-"):
            if head == "env" and seg[k] == "-S" and k + 1 < len(seg):
                return scan(seg[k + 1], curdir, depth + 1)
            k += 2 if seg[k] in vals else 1
        if head in TAKES_ONE:
            k += 1
        return scan_segment(seg[k:], prev, curdir, depth, fed)
    if head == "xargs":
        k = 1
        while k < len(seg) and seg[k].startswith("-"):
            k += 2 if seg[k] in XARGS_VALUE_OPTS else 1
        fed = []
        if prev and progname(prev[0]) in ("echo", "printf"):
            fed = prev[1:]
            while fed and re.match(r"^-[neEv]+$", fed[0]):   # echo/printf's own flags
                fed = fed[1:]
        VIA.append("xargs")
        try:
            return scan_segment(seg[k:], prev, curdir, depth, fed)
        finally:
            VIA.pop()
    if head == "find":
        if not any(t in FIND_EXEC for t in seg):
            _opaque(seg)            # no clause runs a program: find is the program
        k = 0
        while k < len(seg):
            if seg[k] in FIND_EXEC:
                end = k + 1
                while end < len(seg) and seg[end] not in FIND_END:
                    end += 1
                VIA.append("find")
                try:
                    hit = scan_segment(seg[k + 1:end], prev, curdir, depth)
                finally:
                    VIA.pop()
                if hit:
                    return hit
                k = end
            k += 1
        return None
    if head in SHELLS:
        for k, t in enumerate(seg):
            if re.match(r"^-[A-Za-z]*c[A-Za-z]*$", t) and k + 1 < len(seg):
                return scan(seg[k + 1], curdir, depth + 1)
        if runs_script_file(seg):
            _opaque(seg)
            return None             # `… | bash hook.sh`: the pipe is the script's input
        # no -c and no script file: a here-string, or a string piped in from the previous segment, runs here
        for k, t in enumerate(seg):
            body = seg[k + 1] if t == "<<<" and k + 1 < len(seg) else t[3:] if t.startswith("<<<") else ""
            if body:
                hit = scan(body, curdir, depth + 1)
                if hit:
                    return hit
        for t in (prev or []):
            hit = scan(t.replace("\\n", "\n"), curdir, depth + 1)
            if hit:
                return hit
        return None
    if head == "eval":
        return scan(" ".join(seg[1:]), curdir, depth + 1)
    return _on_command(seg + (fed or []), curdir)


def runs_script_file(seg):
    """True when a shell segment (no -c) names a script file to run, so its
    stdin is data. Anything that may leave the shell reading commands from
    stdin — no operand, `-s`, a stdin path, an operand the scanner cannot
    expand, a redirection where the operand would be — is False."""
    k = 1
    while k < len(seg):
        t = seg[k]
        if t == "--":
            k += 1
            break
        if len(t) > 1 and t[0] in "-+":
            if re.match(r"^-[A-Za-z]*s[A-Za-z]*$", t):
                return False        # -s: commands come from stdin
            k += 2 if SHELL_VALUE_OPTS.match(t) else 1
            continue
        break
    if k >= len(seg):
        return False
    t = seg[k]
    return not (t in STDIN_SCRIPTS or any(c in t for c in "$`<>"))


def base():
    """The payload's cwd, absolute. hook_scan exports PAYLOAD_CWD; a KeyError
    here means a hook ran the scanner without it, and fails open named."""
    return os.path.abspath(os.environ["PAYLOAD_CWD"])


class GitSplit(tuple):
    """split_git's result. Unpacks as (dir, subcommand, args after it,
    git_dir, work_tree); `.placed` says whether the repo git runs in is known."""


def split_git(args, curdir):
    """Read the tokens after the `git` word the way git does. Returns a
    GitSplit (dir, subcommand or None, args after it, git_dir, work_tree):
    dir is base() moved by curdir (None, an unexpandable cd, leaves base())
    and by each `-C` (an unexpandable one is skipped); git_dir and work_tree
    are the last `--git-dir` / `--work-tree` values resolved from the final
    dir, or None. `.placed` is False when curdir is None and nothing names
    the repo instead: an absolute `-C`, or both a `--git-dir` and a
    `--work-tree` whose last values are absolute. Either one alone still
    leaves the other to the unknown directory."""
    d = base() if curdir is None else joined(base(), curdir)
    known = curdir is not None
    gd = wt = None
    gd_abs = wt_abs = False
    i = 0
    while i < len(args):
        a = args[i]
        name, eq, val = a.partition("=") if a.startswith("--") else (a, "", "")
        if name in GIT_VALUE_OPTS:
            if not eq:
                if i + 1 >= len(args):
                    break
                val = args[i + 1]
                i += 1
            i += 1
            v = expand(val)
            if name == "-C":
                d = joined(d, v) or d
                known = known or (v is not None and os.path.isabs(v))
            elif name == "--git-dir":
                gd = v if v is not None else gd
                gd_abs = v is not None and os.path.isabs(v)
            elif name == "--work-tree":
                wt = v if v is not None else wt
                wt_abs = v is not None and os.path.isabs(v)
            continue
        if a.startswith("-"):
            i += 1
            continue
        gd = joined(d, gd) if gd is not None else None
        wt = joined(d, wt) if wt is not None else None
        out = GitSplit((os.path.normpath(d), a, args[i + 1:], gd and os.path.normpath(gd), wt and os.path.normpath(wt)))
        out.placed = known or (gd_abs and wt_abs)
        return out
    out = GitSplit((os.path.normpath(d), None, [], None, None))
    out.placed = known
    return out


def fed_by():
    """The feeders (`xargs`, `find`) the segment now being scanned runs under,
    outermost first; empty when its arguments are all on the command line."""
    return tuple(VIA)


def git_args(seg):
    """The tokens after the `git` word, with a command-line alias (`git -c
    alias.ci='commit -n' ci`) expanded into the subcommand's place; None when
    the segment is not git."""
    if progname(seg[0]) != "git":
        return None
    args = seg[1:]
    aliases = {}
    i = 0
    while i < len(args):
        a = args[i]
        if a in GIT_VALUE_OPTS and i + 1 < len(args):
            m = ALIAS.match(args[i + 1]) if a == "-c" else None
            if m:
                aliases[m.group(1)] = m.group(2)
            i += 2
            continue
        if a.startswith("-"):
            i += 1
            continue
        if a in aliases:
            body = aliases[a]
            if body.startswith("!"):                     # a shell alias: `!git commit -n`
                body = body[1:].strip()
                body = body[4:] if body.startswith("git ") else body
            try:
                words = shlex.split(body)
            except ValueError:
                words = []
            return args[:i] + words + args[i + 1:]
        return args
    return args


def _opaque(seg):
    if _on_opaque:
        _on_opaque(seg)


def scan_command(text, on_command):
    """Scan one command line, calling on_command(seg, curdir) per program
    segment; the first truthy return is the hit. Raises TokeniseError."""
    global _on_command
    _on_command = on_command
    VARS.clear()
    TOUCHED.clear()
    del BODIES[:]
    del VIA[:]
    try:
        return scan(drop_heredocs(text), "")
    except (ValueError, RuntimeError) as e:
        raise TokeniseError(str(e))


def program_segments(cmd):
    """Every program segment cmd runs, in order, with the segments the scanner
    reads itself (a shell given a script file, a find with no -exec clause)
    as written. Pure: no stdin, no exit. Raises TokeniseError."""
    global _on_opaque
    segs = []
    _on_opaque = segs.append
    try:
        scan_command(cmd, lambda seg, curdir: segs.append(seg))
    finally:
        _on_opaque = None
    return segs


def run_scanner(on_command, emit, finish=None):
    """The process entry hook_scan appends: the command from stdin, the exit
    codes in the header, and emit(hit) on a hit from on_command or finish()."""
    try:
        hit = scan_command(sys.stdin.read(), on_command)
        if not hit and finish:
            hit = finish()
    except TokeniseError:
        sys.exit(3)                  # a tokeniser error: an unterminated quote, more than four nested shells
    except Exception as e:
        sys.stdout.write("%s: %s" % (type(e).__name__, e))
        sys.exit(4)                  # the scanner itself is broken
    if hit:
        emit(hit)
