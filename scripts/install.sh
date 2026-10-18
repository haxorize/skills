#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
GLOBAL_DIR="$(cd "$(dirname "$0")/../global" && pwd)"
# Every path this script WRITES to hangs off one root, and that root is an
# explicit input. It is the only seam that makes this script safe to run for
# real in a test: prune_owned calls `rm` under it, and
# scripts/install-selftest.sh runs the real installer with TARGET_ROOT pointed
# at a throwaway directory. Derived from $HOME rather than declared, the seam
# was a property the selftest asserted about this file rather than an interface
# this file offers — so an edit here to an XDG path, a literal `~`, or a second
# ${HOME} expansion would leave the selftest green while its `rm` loops ran
# against the user's real ~/.claude/skills. SKILLS_DIR and GLOBAL_DIR come from
# this script's own path and are read-only; they are deliberately NOT under it.
TARGET_ROOT="${TARGET_ROOT:-$HOME}"
TARGET_DIR="${TARGET_ROOT}/.claude/skills"
RULES_TARGET="${TARGET_ROOT}/.claude/rules"

# Opt-in skills (ADR-0114): never linked into ~/.claude/skills, so
# their descriptions cost nothing in a repo that does not use them. A repo
# opts in with a `Shared skills: a, b` line in its CLAUDE.md, and
# `install.sh --project <repo>` links those names into <repo>/.claude/skills/
# and lists each link in the repo's .git/info/exclude. An opt-in skill's
# `requires:` may name a global skill; a global skill's may not name an opt-in
# one, since outside the opted-in repos nothing would satisfy it.
# The line below is read by more than this file, each with its own parser, so
# its shape is a contract: ONE line, `opt_in_skills="a b c"`, double-quoted,
# space-separated, nothing after the closing quote (no trailing comment). The
# readers: scripts/lint-skills.sh (check_requires_resolve, `head -1`, and its
# own copy of is_opt_in, name_is_opt_in), scripts/install-selftest.sh (a sed
# anchored on both quotes), and src/audit-skills/SKILL.md, which a model reads
# by hand. A second definition line, or a wrapped one, splits those readers.
opt_in_skills="accessible-ui aeo audit-aeo health-literacy phi-safe-code product-description rebuild-contract respond-to-incident roll-out"
is_opt_in() {
  case " $opt_in_skills " in *" $1 "*) return 0 ;; esac
  return 1
}

