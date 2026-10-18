#!/usr/bin/env python3
# Conventions for this tree: scripts/README.md
"""find-image-story.py — find the image Story under a CVIT security feature.

Owned by inventory-cvits, whose draft-cvit-stories.py stamps the marker it
reads; triage-cvits runs this copy by its installed path. Data in,
data out (ADR-0103): it reads `az` JSON on stdin and never calls `az` itself;
the skill body prints the `az` commands that produce its input.

Usage:
  find-image-story.py children < feature.json
      feature.json is `az boards work-item show --id <feature> --output json
      --expand relations`. Prints each child ID (the
      System.LinkTypes.Hierarchy-Forward relations), one per line.

  find-image-story.py match [--expect N] [--image REPO] < children.json
      children.json is the `az boards work-item show --id <id> --output json`
      output for every child, concatenated or as one JSON array, so
      `while read -r id; do az boards work-item show --id "$id" --output json
      || exit 1; done < children.txt | find-image-story.py match --expect N`
      works. --expect N is the line count of children.txt: a read that read
      a different number of work items (a failed or throttled `az` call)
      exits 2 and prints no map, since a partial map reads a dropped Story
      as absent. Prints JSON:
        stories   [{id, image, priority, forged}]  every marked child
        unmarked  [id]  children with no marker (pre-date the skill or were
                        hand-made; reported for the user, never a match)
        forged    [{id, markers}]  a body carrying a second `Image:`; the
                        Story is matched by its first marker only
        matches   [id]  with --image, the stories whose marker is REPO
      With --image, zero or more than one match is a FAIL on stderr.

The marker is the first match of MARKER_PREFIX, then `\\s*([^\\s<]+)`, in
System.Description. MARKER_PREFIX is imported from draft-cvit-stories.py beside
this file, which stamps it, so the two cannot drift.

Exit: 0 clean; 1 with --image, zero or several matches; 2 with --expect, the
count of work items read differs from N (no map printed); 3 usage or input
that is not the JSON named above; 4 draft-cvit-stories.py is missing beside
this file or defines no MARKER_PREFIX.
"""
import importlib.util
import json
import os
import re
import sys


def _marker_prefix():
    """MARKER_PREFIX from draft-cvit-stories.py, the one definition of the marker."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "draft-cvit-stories.py")
    try:
        # No __pycache__ beside a shipped script: security.sh reads bytecode as a REVIEW.
        sys.dont_write_bytecode = True
        spec = importlib.util.spec_from_file_location("draft_cvit_stories", path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod.MARKER_PREFIX
    except (OSError, SyntaxError, AttributeError) as e:
        print(f"find-image-story.py: cannot read MARKER_PREFIX from {path}: {e}", file=sys.stderr)
        sys.exit(4)


MARKER_PREFIX = _marker_prefix()
MARKER_RE = re.compile(re.escape(MARKER_PREFIX) + r"\s*([^\s<]+)")
CHILD_LINK = "System.LinkTypes.Hierarchy-Forward"


def usage(msg):
    print(f"find-image-story.py: {msg}", file=sys.stderr)
    print(__doc__.split("\n\n", 2)[1], file=sys.stderr)
    sys.exit(3)


def read_objects(text):
    """Every JSON value on stdin, concatenated or wrapped in one array."""
    dec, i, out = json.JSONDecoder(), 0, []
    while True:
        while i < len(text) and text[i].isspace():
            i += 1
        if i == len(text):
            break
        try:
            value, i = dec.raw_decode(text, i)
        except json.JSONDecodeError as e:
            usage(f"stdin is not JSON at offset {i}: {e.msg}")
        out.extend(value if isinstance(value, list) else [value])
    for v in out:
        if not isinstance(v, dict) or "id" not in v:
            usage("stdin holds a value that is not a work item (no id)")
    return out


def children(items):
    if len(items) != 1:
        usage(f"children reads one feature, got {len(items)}")
    for rel in items[0].get("relations") or []:
        if rel.get("rel") == CHILD_LINK:
            print(rel.get("url", "").rstrip("/").rsplit("/", 1)[-1])


def match(items, image, expect):
    if expect is not None and len(items) != expect:
        print(f"find-image-story.py: short read: match read {len(items)} work items, --expect {expect};"
              " an az read failed or was dropped, so no map is printed", file=sys.stderr)
        return 2
    report = {"stories": [], "unmarked": [], "forged": []}
    for item in items:
        fields = item.get("fields") or {}
        markers = MARKER_RE.findall(fields.get("System.Description") or "")
        if not markers:
            report["unmarked"].append(item["id"])
            continue
        if len(markers) > 1:
            report["forged"].append({"id": item["id"], "markers": markers})
        report["stories"].append({
            "id": item["id"],
            "image": markers[0],
            "priority": fields.get("Microsoft.VSTS.Common.Priority"),
            "forged": len(markers) > 1,
        })
    rc = 0
    if image is not None:
        report["matches"] = [s["id"] for s in report["stories"] if s["image"] == image]
        if len(report["matches"]) != 1:
            print(f"FAIL: --image expected exactly one Story, found {len(report['matches'])}"
                  f" carrying `{MARKER_PREFIX} {image}` (ids: {report['matches']})", file=sys.stderr)
            rc = 1
    json.dump(report, sys.stdout, indent=2)
    print()
    return rc


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if argv else 3
    mode, rest = argv[0], argv[1:]
    if mode == "children":
        if rest:
            usage(f"children takes no arguments, got {rest}")
        children(read_objects(sys.stdin.read()))
        return 0
    if mode == "match":
        opts = {"--image": None, "--expect": None}
        args = list(rest)
        while args:
            flag = args.pop(0)
            if flag not in opts or opts[flag] is not None or not args or not args[0]:
                usage(f"match takes only --expect N and --image REPO, got {rest}")
            opts[flag] = args.pop(0)
        expect = opts["--expect"]
        if expect is not None:
            if not expect.strip().isdigit():
                usage(f"--expect takes a count, got {expect!r}")
            expect = int(expect)
        return match(read_objects(sys.stdin.read()), opts["--image"], expect)
    usage(f"unknown mode {mode!r}")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
