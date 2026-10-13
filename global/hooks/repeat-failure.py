# repeat-failure.py — the key and the count of repeat-failure.sh, the
# PostToolUseFailure hook beside it. Not a hook and not run on its own: the
# wrapper checks for python3 and for this file, session-hook-lib.py and
# hook-lib.py, then runs this with the payload on stdin. The contract — the
# head, the error class, the count, what is stored, the fail-open rule — is
# stated once, in repeat-failure.sh's header; this file is where the key is
# built so the selftest can mutate it as a file.
#
# The command is segmented by hook-lib.py's scanner (its public entry,
# run_scanner, fed the command on a swapped stdin), so a separator inside
# quotes does not split, wrappers are peeled, and `bash -c` bodies are read.

import contextlib, hashlib, importlib.util, io, json, os, re, sys

_here = os.path.dirname(os.path.abspath(__file__))


def _load(name, file):
    spec = importlib.util.spec_from_file_location(name, os.path.join(_here, file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


lib = _load("session_hook_lib", "session-hook-lib.py")
lib.init("repeat-failure")
scanner = None                       # hook-lib.py, loaded inside main() so a load failure is a breadcrumb

FIRE_AT = 3
SKIP = {"cd", "pushd", "export", "source", ".", "set", "true", "exit"}
SUBCOMMAND = re.compile(r"^[a-z][a-z0-9-]*$")
PROG = re.compile(r"^[A-Za-z0-9._+-]{1,40}$")
EXIT_CODE = re.compile(r"^Exit code (\d+)$")
# Token shapes masked out of the stored error line before anything else
# touches it: a credential the failing tool echoed back never reaches disk.
SECRETS = [
    re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{16,})"),
    re.compile(r"\bsk-[A-Za-z0-9_-]{16,}"),                    # sk-, sk-ant-, sk-proj-
    re.compile(r"\b(?:sk|pk|rk)_(?:live|test)_[A-Za-z0-9]{16,}"),
    re.compile(r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b"),
    re.compile(r"\bxox[abposr]-[A-Za-z0-9-]{10,}"),
    re.compile(r"\bglpat-[A-Za-z0-9_-]{16,}"),
    re.compile(r"\bAIza[0-9A-Za-z_-]{30,}"),
    re.compile(r"\bnpm_[A-Za-z0-9]{30,}"),
    re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*"),   # a JWT
    re.compile(r"(?i)\b(bearer|basic)\s+\S+"),
    re.compile(r"(?i)\b(token|secret|password|passwd|pwd|api[_-]?key|auth)\b(\s*[=:]\s*)\S+"),
    re.compile(r"(?=[A-Za-z0-9+_=-]*[0-9])(?=[A-Za-z0-9+_=-]*[A-Za-z])[A-Za-z0-9+_=-]{24,}"),   # a long base64/hex run
]


def mask(line):
    for rx in SECRETS:
        if rx.groups == 1:
            line = rx.sub(lambda m: m.group(1) + " #", line)
        elif rx.groups == 2:
            line = rx.sub(lambda m: m.group(1) + m.group(2) + "#", line)
        else:
            line = rx.sub("#", line)
    return line


def programs(cmd):
    """The program segments the command runs, in order, as hook-lib.py's
    scanner hands them to on_command; [] on a tokeniser error."""
    segs = []

    def on_command(seg, curdir):
        segs.append(seg)
        return None                  # never a hit: walk every segment

    stdin = sys.stdin
    sys.stdin = io.StringIO(cmd)
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            scanner.run_scanner(on_command, lambda hit: None)
    except SystemExit:
        pass                         # exit 3/4: a tokeniser error or a scanner crash; what was walked stands
    finally:
        sys.stdin = stdin
    return segs


def name_of(seg):
    prog = os.path.basename(seg[0])
    if not PROG.match(prog):
        return None
    nxt = seg[1] if len(seg) > 1 else ""
    return prog + (" " + nxt if SUBCOMMAND.match(nxt) else "")


def head(cmd, err):
    """The failing program's name, plus its subcommand. The failing segment is
    the `exit N` whose N is the reported exit code, else the last segment whose
    program the error names as `<prog>:`, else the first program not in SKIP.
    With none, a hash of the command — never its text."""
    segs = [s for s in programs(cmd) if s]
    lines = [l.strip() for l in err.splitlines() if l.strip()]
    m = EXIT_CODE.match(lines[0]) if lines else None
    if m:
        for s in segs:
            if os.path.basename(s[0]) == "exit" and s[1:2] == [m.group(1)]:
                return "exit"
    for s in reversed(segs):
        prog = os.path.basename(s[0])
        if prog not in SKIP and PROG.match(prog) and re.search(r"(^|[\s/])" + re.escape(prog) + r":", err, re.M):
            return name_of(s)
    for s in segs:
        if os.path.basename(s[0]) not in SKIP and name_of(s):
            return name_of(s)
    return "cmd#" + hashlib.sha256(cmd.encode("utf-8", "replace")).hexdigest()[:10]


def error_class(err):
    lines = [l.strip() for l in err.splitlines() if l.strip()]
    if not lines:
        return ""
    first = lines[0] if lines[0].startswith("Exit code") else ""
    last = mask(lines[-1][:1000]).lower()   # masked whole before the 120-character cut
    last = re.sub(r"\b[0-9a-f]*[0-9][0-9a-f]*\b", lambda m: "#" if len(m.group()) >= 8 else m.group(), last)
    last = re.sub(r"\d{4,}", "#", last)
    return (first + " | " + last)[:120]


def main():
    global scanner
    d = lib.read_payload()
    if d.get("tool_name") != "Bash" or d.get("is_interrupt"):
        return
    ti = d.get("tool_input") or {}
    cmd = ti.get("command") if isinstance(ti, dict) else None
    sid, err = lib.session_id(d), d.get("error")
    if not isinstance(cmd, str) or not cmd or sid is None:
        lib.crumb("payload has no usable tool_input.command or session_id")
    if isinstance(err, list):
        err = "\n".join(e for e in err if isinstance(e, str))
    if not isinstance(err, str):
        err = ""
    scanner = _load("hook_lib", "hook-lib.py")
    eclass = error_class(err)
    key = head(cmd, err) + " :: " + eclass
    state = lib.state_dir()
    path = os.path.join(state, sid)
    try:
        with open(path) as f:
            last = json.load(f)
        count = last["count"] + 1 if last.get("key") == key else 1
    except (OSError, ValueError, KeyError, TypeError, AttributeError):
        count = 1
    # The count first (without it the third failure is never seen), then the
    # line, and the prune last, so nothing the prune does can lose the line.
    try:
        lib.write_state(path, json.dumps({"key": key, "count": count}))
    except OSError:
        lib.crumb("state directory not writable (%s)" % state)
    if count >= FIRE_AT:
        lib.emit("PostToolUseFailure",
                 "repeat-failure: `%s` has now failed %d times in a row with the same error (%s). "
                 "Treat it as structural: stop retrying variations and stop guessing at causes. Tell the user "
                 "the exact command, the exact error, and what only they can do (a credential, access, the "
                 "network, a sandbox rule)." % (key.split(" :: ")[0], count, eclass.split(" | ")[0] or "no exit code"))
    lib.prune(state)


lib.run(main)
