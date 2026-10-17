# context-nudge.py — the transcript reader of context-nudge.sh, the
# UserPromptSubmit hook beside it. Not a hook and not run on its own: the
# wrapper checks for python3 and for this file and session-hook-lib.py, then
# runs this with the payload on stdin. The contract — the thresholds, the
# once-only marker, what is read and written, the fail-open rule — is stated
# once, in context-nudge.sh's header; this file is where the threshold table
# and the transcript walk live so the selftest can mutate them as a file.

import importlib.util, json, os, sys

_spec = importlib.util.spec_from_file_location(
    "session_hook_lib", os.path.join(os.path.dirname(os.path.abspath(__file__)), "session-hook-lib.py"))
lib = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(lib)
lib.init("context-nudge")

THRESHOLDS = [   # highest first; each fires once per climb
    (200000, "context-nudge: this session's context is at {k}k tokens, past 200k. Offer the user /handoff now, before the next step."),
    (150000, "context-nudge: this session's context is at {k}k tokens. At the next phase boundary, offer the user /handoff rather than starting a long new step."),
]
CHUNK = 1 << 20


def last_usage(path):
    """Context tokens of the last main-thread assistant entry with usage."""
    with open(path, "rb") as f:
        f.seek(0, 2)
        end = f.tell()
        tail = b""
        while end > 0:
            start = max(0, end - CHUNK)
            f.seek(start)
            buf = f.read(end - start) + tail
            lines = buf.split(b"\n")
            tail = lines[0] if start > 0 else b""   # a partial first line waits for the next chunk
            for line in reversed(lines[1:] if start > 0 else lines):
                if b"\"usage\"" not in line:
                    continue
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(d, dict) or d.get("type") != "assistant" or d.get("isSidechain"):
                    continue
                m = d.get("message") or {}
                u = m.get("usage") if isinstance(m, dict) else None
                if not isinstance(u, dict) or m.get("model") == "<synthetic>":
                    continue
                n = sum(u.get(k) or 0 for k in ("input_tokens", "cache_creation_input_tokens",
                                                "cache_read_input_tokens", "output_tokens")
                        if isinstance(u.get(k) or 0, int))
                if n > 0:
                    return n
            end = start
    return 0


def main():
    d = lib.read_payload()
    tp, sid = d.get("transcript_path"), lib.session_id(d)
    if not isinstance(tp, str) or not tp or sid is None:
        lib.crumb("payload has no usable transcript_path or session_id")
    try:
        n = last_usage(tp)
    except OSError:
        lib.crumb("transcript unreadable")
    level = next(((t, msg) for t, msg in THRESHOLDS if n >= t), None)
    state = lib.state_dir()
    marker = os.path.join(state, sid)
    try:
        with open(marker) as f:
            sent = int(f.read().strip() or 0)
    except (OSError, ValueError):
        sent = 0
    if level is None:
        # Back under the lowest threshold after a nudge: a compaction ran, so
        # re-arm and let a second climb nudge again.
        if sent:
            try:
                lib.write_state(marker, "0\n")
            except OSError:
                lib.crumb("state directory not writable (%s)" % state)
        return
    if level[0] <= sent:
        return
    # The marker first: a nudge that cannot be marked as sent would repeat on
    # every prompt, so an unwritable directory stays quiet. Then the line, and
    # the prune last, so nothing the prune does can lose the line.
    try:
        lib.write_state(marker, "%d\n" % level[0])
    except OSError:
        lib.crumb("state directory not writable (%s)" % state)
    lib.emit_additional_context("UserPromptSubmit", level[1].format(k=n // 1000))
    lib.prune(state)


lib.run(main)
