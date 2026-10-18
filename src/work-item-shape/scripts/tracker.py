#!/usr/bin/env python3
# Conventions for this tree: scripts/README.md
"""tracker.py — the fixed half of every work-item read and write, for GitHub
(`gh`) and Azure DevOps (`az boards`).

One copy, owned by work-item-shape; every skill that resolves or touches a
tracker runs it from that skill's installed directory (one owner, one copy,
as for shared references). Judgment stays in the calling skill: whether a draft was
approved, what the dedupe search's near match means, which parent to pick.
This script owns what has one right answer: reading the CLAUDE.md block, the
title prefix, the ADO tag set, Markdown to HTML, the one `--fields` list, the
rich-text read-back, sub-issue and relation links.

Usage: tracker.py <command> [options]   (every command takes --root DIR, the
       repo whose CLAUDE.md holds the `## Issue tracker` block; default: the
       git top level of the working directory, else the working directory;
       `<command> --help` prints this text)

  resolve                    print mode=, tracker= and one key=value per block
                             line (key lowercased, spaces and hyphens as _)
  tags --type T --title T [--debt]
                             print the ADO System.Tags value ("" for none)
  html IN.md OUT.html        convert with pandoc, else python3's markdown
  create --type T --title T [--body FILE] [--field REF=VALUE | REF=@FILE]...
         [--label L]... [--parent ID] [--debt] [--no-prefix] [--workdir DIR]
         [--dry-run]         one create, then its read-back and parent link;
                             prints id= (GitHub: number) and url= (empty when
                             unknown) as soon as the write lands; on ADO also
                             tags-not-applied= and apply-tags= (both empty
                             when the tags went on); then linked= or
                             incomplete= lines
  update ID [--title T] [--type T] [--no-prefix] [--body FILE] [--field ...]...
         [--workdir DIR] [--dry-run]
                             prints id=, then incomplete= lines on a failed
                             read-back; --type picks the prefix for --title
  link --parent ID --child ID        GitHub sub-issue / ADO Parent relation
  block --blocked ID --blocker ID    GitHub blocked_by / ADO Predecessor
  search --terms "A B" [--state open|all]
                             one id<TAB>title<TAB>state line per item matching
                             any term (tabs and newlines in a title become spaces)
  show ID                    the item as the tracker's JSON (ADO: relations)
  comment ID --body FILE     (--body-file FILE is the same option)

Every ID is digits only; --field takes GitHub nowhere (create and update
alike exit 3); a --label starting with "-" exits 3.

The block: from the `## Issue tracker` heading to the next heading of any
level. A field is a line `Key: value` (a leading `- ` or `* ` allowed) whose
Key is one README.md § Conventions documents for the block (KNOWN_KEYS
below); any other line is prose, such as the routing-policy line, and is not
a field. `resolve` names each ignored `Key:`-shaped line on stderr.

Rules it carries, each once:
  - The title prefix is applied here, after the tags are derived from the
    drafted title: a Feature takes `Feature title prefix:`, else `Title
    prefix:`; every other type takes `Title prefix:` only. A title that
    already starts with its prefix is left alone, so create and update are
    idempotent. --no-prefix skips it. update --title needs --type only when
    the block's Feature title prefix differs from its Title prefix.
  - Tags (ADO): the drafted title's leading [bracket] contents, unioned with
    `Additional tags:`, minus `Never tag:`, then `debt` with --debt; joined
    with "; " inside the one --fields list.
  - A body or a REF=@FILE ending .md is converted to HTML in the per-item
    directory (<workdir>/<type>-<slug>/<stem>.html; with no --workdir, a
    fresh private mkdtemp directory) and passed by absolute path; an empty
    file stops before any call.
  - After a create or update carrying rich text, the item is read back; a
    field that is empty or still begins with @ is a failed publish: id= is
    already printed, `incomplete=readback:<REF>` follows, exit 5. Fix the
    path and patch with `update`, never re-run the create.
  - A failed create is never retried, with one exception: a create the org
    refuses for a tag is retried once without System.Tags, and the tags and
    the command that applies them are printed. Any other failed create can
    arrive after the write committed, so search the tracker before trying
    again.
  - GitHub labels: `Default labels:`, each --label, and `debt` with --debt;
    a missing label is created before the first issue.
  - GitHub `Repo: OWNER/NAME` in the block sets GH_REPO for every gh call,
    so a run from outside the checkout (a --root scratch block) files there.
    Only OWNER/NAME is accepted (no host); ADO `Organization:` is a bare org
    name, https://dev.azure.com/<org> or https://<org>.visualstudio.com.
  - A block whose `Tracker:` names two trackers, or that has two `Tracker:`
    lines, is asked about, never guessed: exit 1.
  - --dry-run makes no tracker call and prints the commands, for a write
    that is blocked and goes to the manual-commands block.

Exit: 0 done; 1 nothing is known to have landed — a call failed, or a block
line is missing, malformed or ambiguous (ADO without Project:, a bad Repo:
or Organization:, two trackers) — after a failed create, search before any
retry; 2 no `## Issue tracker` block with a Tracker: line (resolve prints
mode=bootstrap or mode=no-repo; every other command says to run resolve);
3 usage; 4 never ran (no gh or az on PATH, no Markdown converter); 5 written
but incomplete: id= and url= are printed, then one incomplete=readback:<REF>
or incomplete=link:<parent> line per gap — never re-run the create; patch
with `update` or re-run `link`.
"""
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

