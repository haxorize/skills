#!/usr/bin/env python3
# Conventions for this tree: scripts/README.md
"""round-yield.py: a mining round's usable ideas per million input tokens, by source class.

    round-yield.py <round-dir> [--projects DIR]

Reads three things:
  <round-dir>/dispatch.md   every Markdown table whose header has both an
                            `Agent id` and a `Class` column; a row is one
                            reader. Its ledger row prefix is the `Prefix`
                            cell where the table has one, else the first word
                            of the `Reader` cell; a table with neither column
                            is a never-ran (4).
  <round-dir>/ledger.md     every table whose header has `id` and
                            `final verdict`; a row counts as ADOPT or ADAPT by
                            the first word of its final verdict, in any case,
                            under the reader whose prefix its id carries
                            (`<prefix>-`).
  subagent transcripts      <projects>/*/*/subagents/agent-<agent id>.jsonl
                            (projects defaults to ~/.claude/projects); input
                            tokens are input, cache read and cache creation,
                            once per assistant message id across every file
                            found for one agent (a copy counts once); a message
                            with no id or uuid counts on its own.

Prints a TSV, one row per class: class, agents, M input tokens, ADOPT, ADAPT,
rows per M tokens; then `unclassed readers:`, `missing transcripts:`,
`unmatched ledger rows:` and `skipped input:` lines, which say what the table
could not count. `skipped input:` sums the dispatch and ledger rows too short
for their table's columns, the readers whose row yields no prefix, and the
transcript lines that are not JSON, each named in its parenthetical.

Why: the 2026-10-12 round tallied this by hand (TC-15); own corpus 1.51 rows
per M tokens against 0.23 for named external repos decided where readers go.

Exit: 0 everything counted · 2 a transcript missing, a ledger ADOPT/ADAPT
row matched no reader, or any skipped input · 3 usage · 4 never ran
(dispatch.md, ledger.md or a transcript missing or unreadable, no dispatch
table carries a Class column, or a classed table has neither a Reader nor a
Prefix column).
"""
import glob
import json
import os
import re
import sys

USAGE = "usage: round-yield.py <round-dir> [--projects DIR]"


class NeverRan(Exception):
    """A check that cannot run: exit 4 with the message, no traceback."""


