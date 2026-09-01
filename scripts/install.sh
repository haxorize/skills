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
mkdir -p "$TARGET_DIR"

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
  # Resolve declared discipline dependencies. Only descend into deps that aren't
  # already present, which also guards against cycles.
  for dep in $(read_requires "$skill"); do
    if [ ! -L "$TARGET_DIR/$dep" ] && [ ! -e "$TARGET_DIR/$dep" ]; then
      echo "dep   $name -> $dep"
      link_skill "$dep"
    fi
  done
}

prune_owned "$TARGET_DIR" "$SKILLS_DIR" ""

for skill in "$SKILLS_DIR"/*/; do
  link_skill "$(basename "$skill")"
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

# Hooks are wired in ~/.claude/settings.json, which this script never edits:
# an installer that rewrites the harness config leaves the user with a
# settings file they no longer know the contents of. Print the block; the
# user pastes it. Once settings.json names the hook, stay quiet — the
# post-merge hook (ADR-0049) re-runs this script on every merge.
# The roster is the directory: a hook is a hooks/*.sh whose header carries an
# `# Install note:` line (the libraries and selftests beside it carry none);
# that line is also its one-line install note. post-merge derives the same
# roster the same way.
SETTINGS="${TARGET_ROOT}/.claude/settings.json"
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
# so the entries are built first and printed once.
entries=""
for hook in $missing; do
  HOOK_PATH="$(printf '%s' "$GLOBAL_DIR/hooks/$hook.sh" | sed 's/[\\"]/\\&/g')"
  entry="      {
        \"matcher\": \"Bash\",
        \"hooks\": [
          { \"type\": \"command\", \"command\": \"bash $HOOK_PATH\" }
        ]
      }"
  if [ -n "$entries" ]; then entries="$entries,
$entry"; else entries="$entry"; fi
done
cat <<SNIPPET
{
  "hooks": {
    "PreToolUse": [
$entries
    ]
  }
}
SNIPPET
for hook in $missing; do
  note="$(grep -m1 '^# Install note: ' "$GLOBAL_DIR/hooks/$hook.sh" | sed 's/^# Install note: //' || true)"
  echo "$hook: ${note:-see the header of global/hooks/$hook.sh}"
done