# --project <repo>: the repo-side install. TARGET_DIR moves into the repo and
# EXCLUDE names its exclude file; every other path stays as above, and the
# rules, settings keys and hooks below are never reached in this mode. EXCLUDE
# is also the mode switch: link_skill and exclude_one read it, empty for the
# global run and set for this one.
# The install is additive only. A name taken off the `Shared skills:` line,
# or off opt_in_skills, keeps its repo link and its exclude line: nothing here
# knows a name it no longer reads, and the post-merge hook re-runs only the
# global install, never this one. Remove both by hand (`rm` the link, delete
# the line from the exclude file); the link dangles harmlessly until then.
# Each refusal below exits 3 before anything is written, since every one is a
# repo shape where a write would land somewhere the user did not ask for.
EXCLUDE=""
case "${1:-}" in
  "") ;;
  --project)
    if [ $# -ne 2 ] || [ -z "$2" ]; then
      echo "usage: install.sh [--project <repo>]" >&2
      exit 3
    fi
    # CDPATH= and -- so a relative <repo> means the directory under cwd and a
    # <repo> of `-` is a name, not $OLDPWD; a CDPATH hit would also echo the
    # path, doubling it in PROJECT. -P because the comparisons below are
    # between physical paths.
    PROJECT="$(CDPATH= cd -- "$2" 2>/dev/null && pwd -P)" || { echo "ERROR $2 is not a directory" >&2; exit 3; }
    # The exclude line is a path from the work tree's root, and git anchors it
    # there: run on a subdirectory, the link would sit under <sub>/.claude while
    # the line named <root>/.claude, so the link would show in `git status`.
    top="$(git -C "$PROJECT" rev-parse --show-toplevel 2>/dev/null)" &&
      top="$(CDPATH= cd -- "$top" 2>/dev/null && pwd -P)" ||
      { echo "ERROR $PROJECT is not a git work tree — the links could not be kept out of its tracked files" >&2; exit 3; }
    if [ "$top" != "$PROJECT" ]; then
      echo "ERROR $PROJECT is not the root of its git work tree ($top) — run install.sh --project $top" >&2
      exit 3
    fi
    # git resolves the exclude file, so a worktree (whose .git is a file) and
    # a repo with a moved git dir both get the right one. No
    # --path-format=absolute: before git 2.31 that flag is echoed back as
    # output with exit 0, so the path is made absolute here instead, and a
    # result that is not one line is refused rather than appended to.
    EXCLUDE="$(git -C "$PROJECT" rev-parse --git-path info/exclude 2>/dev/null)" ||
      { echo "ERROR $PROJECT is not a git work tree — the links could not be kept out of its tracked files" >&2; exit 3; }
    case "$EXCLUDE" in
      "" | *$'\n'*) echo "ERROR git named no single exclude file for $PROJECT (got: $EXCLUDE)" >&2; exit 3 ;;
      /*) ;;
      *) EXCLUDE="$PROJECT/$EXCLUDE" ;;
    esac
    # A committed .claude or .claude/skills symlink would carry `mkdir -p` and
    # every `ln -s` below out of the repo, to wherever the commit points.
    for d in "$PROJECT/.claude" "$PROJECT/.claude/skills"; do
      if [ -L "$d" ]; then
        echo "ERROR $d is a symlink — refusing to write links through it" >&2
        exit 3
      fi
    done
    # The root CLAUDE.md first, then .claude/CLAUDE.md, the other place Claude
    # Code reads a project's instructions from. The key may be a bare line or a
    # markdown bullet (`- Shared skills: …`), since this repo writes its
    # contract keys as bullets; a CRLF file's `\r` is dropped with the commas.
    if [ ! -f "$PROJECT/CLAUDE.md" ] && [ ! -f "$PROJECT/.claude/CLAUDE.md" ]; then
      echo "ERROR $PROJECT has no CLAUDE.md — create one with a 'Shared skills:' line naming the opt-in skills this repo uses (one of: $opt_in_skills)" >&2
      exit 3
    fi
    shared="" shared_from=""
    for f in "$PROJECT/CLAUDE.md" "$PROJECT/.claude/CLAUDE.md"; do
      [ -f "$f" ] || continue
      shared="$(sed -n 's/^[[:space:]]*\([-*][[:space:]]\{1,\}\)\{0,1\}Shared skills:[[:space:]]*//p' "$f" | head -1 | tr ',\r' '  ')"
      [ -z "${shared//[[:space:]]/}" ] || { shared_from=$f; break; }
      shared=""
    done
    if [ -z "$shared" ]; then
      echo "ERROR $PROJECT's CLAUDE.md has no 'Shared skills:' line — add one naming the opt-in skills this repo uses (one of: $opt_in_skills)" >&2
      exit 3
    fi
    TARGET_DIR="$PROJECT/.claude/skills"
    ;;
  *)
    echo "usage: install.sh [--project <repo>]" >&2
    exit 3
    ;;
esac
mkdir -p "$TARGET_DIR"
# The symlink refusal above ran before mkdir; this re-reads what mkdir made, so
# a .claude swapped in between still cannot carry the links out of the repo.
if [ -n "$EXCLUDE" ] && [ "$(CDPATH= cd -- "$TARGET_DIR" && pwd -P)" != "$PROJECT/.claude/skills" ]; then
  echo "ERROR $TARGET_DIR resolves outside $PROJECT — refusing to link into it" >&2
  exit 3
fi

