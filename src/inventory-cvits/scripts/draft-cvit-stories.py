#!/usr/bin/env python3
# Conventions for this tree: scripts/README.md
"""Draft one CVIT-remediation Story per owned container image from a ServiceNow export.

Pure transform: data in (CSV path, manifest path), data out (JSON on stdout). No `az`
call, no network — the tracker reads and writes stay in the skill body, per the skill's
bundled-script boundary (ADR-0103): every tracker write is a command a human types
(`/to-story`, `/to-tasks`), so this script makes no tracker call.

Input CSV is the ServiceNow CVIT export, already transcoded to UTF-8 (the skill body runs
`iconv -f WINDOWS-1252 -t UTF-8` before calling this; a non-UTF-8 byte here fails loudly).
A leading UTF-8 BOM is tolerated (read as utf-8-sig), so it never masquerades as a
renamed first column.

Output (stdout) is a JSON object:
  {
    "in_scope":   [ {image, name, subject, tags, title, priority, total,
                     risk_summary, any_missed, marker,
                     body_markdown, acceptance_markdown}, ... ],
    "zero_finding": [ {image, name}, ... ],   # owned images absent from the export
    "off_manifest": [ {image, count}, ... ],  # export images not owned
    "rejected_rows": [ {line, image, number, reason}, ... ],
                      # rows never rendered: ragged, empty image_repository, or (owned
                      # images only) an invalid number / risk_rating / ttr_target_date /
                      # ttr_status, or a duplicate number. Nothing is dropped silently.
    "mixed_status": [ {image, risk_rating, target, statuses: {status: n}}, ... ]
                      # (risk, day) groups whose rows carry more than one ttr_status;
                      # the heading lists every status with its count
  }
Every in_scope and zero_finding entry also carries `rejected`: that image's count in
rejected_rows. A zero_finding entry with rejected > 0 is NOT a clean image.

Exit codes (scripts/README.md taxonomy): 0 drafted; 1 the export or manifest is
malformed (missing column, bad JSON, non-UTF-8 byte); 3 usage error (wrong argument
count, a path that does not exist or cannot be read); 4 the script itself crashed.
`--help` prints the usage line and exits 0.

stdout is pure ASCII JSON (ensure_ascii, the json default and classify's choice): any
JSON reader restores the characters, and no console codec (cp1252) can fail the write.

The skill body matches each in_scope image to an existing Story (by the `marker`) and
prints the /to-story --parent (create) or --update (update) command a human types.
"""

import csv
import json
import re
import sys
import traceback

USAGE = "usage: draft-cvit-stories.py <utf8-export-csv> <manifest-json>"

EXIT_MALFORMED = 1
EXIT_USAGE = 3
EXIT_CRASH = 4

