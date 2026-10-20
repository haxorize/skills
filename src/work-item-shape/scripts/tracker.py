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
rich-text read-back, sub-issue and relation links, and the claim, close and
label calls.

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
  close ID [--reason completed|not_planned|duplicate] [--state S]
                             GitHub: gh issue close, with --reason; ADO: needs
                             --state, the team process's terminal state (never
                             guessed); --reason is GitHub only, --state ADO only
  assign ID --to USER        GitHub: --add-assignee (a login or @me); ADO:
                             --assigned-to (the uniqueName)
  label ID [--add L]... [--remove L]...
                             GitHub only: a missing --add label is created
                             first; on ADO set tags with update --field
                             "System.Tags=A; B", which replaces the set whole

Every ID is digits only; --field takes GitHub nowhere (create and update
alike exit 3); a label (--label, --add, --remove) starting with "-" exits 3.

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
import collections
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
    need(cmd[0])
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


def cmd_resolve(o, pos):
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


def cmd_tags(o, pos):
    if not o["title"]:
        usage("tags needs --title")
    _, fields = declared(find_root(o["root"]))
    print(derive_tags(o["title"], fields, o["debt"]))


def cmd_html(o, pos):
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


def dash_free(labels):
    for label in labels:
        if label.startswith("-"):
            usage("a label cannot start with '-': %s" % label)
    return labels


def gh_labels(fields, o):
    dash_free(o["label"])
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


def no_fields(o):
    if o.get("field"):
        usage("--field is Azure DevOps only")


def create_failed(cli, err):
    die(1, "%s failed: %s\nDo not retry blind: the item may exist. "
           "Run `tracker.py search --terms ...` for the title first." % (cli, err.strip()))


# --- the backends: one class per tracker, each method one command's tracker half

class GitHub:
    def __init__(self, fields):
        self.fields = fields

    def create(self, o, title):
        """(id, gaps) once the issue exists; id= and url= already printed."""
        no_fields(o)
        if not o["body"]:
            usage("create on GitHub needs --body FILE")
        labels = gh_labels(self.fields, o)
        body = nonempty(o["body"])
        gh_ensure_labels(labels)
        cmd = ["gh", "issue", "create", "--title", title, "--body-file", body]
        for label in labels:
            cmd += ["--label", label]
        rc, out, err = run(cmd)
        if rc != 0:
            create_failed("gh issue create", err)
        url = out.strip().splitlines()[-1] if out.strip() else ""
        m = re.search(r"/issues/(\d+)\s*$", url)
        item_id = m.group(1) if m else ("<new>" if DRY else "")
        if not item_id:
            die(1, "gh issue create printed no issue URL: %r" % out)
        print("id=%s" % item_id)
        print("url=" + (url if m else ""))
        return item_id, []

    def update(self, item_id, o, title):
        """The read-back gaps (none on GitHub: the body is plain Markdown)."""
        no_fields(o)
        cmd = ["gh", "issue", "edit", item_id]
        if title:
            cmd += ["--title", title]
        if o["body"]:
            cmd += ["--body-file", nonempty(o["body"])]
        rc, _, err = run(cmd)
        if rc != 0:
            die(1, "gh issue edit failed for #%s: %s" % (item_id, err.strip()))
        return []

    def link(self, parent, child):
        dbid, err = gh_db_id(child)
        if not dbid:
            return 1, err
        rc, _, err = run(["gh", "api", "repos/{owner}/{repo}/issues/%s/sub_issues" % parent,
                          "-F", "sub_issue_id=%s" % dbid])
        return rc, err

    def block(self, blocked, blocker):
        dbid, err = gh_db_id(blocker)
        rc = 1
        if dbid:
            rc, _, err = run(["gh", "api", "repos/{owner}/{repo}/issues/%s/dependencies/blocked_by" % blocked,
                              "-F", "issue_id=%s" % dbid])
        if rc != 0:
            die(1, "the dependencies API refused (%s); write a `Blocked-by: #%s` line in #%s's body instead"
                % (err.strip(), blocker, blocked))

    def search(self, terms, state):
        """(id, title, state) per match."""
        rc, out, err = run(["gh", "issue", "list", "--state", state, "--search", " OR ".join(terms),
                            "--limit", "100", "--json", "number,title,state"])
        if rc != 0:
            die(1, "gh issue list failed: %s" % err.strip())
        return [(i["number"], i["title"], i["state"]) for i in json.loads(out or "[]")]

    def show(self, item_id):
        return run(["gh", "issue", "view", item_id, "--json", "number,title,body,state,labels,assignees,url"])

    def comment(self, item_id, body):
        return run(["gh", "issue", "comment", item_id, "--body-file", body])

    def close(self, item_id, o):
        if o["state"]:
            usage("--state is Azure DevOps only; GitHub closes with --reason")
        reason = ["--reason", o["reason"].replace("_", " ")] if o["reason"] else []  # gh spells it "not planned"
        return run(["gh", "issue", "close", item_id] + reason)

    def assign(self, item_id, user):
        return run(["gh", "issue", "edit", item_id, "--add-assignee", user])

    def label(self, item_id, add, remove):
        gh_ensure_labels(add)
        cmd = ["gh", "issue", "edit", item_id]
        for label in add:
            cmd += ["--add-label", label]
        for label in remove:
            cmd += ["--remove-label", label]
        return run(cmd)


