#!/usr/bin/env python3
# Conventions for this tree: scripts/README.md
"""Classify each container-image finding in a Twistlock/Prisma export into one of six
disposition buckets (A-F), and roll up per-bucket counts with the confirmed and
unconfirmed split. Emits JSON only; the skill body drafts the Story enrichment and the
Task bodies from it.

Usage: classify-cvit-findings.py <utf8-export-csv> <resolved-tree-json>
       classify-cvit-findings.py --help
(`--help` prints the input shape and the exit codes.)

Pure transform: data in (the export CSV and the resolved-tree JSON), data out (JSON on
stdout). No `az` call, no network, no subprocess. The skill body runs the resolver
commands (`npm ls --omit=dev --all`, `npm ls --all`), reduces them, and passes both
trees here inside the resolved-tree JSON; the tracker reads and writes stay in the skill
body, per the bundled-script boundary (ADR-0103): every tracker write goes through a
publisher (`to-story`, `to-tasks`), so this script makes no tracker call. Keeping the resolver reads in the body lets the selftest freeze tree
shapes as fixtures rather than needing a real node_modules on disk.

<utf8-export-csv> is the Twistlock/Prisma export, already transcoded to UTF-8 (the skill
body runs `iconv -f WINDOWS-1252 -t UTF-8` first). A leading UTF-8 BOM is accepted; a
non-UTF-8 byte fails the run (exit 1) rather than reading as an empty stream.

The bucket taxonomy, the three-tier cascade, and the resolver interface are
ecosystem-neutral and defined in src/triage-cvits/references/buckets.md. This script is
the deterministic engine behind that cascade; the resolver trees it consumes are built
per ecosystem by the skill body, npm proven.

The governing invariant: a missing or ambiguous input flags (`confirmed: false`), never
asserts. Every branch below that cannot prove its disposition from the inputs returns
`confirmed: false` with the reason naming what would confirm it.

Output (stdout) is a JSON object with exactly these top-level keys:
  {
    "findings": [ {
        "cve", "package", "matched_package", "version", "ecosystem", "bucket",
        "bucket_reason", "confirmed", "fixed_versions", "path", "sub_tag"
    }, ... ],
    "rollup": {
        "A": {count, pct, confirmed, unconfirmed, sub_tags}, "B".."F": {count, pct,
        confirmed, unconfirmed}, "needs_checkout": {count}, "unresolved": {count},
        "unconfirmed_total": {count}
    },
    "unresolved_ecosystems": [ "pypi", ... ],
    "disposition": { "A": "...", ... "F": "..." },
    "total": 11
  }

Per finding:
  - `bucket` is one of "A".."F"; "?" when the ecosystem has a built resolver but no tree
    was loaded (or both trees were empty) this run, so the finding needs a checkout; or
    null when no resolver exists for its ecosystem, its PURL prefix is unknown, or it has
    no PURL on an application-dependency path.
  - `package` is the raw `Packages` cell, which may join several names with commas. It is
    export text: never interpolate it into a command.
  - `matched_package` is the single name that matched a resolved-tree key (prod first,
    then dev), or null when no tree entry matched. It is the only package field fit to
    pre-fill an upgrade command.
  - `ecosystem` is the PURL type ("npm", "pypi", "apk", ...) or "none" with no PURL.
  - `sub_tag` is set on bucket A only: "os-package" | "tool-bundle" | "global-module" |
    "runtime"; null elsewhere.

Rollup: all six buckets A-F always, each with `confirmed` + `unconfirmed` = `count`.
`needs_checkout` counts bucket "?", `unresolved` counts bucket null; both sit outside
the six, so the A-F percentages sum against the whole. `unconfirmed_total` counts every
finding with `confirmed: false`, in any bucket including "?" and null, so it is the one
number to name as "still needs confirmation".

This script emits no markdown: the skill body (step 5) drafts the Story enrichment and
one Task body per bucket from `findings` and `rollup`, handing them to to-tasks, and never re-derives any field here.
"""

import csv
import json
import os
import re
import sys