# Field shapes a row must meet before any of it is rendered into a Story body. These
# are ServiceNow system and choice fields, so a miss means a wrong file or a crafted
# value; either way it goes to rejected_rows, never raw into the body (pandoc passes
# raw HTML through, and a stray `Image:` would forge a second idempotency marker).
NUMBER_RE = re.compile(r"^CVIT\d+$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
STATUS_RE = re.compile(r"^[A-Za-z][A-Za-z0-9 -]{0,40}$")

# The heading label for a row whose ttr_status is blank. Not "In-flight": a blank
# is no status, and labelling it as one claims what the export does not say.
BLANK_STATUS = "No status"

# Risk levels highest-severity first; a level absent from the export is omitted downstream.
RISK_ORDER = ["1 - Critical", "2 - High", "3 - Medium", "4 - Low"]

# Columns the transform reads: a renamed header either crashes the run mid-parse with
# a raw KeyError or, for ttr_status, silently reads every row as not-missed and drops
# the Priority-1 escalation. So the header is validated once up front and the missing
# column is named in a clean exit instead.
REQUIRED_COLUMNS = ("image_repository", "risk_rating", "ttr_target_date", "number", "ttr_status")

# The one status that escalates Priority to 1 and raises the banner.
MISSED_STATUS = "Target Missed"

# The idempotency marker stamped in each Story body, by which a re-run matches the
# existing Story instead of opening a duplicate. Defined once here so the body writer
# and the JSON `marker` field never drift apart. The format (`Image: <repo>`) is frozen
# across three homes, so an edit to the prefix must update all three together:
#   - this script (MARKER_PREFIX / marker_for);
#   - src/inventory-cvits/SKILL.md §3, the read-back regex matching existing Stories;
#   - src/triage-cvits/SKILL.md, which parses the same marker to find the image's Story.
MARKER_PREFIX = "Image:"


def marker_for(image):
    """The stamped idempotency marker for an image — the single source for the format."""
    return f"{MARKER_PREFIX} {image}"


class UsageError(Exception):
    """A path argument that does not exist or cannot be read: fix the args (exit 3)."""


class MalformedInput(Exception):
    """The export or manifest is readable but wrong: fix the input (exit 1)."""


def open_input(path, **kw):
    try:
        return open(path, **kw)
    except OSError as e:
        raise UsageError(f"cannot read {path}: {e.strerror}") from None

OUT_OF_SCOPE = (
    "Per-finding classification and disposition (base-image vs. app dependency, "
    "false positives, fix paths) is the Prisma Cloud classification pass, not this "
    "Story. This pass sizes and tracks the image's remediation."
)

BANNER = (
    "⚠️ **Target missed.** One or more findings are past their remediation "
    "target; escalation to leadership may be required."
)


def load_manifest(path):
    """Read the image manifest into {image_repository: {name, tags, subject}}.

    Accepts two forms per entry, so a team supplies whichever its manifest uses:
      - legacy string:  "img": "Product Name"   -> name=Product Name, tags=[name], subject=None
      - object:         "img": {"name": "...", "tags": [...], "subject": "..."}  (tags/subject optional)
    """
    with open_input(path, encoding="utf-8-sig") as fh:
        try:
            raw = json.load(fh)
        except (json.JSONDecodeError, UnicodeDecodeError) as e:
            raise MalformedInput(f"manifest {path} is not valid UTF-8 JSON: {e}") from None
    if not isinstance(raw, dict) or not raw:
        raise MalformedInput(f"manifest {path} resolved to no images — configuration error, not an empty run")
    out = {}
    for image, val in raw.items():
        if isinstance(val, str):
            out[image] = {"name": val, "tags": [val], "subject": None}
        elif isinstance(val, dict):
            name = val.get("name")
            if not name or not isinstance(name, str):
                raise MalformedInput(f"manifest entry {image!r} has no string 'name'")
            tags = val.get("tags") or [name]
            if not isinstance(tags, list) or not all(isinstance(t, str) for t in tags):
                raise MalformedInput(f"manifest entry {image!r} 'tags' must be a list of strings")
            subject = val.get("subject")
            if subject is not None and not isinstance(subject, str):
                raise MalformedInput(f"manifest entry {image!r} 'subject' must be a string")
            out[image] = {"name": name, "tags": list(tags), "subject": subject}
        else:
            raise MalformedInput(f"manifest entry {image!r} is neither a string nor an object")
    return out


def row_defect(r, seen):
    """The reason an owned image's row cannot be rendered, or None if it is clean."""
    number = r["number"]
    if not NUMBER_RE.match(number):
        return "invalid number (expected CVIT<digits>)"
    if number in seen:
        return "duplicate number (an earlier row already carries it)"
    if r["risk_rating"] not in RISK_ORDER:
        return f"unknown risk_rating (expected one of: {', '.join(RISK_ORDER)})"
    if not DATE_RE.match(day(r["ttr_target_date"])):
        return "invalid ttr_target_date (expected YYYY-MM-DD[ hh:mm:ss])"
    status = r["ttr_status"]
    if status and not STATUS_RE.match(status):
        return "invalid ttr_status (letters, digits, spaces and hyphens only)"
    return None


def read_rows(csv_path, owned):
    """Group export rows by image_repository, counting off-manifest images for the report.

    Uses the stdlib CSV reader so quoted fields with embedded commas and newlines
    (the multi-line vulnerability summaries) parse correctly — a naive split mis-aligns.
    Every row lands in exactly one place: an owned image's rows, the off-manifest count,
    or rejected_rows with its reason.
    """
    in_scope = {img: [] for img in owned}
    off_manifest = {}
    rejected = []
    seen = set()
    with open_input(csv_path, encoding="utf-8-sig", newline="") as fh:
        try:
            reader = csv.DictReader(fh)
            fieldnames = reader.fieldnames or []
            missing = [c for c in REQUIRED_COLUMNS if c not in fieldnames]
            if missing:
                raise MalformedInput(
                    f"export {csv_path} is missing required column(s): {', '.join(missing)} "
                    f"— the header was renamed or the wrong file was passed"
                )
            for r in reader:
                line = reader.line_num
                # A short row fills its missing fields with None; a long one carries
                # its extras under the None key. Either way its columns are misaligned.
                if None in r or any(v is None for v in r.values()):
                    rejected.append({
                        "line": line, "image": r.get("image_repository") or None,
                        "number": r.get("number") or None,
                        "reason": f"ragged row (field count differs from the {len(fieldnames)}-column header)",
                    })
                    continue
                img = r["image_repository"]
                if not img:
                    rejected.append({"line": line, "image": None, "number": r["number"] or None,
                                     "reason": "empty image_repository"})
                elif img in owned:
                    reason = row_defect(r, seen)
                    if reason:
                        rejected.append({"line": line, "image": img, "number": r["number"] or None,
                                         "reason": reason})
                    else:
                        seen.add(r["number"])
                        in_scope[img].append(r)
                else:
                    off_manifest[img] = off_manifest.get(img, 0) + 1
        except UnicodeDecodeError as e:
            raise MalformedInput(
                f"export {csv_path} is not UTF-8 ({e.reason} at byte {e.start}) — transcode it first"
            ) from None
        except csv.Error as e:
            raise MalformedInput(f"export {csv_path} is not parseable CSV: {e}") from None
    return in_scope, off_manifest, rejected


def risk_rank(rating):
    try:
        return RISK_ORDER.index(rating)
    except ValueError:
        return len(RISK_ORDER)  # unreachable for rendered rows: read_rows rejects unknown ratings


def strip_level_prefix(rating):
    """'2 - High' -> 'High'."""
    return rating.split(" - ", 1)[1]


def cvit_sort_key(number):
    """Sort 'CVIT7966594' by its numeric suffix, so CVIT9 sorts before CVIT10."""
    digits = number[len("CVIT"):] if number.startswith("CVIT") else number
    return (int(digits), number) if digits.isdigit() else (float("inf"), number)


def day(target):
    """Day-truncate a second-precision target date: '2026-03-10 23:13:49' -> '2026-03-10'.

    Grouping on the raw value makes one group per second; truncating first is the fix.
    """
    return target.split(" ", 1)[0] if target else ""


def risk_summary(rows):
    """'16 High, 16 Medium' — highest severity first, zero levels omitted, prefix stripped."""
    counts = {}
    for r in rows:
        counts[r["risk_rating"]] = counts.get(r["risk_rating"], 0) + 1
    ordered = sorted(counts, key=risk_rank)
    return ", ".join(f"{counts[r]} {strip_level_prefix(r)}" for r in ordered)


def status_order(status):
    """Target Missed first (it is the escalation), then the rest alphabetically."""
    return (status != MISSED_STATUS, status)


def group_findings(rows):
    """Group by (risk_rating, day-truncated target date); return (blocks, mixed groups).

    Order: by risk severity (High before Medium), then ascending target date within a level
    (dates are validated YYYY-MM-DD, so the string sort is the date sort).
    Each group's heading lists every ttr_status in it with its count. Status is per-second
    while the group is per-day, so on the target day an 08:00 row can be Target Missed
    while a 21:00 row is still in flight; such a group is rendered with both counts and
    returned in the mixed list so the run reports it, rather than aborting every image.
    """
    groups = {}
    for r in rows:
        key = (r["risk_rating"], day(r["ttr_target_date"]))
        groups.setdefault(key, []).append(r)

    blocks = []
    mixed = []
    for (rating, target) in sorted(groups, key=lambda k: (risk_rank(k[0]), k[1])):
        members = groups[(rating, target)]
        n = len(members)
        counts = {}
        for m in members:
            s = m["ttr_status"] or BLANK_STATUS
            counts[s] = counts.get(s, 0) + 1
        ordered = sorted(counts, key=status_order)
        if len(ordered) > 1:
            mixed.append({"risk_rating": rating, "target": target,
                          "statuses": {s: counts[s] for s in ordered}})
        noun = "finding" if n == 1 else "findings"
        tally = ", ".join(f"{s}: {counts[s]}" for s in ordered)
        heading = f"**{rating} — target {target} ({n} {noun}; {tally})**"
        # CVITs numerically sorted within a group, so the list is deterministic
        # across runs regardless of export row order.
        numbers = sorted((m["number"] for m in members), key=cvit_sort_key)
        cvits = ", ".join(numbers)
        blocks.append((heading, cvits))
    return blocks, mixed


def draft_body(image, meta, rows):
    """Author the Story body as Markdown — /to-story converts it to HTML via pandoc."""
    name = meta["name"]
    subject = meta["subject"]
    total = len(rows)
    summary = risk_summary(rows)
    # "backing the <name> <subject>" when a subject is set, else "backing the <name> image".
    backing = f"backing the {name} {subject.lower()}" if subject else f"backing the {name} image"
    any_missed = any(r["ttr_status"] == MISSED_STATUS for r in rows)
    blocks, mixed = group_findings(rows)

    lines = []
    lines.append(f"`{marker_for(image)}`")
    lines.append("")
    lines.append("## Problem")
    lines.append("")
    lines.append(
        f"The `{image}` container image {backing} has {total} open "
        f"container-vulnerability findings (CVITs) from the ServiceNow export ({summary}). "
        f"Each must be remediated and its CVIT resolved before the image is clean."
    )
    lines.append("")
    lines.append("## Findings by risk and target date")
    lines.append("")
    if any_missed:
        lines.append(BANNER)
        lines.append("")
    for heading, cvits in blocks:
        lines.append(heading)
        lines.append("")
        lines.append(cvits)
        lines.append("")
    lines.append("## Out of scope")
    lines.append("")
    lines.append(OUT_OF_SCOPE)
    return "\n".join(lines) + "\n", any_missed, total, summary, mixed


def draft_acceptance(image, meta):
    # No live count in AC text: it would change on every run, and /to-story --update
    # stops on a pre-existing AC whose text changed. The count lives in the Problem line.
    name = meta["name"]
    return (
        f"- **AC1:** A ServiceNow rescan of `{image}` reports zero open CVIT findings.\n"
        f"- **AC2:** The fix for each finding is deployed and verified in the {name} image.\n"
    )


def build_title(meta):
    name = meta["name"]
    subject = meta["subject"]
    return f"[{name}] {subject} CVIT remediation" if subject else f"[{name}] CVIT remediation"


def run(csv_path, manifest_path):
    manifest = load_manifest(manifest_path)
    grouped, off_manifest, rejected = read_rows(csv_path, set(manifest))
    rejected_by_image = {}
    for r in rejected:
        if r["image"] in manifest:
            rejected_by_image[r["image"]] = rejected_by_image.get(r["image"], 0) + 1

    in_scope = []
    zero_finding = []
    mixed_status = []
    for image in sorted(manifest):
        meta = manifest[image]
        rows = grouped[image]
        n_rejected = rejected_by_image.get(image, 0)
        if not rows:
            zero_finding.append({"image": image, "name": meta["name"], "rejected": n_rejected})
            continue
        body, any_missed, total, summary, mixed = draft_body(image, meta, rows)
        mixed_status.extend({"image": image, **m} for m in mixed)
        in_scope.append({
            "image": image,
            "name": meta["name"],
            "subject": meta["subject"],
            "tags": meta["tags"],
            "title": build_title(meta),
            "priority": 1 if any_missed else 2,
            "total": total,
            "risk_summary": summary,
            "any_missed": any_missed,
            "marker": marker_for(image),
            "rejected": n_rejected,
            "body_markdown": body,
            "acceptance_markdown": draft_acceptance(image, meta),
        })

    return {
        "in_scope": in_scope,
        "zero_finding": zero_finding,
        "off_manifest": [
            {"image": img, "count": off_manifest[img]} for img in sorted(off_manifest)
        ],
        "rejected_rows": rejected,
        "mixed_status": mixed_status,
    }


def main(argv):
    if len(argv) == 2 and argv[1] in ("-h", "--help"):
        print(USAGE)
        return 0
    if len(argv) != 3:
        print(USAGE, file=sys.stderr)
        return EXIT_USAGE
    try:
        report = run(argv[1], argv[2])
    except UsageError as e:
        print(f"draft-cvit-stories: {e}\n{USAGE}", file=sys.stderr)
        return EXIT_USAGE
    except MalformedInput as e:
        print(f"draft-cvit-stories: {e}", file=sys.stderr)
        return EXIT_MALFORMED
    except Exception:
        traceback.print_exc()
        print("draft-cvit-stories: internal error — the script crashed; this run is no verdict", file=sys.stderr)
        return EXIT_CRASH
    # ensure_ascii (the default) keeps stdout pure ASCII: a cp1252 console cannot fail
    # the write, and any JSON reader restores the characters.
    json.dump(report, sys.stdout, ensure_ascii=True, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