def read_lines(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            return fh.readlines()
    except OSError as e:
        raise NeverRan(f"cannot read {path}: {e.strerror or e}")


def tables(path):
    """Yield (header cells lowercased, rows of cells) for each Markdown table."""
    header, rows = None, []
    for line in read_lines(path):
        line = line.rstrip("\n")
        if not line.lstrip().startswith("|"):
            if header is not None:
                yield header, rows
            header, rows = None, []
            continue
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", line.strip())[1:-1]]
        if header is None:
            header = [c.lower() for c in cells]
        elif all(re.fullmatch(r":?-{3,}:?", c) for c in cells if c):
            continue
        else:
            rows.append(cells)
    if header is not None:
        yield header, rows


def input_tokens(path, seen):
    """Sum one transcript's input tokens, skipping message ids already in `seen`.

    Returns (tokens, lines that are not a JSON object)."""
    total, bad = 0, 0
    for line in read_lines(path):
        if not line.strip():
            continue
        try:
            d = json.loads(line)
        except ValueError:
            bad += 1
            continue
        if not isinstance(d, dict):
            bad += 1
            continue
        if d.get("type") != "assistant":
            continue
        m = d.get("message") or {}
        key = m.get("id") or d.get("uuid")
        if key is not None:
            if key in seen:
                continue
            seen.add(key)
        u = m.get("usage") or {}
        total += sum(u.get(k, 0) or 0 for k in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
    return total, bad


def main(argv):
    try:
        return run(argv)
    except NeverRan as e:
        print(f"round-yield.py: {e}", file=sys.stderr)
        return 4


def run(argv):
    args, projects = [], os.path.expanduser("~/.claude/projects")
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("-h", "--help"):
            print(__doc__.strip())
            return 0
        if a == "--projects":
            if i + 1 >= len(argv):
                print(USAGE, file=sys.stderr)
                return 3
            projects = argv[i + 1]
            i += 2
            continue
        if a.startswith("-"):
            print(f"round-yield.py: unknown argument: {a}\n{USAGE}", file=sys.stderr)
            return 3
        args.append(a)
        i += 1
    if len(args) != 1:
        print(USAGE, file=sys.stderr)
        return 3
    rd = args[0]
    dispatch, ledger = os.path.join(rd, "dispatch.md"), os.path.join(rd, "ledger.md")
    for p in (dispatch, ledger):
        if not os.path.isfile(p):
            print(f"round-yield.py: {p} not found", file=sys.stderr)
            return 4

    readers, unclassed, classed_tables = [], 0, 0
    short_dispatch, short_ledger, no_prefix, bad_lines = 0, 0, 0, 0
    for header, rows in tables(dispatch):
        if "agent id" not in header:
            continue
        if "class" not in header:
            unclassed += len(rows)
            continue
        classed_tables += 1
        ci, ai = header.index("class"), header.index("agent id")
        pi = header.index("prefix") if "prefix" in header else None
        ri = header.index("reader") if "reader" in header else None
        if pi is None and ri is None:
            raise NeverRan(f"a table in {dispatch} has Agent id and Class columns but neither a Reader nor a Prefix column, so no reader's prefix can be read")
        for r in rows:
            if len(r) <= max(ci, ai):
                short_dispatch += 1
                continue
            words = r[ri].split() if ri is not None and len(r) > ri else []
            prefix = r[pi] if pi is not None and len(r) > pi and r[pi] else (words[0] if words else "")
            if not prefix.strip("` "):
                no_prefix += 1
            readers.append({"class": r[ci], "agent": r[ai].strip("` "), "prefix": prefix.strip("` "), "tok": 0, "adopt": 0, "adapt": 0})
    if not classed_tables:
        print(f"round-yield.py: no table in {dispatch} carries both an Agent id and a Class column", file=sys.stderr)
        return 4

    missing = []
    for r in readers:
        hits = sorted(set(glob.glob(os.path.join(projects, "*", "*", "subagents", f"agent-{r['agent']}.jsonl"))))
        if not hits:
            missing.append(r["agent"])
            continue
        seen = set()  # shared across hits: a copied transcript counts once
        for h in hits:
            tok, bad = input_tokens(h, seen)
            r["tok"] += tok
            bad_lines += bad

    # longest prefix first, so `SH-G1-3` is not taken by a reader whose prefix is `SH`
    by_prefix = sorted((r for r in readers if r["prefix"]), key=lambda r: -len(r["prefix"]))
    unmatched = 0
    for header, rows in tables(ledger):
        if "id" not in header or "final verdict" not in header:
            continue
        ii, vi = header.index("id"), header.index("final verdict")
        for row in rows:
            if len(row) <= max(ii, vi):
                short_ledger += 1
                continue
            verdict = re.split(r"[^A-Za-z]", row[vi].lstrip("*` "), maxsplit=1)[0].upper()
            if verdict not in ("ADOPT", "ADAPT"):
                continue
            rid = row[ii].strip("` ")
            owner = next((r for r in by_prefix if rid.startswith(r["prefix"] + "-")), None)
            if owner is None:
                unmatched += 1
                continue
            owner["adopt" if verdict == "ADOPT" else "adapt"] += 1

    classes = {}
    for r in readers:
        c = classes.setdefault(r["class"], {"agents": 0, "tok": 0, "adopt": 0, "adapt": 0})
        c["agents"] += 1
        for k in ("tok", "adopt", "adapt"):
            c[k] += r[k]
    print("class\tagents\tM input tokens\tADOPT\tADAPT\trows per M tokens")
    for name in sorted(classes, key=lambda n: -classes[n]["tok"]):
        c = classes[name]
        mtok = c["tok"] / 1e6
        per = f"{(c['adopt'] + c['adapt']) / mtok:.2f}" if mtok else "n/a"
        print(f"{name}\t{c['agents']}\t{mtok:.1f}\t{c['adopt']}\t{c['adapt']}\t{per}")
    print(f"unclassed readers: {unclassed}")
    print(f"missing transcripts: {len(missing)}" + (f" ({', '.join(missing)})" if missing else ""))
    print(f"unmatched ledger rows: {unmatched}")
    parts = [f"{label} {n}" for label, n in (
        ("short dispatch rows", short_dispatch), ("short ledger rows", short_ledger),
        ("readers with no prefix", no_prefix), ("transcript lines not JSON", bad_lines)) if n]
    skipped = short_dispatch + short_ledger + no_prefix + bad_lines
    print(f"skipped input: {skipped}" + (f" ({', '.join(parts)})" if parts else ""))
    return 2 if missing or unmatched or skipped else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