USAGE = """\
usage: classify-cvit-findings.py <utf8-export-csv> <resolved-tree-json>
       classify-cvit-findings.py --help

  <utf8-export-csv>     the Twistlock/Prisma export, transcoded to UTF-8; must carry the
                        columns CVE ID, Packages, Package Version, PURL, Package Path,
                        Fix Status
  <resolved-tree-json>  {
                          "trees": {"<ecosystem>": {"prod": {<name>: <version>},
                                                    "dev":  {<name>: <version>}}, ...},
                          "controlled_packages": [<base package the app Dockerfile controls>, ...],
                          "dockerfile_read": true|false
                        }
                        The skill body builds it: `trees` from `npm ls` per ecosystem,
                        `controlled_packages` and `dockerfile_read` from reading the app
                        repo's Dockerfile. Every key is optional; an absent tree or
                        Dockerfile is a valid run that flags rather than asserts.

Writes the classification JSON to stdout; the header of this file is its contract.

exit status:
  0  classified; JSON on stdout
  1  an input file was read and rejected: a required column missing, malformed or
     mistyped JSON, a non-UTF-8 byte
  3  usage error: wrong argument count, an unknown option, a path that is not a
     readable file
  4  the script crashed; the run is not a verdict on the inputs"""

EXIT_REJECTED = 1
EXIT_USAGE = 3
EXIT_CRASH = 4

# Columns the transform reads by subscript: a renamed header fails the run with the
# missing column named, rather than a raw KeyError mid-parse (renamed column fails loudly). Extra columns and
# absent optional columns are tolerated; only this subset is required. Every column the
# cascade reads on a row is here — including `Package Path` (feeds origin and the
# A sub-tag) and `Fix Status` (feeds parse_fixed_versions): a renamed `Package Path`
# otherwise reads as "" and a base finding slips to C ("not affected"), and a renamed
# `Fix Status` reads as "" and every E silently becomes F — both the unsafe direction.
REQUIRED_COLUMNS = (
    "CVE ID",
    "Packages",
    "Package Version",
    "PURL",
    "Package Path",
    "Fix Status",
)

# The six buckets, in cascade order. Every rollup carries all six keys even at count 0,
# so the Story enrichment never has to guess which buckets a run omitted.
BUCKETS = ("A", "B", "C", "D", "E", "F")

# Disposition prose per bucket — the single source the Story enrichment and the Task
# bodies both read, so the two never drift. The remediation-lever reference doc carries
# the long form; these are the one-line dispositions.
DISPOSITION = {
    "A": "Reassign to the platform base-image team.",
    "B": "Fix in the repository's own Dockerfile (RUN-list entry or FROM-tag bump), then rebuild.",
    "C": "Not affected — file a scanner or curation exception for findings that recur scan over scan.",
    "D": "Fix the build to exclude non-production dependencies; one build-file change clears the bucket.",
    "E": "Request a rescan — the scan predates the current lockfile.",
    "F": "Upgrade with upgrade-deps; the target org's registry (JFrog Compliant Version Selection) substitutes a compliant version.",
}

# PURL ecosystem prefix -> the resolver key the resolved-tree JSON uses. A PURL whose
# prefix is not here, and that is not an OS/base finding, is an ecosystem the interface
# does not name at all: flagged loudly, never guessed. apk/deb/rpm are OS ecosystems
# handled by the base-image cascade, not a two-tree resolver, so they are not keys here.
PURL_ECOSYSTEM = {
    "pkg:npm": "npm",
    "pkg:pypi": "pypi",
    "pkg:nuget": "nuget",
    "pkg:gradle": "gradle",
    "pkg:maven": "maven",
}

# The ecosystems with a BUILT resolver. npm is proven against two real fixtures; the others
# are named in the interface (PURL_ECOSYSTEM) but have no resolver yet, so a finding in one
# is flagged as needing a resolver (unbuilt ecosystem flagged), distinct from a built ecosystem whose tree merely
# was not loaded this run (which needs a checkout). A resolver is added to this set when a
# real image of its ecosystem first enters triage (src/triage-cvits/references/buckets.md) — never built against fabricated
# data, so this set grows with reality, not ahead of it.
BUILT_RESOLVERS = {"npm"}

# PURL prefixes that mark an OS/base-layer package — routed through the base-image
# cascade (A/B), never through a dependency-tree resolver.
OS_PURL_PREFIXES = ("pkg:apk", "pkg:deb", "pkg:rpm")

# npm's own CLI bundle shipped inside a base image — installed by the base image, not by
# the app. A finding here is a base finding (Bucket A, tool-bundle), never an app
# dependency, even though its path contains `node_modules`. Every ecosystem has one;
# npm's is the proven case.
TOOL_BUNDLE_PATHS = ("/usr/local/lib/node_modules/npm/", "/usr/lib/node_modules/npm/")