# Read a skill's declared discipline dependencies from its frontmatter `requires:`
# line (comma-separated skill names). ADR-0016: an orchestrator's portable unit
# is the skill plus the model-invoked disciplines it declares, so linking a skill
# links those disciplines too — a discipline reached by prose invocation only works
# if it is also installed.
read_requires() {
  awk '
    /^---$/ { c++; next }
    c == 1 && /^requires:/ {
      sub(/^requires:[[:space:]]*/, "")
      gsub(/,/, " ")
      print
      exit
    }
  ' "$1/SKILL.md"
}

# Prune stale links: a symlink we own (its target points under the owning
# prefix — this repo's src/ for skills, its global/ for rules) whose target no
# longer exists — left behind when a skill or rule is renamed or removed.
# Scoped to repo-owned dangling links so it can never touch a real directory
# or a symlink pointing at some other source (e.g. find-skills ->
# .agents/skills/). A rename needs no special handling: the old name dangles
# (pruned here) and the new name is missing (linked below). One function serves
# both targets. The `[ -L ] || continue` guard is load-bearing in one way — on
# a fresh install `mkdir -p` leaves the target empty, the unmatched glob comes
# back as the literal pattern, and `readlink` on it fails an ASSIGNMENT, which
# `set -e` reads as a reason to abort before a single link is made.
# prune_owned <target dir> <owning prefix> <label> — the label names the kind of
# thing being pruned and is printed, followed by a space, between "prune " and
# the name. Pass a bare word or nothing ("" or "rule"), never a word carrying
# its own trailing space: the print site supplies the separator, so a label of
# "rule " prints "prune rule  no-such-rule.md".
prune_owned() {
  local target_dir=$1 owned_prefix=$2 label=$3 link target
  # An empty owning prefix collapses the `case` arm below to `/*`, which matches
  # every dangling absolute symlink under the target — precisely the links this
  # function exists to leave alone. A caller that passes one has a bug, so this
  # aborts rather than quietly widening what `rm` reaches.
  if [ -z "$owned_prefix" ]; then
    echo "ERROR prune_owned called with no owning prefix for $target_dir — refusing to prune" >&2
    exit 1
  fi
  for link in "$target_dir"/*; do
    [ -L "$link" ] || continue          # symlinks only; skip real dirs/files
    [ -e "$link" ] && continue          # target resolves → still valid, keep
    target="$(readlink "$link")"
    case "$target" in
      "$owned_prefix"/*)                # dangling AND points into what we own
        rm "$link"
        echo "prune ${label:+$label }$(basename "$link") (stale: $target no longer exists)"
        ;;
    esac
  done
}

# link_one <source> <target> <label> <what this checkout calls the source>
# The four outcomes at one name, shared by the skill loop and the rule loop
# below, which differed only in the label and in that last phrase. A symlink
# already at the name is left alone either way, and the message says which way:
# "already linked" is a claim about THIS checkout's copy, so a link pointing
# anywhere else is reported as what it is. Like prune_owned above, these
# messages are scoped to what this checkout owns. The label follows
# prune_owned's convention — a bare word or nothing, the space supplied here.
link_one() {
  local source=$1 target=$2 label=$3 owned_as=$4 shown
  shown="${label:+$label }$(basename "$target")"
  if [ -L "$target" ]; then
    if [ "$(readlink "$target")" = "$source" ]; then
      echo "skip  $shown (already linked)"
    else
      echo "skip  $shown (a symlink to $(readlink "$target"), not this checkout's $owned_as — left alone)"
    fi
  elif [ -e "$target" ]; then
    echo "WARN  $shown — $target exists but is not a symlink, skipping"
  else
    ln -s "$source" "$target"
    echo "link  $shown"
  fi
}

# Every loop and name in this file is `local`, and link_skill is why: it
# recurses at the dependency line below, and with `name`, `skill`, `target` and
# `dep` as globals the recursive call overwrote them, so the `dep` line of the
# CALLER's next iteration printed the deepest name the recursion reached — a
# skill requiring `B, C` where `B` requires `D` printed `dep D -> C`. The
# linking was right; the trace a user reads to see why an unasked-for skill is
# now in ~/.claude/skills/ was not. prune_owned and link_rules do not recurse
# today, and share `name` and `target` with this one — so they are `local` as
# well, rather than left as the reason the next call site reintroduces this.
# Scope comes from the global EXCLUDE: empty links into ~/.claude/skills and
# skips opt-in deps, set links into the repo and follows only opt-in ones.
link_skill() {
  local name skill target dep
  name="$1"
  # A name is a directory entry, never a path: the `requires:` line is repo
  # frontmatter, but a `..` or a slash in it would send `ln -s` outside
  # TARGET_DIR, and the -d test below cannot tell that apart from a real skill.
  case "$name" in
    */* | . | ..)
      echo "WARN  $name — dependency name is not a plain skill name, skipping"
      return
      ;;
  esac
  skill="$SKILLS_DIR/$name"
  target="$TARGET_DIR/$name"
  if [ ! -d "$skill" ]; then
    echo "WARN  $name — declared dependency has no src/$name, skipping"
    return
  fi
  link_one "$skill" "$target" "" "src/$name"
  # Only a link that is this checkout's goes in the exclude file: link_one
  # leaves a real directory or a foreign link at the name alone, and an
  # exclude line for one would hide the user's own files from `git status`.
  if [ -n "$EXCLUDE" ] && [ -L "$target" ] && [ "$(readlink "$target")" = "$skill" ]; then
    exclude_one "$name"
  fi
  # Resolve declared discipline dependencies. Only descend into deps that aren't
  # already present, which also guards against cycles. A dep crosses scope in
  # one direction only: in a repo, a global dep is already in ~/.claude/skills
  # and is not linked twice; globally, an opt-in dep is never linked.
  for dep in $(read_requires "$skill"); do
    if [ -n "$EXCLUDE" ] && ! is_opt_in "$dep"; then
      continue
    fi
    if [ -z "$EXCLUDE" ] && is_opt_in "$dep"; then
      echo "WARN  $name requires opt-in $dep, which is not linked globally — $name's requirement is unmet outside a repo naming $dep; scope $name too, or drop the edge"
      continue
    fi
    if [ ! -L "$TARGET_DIR/$dep" ] && [ ! -e "$TARGET_DIR/$dep" ]; then
      echo "dep   $name -> $dep"
      link_skill "$dep"
    fi
  done
}

