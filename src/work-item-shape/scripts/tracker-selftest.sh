#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove tracker.py, the copy beside this file, against fake `gh`, `az` and
# `pandoc` built at run time: each logs its argv and answers by scenario, so
# no call reaches a tracker. The file names its script by its own directory.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
# Run it after changing the script.
#
# What is graded:
#   resolve — a GitHub bullet block and an ADO plain block, key=value out;
#     the routing-policy sentence and a `See:` prose line read as no key, a
#     hyphenated key (In-progress signal:) read; the block ending at the next
#     heading of any level (## and ###); no CLAUDE.md in a repo (bootstrap),
#     outside one (no-repo) and a block with no Tracker: line, each exit 2;
#     ADO with no Project: exit 1 from resolve and from create; two trackers
#     on one Tracker: line, or two Tracker: lines, exit 1.
#   the block's values — a Repo: with a host and an Organization: off the
#     two Azure DevOps URL forms each exit 1 before any call; a missing block
#     exits 2 naming resolve for create and tags alike.
#   tags — the leading bracket's contents, Additional tags with brackets
#     stripped, Never tag dropped, debt added after the Never tag filter, a
#     duplicate once, no bracket and no declaration giving "".
#   title prefix — a Feature takes Feature title prefix, else Title prefix; a
#     Story never takes Feature title prefix; --no-prefix; update --title
#     prefixed idempotently, needing --type only when the two prefixes differ.
#   create on GitHub — Default labels, --label and debt applied; a missing
#     label created first and an existing one never re-created; --dry-run
#     printing `gh label create` without --force; the parent linked by the
#     child's database id, not its number, through the one lookup block uses
#     too; --field a usage error; a failed create exits 1 once with the search
#     advice and no second create; an empty body exits 1 before any call.
#   create on ADO — one --fields flag carrying the fields, the default state
#     and System.Tags; .md converted to HTML in the per-item directory (a
#     fresh mkdtemp one with no --workdir) and sent by absolute path;
#     --project and --org from the block; the read-back passing; url= from
#     Work item URL, and url=, tags-not-applied= and apply-tags= printed empty
#     when there is nothing to say; the parent as a Parent relation; a tag
#     refusal retried once without System.Tags and the tags printed with an
#     apply-tags command carrying --org and no --project; a failed create
#     exits 1 after one call; --dry-run calls nothing.
#   written but incomplete — a read-back holding a literal @path (create and
#     update) and a refused link (sub-issue and Parent relation) each exit 5
#     with id= printed and an incomplete= line naming the gap; a refused
#     `link` on its own exits 1.
#   update — an ADO --field sent in --fields and read back; a GitHub --body
#     sent as --body-file.
#   Repo: — a GitHub block's Repo: reaching every gh call as GH_REPO, from
#     outside any checkout, and leading each --dry-run gh command.
#   search, block, comment, show, html — the WIQL's OR'd CONTAINS with a quote
#     doubled, scoped to @project, and Closed, Removed, Done and Resolved
#     dropped only for open; GitHub's OR'd --search with --state and --limit
#     100, and a tab in a title flattened; GitHub's blocked_by refusal naming
#     the Blocked-by: fallback; an ADO comment by --discussion @absolute path,
#     through --body and --body-file; show reading relations on ADO (no
#     --project) and through gh issue view; html through the python markdown
#     fallback (a stand-in module, since the real one may be absent).
#   close, assign, label — GitHub's close sending not_planned as gh's "not
#     planned" and no --reason when none is given, --state refused; ADO's
#     close by --state with --org and no --project, a missing --state and a
#     --reason each exit 3 before any call; a refused close exits 1 on both;
#     assign by --add-assignee and by --assigned-to (with --org, no
#     --project), --to required and a --to starting with "-" exit 3; label
#     creating a missing --add label first and never a --remove one, then one
#     gh issue edit with --add-label and --remove-label, a --remove label
#     starting with "-" exit 3, and label on ADO exit 3 naming the System.Tags
#     update.
#   az's @file expansion — an ADO --type, title (create and update), close
#     --state and assign --to starting with "@" each exit 3 before any call.
#   usage and never-ran — an unknown command, a create with no --title, an
#     option with no value, a positional count off its command's (update
#     with none, show with two, search with one), a non-numeric ID in every
#     ID slot, a label or a field reference starting with "-": exit 3;
#     `<command> --help` exit 0; no az on PATH, exit 4 before any conversion
#     or file write (a create with a body), and no Markdown converter, exit 4.
# The mutation table drops or reverts each of those checks; each mutant must
# turn its row red.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$here/../../.." && pwd)"
cd "$repo_root" || exit 4
# shellcheck source=SCRIPTDIR/../../../scripts/selftest-lib.sh
. scripts/selftest-lib.sh

TRACKER="$here/tracker.py"
[ -f "$TRACKER" ] || { selftest_fail "script $TRACKER is missing"; exit 1; }
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir tracker-selftest.sh
trap 'rm -rf "$tmp"' EXIT
tmp=$(python3 -c 'import os, sys; print(os.path.abspath(sys.argv[1]))' "$tmp")  # the script's paths are abspath'd

unset GH_REPO  # the fake logs it; only a block's Repo: line may set it

# --- fakes ------------------------------------------------------------------
# Each call appends one line, its argv joined by "|", to $FAKE_LOG.
# FAKE_FAIL=<tag> fails that call; FAKE_TAG_DENY=1 refuses a create carrying
# System.Tags; FAKE_LITERAL=1 stores a rich field as the literal @path (the
# CLI's behavior on a path it cannot open); FAKE_LABELS lists existing labels.
mkdir -p "$tmp/bin" "$tmp/nobin" "$tmp/nomd" "$tmp/fakemd" "$tmp/tmpd"
cat > "$tmp/bin/gh" <<'FAKE'
#!/usr/bin/env bash
(IFS='|'; echo "gh|${GH_REPO:+repo=$GH_REPO|}$*") >> "$FAKE_LOG"
fail() { [ "${FAKE_FAIL:-}" = "$1" ] && { echo "fake gh: $1 refused" >&2; exit 1; }; return 0; }
case "$1 $2" in
  "label list") printf '%s\n' ${FAKE_LABELS:-bug} ;;
  "label create")
    case " ${FAKE_LABELS:-bug} " in *" $3 "*) echo "fake gh: label $3 already exists" >&2; exit 1 ;; esac ;;
  "issue create") fail issue-create; echo "https://github.com/o/r/issues/42" ;;
  "issue list") echo '[{"number":7,"title":"Dup\tthing","state":"OPEN"}]' ;;
  "issue view") echo '{"number":'"$3"',"title":"T"}' ;;
  "issue edit") fail edit ;;
  "issue close") fail close ;;
  "issue comment") ;;
  "api repos/{owner}/{repo}/issues/"*)
    case "$2" in
      */sub_issues) fail sub ;;
      */dependencies/blocked_by) fail deps ;;
      *) echo "9000${2##*/}" ;;
    esac ;;
  *) echo "fake gh: unexpected $*" >&2; exit 9 ;;