class Ado:
    def __init__(self, fields):
        self.fields = fields

    def create(self, o, title):
        fields = self.fields
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
            create_failed("az boards work-item create", err)
        item_id = "<new>" if DRY else json.loads(out)["id"]
        print("id=%s" % item_id)
        print("url=" + ado_url(fields, item_id))
        print("tags-not-applied=" + (tags if untagged else ""))
        print("apply-tags=" + (" ".join(shlex.quote(c) for c in
              ["az", "boards", "work-item", "update", "--id", str(item_id),
               "--fields", "System.Tags=" + tags] + ado_org(fields)) if untagged else ""))
        return item_id, ["readback:" + r for r in read_back(fields, item_id, rich)]

    def update(self, item_id, o, title):
        itemdir = os.path.join(workdir_of(o), "update-%s" % slug(item_id))
        desc, flist, rich = ado_fields(o, itemdir)
        cmd = ["az", "boards", "work-item", "update", "--id", item_id]
        if title:
            cmd += ["--title", title]
        if desc:
            cmd += ["--description", "@" + desc]
        if flist:
            cmd += ["--fields"] + flist
        rc, _, err = run(cmd + ado_org(self.fields) + ["--output", "json"])
        if rc != 0:
            die(1, "az boards work-item update failed for %s: %s" % (item_id, err.strip()))
        return ["readback:" + r for r in read_back(self.fields, item_id, rich)]

    def relate(self, item_id, relation, target):
        rc, _, err = run(["az", "boards", "work-item", "relation", "add", "--id", str(item_id),
                          "--relation-type", relation, "--target-id", str(target)]
                         + ado_org(self.fields) + ["--output", "json"])
        return rc, err

    def link(self, parent, child):
        return self.relate(child, "Parent", parent)

    def block(self, blocked, blocker):
        rc, err = self.relate(blocked, "Predecessor", blocker)
        if rc != 0:
            die(1, "relation add failed: %s" % err.strip())

    def search(self, terms, state):
        clause = " OR ".join("[System.Title] CONTAINS '%s'" % t.replace("'", "''") for t in terms)
        wiql = ("SELECT [System.Id], [System.Title], [System.State] FROM WorkItems "
                "WHERE [System.TeamProject] = @project AND (%s)" % clause)
        if state == "open":
            wiql += "".join(" AND [System.State] <> '%s'" % s for s in ("Closed", "Removed", "Done", "Resolved"))
        rc, out, err = run(["az", "boards", "query", "--wiql", wiql, "--output", "json"] + ado_scope(self.fields))
        if rc != 0:
            die(1, "az boards query failed: %s" % err.strip())
        return [(i.get("id") or i["fields"].get("System.Id"), i["fields"].get("System.Title", ""),
                 i["fields"].get("System.State", "")) for i in json.loads(out or "[]")]

    def show(self, item_id):
        return run(["az", "boards", "work-item", "show", "--id", item_id, "--expand", "relations",
                    "--output", "json"] + ado_org(self.fields))

    def comment(self, item_id, body):
        return self.edit(item_id, ["--discussion", "@" + body])

    def edit(self, item_id, flags):
        return run(["az", "boards", "work-item", "update", "--id", item_id] + flags
                   + ado_org(self.fields) + ["--output", "json"])

    def close(self, item_id, o):
        if o["reason"]:
            usage("--reason is GitHub only; Azure DevOps closes with --state S")
        if not o["state"]:
            usage("close on Azure DevOps needs --state S: the team process's terminal state "
                  "(Closed, Done, Removed), read off the team's closed items, never guessed")
        return self.edit(item_id, ["--state", o["state"]])

    def assign(self, item_id, user):
        return self.edit(item_id, ["--assigned-to", user])

    def label(self, item_id, add, remove):
        usage("label is GitHub only; on Azure DevOps set tags with `update ID --field "
              "\"System.Tags=A; B\"`, which replaces the set whole")