USAGE = __doc__
EXIT_INCOMPLETE = 5

# The block's keys, as README.md § Conventions and onboard-repo document them,
# lowercased with spaces and hyphens as _. A line keyed otherwise is prose.
KNOWN_KEYS = {
    "tracker", "repo", "visibility", "organization", "project", "area_path", "iteration",
    "pi_label", "team", "title_prefix", "feature_title_prefix", "hierarchy",
    "default_labels", "in_progress_signal", "default_state", "additional_tags",
    "never_tag", "work_item_url",
}
REPO_FORM = re.compile(r"^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$")
ORG_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9-]*$")
ORG_URL = re.compile(r"^https://(?:dev\.azure\.com/[A-Za-z0-9][A-Za-z0-9_.-]*"
                     r"|[A-Za-z0-9][A-Za-z0-9-]*\.visualstudio\.com)/?$")
FIELD_REF = re.compile(r"^[A-Za-z][A-Za-z0-9_.]*$")


def die(code, msg):
    print("tracker.py: " + msg, file=sys.stderr)
    sys.exit(code)


def usage(msg):
    die(3, msg + "\n" + USAGE)


def numeric_id(value, what):
    """An ID reaches a URL path or a CLI argument, so it is digits or nothing."""
    if not re.match(r"^\d+$", value or ""):
        usage("not a numeric work-item ID for %s: %r" % (what, value))
    return value


# --- the CLAUDE.md block ---------------------------------------------------

KEY_LINE = re.compile(r"^\s*(?:[-*]\s+)?([A-Za-z][A-Za-z0-9 -]{0,40}?):\s*(.*?)\s*$")


def find_root(root):
    if root:
        return root
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.strip()
    except OSError:
        pass
    return os.getcwd()


def in_git(root):
    try:
        return subprocess.run(["git", "-C", root, "rev-parse", "--git-dir"],
                              capture_output=True).returncode == 0
    except OSError:
        return False


def read_block(root):
    """(mode, fields, trackers, ignored). fields keys are lowercased with spaces
    and hyphens as _; trackers is every Tracker: value; ignored, each Key:-shaped
    line that is not a block key."""
    path = os.path.join(root, "CLAUDE.md")
    if not os.path.isfile(path):
        return ("bootstrap" if in_git(root) else "no-repo"), {}, [], []
    fields, trackers, ignored, inside = {}, [], [], False
    with open(path, encoding="utf-8") as fh:
        for n, line in enumerate(fh, 1):
            if re.match(r"^##\s+Issue tracker\s*$", line):
                inside = True
                continue
            if inside and re.match(r"^#{1,6}\s", line):
                break
            if inside:
                m = KEY_LINE.match(line)
                if not m:
                    continue
                key = re.sub(r"[ -]+", "_", m.group(1).strip().lower())
                if key not in KNOWN_KEYS:
                    ignored.append("line %d `%s:`" % (n, m.group(1).strip()))
                    continue
                if key == "tracker":
                    trackers.append(m.group(2))
                fields.setdefault(key, m.group(2))
    if not fields.get("tracker"):
        return ("bootstrap" if in_git(root) else "no-repo"), {}, [], ignored
    return "declared", fields, trackers, ignored


