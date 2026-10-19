# context-nudge.py — the transcript reader of context-nudge.sh, the
# UserPromptSubmit hook beside it. Not a hook and not run on its own: the
# wrapper checks for python3 and for this file and session-hook-lib.py, then
# runs this with the payload on stdin. The contract — the thresholds, the
# once-per-climb marker, what is read and written, the fail-open rule — is stated
# once, in context-nudge.sh's header; this file is where the threshold tables,
# the model-to-window table and the transcript walk live so the selftest can mutate them as a file.

import importlib.util, json, os, re, sys

_spec = importlib.util.spec_from_file_location(
    "session_hook_lib", os.path.join(os.path.dirname(os.path.abspath(__file__)), "session-hook-lib.py"))
lib = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(lib)
lib.init("context-nudge")

# The context window by machine and model: unset, CONTEXT_NUDGE_1M_MODELS
# reads every model as 1M tokens; set (in that machine's settings.json `env`),
# it names the machine's 1M models, comma- or space-separated as
# family-major-minor (`opus-4-8`), and every other model there is 200k. A
# deployment can cap a model below its published window, so the same id can
# be 1M on one machine and 200k on another. An id the hook cannot read
# (none, before any reply) takes the machine's 200k pair when the list is set.
ONE_M = os.environ.get("CONTEXT_NUDGE_1M_MODELS")
NOW = "context-nudge: this session's context is at {k}k tokens, past %dk. Offer the user /handoff now, before the next step."
LATER = "context-nudge: this session's context is at {k}k tokens. At the next phase boundary, offer the user /handoff rather than starting a long new step."
THRESHOLDS = {   # per window, highest first; each fires once per climb
    1000000: [(200000, NOW % 200), (150000, LATER)],
    200000: [(150000, NOW % 150), (120000, LATER)],
}


def window(model):
    if ONE_M is None:
        return 1000000
    for tok in ONE_M.replace(",", " ").split():
        # the minor version cannot run on (opus-4 is not opus-4-8); a date suffix can
        if isinstance(model, str) and re.search(r"claude-" + re.escape(tok) + r"(?!-?\d{1,2}(?!\d))", model):
            return 1000000
    return 200000


CHUNK = 1 << 20


def last_usage(path):
    """(tokens, model) of the last main-thread assistant entry with usage. A
    compaction after it supplies the tokens, its postTokens, since a
    compaction writes no usage entry and the newest one predates it until the
    next reply lands; the model is still read from that entry."""
    post = None
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
                boundary = b"\"compact_boundary\"" in line
                if not boundary and b"\"usage\"" not in line:
                    continue
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                if (boundary and isinstance(d, dict) and d.get("subtype") == "compact_boundary"
                        and not d.get("isSidechain")):
                    if post is None:
                        meta = d.get("compactMetadata")
                        p = meta.get("postTokens") if isinstance(meta, dict) else None
                        post = p if isinstance(p, int) and p >= 0 else 0
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
                    return (n if post is None else post), m.get("model")
            end = start
    return post or 0, None


def main():
    d = lib.read_payload()
    tp, sid = d.get("transcript_path"), lib.session_id(d)
    if not isinstance(tp, str) or not tp or sid is None:
        lib.crumb("payload has no usable transcript_path or session_id")
    try:
        n, model = last_usage(tp)
    except OSError:
        lib.crumb("transcript unreadable")
    level = next(((t, msg) for t, msg in THRESHOLDS[window(model)] if n >= t), None)
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