# Where an ecosystem installs the application's own dependencies. A finding under one of
# these — and not under a tool-bundle or global-module path — is an app dependency and
# routes to the two-tree resolver. The app's node_modules sits under its working dir
# (`/usr/app`, `/app`, `/srv/app`); the exhaustive list is impossible, so the test is "a
# marker segment that is not a known base path", which the order in origin encodes.
APP_DEP_MARKERS = ("/node_modules/", "/site-packages/", "/.nuget/", "/.m2/", "/.gradle/")

NODE_MODULES = "/node_modules/"


def die(msg, code=EXIT_REJECTED):
    """Print `msg` to stderr and exit with `code` (default 1: an input was rejected)."""
    print(f"classify-cvit-findings.py: {msg}", file=sys.stderr)
    sys.exit(code)


def load_resolved_tree_json(path):
    """Read the resolved-tree JSON the body built, returning (trees, controlled_packages,
    dockerfile_read). Each of its three keys is optional for a degraded run:

      {
        "trees": {"<ecosystem>": {"prod": {...}, "dev": {...}}, ...},
        "controlled_packages": [<name>, ...],
        "dockerfile_read": true|false
      }

    An empty or absent `trees` is a valid run (no checkout or no built resolver) — every
    non-base finding is then flagged rather than asserted (a missing input flags, never asserts). An absent Dockerfile
    (`dockerfile_read` false or missing) flags every base finding for confirmation rather
    than asserting A. A bare `{}` is accepted as all-degraded.

    Every value is type-checked: a string "false" for `dockerfile_read`, or a bare string
    for `controlled_packages`, is rejected (exit 1) rather than coerced, since coercion
    turns "false" into a Dockerfile read and "expat" into five one-letter packages.
    """
    try:
        with open(path, encoding="utf-8-sig") as fh:
            raw = json.load(fh)
    except UnicodeDecodeError as e:
        die(f"resolved-tree JSON {path} is not UTF-8 ({e.reason} at byte {e.start})")
    except json.JSONDecodeError as e:
        die(f"resolved-tree JSON {path} is malformed: {e}")
    if not isinstance(raw, dict):
        die(f"resolved-tree JSON {path} must be an object")
    trees = raw.get("trees", {})
    if trees is None:
        trees = {}
    if not isinstance(trees, dict):
        die(f"resolved-tree JSON {path} 'trees' must be an object keyed by ecosystem")
    for eco, t in trees.items():
        if not isinstance(t, dict) or "prod" not in t or "dev" not in t:
            die(f"trees entry {eco!r} must carry both 'prod' and 'dev' maps")
        for side in ("prod", "dev"):
            m = t[side]
            if not isinstance(m, dict) or not all(
                isinstance(k, str) and isinstance(v, str) for k, v in m.items()
            ):
                die(f"trees entry {eco!r} {side!r} must be a map of {{name: version}} strings")
    controlled = raw.get("controlled_packages", [])
    if controlled is None:
        controlled = []
    if not isinstance(controlled, list) or not all(isinstance(n, str) for n in controlled):
        die(f"resolved-tree JSON {path} 'controlled_packages' must be a list of package-name strings")
    dockerfile_read = raw.get("dockerfile_read", False)
    if dockerfile_read is None:
        dockerfile_read = False
    if not isinstance(dockerfile_read, bool):
        die(f"resolved-tree JSON {path} 'dockerfile_read' must be true or false, not {dockerfile_read!r}")
    return trees, set(controlled), dockerfile_read


def read_export_rows(csv_path):
    """The export's rows as dicts, after checking every REQUIRED_COLUMNS name is in the
    header. A leading BOM is stripped (utf-8-sig), so a BOM never hides the first column."""
    try:
        with open(csv_path, encoding="utf-8-sig", newline="") as fh:
            reader = csv.DictReader(fh)
            fieldnames = reader.fieldnames or []
            missing = [c for c in REQUIRED_COLUMNS if c not in fieldnames]
            if missing:
                die(
                    f"export {csv_path} is missing required column(s): {', '.join(missing)} "
                    f"— the header was renamed or the wrong file was passed"
                )
            return list(reader)
    except UnicodeDecodeError as e:
        die(f"export {csv_path} is not UTF-8 ({e.reason} at byte {e.start}) — transcode it with iconv first")
    except csv.Error as e:
        die(f"export {csv_path} is not a readable CSV: {e}")