def tracker_kind(fields):
    t = fields.get("tracker", "").lower()
    if "github" in t:
        return "github"
    if "azure" in t or re.search(r"\bado\b", t):
        return "ado"
    return "other"


def check_block(fields, trackers, allow_other):
    """The kind, after every block-level check; exit 1 naming the line."""
    said = " ".join(trackers).lower()
    names_both = "github" in said and ("azure" in said or re.search(r"\bado\b", said))
    if len(trackers) > 1 or names_both:
        die(1, "the `## Issue tracker` block names two trackers (%s); ask the user which one "
               "holds this item, never guess" % "; ".join("Tracker: " + t for t in trackers))
    kind = tracker_kind(fields)
    if kind == "other" and not allow_other:
        die(1, "unsupported tracker in the `Tracker:` line (%s): this script drives only GitHub "
               "and Azure DevOps" % fields["tracker"])
    if kind == "ado" and not fields.get("project"):
        die(1, "add a `Project:` line to the `## Issue tracker` block in CLAUDE.md; "
               "Azure DevOps needs it and this script never guesses one")
    if kind == "github" and fields.get("repo") and not REPO_FORM.match(fields["repo"]):
        die(1, "the `Repo:` line must be OWNER/NAME, nothing more (no host): Repo: %s" % fields["repo"])
    if kind == "ado" and fields.get("organization"):
        org = fields["organization"].strip()
        if not (ORG_NAME.match(org) or ORG_URL.match(org)):
            die(1, "the `Organization:` line must be an org name, https://dev.azure.com/<org> or "
                   "https://<org>.visualstudio.com: Organization: %s" % org)
    return kind


def declared(root):
    mode, fields, trackers, _ = read_block(root)
    if mode != "declared":
        die(2, "no `## Issue tracker` block with a `Tracker:` line in CLAUDE.md (mode=%s); "
               "run `tracker.py resolve` and settle the tracker with the user first" % mode)
    kind = check_block(fields, trackers, allow_other=False)
    if kind == "github" and fields.get("repo"):
        os.environ["GH_REPO"] = fields["repo"]  # gh's own override: a run outside the repo's checkout
    return kind, fields


def split_list(value):
    return [p.strip() for p in re.split(r"[;,]", value or "") if p.strip()]


def bare(entry):
    entry = entry.strip()
    if entry.startswith("[") and entry.endswith("]"):
        entry = entry[1:-1].strip()
    return entry


def derive_tags(title, fields, debt):
    tags = []
    m = re.match(r"^\s*\[([^\]]*)\]", title)
    if m and m.group(1).strip():
        tags.append(m.group(1).strip())
    tags += [bare(t) for t in split_list(fields.get("additional_tags"))]
    never = {bare(t) for t in split_list(fields.get("never_tag"))}
    tags = [t for t in tags if t and t not in never]
    if debt:
        tags.append("debt")
    seen, out = set(), []
    for t in tags:
        if t not in seen:
            seen.add(t)
            out.append(t)
    return "; ".join(out)


def title_prefix(item_type, fields):
    if (item_type or "").lower() == "feature":
        return (fields.get("feature_title_prefix") or fields.get("title_prefix", "")).strip()
    return fields.get("title_prefix", "").strip()


def prefixed(item_type, title, fields, no_prefix):
    if no_prefix:
        return title
    prefix = title_prefix(item_type, fields)
    if not prefix or title.startswith(prefix):
        return title
    return prefix + " " + title


# --- running the CLIs --------------------------------------------------------

DRY = False


def need(tool):
    if not DRY and shutil.which(tool) is None:
        die(4, "not on PATH, nothing ran: %s" % tool)


