# Conventions for this tree: scripts/README.md
# mutation-sweep.py — the mutant generator behind mutation-sweep.sh. Not run
# on its own: the driver calls `list` to enumerate the mutants of one file and
# `apply` to write one of them, and does the copying, running, and grading
# itself. The contract, the roster, and the exit codes are the driver's; this
# file owns only what a mutant is.
#
# A mutant is one edit to one line of a script, chosen because a selftest that
# stays green across it has a hole exactly there. Three operators, each the
# shape of a guard going quietly wrong:
#
#   drop-alt   one alternative removed from a `|`-joined group inside a quoted
#              pattern or a bash case arm — the narrowing scripts/README.md names: the instance
#              that stopped matching should turn the selftest red
#   flip-test  one comparison inverted on a line that tests something:
#              -eq/-ne, -z/-n, =/!= inside [ ], ==/!= and is/is not in Python,
#              ||/&& — the widening or inversion: a clean neighbor should now
#              fire, or a firing instance go quiet
#   drop-line  one reporting line removed — a line that calls say_fail,
#              selftest_fail, hook_allow, allow, crumb, emit, findings.append,
#              or exits or returns non-zero — so a failure the script reports
#              has a fixture that expects it
#
# Lines that are comments, blank, or structural (an `elif` or `except` head,
# and the bare `fi`/`done`/`esac`/braces no operator matches) are never mutated. A
# mutant that leaves the file unparseable is the driver's to discard, by
# `bash -n` or `ast.parse`, and is counted, never graded.
#
# Ids are stable across runs: `<op>:<line>:<n>`, n counting mutants on that
# line in source order. `list --max N` keeps the first N by the SHA-1 of the
# id, so a capped run samples the same mutants tomorrow as today and a
# `--path` rerun can reproduce one.
#
# Usage (from the driver):
#   python3 mutation-sweep.py list <file> [--max N] [--op OP]  → id<TAB>op<TAB>line<TAB>what
#   python3 mutation-sweep.py apply <file> <id>                 → the mutated file on stdout

import hashlib, re, sys

# Only the structural lines an operator could otherwise touch are listed: an
# `elif` carries a test, an `except` clause can carry an `is`. `fi`, `done`,
# `esac`, `else`, braces and the like match no operator, so listing them here
# would be a roster nothing reads (the first sweep run over this file said so).
STRUCTURAL = re.compile(r"^\s*(elif\b.*|except\b.*:)\s*$")
REPORT = re.compile(r"\b(say_fail|selftest_fail|selftest_skip|hook_allow|allow|crumb|emit|findings\.append|say_warn)\b\s*[( \"']"
                    r"|\b(exit|return)\s+[1-9]\b|\bsys\.exit\([1-9]\)")
TESTY = re.compile(r"\[\[?[^\]]*\]\]?|\bif\b|\bwhile\b|&&|\|\||==|!=|\bis\s+(not\s+)?None\b|\bis\s+(not\s+)?True\b")
FLIPS = [
    (r"(?<=\s)-eq(?=\s)", "-ne"), (r"(?<=\s)-ne(?=\s)", "-eq"),
    (r"(?<=\s)-z(?=\s)", "-n"), (r"(?<=\s)-n(?=\s)", "-z"),
    (r"(?<=\s)!=(?=\s)", "=="), (r"(?<=\s)==(?=\s)", "!="),
    (r"\bis not\b", "is"), (r"\bis\b(?! not)", "is not"),
    (r"\|\|", "&&"), (r"&&", "||"),
]
QUOTED = re.compile(r"""r?"((?:[^"\\]|\\.)*)"|r?'((?:[^'\\]|\\.)*)'""")


def is_comment(line):
    s = line.lstrip()
    return not s or s.startswith("#")


def alternatives(text):
    """Top-level `|`-separated spans of `text` (a group body): [(start, end)]."""
    spans, depth, start, i = [], 0, 0, 0
    while i < len(text):
        c = text[i]
        if c == "\\":
            i += 2
            continue
        if c in "([":
            depth += 1
        elif c in ")]":
            depth -= 1
        elif c == "|" and depth == 0:
            # a `||`, or a bar with whitespace on both sides, is shell, not a pattern
            if text[i + 1:i + 2] == "|" or text[i - 1:i] == "|" or (text[i - 1:i].isspace() and text[i + 1:i + 2].isspace()):
                i += 1
                continue
            spans.append((start, i))
            start = i + 1
        i += 1
    spans.append((start, len(text)))
    return spans if len(spans) > 1 else []


def balanced(text):
    depth = 0
    for c in text:
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def groups(text):
    """Every parenthesized group body in `text`, innermost last: [(open+1, close)].
    A `$(` opens a command substitution, where a `|` is a shell pipe and not an
    alternative; that group, and the whole string around it, are left alone."""
    out, stack, i = [], [], 0
    while i < len(text):
        c = text[i]
        if c == "\\":
            i += 2
            continue
        if c == "(":
            stack.append((i, i > 0 and text[i - 1] == "$"))
        elif c == ")" and stack:
            start, subst = stack.pop()
            if not subst:
                out.append((start + 1, i))
        i += 1
    return out


CASE_ARM = re.compile(r"^(\s*)([^\s()\"'#]+(?:\|[^\s()\"'#]+)+)\)")


