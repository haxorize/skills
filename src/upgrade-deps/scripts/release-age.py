#!/usr/bin/env python3
# Conventions for this tree: scripts/README.md
"""Release-age floor and registry lookups for an npm or pnpm repo (upgrade-deps steps 1-2).

  release-age.py floor  [--repo DIR] PKG...
  release-age.py lookup [--floor DAYS] [--now ISO] PKG FROM TO

floor prints one tab-separated row per package under a header:
  package  manager  enforced_days  enforced_source  declared_days  default_days  floor_days  governed_by
The enforced operand is the package manager's own floor, in days:
  - pnpm 11+: `minimumReleaseAge` in pnpm-workspace.yaml (minutes), 1440 when unset;
    `.npmrc` is not read (auth and registry only from 11.0.0).
  - pnpm 10 and older: pnpm-workspace.yaml, else `minimum-release-age` in `.npmrc`
    (minutes); none when both are unset.
  - npm: `min-release-age` in the project `.npmrc` (days); none when unset.
A package matched by the manager's exclude list (`minimumReleaseAgeExclude`,
`minimum-release-age-exclude`, `min-release-age-exclude`; globs as minimatch reads them,
`*` within one path segment so `*` never matches `@scope/x`, `**` across `/`) has no
enforced operand. The declared operand is `Minimum release age:` under `## Registry`
in the repo's CLAUDE.md (days). floor_days is the maximum of the enforced value, the
declared value and the 7-day default; governed_by names which operand won (`default`
on a tie with it, since nothing raised the floor). An absent operand prints `none`.
The pnpm major comes from package.json's `packageManager`, else `pnpm --version`; when
neither answers, the pnpm 11 default cannot be decided and the row says `unknown`.

lookup reads the npm registry through `npm view` (pnpm repos share the registry) and
prints key=value lines: each version's publisher (`_npmUser`) and attestation, the
target's publish date and age in days, whether the publisher changed, and, given
--floor, whether the target clears it and the newest release above FROM, at or below
TO, that does (`retarget=none` when none does). `npm view` printing nothing with exit
0 is an absent field; a non-zero exit is a failed lookup and prints `lookup-failed`,
never `absent`. Prereleases are never a retarget.

Exit codes (scripts/README.md taxonomy): 0 every value read; 1 a config value that
does not parse (named on stderr); 2 a value could not be determined (a failed lookup,
an unknown pnpm major); 3 usage error; 4 `npm` missing for lookup, or a crash.
"""
import datetime
import json
import os
import re
import subprocess
import sys

DEFAULT_DAYS = 7
PNPM_DEFAULT_MINUTES = 1440
USAGE = "usage: release-age.py floor [--repo DIR] PKG... | lookup [--floor DAYS] [--now ISO] PKG FROM TO"


class ConfigError(Exception):
    pass


def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return None


def unquote(v):
    v = v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "'\"":
        return v[1:-1]
    return v


def number(value, where):
    try:
        n = float(value)
    except ValueError:
        raise ConfigError(f"config value is not a number: {where} = {value!r}")
    if n < 0:
        raise ConfigError(f"config value is negative: {where} = {value!r}")
    return n


def yaml_floor(text):
    """minimumReleaseAge and minimumReleaseAgeExclude from pnpm-workspace.yaml."""
    minutes, excludes, in_list = None, [], False
    for raw in text.splitlines():
        line = re.sub(r"\s+#.*$", "", raw).rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if in_list:
            m = re.match(r"^\s*-\s+(.+)$", line)  # a block item, indented or not; a key ends the list
            if m:
                excludes.append(unquote(m.group(1)))
                continue
            in_list = False
        m = re.match(r"^minimumReleaseAge:\s*(.*)$", line)
        if m:
            minutes = number(unquote(m.group(1)), "pnpm-workspace.yaml minimumReleaseAge")
            continue
        m = re.match(r"^minimumReleaseAgeExclude:\s*(.*)$", line)
        if m:
            rest = m.group(1).strip()
            if rest.startswith("["):
                excludes += [unquote(x) for x in rest.strip("[]").split(",") if x.strip()]
            else:
                in_list = True
    return minutes, excludes


def npmrc_floor(text, key):
    """KEY=value and KEY-exclude (comma list, or repeated KEY-exclude[]=x) from .npmrc."""
    value, excludes = None, []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line[0] in "#;" or "=" not in line:
            continue
        k, v = (s.strip() for s in line.split("=", 1))
        if k == key:
            value = number(unquote(v), f".npmrc {key}")
        elif k in (f"{key}-exclude", f"{key}-exclude[]"):
            excludes += [unquote(x) for x in v.split(",") if x.strip()]
    return value, excludes