def run(cmd):
    """(rc, stdout, stderr); under --dry-run prints the command and returns success."""
    if DRY:
        lead = "GH_REPO=%s " % shlex.quote(os.environ["GH_REPO"]) if cmd[0] == "gh" and os.environ.get("GH_REPO") else ""
        print(lead + " ".join(shlex.quote(c) for c in cmd))
        return 0, "", ""
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def ado_org(fields):
    """The --org pair, for the az calls that take no --project."""
    org = fields.get("organization", "").strip()
    if not org:
        return []
    return ["--org", org if "://" in org else "https://dev.azure.com/" + org]


def ado_scope(fields):
    """--project and --org, for the az calls that take both."""
    return ["--project", fields["project"]] + ado_org(fields)


def ado_url(fields, item_id):
    tmpl = fields.get("work_item_url", "")
    return tmpl.replace("{id}", str(item_id)) if "{id}" in tmpl else ""


def to_html(src, dst):
    if shutil.which("pandoc"):
        p = subprocess.run(["pandoc", "-f", "markdown", "-t", "html", src, "-o", dst],
                           capture_output=True, text=True)
        if p.returncode != 0:
            die(1, "pandoc could not convert %s: %s" % (src, p.stderr.strip()))
        return
    try:
        import markdown  # noqa: PLC0415
    except ImportError:
        die(4, "neither pandoc nor python3's markdown module is installed; install one — "
               "raw Markdown never goes into an HTML field")
    with open(src, encoding="utf-8") as fh, open(dst, "w", encoding="utf-8") as out:
        out.write(markdown.markdown(fh.read()))


def slug(text):
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return s[:48] or "item"


def nonempty(path):
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        die(1, "missing or empty file, nothing was sent: %s" % path)
    return os.path.abspath(path)


def rich_file(path, itemdir):
    """Absolute path of the HTML to send; converts a .md into itemdir."""
    path = nonempty(path)
    if path.endswith(".md"):
        os.makedirs(itemdir, exist_ok=True)
        dst = os.path.join(itemdir, os.path.basename(path)[:-3] + ".html")
        to_html(path, dst)
        return nonempty(dst)
    return path


def workdir_of(o):
    """--workdir, else a fresh private directory: never a guessable shared path."""
    return o["workdir"] or tempfile.mkdtemp(prefix="tracker-")


# --- commands ---------------------------------------------------------------

def parse(argv, spec):
    """spec: name -> 'flag' | 'one' | 'many'. Positionals collected in order."""
    opts = {k: ([] if v == "many" else (False if v == "flag" else None)) for k, v in spec.items()}
    pos, i = [], 0
    while i < len(argv):
        a = argv[i]
        if a in ("-h", "--help"):
            print(USAGE)
            sys.exit(0)
        if a.startswith("--"):
            name = a[2:]
            if name not in spec:
                usage("unknown option %s" % a)
            if spec[name] == "flag":
                opts[name] = True
            else:
                if i + 1 >= len(argv):
                    usage("option needs a value: %s" % a)
                i += 1
                if spec[name] == "many":
                    opts[name].append(argv[i])
                else:
                    opts[name] = argv[i]
        else:
            pos.append(a)
        i += 1
    return opts, pos


def cmd_resolve(o):
    root = find_root(o["root"])
    mode, fields, trackers, ignored = read_block(root)
    for line in ignored:
        print("tracker.py: not a block key, read as prose: CLAUDE.md %s" % line, file=sys.stderr)
    if mode != "declared":
        print("mode=" + mode)
        sys.exit(2)
    check_block(fields, trackers, allow_other=True)
    print("mode=" + mode)
    print("tracker=" + tracker_kind(fields))
    for k, v in fields.items():
        if k != "tracker":
            print("%s=%s" % (k, v))


def cmd_tags(o):
    if not o["title"]:
        usage("tags needs --title")
    _, fields = declared(find_root(o["root"]))
    print(derive_tags(o["title"], fields, o["debt"]))


def cmd_html(pos):
    if len(pos) != 2:
        usage("html takes IN.md OUT.html")
    to_html(nonempty(pos[0]), pos[1])


def split_field(spec):
    if "=" not in spec:
        usage("--field takes REF=VALUE or REF=@FILE, not %s" % spec)
    ref, value = spec.split("=", 1)
    ref = ref.strip()
    if not FIELD_REF.match(ref):
        usage("--field needs a reference name such as System.State, not %r" % ref)
    return ref, value