def package_names(cell):
    """The individual package names in a Twistlock `Packages` cell. Twistlock joins several
    package names into one cell with commas — `libssl3,libcrypto3` is one finding against
    two packages — so a name match splits the cell and matches any component. Exact per
    component (exact name match): no substring match, so `libssl3` never matches `libssl3-dev`."""
    return [n.strip() for n in cell.split(",") if n.strip()]


def team_controlled(cell, controlled_packages):
    """True only on a POSITIVE signal that the repository's own Dockerfile controls this
    base package's version — one of the finding's package names appears in
    `controlled_packages`, the set the skill body builds by reading the app repo's Dockerfile
    (its `RUN apk add/update`, `microdnf update`, or `apt install` package lists, and a
    compiled runtime the Dockerfile builds).

    Base findings default to Bucket A (reassign — the team cannot control them) and move to
    Bucket B only on this positive signal. The Twistlock Layer field records the instruction
    that built a layer but not whose Dockerfile authored it, so the instruction alone is
    never read as team control. This is the safe direction: a finding wrongly in A is
    reassigned and re-triaged, while one wrongly in B tells the team to fix what it cannot.
    """
    return any(n in controlled_packages for n in package_names(cell))


def origin(path, purl):
    """Where a finding came from, as (kind, ecosystem), computed once per finding from its
    path and PURL. The base-layer kinds route through the base-image cascade (A/B) and
    become A's sub-tag; the rest route to an ecosystem's two-tree resolver or flag:

      - "os-package": an OS package (apk/deb/rpm PURL).
      - "tool-bundle": npm's own CLI bundle (TOOL_BUNDLE_PATHS).
      - "global-module": any other module whose FIRST node_modules segment sits directly
        under a `lib/` directory — npm's global prefix layout (`/usr/local/lib/node_modules/`,
        `/opt/node/lib/node_modules/`, an nvm `.../versions/node/v20/lib/node_modules/`):
        corepack, yarn, pm2. Installed by the base image or by an app Dockerfile's
        `npm install -g` — the path cannot tell which, so classify flags it. A package named
        `lib` nested inside an app's tree (`/usr/app/node_modules/lib/node_modules/x`) is not
        matched, since only the first node_modules segment is read.
      - "runtime": no PURL and no application-dependency path — read as a compiled runtime
        or base binary (the `node` binary) from the path alone.
      - "app-dep-no-purl": an application-dependency path with no PURL, so no ecosystem.
      - "unknown-ecosystem": a PURL prefix the resolver interface does not name; `ecosystem`
        is that prefix (`pkg:golang`).
      - "app-dep": an application dependency; `ecosystem` is its PURL_ECOSYSTEM key, built
        or not (the caller checks BUILT_RESOLVERS).

    `ecosystem` is None for every kind but the last two.
    """
    prefix = purl.split("/", 1)[0] if purl else ""
    if prefix in OS_PURL_PREFIXES:
        return "os-package", None
    if path and any(b in path for b in TOOL_BUNDLE_PATHS):
        return "tool-bundle", None
    i = path.find(NODE_MODULES) if path else -1
    if i >= 0 and path[:i].endswith("/lib"):
        return "global-module", None
    if not purl:
        app_path = bool(path) and any(m in path for m in APP_DEP_MARKERS)
        return ("app-dep-no-purl" if app_path else "runtime"), None
    if prefix not in PURL_ECOSYSTEM:
        return "unknown-ecosystem", prefix
    return "app-dep", PURL_ECOSYSTEM[prefix]


BASE_ORIGINS = ("os-package", "tool-bundle", "global-module", "runtime")