def declared_days(repo):
    text = read(os.path.join(repo, "CLAUDE.md"))
    if text is None:
        return None
    m = re.search(r"^## Registry\s*$(.*?)(?=^#{1,2} |\Z)", text, re.M | re.S)
    if not m:
        return None
    line = re.search(r"^\s*-?\s*Minimum release age:\s*(.+)$", m.group(1), re.M)
    if not line:
        return None
    lead = re.match(r"^`?(\d+(?:\.\d+)?)`?\s*(days?)?\s*\.?$", line.group(1).strip())
    if not lead:
        raise ConfigError(f"CLAUDE.md ## Registry Minimum release age: {line.group(1).strip()!r} is not a number of days")
    return float(lead.group(1))


def manager(repo):
    pkg = read(os.path.join(repo, "package.json"))
    pm = ""
    if pkg is not None:
        try:
            pm = json.loads(pkg).get("packageManager", "") or ""
        except (ValueError, AttributeError):
            raise ConfigError("package.json does not parse as a JSON object")
    if pm.startswith("pnpm@"):
        return "pnpm", pm[5:]
    if pm.startswith("npm@"):
        return "npm", None
    if any(os.path.exists(os.path.join(repo, f)) for f in ("pnpm-lock.yaml", "pnpm-workspace.yaml")):
        return "pnpm", None
    if pkg is not None or os.path.exists(os.path.join(repo, "package-lock.json")):
        return "npm", None
    return None, None


def pnpm_major(version, repo):
    if version is None:
        try:
            out = subprocess.run(["pnpm", "--version"], cwd=repo, capture_output=True, text=True, timeout=30)
            version = out.stdout.strip() if out.returncode == 0 else None
        except (OSError, subprocess.TimeoutExpired):
            version = None
    m = re.match(r"^(\d+)\.", version or "")
    return int(m.group(1)) if m else None


def glob_match(name, pattern):
    """minimatch's reading of an exclude glob: `**` crosses `/`, `*` and `?` stay in one segment."""
    rx = re.sub(r"\\\*\\\*|\\\*|\\\?",
                lambda m: {"\\*\\*": ".*", "\\*": "[^/]*", "\\?": "[^/]"}[m.group(0)],
                re.escape(pattern))
    return re.fullmatch(rx, name) is not None


def fmt(n):
    if n is None:
        return "none"
    return ("%.4f" % n).rstrip("0").rstrip(".")


def cmd_floor(args):
    repo, pkgs = ".", []
    it = iter(args)
    for a in it:
        if a == "--repo":
            repo = next(it, None)
            if repo is None:
                return usage("--repo needs a directory")
        elif a.startswith("-"):
            return usage(f"unknown option {a}")
        else:
            pkgs.append(a)
    if not pkgs:
        return usage("floor needs at least one package")
    if not os.path.isdir(repo):
        return usage(f"--repo {repo} is not a directory")
    mgr, pm_version = manager(repo)
    if mgr is None:
        return usage(f"not an npm or pnpm repo (no package.json, package-lock.json or pnpm lockfile): {repo}")
    declared = declared_days(repo)
    status = 0
    enforced, source, excludes = None, "none", []
    if mgr == "pnpm":
        major = pnpm_major(pm_version, repo)
        ws = read(os.path.join(repo, "pnpm-workspace.yaml"))
        minutes, excludes = yaml_floor(ws) if ws is not None else (None, [])
        if minutes is not None:
            source = "pnpm-workspace.yaml minimumReleaseAge"
        elif major is not None and major < 11:
            rc = read(os.path.join(repo, ".npmrc"))
            if rc is not None:
                minutes, rc_ex = npmrc_floor(rc, "minimum-release-age")
                excludes += rc_ex
                if minutes is not None:
                    source = ".npmrc minimum-release-age"
        elif major is not None:
            minutes, source = PNPM_DEFAULT_MINUTES, f"pnpm {major} default"
        else:
            source = "unknown"
            status = 2
        enforced = minutes / 1440 if minutes is not None else None
    else:
        rc = read(os.path.join(repo, ".npmrc"))
        if rc is not None:
            enforced, excludes = npmrc_floor(rc, "min-release-age")
            if enforced is not None:
                source = ".npmrc min-release-age"
    print("\t".join(["package", "manager", "enforced_days", "enforced_source", "declared_days",
                     "default_days", "floor_days", "governed_by"]))
    for pkg in pkgs:
        e, s = enforced, source
        if any(glob_match(pkg, pat) for pat in excludes):
            e, s = None, "excluded"
        if s == "unknown":
            print("\t".join([pkg, mgr, "unknown", "unknown", fmt(declared), str(DEFAULT_DAYS), "unknown", "unknown"]))
            continue
        operands = [("default", float(DEFAULT_DAYS)), ("declared", declared), ("enforced", e)]
        floor = max(v for _, v in operands if v is not None)
        winner = next(name for name, v in operands if v is not None and v == floor)
        print("\t".join([pkg, mgr, fmt(e), s, fmt(declared), str(DEFAULT_DAYS), fmt(floor), winner]))
    return status