def ado_fields(o, itemdir):
    """(desc_path or None, ['REF=VALUE'...], [rich refs to read back])."""
    desc, out, rich = None, [], []
    if o["body"]:
        desc = rich_file(o["body"], itemdir)
        rich.append("System.Description")
    for spec in o["field"]:
        ref, value = split_field(spec)
        if value.startswith("@"):
            value = "@" + rich_file(value[1:], itemdir)
            rich.append(ref)
        out.append("%s=%s" % (ref, value))
    return desc, out, rich


def read_back(fields, item_id, rich):
    """The rich fields that did not land (all of them when the read itself failed)."""
    if DRY or not rich:
        return []
    rc, out, err = run(["az", "boards", "work-item", "show", "--id", str(item_id), "--output", "json"]
                       + ado_org(fields))
    if rc != 0:
        print("tracker.py: read-back failed for item %s (%s); open it and check %s"
              % (item_id, err.strip(), ", ".join(rich)), file=sys.stderr)
        return list(rich)
    got = json.loads(out).get("fields", {})
    bad = [r for r in rich if not str(got.get(r) or "").strip() or str(got.get(r)).lstrip().startswith("@")]
    if bad:
        print("tracker.py: item %s: %s came back empty or as a literal @path — a failed publish; fix the "
              "path (absolute) and patch with `tracker.py update %s --field ...`; never re-run the create"
              % (item_id, ", ".join(bad), item_id), file=sys.stderr)
    return bad


def incomplete(item_id, gaps):
    """The written-but-incomplete close: one incomplete= line per gap, exit 5."""
    for gap in gaps:
        print("incomplete=" + gap)
    die(EXIT_INCOMPLETE, "written but incomplete, item %s: never re-run the create; patch with "
                         "`update` or re-run `link`" % item_id)


def gh_labels(fields, o):
    for label in o["label"]:
        if label.startswith("-"):
            usage("a --label cannot start with '-': %s" % label)
    defaults = split_list(fields.get("default_labels"))
    for label in defaults:
        if label.startswith("-"):
            die(1, "a `Default labels:` entry cannot start with '-': %s" % label)
    labels = defaults + o["label"]
    if o.get("debt"):
        labels.append("debt")
    seen = []
    for label in labels:
        if label not in seen:
            seen.append(label)
    return seen


def gh_ensure_labels(labels):
    if not labels:
        return
    if DRY:
        for label in labels:
            run(["gh", "label", "create", label])  # no --force: an existing label fails, untouched
        return
    rc, out, err = run(["gh", "label", "list", "--limit", "1000", "--json", "name", "--jq", ".[].name"])
    if rc != 0:
        die(1, "gh label list failed: %s" % err.strip())
    have = set(out.split("\n"))
    for label in labels:
        if label not in have:
            rc, _, err = run(["gh", "label", "create", label])
            if rc != 0:
                die(1, "missing label could not be created: %s: %s" % (label, err.strip()))


def gh_db_id(number):
    """(database id, error) of issue NUMBER — what sub_issues and blocked_by take."""
    rc, out, err = run(["gh", "api", "repos/{owner}/{repo}/issues/%s" % number, "--jq", ".id"])
    if DRY:
        return "<id>", ""
    dbid = out.strip()
    if rc != 0 or not re.match(r"^\d+$", dbid):
        return "", err.strip() or "no database id came back for #%s" % number
    return dbid, ""