def parse_dotted_numeric(v):
    """Parse a dotted version into (components, clean). The components are the leading
    numeric run of each dotted segment, stopping after the first segment that is not purely
    numeric (that segment's leading digits are kept): `1.0.0-rc.1` -> ([1, 0, 0], False),
    `3.5.7-r0` -> ([3, 5, 7], False), `v1.0.0` -> ([], False). `clean` is False when any
    segment carried a non-numeric tail or was empty.

    An unclean parse is the signal to flag rather than compare: truncating `1.0.0-rc.1` to
    [1, 0, 0] makes a pre-release read EQUAL to the 1.0.0 release, so `>=` would call a
    below-fix pre-release "already fixed" — the unsafe direction. version_at_or_above
    treats an unclean installed version as uncomparable so classify can flag it instead.
    """
    out = []
    for seg in v.strip().split("."):
        seg = seg.strip()
        num = ""
        for ch in seg:
            if ch.isdigit():
                num += ch
            else:
                break
        if num:
            out.append(int(num))
        if not num or num != seg:
            return out, False
    return out, True


def release_line(components):
    """The release line a parsed version belongs to under the major key: the major, except
    at major 0, where semver makes the minor the breaking boundary and (0, minor) is the
    line: 0.4.x and 0.9.x are separate lines, while 4.19.2 and 4.19.3 are both the 4.x
    line."""
    if components and components[0] == 0:
        return (0, components[1] if len(components) > 1 else 0)
    return (components[0],) if components else ()


def minor_line(components):
    """The release line under the (major, minor) key — the scheme Python, .NET and some
    Node LTS advisories use (3.10 and 3.11 are separate lines). Used only as a cross-check
    before asserting E: see version_at_or_above."""
    if not components:
        return ()
    return (components[0], components[1] if len(components) > 1 else 0)


def _compare_on_lines(inst, parsed, line_of):
    """(result, why) for one release-line scheme. Once the parsed fixed versions span more
    than one line under `line_of`, only the entries on the install's own line are compared;
    none on it flags. A single line is compared directly, line mismatch or not."""
    if len({line_of(fx) for fx in parsed}) > 1:
        parsed = [fx for fx in parsed if line_of(fx) == line_of(inst)]
        if not parsed:
            return False, "no fixed-version entry for its own release line"
    for fx in parsed:
        # Pad to equal length with zeros for the component-wise compare.
        width = max(len(inst), len(fx))
        a = inst + [0] * (width - len(inst))
        b = fx + [0] * (width - len(fx))
        if a >= b:
            return True, None
    return False, None


def version_at_or_above(installed, fixed_versions):
    """(result, why). `result` is True when the installed version is at or above the
    applicable fixed version. `why` is None when the compare could be trusted; otherwise it
    names why not, and the caller must flag rather than trust `result`.

    Name matching upstream is exact; this compare runs only after the package name
    matched a resolved-tree entry. An installed version that does not parse, or carries a
    suffix, flags. A fixed version that does not parse is skipped (never read as "already
    fixed"); a fixed list with no parseable entry flags.

    A Fix Status naming more than one release line (undici: "fixed in 8.10.2, 7.29.1") lists
    one fix per line, not a set of equivalent thresholds: comparing the install against every
    entry would let an older line's fix (7.29.1) clear an install below its own line's fix
    (8.9.0 < 8.10.2). So once the entries span more than one release line, only the entry on
    the install's own line is compared. A single release line is compared directly — an
    install already on a newer major than that line (express 5.0.0 vs "fixed in 4.19.2") is
    still at or above it.

    What "one release line" means depends on the ecosystem's scheme — npm reads 4.1.x and
    4.0.x as one line, Python reads 3.11 and 3.10 as two — and no ecosystem argument reaches
    here. So the compare runs under the major key (`release_line`, (0, minor) at major 0),
    and an at-or-above result is asserted only when the (major, minor) key agrees. Under the
    major key "fixed in 3.11.9, 3.10.1" is one line and 3.10.1 clears an install of 3.11.2;
    under (major, minor) the install is held to 3.11.9 and is below it. The two disagree, so
    the finding flags rather than asserting E. A below-fix result needs no cross-check: if
    the install is below every entry on its major-keyed line, it is below its own minor
    line's entry too, and F is not a claim of safety.
    """
    inst, inst_clean = parse_dotted_numeric(installed)
    if not inst:
        return False, "an unparseable installed version"
    if not inst_clean:
        # A suffixed install (pre-release/build) cannot be ordered against a release here.
        return False, "an unorderable version suffix"

    parsed = []
    for fixed in fixed_versions:
        fx, _ = parse_dotted_numeric(fixed)
        if fx:
            parsed.append(fx)
    if not parsed:
        return False, "no parseable fixed version"

    result = _compare_on_lines(inst, parsed, release_line)
    if result == (True, None) and _compare_on_lines(inst, parsed, minor_line) != (True, None):
        return False, "a Fix Status whose entries split one major by minor (release-line scheme ambiguous)"
    return result