# exclude_one <name> — keeps the repo-side link out of `git status` by its
# path from the repo root, written once however many runs reach it. Writes to
# the global EXCLUDE, the file the --project arm resolved; never called when
# it is empty. A last line with no newline gets one first, or the appended
# line would fuse with it and neither pattern would match.
exclude_one() {
  local line="/.claude/skills/$1"
  mkdir -p "$(dirname "$EXCLUDE")"
  if ! grep -qxF "$line" "$EXCLUDE" 2>/dev/null; then
    if [ -s "$EXCLUDE" ] && [ -n "$(tail -c1 "$EXCLUDE")" ]; then
      printf '\n' >> "$EXCLUDE"
    fi
    printf '%s\n' "$line" >> "$EXCLUDE"
    echo "exclude $line"
  fi
}

prune_owned "$TARGET_DIR" "$SKILLS_DIR" ""

# The Shared skills line is the repo's text, so its words are split with
# globbing off: a `*` on it would otherwise expand against the cwd and link
# whatever opt-in names happened to sit there. A trailing `/` is dropped, so
# `aeo/` is aeo rather than a path that passes -d and fails is_opt_in.
if [ -n "$EXCLUDE" ]; then
  set -f
  for name in $shared; do
    name="${name%/}"
    if [ ! -d "$SKILLS_DIR/$name" ]; then
      echo "WARN  $name — named in $shared_from's 'Shared skills:' line but src/$name does not exist, skipping"
    elif ! is_opt_in "$name"; then
      echo "skip  $name (installed globally, not per project)"
    else
      link_skill "$name"
    fi
  done
  set +f
  exit 0
fi