def cmd_create(o):
    if not o["type"] or not o["title"]:
        usage("create needs --type and --title")
    if o["parent"]:
        numeric_id(o["parent"], "--parent")
    kind, fields = declared(find_root(o["root"]))
    title = prefixed(o["type"], o["title"], fields, o["no-prefix"])
    if kind == "github":
        if o["field"]:
            usage("--field is Azure DevOps only")
        if not o["body"]:
            usage("create on GitHub needs --body FILE")
        labels = gh_labels(fields, o)
        need("gh")
        body = nonempty(o["body"])
        gh_ensure_labels(labels)
        cmd = ["gh", "issue", "create", "--title", title, "--body-file", body]
        for label in labels:
            cmd += ["--label", label]
        rc, out, err = run(cmd)
        if rc != 0:
            die(1, "gh issue create failed: %s\nDo not retry blind: the issue may exist. "
                   "Run `tracker.py search --terms ...` for the title first." % err.strip())
        url = out.strip().splitlines()[-1] if out.strip() else ""
        m = re.search(r"/issues/(\d+)\s*$", url)
        item_id = m.group(1) if m else ("<new>" if DRY else "")
        if not item_id:
            die(1, "gh issue create printed no issue URL: %r" % out)
        print("id=%s" % item_id)
        print("url=" + (url if m else ""))
        gaps = []
    else:
        need("az")
        itemdir = os.path.join(workdir_of(o), "%s-%s" % (slug(o["type"]), slug(o["title"])))
        desc, flist, rich = ado_fields(o, itemdir)
        if not any(f.startswith("System.State=") for f in flist) and fields.get("default_state"):
            flist.append("System.State=" + fields["default_state"])
        tags = derive_tags(o["title"], fields, o["debt"])
        base = ["az", "boards", "work-item", "create", "--type", o["type"], "--title", title]
        if desc:
            base += ["--description", "@" + desc]
        tail = []
        if fields.get("area_path"):
            tail += ["--area", fields["area_path"]]
        if fields.get("iteration"):
            tail += ["--iteration", fields["iteration"]]
        tail += ado_scope(fields) + ["--output", "json"]
        with_tags = flist + (["System.Tags=" + tags] if tags else [])
        rc, out, err = run(base + (["--fields"] + with_tags if with_tags else []) + tail)
        untagged = False
        if rc != 0 and tags and re.search(r"\btags?\b", err, re.I):
            rc, out, err = run(base + (["--fields"] + flist if flist else []) + tail)
            untagged = rc == 0
        if rc != 0:
            die(1, "az boards work-item create failed: %s\nDo not retry blind: the item may exist. "
                   "Run `tracker.py search --terms ...` for the title first." % err.strip())
        item_id = "<new>" if DRY else json.loads(out)["id"]
        print("id=%s" % item_id)
        print("url=" + ado_url(fields, item_id))
        print("tags-not-applied=" + (tags if untagged else ""))
        print("apply-tags=" + (" ".join(shlex.quote(c) for c in
              ["az", "boards", "work-item", "update", "--id", str(item_id),
               "--fields", "System.Tags=" + tags] + ado_org(fields)) if untagged else ""))
        gaps = ["readback:" + r for r in read_back(fields, item_id, rich)]
    if o["parent"] and not link(kind, fields, o["parent"], item_id):
        gaps.append("link:" + o["parent"])
    if gaps:
        incomplete(item_id, gaps)


def cmd_update(o, pos):
    if len(pos) != 1:
        usage("update takes one ID")
    item_id = numeric_id(pos[0], "update")
    kind, fields = declared(find_root(o["root"]))
    title = None
    if o["title"]:
        if (not o["type"] and not o["no-prefix"]
                and title_prefix("feature", fields) != title_prefix("", fields)):
            usage("update --title needs --type T (or --no-prefix): the block's Feature title prefix "
                  "differs from its Title prefix")
        title = prefixed(o["type"], o["title"], fields, o["no-prefix"])
    if kind == "github":
        if o["field"]:
            usage("--field is Azure DevOps only")
        need("gh")
        cmd = ["gh", "issue", "edit", item_id]
        if title:
            cmd += ["--title", title]
        if o["body"]:
            cmd += ["--body-file", nonempty(o["body"])]
        rc, _, err = run(cmd)
        if rc != 0:
            die(1, "gh issue edit failed for #%s: %s" % (item_id, err.strip()))
        print("id=%s" % item_id)
    else:
        need("az")
        itemdir = os.path.join(workdir_of(o), "update-%s" % slug(item_id))
        desc, flist, rich = ado_fields(o, itemdir)
        cmd = ["az", "boards", "work-item", "update", "--id", item_id]
        if title:
            cmd += ["--title", title]
        if desc:
            cmd += ["--description", "@" + desc]
        if flist:
            cmd += ["--fields"] + flist
        rc, _, err = run(cmd + ado_org(fields) + ["--output", "json"])
        if rc != 0:
            die(1, "az boards work-item update failed for %s: %s" % (item_id, err.strip()))
        print("id=%s" % item_id)
        gaps = ["readback:" + r for r in read_back(fields, item_id, rich)]
        if gaps:
            incomplete(item_id, gaps)