esac
FAKE
cat > "$tmp/bin/az" <<'FAKE'
#!/usr/bin/env bash
(IFS='|'; echo "az|$*") >> "$FAKE_LOG"
fail() { [ "${FAKE_FAIL:-}" = "$1" ] && { echo "fake az: $1 refused" >&2; exit 1; }; return 0; }
store() {  # REF and @path args -> state file, as the service would hold them
  python3 - "$FAKE_STATE" "$@" <<'PY'
import json, os, sys
state_path, args = sys.argv[1], sys.argv[2:]
state = json.load(open(state_path)) if os.path.exists(state_path) else {}
def val(v):
    if v.startswith("@"):
        p = v[1:]
        if os.environ.get("FAKE_LITERAL") == "1" or not os.path.isfile(p):
            return v
        return open(p).read()
    return v
i = 0
while i < len(args):
    a = args[i]
    if a == "--description":
        state["System.Description"] = val(args[i + 1]); i += 2; continue
    if a == "--fields":
        i += 1
        while i < len(args) and not args[i].startswith("--"):
            ref, v = args[i].split("=", 1); state[ref] = val(v); i += 1
        continue
    i += 1
json.dump(state, open(state_path, "w"))
PY
}
case "$1 $2 $3" in
  "boards work-item create")
    fail create
    if [ "${FAKE_TAG_DENY:-}" = 1 ] && [[ "$*" == *System.Tags=* ]]; then
      echo "TF401320: Tags cannot be created by this user" >&2; exit 1
    fi
    store "$@"; echo '{"id": 501}' ;;
  "boards work-item update") fail update; store "$@"; echo '{"id": 501}' ;;
  "boards work-item show")
    if [[ "$*" == *--expand* ]]; then echo '{"id": 501, "relations": []}'
    else python3 -c 'import json,sys; print(json.dumps({"fields": json.load(open(sys.argv[1]))}))' "$FAKE_STATE"; fi ;;
  "boards work-item relation") fail relation ;;
  "boards query"*) echo '[{"id": 11, "fields": {"System.Title": "Dup", "System.State": "New"}}]' ;;
  *) echo "fake az: unexpected $*" >&2; exit 9 ;;