for name in $opt_in_skills; do
  [ -d "$SKILLS_DIR/$name" ] ||
    echo "WARN  $name — on install.sh's opt_in_skills list but src/$name is gone; drop it from the list"
done

# An opt-in skill's global link from before it was opt-in is removed, and only
# when it points at exactly this checkout's copy: a link into another checkout,
# or a real directory, is the user's.
for name in $opt_in_skills; do
  if [ -L "$TARGET_DIR/$name" ] && [ "$(readlink "$TARGET_DIR/$name")" = "$SKILLS_DIR/$name" ]; then
    rm "$TARGET_DIR/$name"
    echo "unlink $name (opt-in: install.sh --project <repo> links it into a repo whose CLAUDE.md names it)"
  fi
done

for skill in "$SKILLS_DIR"/*/; do
  name="$(basename "$skill")"
  is_opt_in "$name" || link_skill "$name"
done

# Global rules (ADR-0053): link global/rules/*.md into ~/.claude/rules/, where
# Claude Code loads them on every turn with no skill in force. Additive — a
# link or file already there that does not point into this repo's global/ is
# left alone, and ~/.claude/CLAUDE.md is never touched. Prune is prune_owned
# above, scoped to dangling links into our global/.
link_rules() {
  local name rule target
  mkdir -p "$RULES_TARGET"
  prune_owned "$RULES_TARGET" "$GLOBAL_DIR" rule
  for rule in "$GLOBAL_DIR"/rules/*.md; do
    name="$(basename "$rule")"
    target="$RULES_TARGET/$name"
    link_one "$rule" "$target" rule "global/rules/$name"
  done
}

link_rules

SETTINGS="${TARGET_ROOT}/.claude/settings.json"

# A wired hook whose script is gone. settings.json outlives the file it names:
# a hook deleted here (friction-log.sh, ADR-0113) stays wired on every machine
# until someone removes its entry, and the harness never says it ran nothing.
# Any path under a global/hooks/ is read, not only this checkout's, since the
# work machine's mirror sits at another path. A leading `~/` or `$HOME/` is
# expanded the way the harness's shell would, so a portable entry is not
# reported missing. A WARN only: the settings file stays the user's to edit.
# A false WARN here is worse than a missed one, since its advice touches a
# live safety hook, so the paths come out of the parsed JSON: every "command"
# string, split the way the shell would split it (quotes, spaces in a path, a
# trailing `;`). Without python3 a grep stands in that trims the JSON-escaped
# quote and a trailing `;`, and cannot follow a path holding a space. A path
# still carrying a `$` after HOME is expanded ($CLAUDE_PROJECT_DIR, say) is
# only known to the harness at run time, so it is not checked at all.
wired_hook_paths() {
  if command -v python3 >/dev/null 2>&1 && python3 -I - "$SETTINGS" <<'PY' 2>/dev/null; then return 0; fi
import json, shlex, sys
def commands(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if k == "command" and isinstance(v, str):
                yield v
            else:
                yield from commands(v)
    elif isinstance(o, list):
        for v in o:
            yield from commands(v)
with open(sys.argv[1]) as f:
    doc = json.load(f)
for cmd in commands(doc):
    try:
        words = shlex.split(cmd)
    except ValueError:
        words = cmd.split()
    for w in words:
        w = w.rstrip(";&|")
        if "global/hooks/" in w and "\n" not in w:
            print(w)
PY
  grep -o '[^"[:space:]]*global/hooks/[^"[:space:];\\]*' "$SETTINGS" || true
}
if [ -f "$SETTINGS" ]; then
  while IFS= read -r wired; do
    path="$wired"
    case "$path" in
      '~/'*) path="$HOME/${path#'~/'}" ;;
      '$HOME/'*) path="$HOME/${path#'$HOME/'}" ;;
      '${HOME}/'*) path="$HOME/${path#'${HOME}/'}" ;;
    esac
    case "$path" in *'$'*) continue ;; esac
    [ -e "$path" ] || echo "WARN  $SETTINGS wires $wired, which does not exist — check that hook entry: a mistyped path, or a hook this repo removed"
  done < <(wired_hook_paths | sort -u)
fi

# Settings keys this repo owns a value for, printed the way hooks are below
# and never written (ADR-0053). CLAUDE_CODE_SHELL: zsh reads the agent's
# `grep --include=…` as a glob and refuses it, and the empty result reads as
# "nothing found". The name-only skills: model-loaded only because another
# skill names them, so their descriptions cost every turn and start nothing;
# name-only keeps each callable by name. work-item-shape stays off the list
# (grill Q32). Quiet per key once settings.json carries it.
name_only_skills="feedback-loops writing-for-agents diverging doc-claims"
want_shell=1
if [ -f "$SETTINGS" ] && grep -Eq '"CLAUDE_CODE_SHELL"[[:space:]]*:[[:space:]]*"[^"]*/bash"' "$SETTINGS"; then
  echo "key   env.CLAUDE_CODE_SHELL already bash in $SETTINGS"
  want_shell=0
