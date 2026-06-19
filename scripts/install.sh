#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
TARGET_DIR="${HOME}/.claude/skills"
mkdir -p "$TARGET_DIR"

for skill in "$SKILLS_DIR"/*/; do
  name="$(basename "$skill")"
  target="$TARGET_DIR/$name"
  if [ -L "$target" ]; then
    echo "skip  $name (already linked)"
  elif [ -e "$target" ]; then
    echo "WARN  $name — $target exists but is not a symlink, skipping"
  else
    ln -s "$skill" "$target"
    echo "link  $name"
  fi
done
