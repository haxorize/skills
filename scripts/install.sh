#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
TARGET_DIR="${HOME}/.claude/skills"
mkdir -p "$TARGET_DIR"

# Read a skill's declared behavior dependencies from its frontmatter `requires:`
# line (comma-separated skill names). ADR-0016: an orchestrator's portable unit
# is the skill plus the model-invoked behaviors it declares, so linking a skill
# links those behaviors too — a behavior reached by prose invocation only works
# if it is also installed.
read_requires() {
  awk '
    /^---$/ { c++; next }
    c == 1 && /^requires:[[:space:]]/ {
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
