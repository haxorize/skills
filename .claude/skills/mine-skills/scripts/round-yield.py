#!/usr/bin/env python3
# Conventions for this tree: scripts/README.md
"""round-yield.py: a mining round's usable ideas per million input tokens, by source class.

    round-yield.py <round-dir> [--projects DIR]

Reads three things:
  <round-dir>/dispatch.md   every Markdown table whose header has both an
                            `Agent id` and a `Class` column; a row is one
                            reader. Its ledger row prefix is the `Prefix`
                            cell where the table has one, else the first word
                            of the `Reader` cell.
  <round-dir>/ledger.md     every table whose header has `id` and
                            `final verdict`; a row counts as ADOPT or ADAPT by
                            the first word of its final verdict, under the
                            reader whose prefix its id carries (`<prefix>-`).
  subagent transcripts      <projects>/*/*/subagents/agent-<agent id>.jsonl
                            (projects defaults to ~/.claude/projects); input
                            tokens are input, cache read and cache creation,
                            once per assistant message id.

Prints a TSV, one row per class: class, agents, M input tokens, ADOPT, ADAPT,
rows per M tokens; then `unclassed readers:`, `missing transcripts:` and
`unmatched ledger rows:` lines, which say what the table could not count.

Why: the 2026-10-12 round tallied this by hand (TC-15); own corpus 1.51 rows
per M tokens against 0.23 for named external repos decided where readers go.

Exit: 0 everything counted · 2 a transcript missing or a ledger ADOPT/ADAPT
row matched no reader · 3 usage · 4 never ran (dispatch.md or ledger.md
missing, or no dispatch table carries a Class column).
"""
import glob
import json
import os
import re
import sys

USAGE = "usage: round-yield.py <round-dir> [--projects DIR]"


def tables(path):
    """Yield (header cells lowercased, rows of cells) for each Markdown table."""
    header, rows = None, []
    for line in open(path, encoding="utf-8", errors="replace"):
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


def input_tokens(path):
    seen, total = set(), 0
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if d.get("type") != "assistant":
            continue
        m = d.get("message") or {}
        key = m.get("id") or d.get("uuid")
        if key in seen:
            continue
        seen.add(key)
        u = m.get("usage") or {}
        total += sum(u.get(k, 0) or 0 for k in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
    return total


def main(argv):
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
    for header, rows in tables(dispatch):
        if "agent id" not in header:
            continue
        if "class" not in header:
            unclassed += len(rows)
            continue
        classed_tables += 1
        ci, ai = header.index("class"), header.index("agent id")
        pi = header.index("prefix") if "prefix" in header else None
        ri = header.index("reader") if "reader" in header else 0
        for r in rows:
            if len(r) <= max(ci, ai, ri):
                continue
            words = r[ri].split()
            prefix = r[pi] if pi is not None and len(r) > pi and r[pi] else (words[0] if words else "")
            readers.append({"class": r[ci], "agent": r[ai].strip("` "), "prefix": prefix.strip("` "), "tok": 0, "adopt": 0, "adapt": 0})
    if not classed_tables:
        print(f"round-yield.py: no table in {dispatch} carries both an Agent id and a Class column", file=sys.stderr)
        return 4

    missing = []
    for r in readers:
        hits = glob.glob(os.path.join(projects, "*", "*", "subagents", f"agent-{r['agent']}.jsonl"))
        if not hits:
            missing.append(r["agent"])
            continue
        r["tok"] = sum(input_tokens(h) for h in hits)

    # longest prefix first, so `SH-G1-3` is not taken by a reader whose prefix is `SH`
    by_prefix = sorted((r for r in readers if r["prefix"]), key=lambda r: -len(r["prefix"]))
    unmatched = 0
    for header, rows in tables(ledger):
        if "id" not in header or "final verdict" not in header:
            continue
        ii, vi = header.index("id"), header.index("final verdict")
        for row in rows:
            if len(row) <= max(ii, vi):
                continue
            verdict = re.split(r"[^A-Z]", row[vi].lstrip("*` "), maxsplit=1)[0]
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
    return 2 if missing or unmatched else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