def link(kind, fields, parent, child):
    """True once linked (linked= printed); False with the reason on stderr."""
    if kind == "github":
        dbid, err = gh_db_id(child)
        link_rc = 1
        if dbid:
            link_rc, _, err = run(["gh", "api", "repos/{owner}/{repo}/issues/%s/sub_issues" % parent,
                                   "-F", "sub_issue_id=%s" % dbid])
    else:
        link_rc, _, err = run(["az", "boards", "work-item", "relation", "add", "--id", str(child),
                               "--relation-type", "Parent", "--target-id", str(parent)]
                              + ado_org(fields) + ["--output", "json"])
    if link_rc != 0:
        print("tracker.py: item %s is not linked under %s (%s); re-run `tracker.py link --parent %s "
              "--child %s` or link the two by hand — never retry the create"
              % (child, parent, err.strip(), parent, child), file=sys.stderr)
        return False
    print("linked=%s>%s" % (parent, child))
    return True


def cmd_link(o):
    if not o["parent"] or not o["child"]:
        usage("link needs --parent and --child")
    numeric_id(o["parent"], "--parent")
    numeric_id(o["child"], "--child")
    kind, fields = declared(find_root(o["root"]))
    need("gh" if kind == "github" else "az")
    if not link(kind, fields, o["parent"], o["child"]):
        sys.exit(1)


def cmd_block(o):
    if not o["blocked"] or not o["blocker"]:
        usage("block needs --blocked and --blocker")
    numeric_id(o["blocked"], "--blocked")
    numeric_id(o["blocker"], "--blocker")
    kind, fields = declared(find_root(o["root"]))
    if kind == "github":
        need("gh")
        dbid, err = gh_db_id(o["blocker"])
        rc = 1
        if dbid:
            rc, _, err = run(["gh", "api", "repos/{owner}/{repo}/issues/%s/dependencies/blocked_by" % o["blocked"],
                              "-F", "issue_id=%s" % dbid])
        if rc != 0:
            die(1, "the dependencies API refused (%s); write a `Blocked-by: #%s` line in #%s's body instead"
                % (err.strip(), o["blocker"], o["blocked"]))
    else:
        need("az")
        rc, _, err = run(["az", "boards", "work-item", "relation", "add", "--id", o["blocked"],
                          "--relation-type", "Predecessor", "--target-id", o["blocker"]]
                         + ado_org(fields) + ["--output", "json"])
        if rc != 0:
            die(1, "relation add failed: %s" % err.strip())
    print("blocked=%s<%s" % (o["blocked"], o["blocker"]))


def tsv(value):
    return re.sub(r"[\t\r\n]+", " ", str(value))


def cmd_search(o):
    terms = (o["terms"] or "").split()
    if not terms:
        usage("search needs --terms")
    state = o["state"] or "open"
    if state not in ("open", "all"):
        usage("--state is open or all")
    kind, fields = declared(find_root(o["root"]))
    if kind == "github":
        need("gh")
        rc, out, err = run(["gh", "issue", "list", "--state", state, "--search", " OR ".join(terms),
                            "--limit", "100", "--json", "number,title,state"])
        if rc != 0:
            die(1, "gh issue list failed: %s" % err.strip())
        rows = [(i["number"], i["title"], i["state"]) for i in json.loads(out or "[]")]
    else:
        need("az")
        clause = " OR ".join("[System.Title] CONTAINS '%s'" % t.replace("'", "''") for t in terms)
        wiql = ("SELECT [System.Id], [System.Title], [System.State] FROM WorkItems "
                "WHERE [System.TeamProject] = @project AND (%s)" % clause)
        if state == "open":
            wiql += "".join(" AND [System.State] <> '%s'" % s for s in ("Closed", "Removed", "Done", "Resolved"))
        rc, out, err = run(["az", "boards", "query", "--wiql", wiql, "--output", "json"] + ado_scope(fields))
        if rc != 0:
            die(1, "az boards query failed: %s" % err.strip())
        rows = [(i.get("id") or i["fields"].get("System.Id"), i["fields"].get("System.Title", ""),
                 i["fields"].get("System.State", "")) for i in json.loads(out or "[]")]
    for r in rows:
        print("\t".join(tsv(c) for c in r))


