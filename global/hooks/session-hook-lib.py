# session-hook-lib.py — the scaffolding shared by the two session hooks beside
# it, context-nudge.py and repeat-failure.py. Not a hook and not run on its
# own: each hook's .py loads it by path through importlib (a hyphenated file
# name cannot be imported by name), and each hook's .sh wrapper checks it is
# readable before it runs the .py. It carries no `# Install note:` line, so
# install.sh, post-merge and lint-skills.sh's selftest pairing read it as a
# library, as they read hook-lib.py; mutation-sweep.sh grades it through the
# selftests of the two wrappers that name it.
#
# What a session hook gets here, and the contract each name keeps:
#   crumb(why)            stderr `<hook>: <why>, allowing`, exit 0 — the shape
#                         of hook-lib.sh's hook_allow and friction-log.py's
#                         crumb, and the same meaning: a breadcrumb written
#                         directly, never a stdout sentinel
#   read_payload()        the stdin payload as a dict; crumbs on an empty
#                         payload, one that is not JSON, or one that is not an
#                         object
#   session_id(d)         the payload's session_id when it is a file-safe name
#                         (`[A-Za-z0-9_-]{1,128}`), else None
#   state_dir()           ${HOOK_STATE_DIR:-~/.claude/hook-state}/<hook>
#   write_state(p, text)  writes p through a 0600 temp file renamed into place,
#                         under a 0700 directory; raises OSError for the caller
#   prune(dir)            removes files in dir older than 30 days; never raises
#                         and never exits, so it runs after the hook's output
#   emit(event, text)     the hookSpecificOutput.additionalContext JSON on
#                         stdout, flushed
#   run(main)             runs main(); a crash is a breadcrumb naming the
#                         exception, never a non-zero exit
#
# `HOOK` is set by `init(name)` before any of these is called.

import json, os, re, sys, tempfile, time

HOOK = "session-hook"
SID = re.compile(r"^[A-Za-z0-9_-]{1,128}$")
PRUNE_AFTER = 30 * 86400


def init(name):
    global HOOK
    HOOK = name


def crumb(why):
    sys.stderr.write("%s: %s, allowing\n" % (HOOK, why))
    sys.exit(0)


def read_payload():
    raw = sys.stdin.read()
    if not raw.strip():
        crumb("empty payload")
    try:
        d = json.loads(raw)
    except ValueError:
        crumb("payload is not JSON")
    if not isinstance(d, dict):
        crumb("payload is not an object")
    return d


def session_id(d):
    sid = d.get("session_id")
    return sid if isinstance(sid, str) and SID.match(sid) else None


def state_dir():
    base = os.environ.get("HOOK_STATE_DIR") or os.path.join(os.path.expanduser("~"), ".claude", "hook-state")
    return os.path.join(base, HOOK)


def write_state(path, text):
    d = os.path.dirname(path)
    os.makedirs(d, mode=0o700, exist_ok=True)
    try:
        os.chmod(d, 0o700)            # a directory an older version made 0755
    except OSError:
        pass
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp-")   # mkstemp creates the file 0600
    try:
        with os.fdopen(fd, "w") as f:
            f.write(text)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.remove(tmp)
        except OSError:
            pass
        raise


def prune(d):
    cutoff = time.time() - PRUNE_AFTER
    try:
        names = os.listdir(d)
    except OSError:
        return
    for name in names:
        p = os.path.join(d, name)
        try:
            if os.path.getmtime(p) < cutoff:
                os.remove(p)
        except OSError:
            pass


def emit(event, text):
    sys.stdout.write(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}}) + "\n")
    sys.stdout.flush()


def run(main):
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        crumb("crashed (%s)" % type(e).__name__)