def drop_alt_mutants(line):
    out = []
    spans = [(m.start() + (2 if line[m.start()] == "r" else 1), m.group(1) if m.group(1) is not None else m.group(2))
             for m in QUOTED.finditer(line)]
    arm = CASE_ARM.match(line)   # a bash case arm: unquoted alternatives before the `)`
    if arm:
        spans.append((arm.start(2), arm.group(2)))
    for off, body in spans:
        if "|" not in body:
            continue
        # the whole string counts as a group only when it is one pattern, not a fragment
        # of a larger construct the quote regex cut through (a `"$(...)"` with quotes inside)
        bodies = ([(0, len(body))] if balanced(body) and "$(" not in body else []) + groups(body)
        for gs, ge in bodies:
            seg = body[gs:ge]
            alts = alternatives(seg)
            if not alts:
                continue
            for k, (a, b) in enumerate(alts):
                alt = seg[a:b]
                if not alt.strip():
                    continue
                # remove the alternative and one adjoining bar
                if k < len(alts) - 1:
                    new_seg = seg[:a] + seg[b + 1:]
                else:
                    new_seg = seg[:a - 1] + seg[b:]
                new_body = body[:gs] + new_seg + body[ge:]
                out.append((line[:off] + new_body + line[off + len(body):], "drops the alternative %r" % alt))
    return out


def masked(line):
    """The line with every quoted span blanked, so a flip never lands in message text."""
    out = list(line)
    for m in QUOTED.finditer(line):
        for i in range(m.start(), m.end()):
            out[i] = " "
    return "".join(out)


def flip_test_mutants(line):
    if is_comment(line) or not TESTY.search(line):
        return []
    out, seen, mask = [], set(), masked(line)
    # `=` inside a [ ] test, told from an assignment by the spaces around it and the bracket
    for t in re.finditer(r"\[\[?[^\]]*\]\]?", mask):
        for m in re.finditer(r"(?<=\s)=(?=\s)", t.group(0)):
            at = t.start() + m.start()
            new = line[:at] + "!=" + line[at + 1:]
            if new not in seen:
                seen.add(new); out.append((new, "flips '=' to '!=' in a test"))
    for pat, rep in FLIPS:
        m = re.search(pat, mask)
        if not m:
            continue
        new = line[:m.start()] + rep + line[m.end():]
        if new != line and new not in seen:
            seen.add(new); out.append((new, "flips %r to %r" % (m.group(0), rep)))
    return out


def drop_line_mutants(line):
    if is_comment(line) or STRUCTURAL.match(line) or not REPORT.search(line):
        return []
    return [(None, "drops the reporting line")]


def mutants(lines):
    """[(id, op, lineno, what, new_line_or_None)] in source order."""
    out = []
    for i, line in enumerate(lines):
        if is_comment(line) or STRUCTURAL.match(line) or line.rstrip().endswith("\\"):
            continue
        n = i + 1
        for op, fn in (("drop-alt", drop_alt_mutants), ("flip-test", flip_test_mutants), ("drop-line", drop_line_mutants)):
            for k, (new, what) in enumerate(fn(line), 1):
                out.append(("%s:%d:%d" % (op, n, k), op, n, what, new))
    return out


def main(argv):
    if len(argv) < 3 or argv[1] not in ("list", "apply"):
        sys.stderr.write("usage: mutation-sweep.py list <file> [--max N] [--op OP] | apply <file> <id>\n")
        return 3
    path = argv[2]
    try:
        with open(path, encoding="utf-8", errors="surrogateescape") as f:
            lines = f.read().split("\n")
    except OSError as e:
        sys.stderr.write("mutation-sweep.py: cannot read %s: %s\n" % (path, e))
        return 4
    ms = mutants(lines)
    if argv[1] == "list":
        cap, op = None, None
        rest = argv[3:]
        while rest:
            if rest[0] == "--max" and len(rest) > 1 and rest[1].isdigit():
                cap = int(rest[1]); rest = rest[2:]
            elif rest[0] == "--op" and len(rest) > 1:
                op = rest[1]; rest = rest[2:]
            else:
                sys.stderr.write("mutation-sweep.py: unknown list option %r\n" % rest[0])
                return 3
        if op:
            ms = [m for m in ms if m[1] == op]
        if cap is not None:
            keep = set(sorted((m[0] for m in ms), key=lambda s: hashlib.sha1(s.encode()).hexdigest())[:cap])
            ms = [m for m in ms if m[0] in keep]
        for mid, mop, n, what, _ in ms:
            sys.stdout.write("%s\t%s\t%d\t%s\n" % (mid, mop, n, what))
        return 0
    if len(argv) != 4:
        sys.stderr.write("usage: mutation-sweep.py apply <file> <id>\n")
        return 3
    want = argv[3]
    for mid, mop, n, what, new in ms:
        if mid != want:
            continue
        out = list(lines)
        if new is None:
            del out[n - 1]
        else:
            out[n - 1] = new
        sys.stdout.write("\n".join(out))
        return 0
    sys.stderr.write("mutation-sweep.py: no mutant %s in %s\n" % (want, path))
    return 3


if __name__ == "__main__":
    sys.exit(main(sys.argv))