def cmd_show(o, pos):
    if len(pos) != 1:
        usage("show takes one ID")
    item_id = numeric_id(pos[0], "show")
    kind, fields = declared(find_root(o["root"]))
    if kind == "github":
        need("gh")
        cmd = ["gh", "issue", "view", item_id, "--json", "number,title,body,state,labels,assignees,url"]
    else:
        need("az")
        cmd = ["az", "boards", "work-item", "show", "--id", item_id, "--expand", "relations",
               "--output", "json"] + ado_org(fields)
    rc, out, err = run(cmd)
    if rc != 0:
        die(1, "could not read item %s: %s" % (item_id, err.strip()))
    sys.stdout.write(out)


def cmd_comment(o, pos):
    if o["body"] and o["body-file"] and o["body"] != o["body-file"]:
        usage("comment takes one body: --body and --body-file are the same option")
    body_opt = o["body"] or o["body-file"]
    if len(pos) != 1 or not body_opt:
        usage("comment takes one ID and --body FILE")
    item_id = numeric_id(pos[0], "comment")
    kind, fields = declared(find_root(o["root"]))
    body = nonempty(body_opt)
    if kind == "github":
        need("gh")
        rc, _, err = run(["gh", "issue", "comment", item_id, "--body-file", body])
    else:
        need("az")
        rc, _, err = run(["az", "boards", "work-item", "update", "--id", item_id, "--discussion", "@" + body]
                         + ado_org(fields) + ["--output", "json"])
    if rc != 0:
        die(1, "comment failed on item %s: %s; hand the user the text to post" % (item_id, err.strip()))
    print("commented=%s" % item_id)


SPECS = {
    "resolve": {"root": "one"},
    "tags": {"root": "one", "type": "one", "title": "one", "debt": "flag"},
    "html": {"root": "one"},
    "create": {"root": "one", "type": "one", "title": "one", "body": "one", "field": "many",
               "label": "many", "parent": "one", "debt": "flag", "workdir": "one",
               "dry-run": "flag", "no-prefix": "flag"},
    "update": {"root": "one", "title": "one", "type": "one", "no-prefix": "flag", "body": "one",
               "field": "many", "workdir": "one", "dry-run": "flag"},
    "link": {"root": "one", "parent": "one", "child": "one", "dry-run": "flag"},
    "block": {"root": "one", "blocked": "one", "blocker": "one", "dry-run": "flag"},
    "search": {"root": "one", "terms": "one", "state": "one"},
    "show": {"root": "one"},
    "comment": {"root": "one", "body": "one", "body-file": "one", "dry-run": "flag"},
}


def main(argv):
    global DRY
    if not argv or argv[0] in ("-h", "--help"):
        print(USAGE)
        sys.exit(0 if argv else 3)
    command = argv[0]
    if command not in SPECS:
        usage("unknown command %s" % command)
    o, pos = parse(argv[1:], SPECS[command])
    DRY = bool(o.get("dry-run"))
    if pos and command not in ("html", "update", "show", "comment"):
        usage("%s takes no positional argument (%s)" % (command, pos[0]))
    if command == "resolve":
        cmd_resolve(o)
    elif command == "tags":
        cmd_tags(o)
    elif command == "html":
        cmd_html(pos)
    elif command == "create":
        cmd_create(o)
    elif command == "update":
        cmd_update(o, pos)
    elif command == "link":
        cmd_link(o)
    elif command == "block":
        cmd_block(o)
    elif command == "search":
        cmd_search(o)
    elif command == "show":
        cmd_show(o, pos)
    elif command == "comment":
        cmd_comment(o, pos)


if __name__ == "__main__":
    main(sys.argv[1:])
