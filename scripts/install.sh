#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
TARGET_DIR="${HOME}/.claude/skills"
GLOBAL_DIR="$(cd "$(dirname "$0")/../global" && pwd)"
RULES_TARGET="${HOME}/.claude/rules"
mkdir -p "$TARGET_DIR"

# Read a skill's declared behavior dependencies from its frontmatter `requires:`
# line (comma-separated skill names). ADR-0016: an orchestrator's portable unit
# is the skill plus the model-invoked behaviors it declares, so linking a skill
# links those behaviors too — a behavior reached by prose invocation only works
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

# Prune stale links: a symlink we own (its target points under this repo's
# src/) whose target no longer exists — left behind when a skill is renamed or
# removed. Scoped to repo-owned dangling links so it can never touch a real
# directory or a symlink pointing at some other source (e.g. find-skills ->
# .agents/skills/). A rename needs no special handling: the old name dangles
# (pruned here) and the new name is missing (linked below).
prune_stale() {
  for link in "$TARGET_DIR"/*; do
    [ -L "$link" ] || continue          # symlinks only; skip real dirs/files
    [ -e "$link" ] && continue          # target resolves → still valid, keep
    target="$(readlink "$link")"
    case "$target" in
      "$SKILLS_DIR"/*)                  # dangling AND points into our src/
        rm "$link"
        echo "prune $(basename "$link") (stale: $target no longer exists)"
        ;;
    esac
  done
}

link_skill() {
  name="$1"
  skill="$SKILLS_DIR/$name"
  target="$TARGET_DIR/$name"
  if [ ! -d "$skill" ]; then
    echo "WARN  $name — declared dependency has no src/$name, skipping"
    return
  fi
  if [ -L "$target" ]; then
    echo "skip  $name (already linked)"
  elif [ -e "$target" ]; then
    echo "WARN  $name — $target exists but is not a symlink, skipping"
  else
    ln -s "$skill" "$target"
    echo "link  $name"
  fi
  # Resolve declared behavior dependencies. Only descend into deps that aren't
  # already present, which also guards against cycles.
  for dep in $(read_requires "$skill"); do
    if [ ! -L "$TARGET_DIR/$dep" ] && [ ! -e "$TARGET_DIR/$dep" ]; then
      echo "dep   $name -> $dep"
      link_skill "$dep"
    fi
  done
}

prune_stale

for skill in "$SKILLS_DIR"/*/; do
  link_skill "$(basename "$skill")"
done

# Global rules (ADR-0053): link global/rules/*.md into ~/.claude/rules/, where
# Claude Code loads them on every turn with no skill in force. Additive — a
# link or file already there that does not point into this repo's global/ is
# left alone, and ~/.claude/CLAUDE.md is never touched. Prune is scoped the
# same way as prune_stale above: only dangling links into our global/.
link_rules() {
  mkdir -p "$RULES_TARGET"
  for link in "$RULES_TARGET"/*; do
    [ -L "$link" ] || continue
    [ -e "$link" ] && continue
    case "$(readlink "$link")" in
      "$GLOBAL_DIR"/*)
        rm "$link"
        echo "prune rule $(basename "$link") (stale: target no longer exists)"
        ;;
    esac
  done
  for rule in "$GLOBAL_DIR"/rules/*.md; do
    name="$(basename "$rule")"
    target="$RULES_TARGET/$name"
    if [ -L "$target" ]; then
      echo "skip  rule $name (already linked)"
    elif [ -e "$target" ]; then
      echo "WARN  rule $name — $target exists but is not a symlink, skipping"
    else
      ln -s "$rule" "$target"
      echo "link  rule $name"
    fi
  done
}

link_rules

# Hooks are wired in ~/.claude/settings.json, which this script never edits:
# an installer that rewrites the harness config leaves the user with a
# settings file they no longer know the contents of. Print the block; the
# user pastes it. Once settings.json names the hook, stay quiet — the
# post-merge hook (ADR-0049) re-runs this script on every merge.
SETTINGS="${HOME}/.claude/settings.json"
if [ -f "$SETTINGS" ] && grep -q 'rename-safety.sh' "$SETTINGS"; then
  echo "hook  rename-safety already named in $SETTINGS"
  exit 0
fi
HOOK_PATH="$(printf '%s' "$GLOBAL_DIR/hooks/rename-safety.sh" | sed 's/[\\"]/\\&/g')"
cat <<SNIPPET

Hook snippet — paste this into ~/.claude/settings.json under "hooks" (not applied automatically):
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash $HOOK_PATH" }
        ]
      }
    ]
  }
}
Then opt a directory in with:  touch .claude/rename-safety   (at that repo's root)
SNIPPET