esac
FAKE
cat > "$tmp/bin/pandoc" <<'FAKE'
#!/usr/bin/env bash
out=""; in=""
while [ $# -gt 0 ]; do case "$1" in -o) out=$2; shift 2 ;; -f|-t) shift 2 ;; *) in=$1; shift ;; esac; done
{ printf '<p>'; cat "$in"; printf '</p>\n'; } > "$out"
FAKE
chmod +x "$tmp/bin/gh" "$tmp/bin/az" "$tmp/bin/pandoc"
for t in git python3 env; do ln -s "$(command -v $t)" "$tmp/nobin/$t"; done
# A markdown module that refuses to import stands in for "not installed".
echo 'raise ImportError("not installed")' > "$tmp/nomd/markdown.py"
# A stand-in markdown module, so the fallback path is graded whether or not
# python-markdown is installed here.
printf 'def markdown(text):\n    return "<p>MD:" + text + "</p>"\n' > "$tmp/fakemd/markdown.py"

# --- repos ------------------------------------------------------------------
mkrepo() { mkdir -p "$1"; git -C "$1" init -q 2>/dev/null; printf '%s\n' "$2" > "$1/CLAUDE.md"; }
mkrepo "$tmp/gh" '# R

## Issue tracker

- Tracker: GitHub
- Visibility: private
- Default labels: triage

Work items are created only through the `to-*` publishers (`to-feature`, `to-story`, `to-tasks`, `to-bug`) — never drafted and pushed with raw `gh`/`az` calls. On a casual ask ('"'"'file a story'"'"'), load the right publisher.

## Landing

- Branch policy: trunk
- Team: landing'
mkrepo "$tmp/ado" '## Issue tracker

Tracker: Azure DevOps
Organization: humana
Project: Proj X
Area path: Proj X\Team
Iteration: Proj X\PI 1
Title prefix: [App]
Feature title prefix: 26.4 Team –
Default state: New
Additional tags: [Shared], Extra
Never tag: Internal
Work item URL: https://dev.azure.com/humana/P/_workitems/edit/{id}'
mkrepo "$tmp/ado-noproj" '## Issue tracker

Tracker: ADO'
mkrepo "$tmp/gh-sub" '## Issue tracker

Tracker: GitHub
In-progress signal: label in-progress
See: something

### Notes

Team: late'
mkrepo "$tmp/two" '## Issue tracker

Tracker: GitHub (code), Azure DevOps (work items)'
mkrepo "$tmp/two-lines" '## Issue tracker

Tracker: GitHub
Tracker: Azure DevOps
Project: P'
mkrepo "$tmp/badrepo" '## Issue tracker

Tracker: GitHub
Repo: attacker.example.com/o/n'
mkrepo "$tmp/badorg" '## Issue tracker

Tracker: ADO
Project: P
Organization: https://evil.example.com/x'
mkrepo "$tmp/oneprefix" '## Issue tracker

Tracker: ADO
Project: P
Title prefix: [App]'
mkrepo "$tmp/notracker" '## Issue tracker

Some prose only.'
mkdir -p "$tmp/bare-git" "$tmp/nogit" "$tmp/scratch"; git -C "$tmp/bare-git" init -q 2>/dev/null
printf '## Issue tracker\n\nTracker: GitHub\nRepo: o/r\n' > "$tmp/scratch/CLAUDE.md"
printf '# Body\n\nText with `code` and $HOME.\n' > "$tmp/body.md"
printf -- '- **AC1:** works\n' > "$tmp/acceptance.md"
: > "$tmp/empty.md"

# trk <dir> <args…>: run the script (or $TRACKER_MUT) from <dir> with the fakes
# first on PATH; sets $out (stdout+stderr), $rc and $log.
trk() {
  local dir=$1; shift
  : > "$tmp/log"; rm -f "$tmp/state.json"
  out=$(cd "$dir" && FAKE_LOG="$tmp/log" FAKE_STATE="$tmp/state.json" PATH="$tmp/bin:$PATH" \
        python3 "${TRACKER_MUT:-$TRACKER}" "$@" --workdir "$tmp/work" 2>&1); rc=$?
  log=$(cat "$tmp/log")
}
# trkn: the same without --workdir, for commands that take none.
trkn() {
  local dir=$1; shift
  : > "$tmp/log"; rm -f "$tmp/state.json"
  out=$(cd "$dir" && FAKE_LOG="$tmp/log" FAKE_STATE="$tmp/state.json" PATH="$tmp/bin:$PATH" \
        python3 "${TRACKER_MUT:-$TRACKER}" "$@" 2>&1); rc=$?
  log=$(cat "$tmp/log")
}

# --- rows, each a function so the mutation table can re-run it --------------
row_resolve() {
  trkn "$tmp/gh" resolve
  expect_rc "resolve on a GitHub block" 0 "$rc"
  expect_row "$out" "resolve did not name the mode" "mode=declared"
  expect_row "$out" "resolve did not read a bullet Tracker: line" "tracker=github"
  expect_row "$out" "resolve did not read a bullet key" "default_labels=triage"
  reject_in "$out" "resolve read the routing-policy sentence as a key" "work_items"
  trkn "$tmp/ado" resolve
  expect_row "$out" "resolve did not read an ADO block" "tracker=ado"
  expect_row "$out" "resolve lost a key with a space" "area_path=Proj X\\Team"
  trkn "$tmp/bare-git" resolve
  expect_rc "resolve with no CLAUDE.md in a repo" 2 "$rc"
  expect_row "$out" "no CLAUDE.md in a repo is not bootstrap" "mode=bootstrap"
  trkn "$tmp/nogit" resolve
  expect_row "$out" "outside a repo is not no-repo" "mode=no-repo"
  trkn "$tmp/notracker" resolve
  expect_rc "a block with no Tracker: line" 2 "$rc"
}
row_heading() {
  trkn "$tmp/gh" resolve
  reject_in "$out" "the block ran past the next heading" "team=landing"
}
row_subheading() {
  trkn "$tmp/gh-sub" resolve
  expect_rc "resolve on a block with a ### subsection" 0 "$rc"
  reject_in "$out" "the block ran past a ### heading" "team=late"
}
row_prose() {
  trkn "$tmp/gh-sub" resolve
  reject_in "$out" "a prose line shaped Key: text became a field" "see=something"
  expect_in "$out" "the ignored prose line is not named on stderr" "read as prose: CLAUDE.md line 5 \`See:\`"
  expect_row "$out" "a hyphenated key was not read" "in_progress_signal=label in-progress"
}
row_two_trackers() {
  trkn "$tmp/two" resolve
  expect_rc "a Tracker: line naming two trackers" 1 "$rc"
  expect_in "$out" "two trackers not named as the reason" "names two trackers"
  reject_in "$out" "a two-tracker block still printed a tracker" "tracker=github"
  trkn "$tmp/two-lines" create --type Task --title x --body "$tmp/body.md"
  expect_rc "two Tracker: lines" 1 "$rc"
  [ -z "$log" ] || selftest_fail "a two-tracker block still called the tracker: $log"
}
row_project() {
  trk "$tmp/ado-noproj" create --type Task --title x --body "$tmp/body.md"
  expect_rc "ADO with no Project:" 1 "$rc"
  expect_in "$out" "the missing Project: is not named" "Project:"
  [ -z "$log" ] || selftest_fail "a create with no Project: still called az: $log"
  trkn "$tmp/ado-noproj" resolve
  expect_rc "resolve on ADO with no Project:" 1 "$rc"
  expect_in "$out" "resolve did not name the missing Project:" "Project:"
}
row_badrepo() {
  trk "$tmp/badrepo" create --type Story --title x --body "$tmp/body.md"
  expect_rc "a Repo: with a host" 1 "$rc"
  expect_in "$out" "the bad Repo: line is not named" "Repo: attacker.example.com/o/n"
  [ -z "$log" ] || selftest_fail "a bad Repo: still called gh: $log"
}
row_badorg() {
  trkn "$tmp/badorg" show 5
  expect_rc "an Organization: off the Azure DevOps forms" 1 "$rc"
  expect_in "$out" "the bad Organization: line is not named" "Organization: https://evil.example.com/x"
  [ -z "$log" ] || selftest_fail "a bad Organization: still called az: $log"
}
row_noblock() {
  trk "$tmp/notracker" create --type Task --title x --body "$tmp/body.md"
  expect_rc "create with no tracker block" 2 "$rc"
  expect_in "$out" "a missing block does not send the caller to resolve" "run \`tracker.py resolve\`"
}
row_tags_block() {
  trkn "$tmp/notracker" tags --type Story --title "[A] x"
  expect_rc "tags with no tracker block" 2 "$rc"
}
row_tags() {
  trkn "$tmp/ado" tags --type Story --title "[HMF Catalog] Add wizard"
  expect_row "$out" "tags: primary plus Additional tags" "HMF Catalog; Shared; Extra"
  trkn "$tmp/ado" tags --type Story --title "[Internal] Thing"
  expect_row "$out" "tags: Never tag not dropped" "Shared; Extra"
  trkn "$tmp/ado" tags --type Story --title "[Extra] Thing" --debt
  expect_row "$out" "tags: duplicate kept or debt missing" "Extra; Shared; debt"
  trkn "$tmp/gh" tags --type Story --title "No bracket"
  expect_row "$out" "tags: no bracket and no declaration is not empty" ""
}
row_debt() {
  printf '## Issue tracker\n\nTracker: ADO\nProject: P\nNever tag: debt\n' > "$tmp/ado-nodebt/CLAUDE.md"
  trkn "$tmp/ado-nodebt" tags --type Task --title "x" --debt
  expect_row "$out" "debt is added after the Never tag filter" "debt"
}
mkdir -p "$tmp/ado-nodebt"
row_prefix() {
  trk "$tmp/ado" create --type Feature --title "Big thing" --body "$tmp/body.md"
  expect_in "$log" "a Feature did not take Feature title prefix" "--title|26.4 Team – Big thing|"
  trk "$tmp/ado" create --type "User Story" --title "Small" --body "$tmp/body.md"
  expect_in "$log" "a Story did not take Title prefix" "--title|[App] Small|"
  trk "$tmp/ado" create --type "User Story" --title "Small" --body "$tmp/body.md" --no-prefix
  expect_in "$log" "--no-prefix still prefixed" "--title|Small|"
}
row_update_prefix() {
  trk "$tmp/ado" update 12 --title "New"
  expect_rc "update --title where the two prefixes differ, no --type" 3 "$rc"
  [ -z "$log" ] || selftest_fail "an update needing --type still called az: $log"
  trk "$tmp/ado" update 12 --title "New" --type "User Story"
  expect_rc "update --title --type" 0 "$rc"
  expect_in "$log" "update --title did not take Title prefix" "--title|[App] New|"
  trk "$tmp/oneprefix" update 12 --title "New"
  expect_in "$log" "update --title with one prefix declared did not take it" "--title|[App] New|"
  trk "$tmp/ado" update 12 --title "New" --no-prefix
  expect_in "$log" "update --no-prefix still prefixed" "--title|New|"
}
row_prefix_idem() {
  trk "$tmp/ado" update 12 --title "[App] New" --type "User Story"
  expect_in "$log" "an already-prefixed title was not sent as is" "--title|[App] New|"
  reject_in "$log" "an already-prefixed title was prefixed twice" "[App] [App]"
}
row_gh_create() {
  FAKE_LABELS=bug trk "$tmp/gh" create --type Story --title "New" --body "$tmp/body.md" --label story --debt --parent 9
  expect_rc "GitHub create" 0 "$rc"
  expect_row "$out" "GitHub create did not print the number" "id=42"
  expect_row "$out" "GitHub create did not print the url" "url=https://github.com/o/r/issues/42"
  expect_in "$log" "the missing default label was not created" "gh|label|create|triage"
  expect_in "$log" "labels missing from the create" "--label|triage|--label|story|--label|debt"
  expect_in "$log" "the parent was not linked by database id" "-F|sub_issue_id=900042"
  expect_row "$out" "the link was not reported" "linked=9>42"
}
row_gh_labels() {
  FAKE_LABELS=bug trk "$tmp/gh" create --type Story --title "New" --body "$tmp/body.md"
  expect_in "$log" "a missing label was not created before the issue" "gh|label|create|triage"
}
row_gh_label_exists() {
  FAKE_LABELS="bug triage" trk "$tmp/gh" create --type Story --title "New" --body "$tmp/body.md"
  expect_rc "a create whose label already exists" 0 "$rc"
  reject_in "$log" "an existing label was created again" "label|create|triage"
}
row_dry_labels() {
  trk "$tmp/gh" create --type Story --title "New" --body "$tmp/body.md" --dry-run
  expect_in "$out" "--dry-run did not print the label create" "gh label create triage"
  reject_in "$out" "--dry-run's label create would overwrite an existing label" "--force"
}
row_dbid() {
  trk "$tmp/gh" create --type Story --title "New" --body "$tmp/body.md" --parent 9
  expect_in "$log" "create's link did not send the database id" "-F|sub_issue_id=900042"
  trkn "$tmp/gh" block --blocked 5 --blocker 6
  expect_rc "GitHub block" 0 "$rc"
  expect_in "$log" "block did not send the blocker's database id" "-F|issue_id=90006"
}
row_gh_field() {
  trk "$tmp/gh" create --type Story --title "New" --body "$tmp/body.md" --field "A.B=c"
  expect_rc "GitHub create with --field" 3 "$rc"
  [ -z "$log" ] || selftest_fail "a GitHub create with --field still called gh: $log"
}
row_gh_fail() {
  FAKE_FAIL=issue-create trk "$tmp/gh" create --type Story --title "New" --body "$tmp/body.md"
  expect_rc "a failed GitHub create" 1 "$rc"
  expect_in "$out" "the failure does not send the caller to search" "tracker.py search"
  [ "$(grep -c 'issue|create' <<< "$log")" -eq 1 ] || selftest_fail "a failed create was retried"
}
row_empty() {
  trk "$tmp/gh" create --type Story --title "New" --body "$tmp/empty.md"
  expect_rc "an empty body" 1 "$rc"
  reject_in "$log" "an empty body still reached gh issue create" "issue|create"
}
row_ado_create() {
  trk "$tmp/ado" create --type "User Story" --title "[HMF] Add" --body "$tmp/body.md" \
     --field "Microsoft.VSTS.Common.AcceptanceCriteria=@$tmp/acceptance.md" --parent 77
  expect_rc "ADO create" 0 "$rc"
  expect_row "$out" "ADO create did not print the id" "id=501"
  expect_row "$out" "url= not built from Work item URL" "url=https://dev.azure.com/humana/P/_workitems/edit/501"
  [ "$(grep 'work-item|create' <<< "$log" | grep -o '|--fields|' | wc -l | tr -d ' ')" = 1 ] \
    || selftest_fail "the ADO create did not carry exactly one --fields flag"
  expect_in "$log" "tags missing from the one --fields list" "System.State=New|System.Tags=HMF; Shared; Extra|"
  expect_in "$log" "the body was not sent as the converted HTML by absolute path" "--description|@$tmp/work/user-story-hmf-add/body.html|"
  expect_in "$log" "the acceptance field was not converted" "AcceptanceCriteria=@$tmp/work/user-story-hmf-add/acceptance.html"
  expect_in "$log" "--project/--org not passed" "--project|Proj X|--org|https://dev.azure.com/humana"
  expect_in "$log" "the read-back did not run" "az|boards|work-item|show|--id|501|--output|json|--org|https://dev.azure.com/humana"
  expect_in "$log" "the parent was not a Parent relation" "relation|add|--id|501|--relation-type|Parent|--target-id|77|--org|"
}
row_keys() {
  trk "$tmp/ado-nodebt" create --type Task --title "x" --field "System.State=Active"
  expect_rc "an ADO create with no URL template" 0 "$rc"
  expect_row "$out" "url= not printed empty when unknown" "url="
  expect_row "$out" "tags-not-applied= not printed empty when nothing was refused" "tags-not-applied="
  expect_row "$out" "apply-tags= not printed empty when nothing was refused" "apply-tags="
}
row_workdir() {
  : > "$tmp/log"; rm -f "$tmp/state.json"
  out=$(cd "$tmp/ado" && TMPDIR="$tmp/tmpd" FAKE_LOG="$tmp/log" FAKE_STATE="$tmp/state.json" PATH="$tmp/bin:$PATH" \
        python3 "${TRACKER_MUT:-$TRACKER}" create --type Task --title x --body "$tmp/body.md" 2>&1); rc=$?
  log=$(cat "$tmp/log")
  expect_rc "an ADO create with no --workdir" 0 "$rc"
  expect_in "$log" "no --workdir did not convert into a fresh mkdtemp directory" "--description|@$tmp/tmpd/tracker-"
  reject_in "$log" "no --workdir used a predictable shared path" "@$tmp/tmpd/task-x/"
}
row_state() {
  trk "$tmp/ado" create --type Bug --title "x" --field "Custom.Notes=@$tmp/body.md" --field "System.State=Active"
  reject_in "$log" "the default state overrode a given one" "System.State=New"
}
row_convert() {
  trk "$tmp/ado" create --type Task --title "x" --body "$tmp/body.md"
  [ -s "$tmp/work/task-x/body.html" ] || selftest_fail "the .md was not converted into the per-item directory"
  reject_in "$log" "raw Markdown was sent" "@$tmp/body.md"
}
row_tagdeny() {
  FAKE_TAG_DENY=1 trk "$tmp/ado" create --type Task --title "[T] x" --body "$tmp/body.md"
  expect_rc "a tag refusal" 0 "$rc"
  [ "$(grep -c 'work-item|create' <<< "$log")" -eq 2 ] || selftest_fail "a tag refusal was not retried exactly once"
  [ "$(grep 'work-item|create' <<< "$log" | tail -1 | grep -c System.Tags)" -eq 0 ] \
    || selftest_fail "the retry still carried System.Tags"
  expect_row "$out" "the unapplied tags were not printed" "tags-not-applied=T; Shared; Extra"
  expect_row "$out" "the apply-tags command is not built like the update calls (--org, no --project)" \
    "apply-tags=az boards work-item update --id 501 --fields 'System.Tags=T; Shared; Extra' --org https://dev.azure.com/humana"
}
row_readback() {
  FAKE_LITERAL=1 trk "$tmp/ado" create --type Task --title "x" --body "$tmp/body.md"
  expect_rc "a literal @path read back" 5 "$rc"
  expect_row "$out" "a written item's id was not printed before the read-back failed" "id=501"
  expect_row "$out" "the failed field is not an incomplete= line" "incomplete=readback:System.Description"
  expect_in "$out" "the failed field is not named" "System.Description came back empty or as a literal @path"
  expect_in "$out" "the read-back failure invites a re-run" "never re-run the create"
}
row_link_fail() {
  FAKE_FAIL=sub trk "$tmp/gh" create --type Story --title "New" --body "$tmp/body.md" --parent 9
  expect_rc "a refused sub-issue link after a create" 5 "$rc"
  expect_row "$out" "the created issue's id was not printed" "id=42"
  expect_row "$out" "the refused link is not an incomplete= line" "incomplete=link:9"
  reject_in "$out" "a refused link still printed linked=" "linked="
  FAKE_FAIL=relation trk "$tmp/ado" create --type Task --title "x" --body "$tmp/body.md" --parent 77
  expect_rc "a refused Parent relation after a create" 5 "$rc"
  expect_row "$out" "the refused relation is not an incomplete= line" "incomplete=link:77"
  FAKE_FAIL=relation trkn "$tmp/ado" link --parent 77 --child 12
  expect_rc "a refused link on its own" 1 "$rc"
}
row_update() {
  trk "$tmp/ado" update 12 --field "Custom.Notes=@$tmp/body.md"
  expect_rc "ADO update --field" 0 "$rc"
  expect_row "$out" "update did not print the id" "id=12"
  expect_in "$log" "update dropped its --field" "work-item|update|--id|12|--fields|Custom.Notes=@$tmp/work/update-12/body.html|--org|"
  expect_in "$log" "update did not read back its rich field" "work-item|show|--id|12"
}
row_update_readback() {
  FAKE_LITERAL=1 trk "$tmp/ado" update 12 --body "$tmp/body.md"
  expect_rc "an update whose read-back holds a literal @path" 5 "$rc"
  expect_row "$out" "the updated item's id was not printed" "id=12"
  expect_row "$out" "the update's failed field is not an incomplete= line" "incomplete=readback:System.Description"
}
row_gh_update() {
  trk "$tmp/gh" update 12 --body "$tmp/body.md"
  expect_rc "GitHub update --body" 0 "$rc"
  expect_in "$log" "a GitHub update did not send the body file" "gh|issue|edit|12|--body-file|$tmp/body.md"
}
row_ado_fail() {
  FAKE_FAIL=create trk "$tmp/ado" create --type Task --title "x" --body "$tmp/body.md"
  expect_rc "a failed ADO create" 1 "$rc"
  [ "$(grep -c 'work-item|create' <<< "$log")" -eq 1 ] || selftest_fail "a failed ADO create was retried"
}
row_dry() {
  trk "$tmp/ado" create --type Task --title "x" --body "$tmp/body.md" --dry-run
  expect_rc "--dry-run" 0 "$rc"
  [ -z "$log" ] || selftest_fail "--dry-run called the tracker: $log"
  expect_in "$out" "--dry-run did not print the create" "az boards work-item create --type Task"
}
row_search() {
  trkn "$tmp/ado" search --terms "o'brien widget"
  expect_in "$log" "the WIQL lost the doubled quote" "[System.Title] CONTAINS 'o''brien' OR [System.Title] CONTAINS 'widget'"
  expect_in "$log" "open search kept closed items" "<> 'Closed'"
  expect_row "$out" "search rows not printed" "11	Dup	New"
  trkn "$tmp/ado" search --terms "widget" --state all
  reject_in "$log" "--state all dropped closed items" "<> 'Closed'"
}
row_search_scope() {
  trkn "$tmp/ado" search --terms "widget"
  expect_in "$log" "the WIQL is not scoped to the project" "WHERE [System.TeamProject] = @project AND ("
  expect_in "$log" "open search kept Done items" "<> 'Done'"
  expect_in "$log" "open search kept Resolved items" "<> 'Resolved'"
}
row_gh_search() {
  trkn "$tmp/gh" search --terms "alpha beta"
  expect_rc "GitHub search" 0 "$rc"
  expect_in "$log" "GitHub search did not OR the terms with --state" "gh|issue|list|--state|open|--search|alpha OR beta|"
  expect_in "$log" "GitHub search kept gh's default limit" "--limit|100|"
  expect_row "$out" "a tab in a title broke the TSV row" "7	Dup thing	OPEN"
}
row_gh_repo() {
  trk "$tmp/nogit" create --type Story --title "Thing" --body "$tmp/body.md" --root "$tmp/scratch"
  expect_rc "a GitHub create from a --root scratch block" 0 "$rc"
  expect_in "$log" "Repo: did not reach gh as GH_REPO" "gh|repo=o/r|issue|create"
  trk "$tmp/nogit" create --type Story --title "Thing" --body "$tmp/body.md" --root "$tmp/scratch" --dry-run
  expect_in "$out" "a dry-run gh command dropped GH_REPO" "GH_REPO=o/r gh issue create"
}
row_misc() {
  FAKE_FAIL=deps trkn "$tmp/gh" block --blocked 5 --blocker 6
  expect_rc "a refused blocked_by" 1 "$rc"
  expect_in "$out" "the Blocked-by: fallback is not named" "Blocked-by: #6"
  trkn "$tmp/ado" comment 12 --body-file "$tmp/body.md"
  expect_in "$log" "an ADO comment did not go by --discussion @absolute path" "--discussion|@$tmp/body.md"
  trkn "$tmp/ado" show 12
  expect_in "$log" "show did not expand relations" "--expand|relations"
  reject_in "$log" "an ADO show carried --project, which work-item show does not take" "--project"
  trkn "$tmp/gh" show 12
  expect_rc "GitHub show" 0 "$rc"
  expect_in "$log" "GitHub show did not go through gh issue view" "gh|issue|view|12|--json|"
}
row_comment_body() {
  trkn "$tmp/gh" comment 12 --body "$tmp/body.md"
  expect_rc "comment --body" 0 "$rc"
  expect_in "$log" "comment --body did not send the file" "gh|issue|comment|12|--body-file|$tmp/body.md"
}
row_close() {
  trkn "$tmp/gh" close 12 --reason not_planned
  expect_rc "a GitHub close" 0 "$rc"
  expect_in "$log" "not_planned did not reach gh as \"not planned\"" "gh|issue|close|12|--reason|not planned"
  expect_in "$out" "close printed no closed= line" "closed=12"
  trkn "$tmp/gh" close 12
  reject_in "$log" "a close with no --reason sent one" "--reason"
  trkn "$tmp/gh" close 12 --state Done; expect_rc "a GitHub close with --state" 3 "$rc"
  trkn "$tmp/gh" close 12 --reason wontfix; expect_rc "an unknown close --reason" 3 "$rc"
  trkn "$tmp/ado" close 12 --state Removed
  expect_row "$log" "an ADO close did not send state, --org and --output in full" \
    "az|boards|work-item|update|--id|12|--state|Removed|--org|https://dev.azure.com/humana|--output|json"
  reject_in "$log" "an ADO close carried --project, which work-item update does not take" "--project"
  trkn "$tmp/ado" close 12; expect_rc "an ADO close with no --state" 3 "$rc"
  [ -z "$log" ] || selftest_fail "an ADO close with no --state still called az: $log"
  trkn "$tmp/ado" close 12 --state Done --reason completed; expect_rc "an ADO close with --reason" 3 "$rc"
  FAKE_FAIL=update trkn "$tmp/ado" close 12 --state Done; expect_rc "a refused ADO close" 1 "$rc"
  FAKE_FAIL=close trkn "$tmp/gh" close 12; expect_rc "a refused GitHub close" 1 "$rc"
}
row_assign() {
  trkn "$tmp/gh" assign 12 --to @me
  expect_in "$log" "a GitHub assign did not add the assignee" "gh|issue|edit|12|--add-assignee|@me"
  expect_in "$out" "assign printed no assigned= line" "assigned=12>@me"
  trkn "$tmp/ado" assign 12 --to jo@example.com
  expect_row "$log" "an ADO assign did not send --assigned-to, --org and --output in full" \
    "az|boards|work-item|update|--id|12|--assigned-to|jo@example.com|--org|https://dev.azure.com/humana|--output|json"
  reject_in "$log" "an ADO assign carried --project, which work-item update does not take" "--project"
  trkn "$tmp/ado" assign 12; expect_rc "assign with no --to" 3 "$rc"
  trkn "$tmp/gh" assign 12 --to -x; expect_rc "a --to starting with -" 3 "$rc"
  [ -z "$log" ] || selftest_fail "a --to starting with - still reached gh: $log"
  FAKE_FAIL=edit trkn "$tmp/gh" assign 12 --to @me; expect_rc "a refused assign" 1 "$rc"
}
row_label() {
  FAKE_LABELS="bug sev:3" trkn "$tmp/gh" label 12 --add sev:2 --remove sev:3
  expect_rc "a GitHub label edit" 0 "$rc"
  expect_in "$log" "a missing --add label was not created first" "gh|label|create|sev:2"
  expect_in "$log" "the label edit did not add and remove" "gh|issue|edit|12|--add-label|sev:2|--remove-label|sev:3"
  FAKE_LABELS=bug trkn "$tmp/gh" label 12 --remove gone
  expect_rc "a --remove of a label the repo lacks" 0 "$rc"
  reject_in "$log" "a --remove label was created before being removed" "label|create|gone"
  trkn "$tmp/gh" label 12; expect_rc "label with nothing to change" 3 "$rc"
  trkn "$tmp/gh" label 12 --remove -x; expect_rc "a --remove label starting with -" 3 "$rc"
  [ -z "$log" ] || selftest_fail "a --remove label starting with - still reached gh: $log"
  trkn "$tmp/ado" label 12 --add x; expect_rc "label on ADO" 3 "$rc"
  expect_in "$out" "label on ADO did not name the System.Tags update" "System.Tags="
  [ -z "$log" ] || selftest_fail "label on ADO still called az: $log"
}
row_html() {
  out=$(PATH="$tmp/nobin" PYTHONPATH="$tmp/fakemd" python3 "${TRACKER_MUT:-$TRACKER}" html "$tmp/body.md" "$tmp/md.html" 2>&1); rc=$?
  expect_rc "html through the python markdown fallback" 0 "$rc"
  expect_in "$(cat "$tmp/md.html" 2>/dev/null)" "the markdown fallback did not convert" "<p>MD:# Body"
}
row_help() {
  trkn "$tmp/ado" create --help
  expect_rc "create --help" 0 "$rc"
  expect_in "$out" "create --help printed no usage" "Usage: tracker.py"
  trkn "$tmp/ado" update -h
  expect_rc "update -h" 0 "$rc"
}
row_ids() {
  trk "$tmp/gh" create --type Story --title x --body "$tmp/body.md" --parent '1/../../user/repos'
  expect_rc "a path in --parent" 3 "$rc"
  [ -z "$log" ] || selftest_fail "a non-numeric --parent still called gh: $log"
  trkn "$tmp/gh" link --parent 1 --child -5; expect_rc "a non-numeric --child" 3 "$rc"
  trkn "$tmp/gh" block --blocked 5 --blocker abc; expect_rc "a non-numeric --blocker" 3 "$rc"
  trkn "$tmp/gh" block --blocked x --blocker 6; expect_rc "a non-numeric --blocked" 3 "$rc"
  trkn "$tmp/gh" show -5; expect_rc "a non-numeric show ID" 3 "$rc"
  trk "$tmp/gh" update --x; expect_rc "an option-shaped update ID" 3 "$rc"
  trk "$tmp/gh" update 1x --body "$tmp/body.md"; expect_rc "a non-numeric update ID" 3 "$rc"
  trkn "$tmp/gh" comment 12abc --body "$tmp/body.md"; expect_rc "a non-numeric comment ID" 3 "$rc"
  [ -z "$log" ] || selftest_fail "a non-numeric ID still called the tracker: $log"
}
row_label_dash() {
  trk "$tmp/gh" create --type Story --title x --body "$tmp/body.md" --label -x
  expect_rc "a label starting with -" 3 "$rc"
  [ -z "$log" ] || selftest_fail "a label starting with - still reached gh: $log"
}
row_ado_at() {
  trk "$tmp/ado" create --type Task --title "@$tmp/body.md" --no-prefix --body "$tmp/body.md"
  expect_rc "an ADO create title starting with @" 3 "$rc"
  [ -z "$log" ] || selftest_fail "an @ title still reached az create: $log"
  trk "$tmp/ado" create --type "@$tmp/body.md" --title x --body "$tmp/body.md"
  expect_rc "an ADO create --type starting with @" 3 "$rc"
  trk "$tmp/ado" update 12 --title "@$tmp/body.md" --no-prefix
  expect_rc "an ADO update title starting with @" 3 "$rc"
  trkn "$tmp/ado" close 12 --state "@$tmp/body.md"
  expect_rc "an ADO close --state starting with @" 3 "$rc"
  trkn "$tmp/ado" assign 12 --to @me
  expect_rc "an ADO assign --to starting with @" 3 "$rc"
  [ -z "$log" ] || selftest_fail "an @ value still reached az: $log"
}
row_field_ref() {
  trk "$tmp/ado" create --type Task --title x --field "-x=1"
  expect_rc "a field reference starting with -" 3 "$rc"
  [ -z "$log" ] || selftest_fail "a field reference starting with - still reached az: $log"
}
row_usage() {
  trkn "$tmp/ado" bogus; expect_rc "an unknown command" 3 "$rc"
  trkn "$tmp/ado" update; expect_rc "update with no ID" 3 "$rc"
  trkn "$tmp/ado" show 12 13; expect_rc "show with two IDs" 3 "$rc"
  trkn "$tmp/ado" search --terms x extra; expect_rc "search with a positional" 3 "$rc"
  trkn "$tmp/ado" create --type Task; expect_rc "create with no --title" 3 "$rc"
  trkn "$tmp/ado" create --type; expect_rc "an option with no value" 3 "$rc"
  rm -rf "$tmp/noaz"
  out=$(cd "$tmp/ado" && PATH="$tmp/nobin" PYTHONPATH="$tmp/fakemd" python3 "${TRACKER_MUT:-$TRACKER}" \
        create --type Task --title x --body "$tmp/body.md" --workdir "$tmp/noaz" 2>&1); rc=$?
  expect_rc "no az on PATH" 4 "$rc"
  expect_in "$out" "no az on PATH is not named" "not on PATH, nothing ran: az"
  [ ! -e "$tmp/noaz" ] || selftest_fail "no az on PATH still converted the body into $tmp/noaz"
  out=$(cd "$tmp/ado" && FAKE_LOG="$tmp/log" FAKE_STATE="$tmp/state.json" PATH="$tmp/nobin:$(dirname "$(command -v bash)")" \
        PYTHONPATH="$tmp/nomd" python3 "${TRACKER_MUT:-$TRACKER}" html "$tmp/body.md" "$tmp/out.html" 2>&1); rc=$?
  expect_rc "no Markdown converter" 4 "$rc"
}

rows=(row_resolve row_heading row_subheading row_prose row_two_trackers row_project row_badrepo
      row_badorg row_noblock row_tags_block row_tags row_debt row_prefix row_update_prefix
      row_prefix_idem row_gh_create row_gh_labels row_gh_label_exists row_dry_labels row_dbid
      row_gh_field row_gh_fail row_empty row_ado_create row_keys row_workdir row_state row_convert
      row_tagdeny row_readback row_link_fail row_update row_update_readback row_gh_update
      row_ado_fail row_dry row_search row_search_scope row_gh_search row_gh_repo row_misc
      row_comment_body row_close row_assign row_label row_html row_help row_ids row_label_dash row_ado_at row_field_ref row_usage)
for r in "${rows[@]}"; do "$r"; done

# --- mutation table ---------------------------------------------------------
m="$tmp/mut.py"
mutant() {  # <label> <row> <from> <to>
  selftest_mutate "$TRACKER" "$m" "$3" "$4" || return 0
  selftest_expect_killed --mutant TRACKER_MUT "$m" "$1" "$2"
}
mutant "Never tag filter dropped" row_tags 'if t and t not in never]' 'if t]'
mutant "debt tag dropped" row_debt 'tags.append("debt")' 'pass'
mutant "Feature prefix for every type" row_prefix 'if (item_type or "").lower() == "feature":' 'if True:'
mutant "read-back dropped" row_readback 'bad = [r for r in rich if' 'bad = [r for r in [] if'
mutant "tag-refusal retry dropped" row_tagdeny 'if rc != 0 and tags and re.search' 'if False and re.search'
mutant "apply-tags built with --project" row_tagdeny '"System.Tags=" + tags] + self.org())' '"System.Tags=" + tags] + self.scope())'
mutant ".md conversion dropped" row_convert 'if path.endswith(".md"):' 'if False:'
mutant "empty-file stop dropped" row_empty 'os.path.getsize(path) == 0' 'False'
mutant "WIQL quote doubling dropped" row_search "t.replace(\"'\", \"''\")" 't'
mutant "WIQL project scope dropped" row_search_scope 'WHERE [System.TeamProject] = @project AND (%s)' 'WHERE (%s)'
mutant "Done and Resolved count as open" row_search_scope '("Closed", "Removed", "Done", "Resolved")' '("Closed", "Removed")'
mutant "GitHub search ANDs the terms" row_gh_search '" OR ".join(terms)' '" ".join(terms)'
mutant "GitHub search limit dropped" row_gh_search '"--limit", "100", ' ''
mutant "a tab in a title kept" row_gh_search 're.sub(r"[\t\r\n]+", " ", str(value))' 'str(value)'
mutant "label precheck dropped" row_gh_labels '        if label not in have:' '        if False:'
mutant "an existing label re-created" row_gh_label_exists '        if label not in have:' '        if True:'
mutant "dry-run label create forced" row_dry_labels 'run(["gh", "label", "create", label])  # no --force' 'run(["gh", "label", "create", label, "--force"])'
mutant "block runs past the next heading" row_heading 'if inside and re.match(r"^#{1,6}\s", line):' 'if False:'
mutant "block runs past a ### heading" row_subheading 'r"^#{1,6}\s"' 'r"^#{1,2}\s"'
mutant "prose read as a field" row_prose '                if key not in KNOWN_KEYS:' '                if False:'
mutant "two trackers guessed" row_two_trackers 'if len(trackers) > 1 or names_both:' 'if False:'
mutant "child number for its database id" row_gh_create '"sub_issue_id=%s" % dbid' '"sub_issue_id=%s" % child'
mutant "the database-id lookup returns the number" row_dbid '        return dbid' '        return number'
mutant "Repo: not passed to gh" row_gh_repo 'dict(os.environ, GH_REPO=fields["repo"]) if' 'None if'
mutant "Repo: not validated" row_badrepo 'not REPO_FORM.match(fields["repo"])' 'False'
mutant "Organization: not validated" row_badorg 'not (ORG_NAME.match(org) or ORG_URL.match(org))' 'False'
mutant "ADO Project: not required" row_project 'if kind == "ado" and not fields.get("project"):' 'if False:'
mutant "a missing block exits 1" row_noblock 'TrackerError(2, "no `## Issue tracker` block' 'TrackerError(1, "no `## Issue tracker` block'
mutant "tags reads the block without declared()" row_tags_block \
  '    _, fields = declared(find_root(o["root"]))
    print(derive_tags(' '    _, fields, _, _ = read_block(find_root(o["root"]))
    print(derive_tags('
mutant "GitHub create drops --field" row_gh_field '        no_fields(o)
        if not o["body"]:' '        if not o["body"]:'
mutant "update read-back dropped" row_update_readback \
  '        return ["readback:" + r for r in self.read_back(item_id, rich)]' '        return []'
mutant "update drops its --field list" row_update '        if flist:
            flags += ["--fields"] + flist' '        if False:
            flags += ["--fields"] + flist'
mutant "update --title unprefixed" row_update_prefix '        title = prefixed(o["type"], o["title"], fields, o["no-prefix"])' '        title = o["title"]'
mutant "update --title needs no --type" row_update_prefix 'and title_prefix("feature", fields) != title_prefix("", fields)):' 'and False):'
mutant "prefix applied twice" row_prefix_idem 'if not prefix or title.startswith(prefix):' 'if not prefix:'
mutant "link failure ignored" row_link_fail '        return False
    print("linked=' '        pass
    print("linked='
mutant "written-but-incomplete exits 1" row_readback 'EXIT_INCOMPLETE = 5' 'EXIT_INCOMPLETE = 1'
mutant "url= printed only when known" row_keys '        print("url=" + self.url(item_id))' '        pass'
mutant "tags-not-applied= printed only on a refusal" row_keys '        print("tags-not-applied=" + (tags if untagged else ""))' '        pass'
mutant "a predictable workdir" row_workdir 'tempfile.mkdtemp(prefix="tracker-")' 'tempfile.gettempdir()'
mutant "comment ignores --body" row_comment_body 'body_opt = o["body"] or o["body-file"]' 'body_opt = o["body-file"]'
mutant "markdown fallback skipped" row_html 'out.write(markdown.markdown(fh.read()))' 'out.write(fh.read())'
mutant "per-command --help is a usage error" row_help '        if a in ("-h", "--help"):' '        if False:'
mutant "IDs not checked as numeric" row_ids '    if not re.match(r"^\d+$", value or ""):' '    if False:'
mutant "a label starting with - passed" row_label_dash '        if label.startswith("-"):
            raise UsageError(' '        if False:
            raise UsageError('
mutant "not_planned sent unspelled" row_close 'o["reason"].replace("_", " ")' 'o["reason"]'
mutant "an ADO close guesses no state" row_close '        if not o["state"]:' '        if False:'
mutant "a GitHub close takes --state" row_close '        if o["state"]:
            raise UsageError("--state is Azure DevOps only' '        if False:
            raise UsageError("--state is Azure DevOps only'
mutant "an ADO assign by --fields" row_assign '["--assigned-to", at_free(user, "--to")]' '["--fields", "System.AssignedTo=" + user]'
mutant "a missing --add label not created" row_label '        self.ensure_labels(add)' '        pass'
mutant "a --remove label created first" row_label '        self.ensure_labels(add)' '        self.ensure_labels(add + remove)'
mutant "an ADO close and assign drop --org" row_close '        call(["az", "boards", "work-item", "update", "--id", item_id] + flags
             + self.org()' '        call(["az", "boards", "work-item", "update", "--id", item_id] + flags
             + []'
mutant "an ADO assign drops --org" row_assign '        call(["az", "boards", "work-item", "update", "--id", item_id] + flags
             + self.org()' '        call(["az", "boards", "work-item", "update", "--id", item_id] + flags
             + []'
mutant "an ADO assign sends --project" row_assign '["--assigned-to", at_free(user, "--to")]' '["--assigned-to", at_free(user, "--to")] + ["--project", "Proj X"]'
mutant "a --to starting with - passed" row_assign '    if o["to"].startswith("-"):' '    if False:'
mutant "an @ value passed to az" row_ado_at '    if value and value.startswith("@"):' '    if False:'
mutant "a --remove label starting with - passed" row_label 'dash_free(o["remove"])' 'o["remove"]'
mutant "positional count unchecked" row_usage '    if len(pos) != spec.count:' '    if False:'
mutant "a missing CLI caught only after the body is converted" row_usage '    need(CLIS[kind])' '    pass'
mutant "a field reference starting with - passed" row_field_ref '    if not FIELD_REF.match(ref):' '    if False:'

selftest_close \
  "tracker self-test clean — resolve and the block's end, prose, keys and two-tracker refusal, Repo: and Organization: forms, a missing block's exit 2, tags, title prefix on create and update, GitHub and ADO create with labels, Repo:, conversion, one --fields list, read-back, tag-refusal retry, parent link and the written-but-incomplete exit 5, update, search on both trackers, block, comment, show, close, assign, label, az @file refusal, html, help, ID and option checks, usage and never-ran rows pass, and every mutant in the table went red." \
  "tracker self-test: a row was skipped; see the SKIP line above."