fi
want_skills=""
for s in $name_only_skills; do
  if [ ! -d "$SKILLS_DIR/$s" ]; then
    echo "WARN  $s — on install.sh's name-only list but src/$s is gone; drop it from the list"
  elif [ -f "$SETTINGS" ] && grep -Eq "\"$s\"[[:space:]]*:[[:space:]]*\"name-only\"" "$SETTINGS"; then
    echo "key   skillOverrides.$s already name-only in $SETTINGS"
  else
    want_skills="$want_skills $s"
  fi
done
if [ "$want_shell" = 1 ] || [ -n "$want_skills" ]; then
  cat <<SNIPPET

Settings keys — merge these into ~/.claude/settings.json (not applied automatically).
Keep any key already there; a managed env setting (/status) wins over this one.
SNIPPET
  keys=""
  if [ "$want_shell" = 1 ]; then
    keys='  "env": { "CLAUDE_CODE_SHELL": "/bin/bash" }'
  fi
  if [ -n "$want_skills" ]; then
    overrides=""
    for s in $want_skills; do
      if [ -n "$overrides" ]; then overrides="$overrides,
"; fi
      overrides="$overrides    \"$s\": \"name-only\""
    done
    block="  \"skillOverrides\": {
$overrides
  }"
    if [ -n "$keys" ]; then keys="$keys,
$block"; else keys="$block"; fi
  fi
  printf '{\n%s\n}\n' "$keys"
fi