BACKENDS = {"github": GitHub, "ado": Ado}


def backend(o):
    """The declared tracker's backend, after every block check."""
    kind, fields = declared(find_root(o["root"]))
    return BACKENDS[kind](fields)


# --- the commands: checks and output shared by both trackers ----------------

def cmd_create(o, pos):
    if not o["type"] or not o["title"]:
        usage("create needs --type and --title")
    if o["parent"]:
        numeric_id(o["parent"], "--parent")
    tracker = backend(o)
    title = prefixed(o["type"], o["title"], tracker.fields, o["no-prefix"])
    item_id, gaps = tracker.create(o, title)
    if o["parent"] and not link(tracker, o["parent"], item_id):
        gaps.append("link:" + o["parent"])
    if gaps:
        incomplete(item_id, gaps)


def cmd_update(o, pos):
    item_id = numeric_id(pos[0], "update")
    tracker = backend(o)
    fields, title = tracker.fields, None
    if o["title"]:
        if (not o["type"] and not o["no-prefix"]
                and title_prefix("feature", fields) != title_prefix("", fields)):
            usage("update --title needs --type T (or --no-prefix): the block's Feature title prefix "
                  "differs from its Title prefix")
        title = prefixed(o["type"], o["title"], fields, o["no-prefix"])
    gaps = tracker.update(item_id, o, title)
    print("id=%s" % item_id)
    if gaps:
        incomplete(item_id, gaps)


def link(tracker, parent, child):
    """True once linked (linked= printed); False with the reason on stderr."""
    link_rc, err = tracker.link(parent, child)
    if link_rc != 0:
        print("tracker.py: item %s is not linked under %s (%s); re-run `tracker.py link --parent %s "
              "--child %s` or link the two by hand — never retry the create"
              % (child, parent, err.strip(), parent, child), file=sys.stderr)
        return False
    print("linked=%s>%s" % (parent, child))
    return True


def cmd_link(o, pos):
    if not o["parent"] or not o["child"]:
        usage("link needs --parent and --child")
    numeric_id(o["parent"], "--parent")
    numeric_id(o["child"], "--child")
    if not link(backend(o), o["parent"], o["child"]):
        sys.exit(1)


def cmd_block(o, pos):
    if not o["blocked"] or not o["blocker"]:
        usage("block needs --blocked and --blocker")
    numeric_id(o["blocked"], "--blocked")
    numeric_id(o["blocker"], "--blocker")
    backend(o).block(o["blocked"], o["blocker"])
    print("blocked=%s<%s" % (o["blocked"], o["blocker"]))


def tsv(value):
    return re.sub(r"[\t\r\n]+", " ", str(value))


def cmd_search(o, pos):
    terms = (o["terms"] or "").split()
    if not terms:
        usage("search needs --terms")
    state = o["state"] or "open"
    if state not in ("open", "all"):
        usage("--state is open or all")
    for r in backend(o).search(terms, state):
        print("\t".join(tsv(c) for c in r))


def cmd_show(o, pos):
    item_id = numeric_id(pos[0], "show")
    rc, out, err = backend(o).show(item_id)
    if rc != 0:
        die(1, "could not read item %s: %s" % (item_id, err.strip()))
    sys.stdout.write(out)


def cmd_comment(o, pos):
    if o["body"] and o["body-file"] and o["body"] != o["body-file"]:
        usage("comment takes one body: --body and --body-file are the same option")
    body_opt = o["body"] or o["body-file"]
    if not body_opt:
        usage("comment needs --body FILE")
    item_id = numeric_id(pos[0], "comment")
    tracker = backend(o)
    rc, _, err = tracker.comment(item_id, nonempty(body_opt))
    if rc != 0:
        die(1, "comment failed on item %s: %s; hand the user the text to post" % (item_id, err.strip()))
    print("commented=%s" % item_id)