FIXED_IN = re.compile(r"fixed in", re.IGNORECASE)


def parse_fixed_versions(fix_status):
    """'fixed in 4.0.2, 3.6.4, 3.5.8' -> ['4.0.2', '3.6.4', '3.5.8']; a trailing '...' is
    dropped; 'fixed in 3.5.7-r0' -> ['3.5.7-r0']; 'Fixed in' matches in any case. A status
    with no 'fixed in' (a bare 'open', 'will not fix', or empty) returns [], marking no fix
    available."""
    if not fix_status:
        return []
    parts = FIXED_IN.split(fix_status, 1)
    if len(parts) < 2:
        return []
    out = []
    for token in parts[1].split(","):
        # rstrip(".") already reduces a trailing-ellipsis token ("..", "...") to "",
        # which the truthiness check drops — so no explicit ellipsis guard is needed.
        token = token.strip().rstrip(".").strip()
        if token:
            out.append(token)
    return out


def place(kind, eco, row, fixed, trees, controlled_packages, dockerfile_read):
    """Run the cascade for one finding of origin `kind` (and `eco`, from origin), returning
    (bucket, reason, confirmed, matched_package). `confirmed` is False when the cascade
    needed an input this run did not have, or the inputs it had could not settle the call,
    so a candidate is reported as needing that input, never asserted (a missing input
    flags, never asserts)."""
    path = row.get("Package Path", "")
    name = row.get("Packages", "")
    version = row.get("Package Version", "")
    fix_status = row.get("Fix Status", "")

    # Tier 1 — base-image layer? A by default; B only on a positive team-control signal.
    if kind in BASE_ORIGINS:
        if team_controlled(name, controlled_packages):
            return "B", "base package the repository's own Dockerfile controls", True, None
        if kind == "global-module":
            return ("A", "global node module outside npm's own bundle — confirm the app Dockerfile has no "
                    "`npm install -g` for it before reassigning", False, None)
        if kind == "runtime":
            return ("A", "no PURL and no application-dependency path — read as a base runtime from the path "
                    "alone; confirm it is not an application component before reassigning", False, None)
        if dockerfile_read:
            return "A", "base-image package the team cannot control (absent from the Dockerfile's own package ops)", True, None
        return "A", "base-image package — confirm against the app Dockerfile before reassigning (no Dockerfile read this run)", False, None

    # Tier 2/3 — the finding is an application dependency; it needs its ecosystem's trees.
    if kind == "app-dep-no-purl":
        return None, "application-dependency path with no PURL — ecosystem and package unresolvable; identify it by hand", False, None
    if kind == "unknown-ecosystem":
        return None, f"unknown ecosystem {eco} — not in the resolver interface", False, None
    if eco not in BUILT_RESOLVERS:
        return None, f"no resolver built for ecosystem {eco} — add one when a real {eco} image is triaged", False, None
    eco_trees = trees.get(eco)
    if not eco_trees or not eco_trees["prod"] or not eco_trees["dev"]:
        # No tree loaded, or either tree empty — a failed `npm ls` reduces to {}, which must
        # not read as "absent from both trees" (C, not affected), and an empty production
        # tree beside a good development tree would put every production dependency in D.
        return "?", "dependency finding needs both resolved trees to confirm (none loaded, or a tree empty)", False, None

    prod = eco_trees["prod"]
    dev = eco_trees["dev"]
    # Match any component of a multi-name cell exactly against each tree (exact name match).
    names = package_names(name)
    prod_name = next((n for n in names if n in prod), None)
    dev_name = next((n for n in names if n in dev), None)
    # A path with more than one node_modules segment is a nested copy. The trees are a
    # flattened {name: version} map, so the version they carry for this name is some other
    # copy's (the hoisted one); the nested copy is judged by its own row.
    nested = path.count(NODE_MODULES) > 1

    if prod_name is None and dev_name is None:
        if nested:
            return "C", "nested copy absent from both flattened trees — confirm the tree reduction kept nested installs", False, None
        return "C", "absent from both the production and development trees", True, None
    if prod_name is None:
        return "D", "in the development tree, absent from production (installed anyway)", True, dev_name

    installed = version if nested else prod[prod_name]
    if not fixed:
        return ("F", f"production dependency with no published fix (Fix Status {fix_status.strip() or 'empty'!r}) — "
                "no upgrade exists yet; confirm the disposition by hand", False, prod_name)
    at_or_above, why = version_at_or_above(installed, fixed)
    if why is not None:
        return "F", f"production dependency with {why} (installed {installed}) — confirm against the fix by hand", False, prod_name
    if at_or_above:
        if installed.strip() == version.strip():
            # The scanner already saw this exact version and still reported it: a rescan
            # reports it again, so "the scan predates the lockfile" cannot be the reason.
            return ("E", f"installed {installed} equals the scanned version and is at or above the listed fix — "
                    "a rescan reports it again; confirm the advisory's affected range by hand", False, prod_name)
        return "E", f"production dependency at or above the fix (installed {installed})", True, prod_name
    return "F", "production dependency below the fix, upgrade available", True, prod_name