# Hooks are wired in ~/.claude/settings.json, which this script never edits:
# an installer that rewrites the harness config leaves the user with a
# settings file they no longer know the contents of. Print the block; the
# user pastes it. Once settings.json names the hook, stay quiet — the
# post-merge hook (ADR-0049) re-runs this script on every merge.
# The roster is the directory: a hook is a hooks/*.sh whose header carries an
# `# Install note:` line (the libraries, selftests, and a hook's own scanner
# half — e.g. context-nudge.py — beside it carry none);
# that line is also its one-line install note. post-merge derives the same
# roster the same way. A hook's event is its `# Event:` header line, and a
# hook with none is a PreToolUse check on Bash; only PreToolUse entries take
# a matcher, so a Stop hook's entry is the bare hooks list.
# hook_event <hook name> — prints the event the hook's `# Event:` header names,
# or PreToolUse when it carries none. The value lands in a JSON key position
# in the snippet below, so it is checked against the harness's event names
# (https://code.claude.com/docs/en/hooks, read 2026-09-13): an unknown name
# would print a key the harness ignores, the hook would never fire, and every
# later run would still report it "already named" because that check greps
# for the path. Trailing whitespace on the header is trimmed first, so
# `# Event: Stop ` is Stop and not an unknown event. Called once per hook,
# below; the grouping loop reads the pair that call recorded.
hook_event() {
  local ev
  ev="$(grep -m1 '^# Event: ' "$GLOBAL_DIR/hooks/$1.sh" | sed -e 's/^# Event: //' -e 's/[[:space:]]*$//' || true)"
  ev="${ev:-PreToolUse}"
  case "$ev" in
    SessionStart | Setup | UserPromptSubmit | UserPromptExpansion | PreToolUse | \
    PermissionRequest | PermissionDenied | PostToolUse | PostToolUseFailure | \
    PostToolBatch | Notification | MessageDisplay | SubagentStart | SubagentStop | \
    TaskCreated | TaskCompleted | Stop | StopFailure | TeammateIdle | \
    InstructionsLoaded | ConfigChange | CwdChanged | DirectoryAdded | FileChanged | \
    WorktreeCreate | WorktreeRemove | PreCompact | PostCompact | PreModelSwitch | \
    PostModelSwitch | Elicitation | ElicitationResult | SessionEnd)
      ;;
    *)
      echo "WARN  $1 — '# Event: $ev' is not a hook event the harness knows; wiring it as PreToolUse" >&2
      ev=PreToolUse
      ;;
  esac
  printf '%s' "$ev"
}
hooks=""
for f in $(grep -l '^# Install note: ' "$GLOBAL_DIR"/hooks/*.sh); do
  hooks="$hooks $(basename "$f" .sh)"
done
missing=""
for hook in $hooks; do
  if [ -f "$SETTINGS" ] && grep -q "hooks/$hook.sh" "$SETTINGS"; then
    echo "hook  $hook already named in $SETTINGS"
  else
    missing="$missing $hook"
  fi
done
[ -n "$missing" ] || exit 0
cat <<SNIPPET

Hook snippet — paste this into ~/.claude/settings.json under "hooks" (not applied automatically).
The paths point at this checkout: a 'git pull' that edits global/hooks/ changes the live hook.
SNIPPET
# One JSON object for every missing hook: a settings file holds one object,
# so the entries are built first, grouped by event, and printed once. Each
# hook's event is resolved once here, as a `hook=event` pair, so the grouping
# loop below asks hook_event nothing and its WARN prints once.
events=""
hook_events=""
for hook in $missing; do
  ev="$(hook_event "$hook")"
  hook_events="$hook_events $hook=$ev"
  case " $events " in *" $ev "*) ;; *) events="$events $ev" ;; esac
done
blocks=""
for ev in $events; do
  entries=""
  for pair in $hook_events; do
    [ "${pair#*=}" = "$ev" ] || continue
    hook="${pair%%=*}"
    # The path is shell-quoted inside the JSON string (`bash \"<path>\"`), so
    # a checkout under a directory with a space still runs the hook.
    HOOK_PATH="$(printf '%s' "$GLOBAL_DIR/hooks/$hook.sh" | sed 's/[\\"]/\\&/g')"
    if [ "$ev" = PreToolUse ]; then
      entry="      {
        \"matcher\": \"Bash\",
        \"hooks\": [
          { \"type\": \"command\", \"command\": \"bash \\\"$HOOK_PATH\\\"\" }
        ]
      }"
    else
      entry="      {
        \"hooks\": [
          { \"type\": \"command\", \"command\": \"bash \\\"$HOOK_PATH\\\"\" }
        ]
      }"
    fi
    if [ -n "$entries" ]; then entries="$entries,
$entry"; else entries="$entry"; fi
  done
  # hook_event admits only bare names, so there is nothing to escape today;
  # the key is escaped anyway, the same way HOOK_PATH is, so the two do not
  # differ if the case above ever widens.
  ev_json="$(printf '%s' "$ev" | sed 's/[\\"]/\\&/g')"
  block="    \"$ev_json\": [
$entries
    ]"
  if [ -n "$blocks" ]; then blocks="$blocks,
$block"; else blocks="$block"; fi
done
cat <<SNIPPET
{
  "hooks": {
$blocks
  }
}
SNIPPET
for hook in $missing; do
  note="$(grep -m1 '^# Install note: ' "$GLOBAL_DIR/hooks/$hook.sh" | sed 's/^# Install note: //' || true)"
  echo "$hook: ${note:-see the header of global/hooks/$hook.sh}"
done