def cmd_close(o, pos):
    item_id = numeric_id(pos[0], "close")
    if o["reason"] and o["reason"] not in ("completed", "not_planned", "duplicate"):
        usage("--reason is completed, not_planned or duplicate, not %r" % o["reason"])
    rc, _, err = backend(o).close(item_id, o)
    if rc != 0:
        die(1, "close failed on item %s: %s" % (item_id, err.strip()))
    print("closed=%s" % item_id)


def cmd_assign(o, pos):
    item_id = numeric_id(pos[0], "assign")
    if not o["to"]:
        usage("assign needs --to USER")
    rc, _, err = backend(o).assign(item_id, o["to"])
    if rc != 0:
        die(1, "assign failed on item %s: %s" % (item_id, err.strip()))
    print("assigned=%s>%s" % (item_id, o["to"]))


def cmd_label(o, pos):
    item_id = numeric_id(pos[0], "label")
    if not o["add"] and not o["remove"]:
        usage("label needs --add L or --remove L")
    rc, _, err = backend(o).label(item_id, dash_free(o["add"]), dash_free(o["remove"]))
    if rc != 0:
        die(1, "label edit failed on item %s: %s" % (item_id, err.strip()))
    print("labeled=%s" % item_id)


# Every command, once: its handler, its options (parse's spec) and its
# positionals (the usage text and how many); main() reads nothing else.
Command = collections.namedtuple("Command", "handler options positionals")
NO_ARGS = ("no positional argument", 0)
ONE_ID = ("one ID", 1)

SPECS = {
    "resolve": Command(cmd_resolve, {"root": "one"}, NO_ARGS),
    "tags": Command(cmd_tags, {"root": "one", "type": "one", "title": "one", "debt": "flag"}, NO_ARGS),
    "html": Command(cmd_html, {"root": "one"}, ("IN.md OUT.html", 2)),
    "create": Command(cmd_create, {"root": "one", "type": "one", "title": "one", "body": "one",
                                   "field": "many", "label": "many", "parent": "one", "debt": "flag",
                                   "workdir": "one", "dry-run": "flag", "no-prefix": "flag"}, NO_ARGS),
    "update": Command(cmd_update, {"root": "one", "title": "one", "type": "one", "no-prefix": "flag",
                                   "body": "one", "field": "many", "workdir": "one",
                                   "dry-run": "flag"}, ONE_ID),
    "link": Command(cmd_link, {"root": "one", "parent": "one", "child": "one", "dry-run": "flag"}, NO_ARGS),
    "block": Command(cmd_block, {"root": "one", "blocked": "one", "blocker": "one", "dry-run": "flag"},
                     NO_ARGS),
    "search": Command(cmd_search, {"root": "one", "terms": "one", "state": "one"}, NO_ARGS),
    "show": Command(cmd_show, {"root": "one"}, ONE_ID),
    "comment": Command(cmd_comment, {"root": "one", "body": "one", "body-file": "one",
                                     "dry-run": "flag"}, ONE_ID),
    "close": Command(cmd_close, {"root": "one", "reason": "one", "state": "one", "dry-run": "flag"}, ONE_ID),
    "assign": Command(cmd_assign, {"root": "one", "to": "one", "dry-run": "flag"}, ONE_ID),
    "label": Command(cmd_label, {"root": "one", "add": "many", "remove": "many", "dry-run": "flag"}, ONE_ID),
}


def main(argv):
    global DRY
    if not argv or argv[0] in ("-h", "--help"):
        print(USAGE)
        sys.exit(0 if argv else 3)
    command = argv[0]
    if command not in SPECS:
        usage("unknown command %s" % command)
    spec = SPECS[command]
    o, pos = parse(argv[1:], spec.options)
    DRY = bool(o.get("dry-run"))
    takes, count = spec.positionals
    if len(pos) != count:
        usage("%s takes %s (got %d)" % (command, takes, len(pos)))
    spec.handler(o, pos)


if __name__ == "__main__":
    main(sys.argv[1:])