def classify(row, trees, controlled_packages, dockerfile_read):
    """The finding record for one export row: its origin computed once, the cascade run on
    it, and every output field filled. A's `sub_tag` is the base origin kind — a reporting
    breakdown for the platform handoff (src/triage-cvits/references/buckets.md), not a
    bucket — and null elsewhere."""
    purl = row.get("PURL", "")
    path = row.get("Package Path", "")
    fixed = parse_fixed_versions(row.get("Fix Status", ""))
    kind, eco = origin(path, purl)
    bucket, reason, confirmed, matched = place(kind, eco, row, fixed, trees, controlled_packages, dockerfile_read)
    return {
        "cve": row.get("CVE ID", ""),
        "package": row.get("Packages", ""),
        "matched_package": matched,
        "version": row.get("Package Version", ""),
        "ecosystem": purl.split("/", 1)[0].replace("pkg:", "") if purl else "none",
        "bucket": bucket,
        "bucket_reason": reason,
        "confirmed": confirmed,
        "fixed_versions": fixed,
        "path": path,
        "sub_tag": kind if bucket == "A" else None,
    }


def build_rollup(findings):
    total = len(findings)
    rollup = {}
    for b in BUCKETS:
        members = [f for f in findings if f["bucket"] == b]
        entry = {
            "count": len(members),
            "pct": round(100 * len(members) / total, 1) if total else 0.0,
            "confirmed": sum(1 for f in members if f["confirmed"]),
            "unconfirmed": sum(1 for f in members if not f["confirmed"]),
        }
        if b == "A":
            sub = {}
            for f in members:
                sub[f["sub_tag"]] = sub.get(f["sub_tag"], 0) + 1
            entry["sub_tags"] = sub
        rollup[b] = entry
    rollup["needs_checkout"] = {"count": sum(1 for f in findings if f["bucket"] == "?")}
    rollup["unresolved"] = {"count": sum(1 for f in findings if f["bucket"] is None)}
    rollup["unconfirmed_total"] = {"count": sum(1 for f in findings if not f["confirmed"])}
    return rollup


def main(argv):
    args = argv[1:]
    if args in (["--help"], ["-h"]):
        print(USAGE)
        return 0
    if len(args) != 2 or any(a.startswith("-") for a in args):
        die(f"expected 2 arguments, got {args!r}\n{USAGE}", EXIT_USAGE)
    export_csv, resolved_tree_json = args
    for p in args:
        if not os.path.isfile(p) or not os.access(p, os.R_OK):
            die(f"not a readable file: {p}", EXIT_USAGE)

    trees, controlled, dockerfile_read = load_resolved_tree_json(resolved_tree_json)
    rows = read_export_rows(export_csv)

    findings = [classify(r, trees, controlled, dockerfile_read) for r in rows]
    # A null bucket is an unknown prefix, a named-but-unbuilt ecosystem, or no PURL on an
    # app path: the run could not disposition it, so its label is reported before the next
    # run (unbuilt ecosystem flagged).
    unresolved = {f["ecosystem"] for f in findings if f["bucket"] is None}

    print(
        json.dumps(
            {
                "findings": findings,
                "rollup": build_rollup(findings),
                "unresolved_ecosystems": sorted(unresolved),
                "disposition": DISPOSITION,
                "total": len(findings),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except Exception as e:  # SystemExit is not an Exception: die()'s codes pass through
        print(f"classify-cvit-findings.py: crashed: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(EXIT_CRASH)