def npm_view(spec, field):
    """(value, ok): value is parsed JSON or None when npm printed nothing; ok False on a non-zero exit."""
    try:
        out = subprocess.run(["npm", "view", spec, field, "--json"], capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return None, False
    if out.returncode != 0:
        return None, False
    text = out.stdout.strip()
    if not text:
        return None, True
    try:
        return json.loads(text), True
    except ValueError:
        return None, False


def publisher(value):
    if isinstance(value, dict):
        return value.get("name") or "unknown"
    if isinstance(value, str) and value:
        return value.split(" <")[0]
    return None


def semver(v):
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)$", v)
    return tuple(int(x) for x in m.groups()) if m else None


def parse_time(s):
    """An ISO time; one with no offset (`--now 2026-10-18`) is read as UTC."""
    t = datetime.datetime.fromisoformat(s.replace("Z", "+00:00"))
    return t if t.tzinfo is not None else t.replace(tzinfo=datetime.timezone.utc)


def cmd_lookup(args):
    floor, now, rest = None, None, []
    it = iter(args)
    for a in it:
        if a in ("--floor", "--now"):
            v = next(it, None)
            if v is None:
                return usage(f"option needs a value: {a}")
            try:
                if a == "--floor":
                    floor = float(v)
                else:
                    now = parse_time(v)
            except ValueError:
                return usage(f"option value does not parse: {a} {v!r}")
        elif a.startswith("-"):
            return usage(f"unknown option {a}")
        else:
            rest.append(a)
    if len(rest) != 3:
        return usage("lookup needs PKG FROM TO")
    pkg, frm, to = rest
    if semver(frm) is None or semver(to) is None:
        return usage("FROM and TO must be plain x.y.z versions")
    now = now or datetime.datetime.now(datetime.timezone.utc)
    status = 0
    names = {}
    for label, v in (("from", frm), ("to", to)):
        user, ok = npm_view(f"{pkg}@{v}", "_npmUser")
        names[label] = publisher(user) if ok else None
        print(f"{label}_publisher={names[label] or ('lookup-failed' if not ok else 'absent')}")
        if not ok:
            status = 2
        att, ok = npm_view(f"{pkg}@{v}", "dist.attestations")
        print(f"{label}_attestation={'lookup-failed' if not ok else ('present' if att else 'absent')}")
        if not ok:
            status = 2
    if names["from"] and names["to"]:
        print(f"publisher={'same' if names['from'] == names['to'] else 'changed'}")
    else:
        print("publisher=unknown")
    times, ok = npm_view(pkg, "time")
    if not ok or not isinstance(times, dict):
        print("to_published=lookup-failed")
        return 2
    if to not in times:
        print("to_published=absent")
        return 2
    def age_days(published):
        return (now - parse_time(published)).total_seconds() / 86400

    age = age_days(times[to])
    print(f"to_published={times[to]}")
    print(f"to_age_days={fmt(round(age, 2))}")
    if floor is not None:
        print(f"floor_days={fmt(floor)}")
        print(f"clears_floor={'yes' if age >= floor else 'no'}")
        lo, hi = semver(frm), semver(to)
        cleared = [v for v, t in times.items()
                   if semver(v) and lo < semver(v) <= hi and age_days(t) >= floor]
        print(f"retarget={max(cleared, key=semver) if cleared else 'none'}")
    return status


def usage(msg):
    print(f"release-age.py: {msg}\n{USAGE}", file=sys.stderr)
    return 3


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0 if argv else 3
    sub, args = argv[0], argv[1:]
    try:
        if sub == "floor":
            return cmd_floor(args)
        if sub == "lookup":
            try:
                subprocess.run(["npm", "--version"], capture_output=True, timeout=30)
            except OSError:
                print("release-age.py: npm is not on PATH; nothing looked up", file=sys.stderr)
                return 4
            return cmd_lookup(args)
        return usage(f"unknown subcommand {sub}")
    except ConfigError as e:
        print(f"release-age.py: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except SystemExit:
        raise
    except Exception as e:  # a crash is a check that never ran
        print(f"release-age.py: crashed: {e!r}", file=sys.stderr)
        sys.exit(4)
