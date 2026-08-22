#!/bin/bash
# Enumerate skills/commands/plugins under a lib dir, one TSV line per entry: source<TAB>relpath<TAB>name<TAB>description. Usage: enum.sh [lib-dir] [skip-regex]
LIB="${1:-$HOME/code/lib}"
SKIP="${2:-^_rounds}"   # regex of directory names to skip (pass sources already reported)
desc_of() { # print description from frontmatter, else first heading, else first nonblank line
  local f="$1" d
  d=$(awk 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1{print}' "$f" | awk '
    /^description:[[:space:]]*[>|]?[[:space:]]*$/ {m=1; next}
    /^description:/ {sub(/^description:[[:space:]]*/,""); print; exit}
    m && /^[[:space:]]+/ {sub(/^[[:space:]]+/,""); printf "%s ", $0; next}
    m {exit}' | head -c 300)
  if [ -z "$d" ]; then d=$(grep -m1 -E '^#' "$f" | sed 's/^#* *//' | head -c 200); fi
  if [ -z "$d" ]; then d=$(grep -m1 -vE '^\s*$|^---' "$f" | head -c 200); fi
  printf '%s' "$d" | tr -d '"\r' | tr '\t' ' '
}
for src in "$LIB"/*/; do
  s=$(basename "$src"); [[ "$s" =~ $SKIP ]] && continue
  {
    find "$src" -type f \( -iname 'SKILL.md' -o -iname 'skill.md' \) -not -path '*/node_modules/*' -not -path '*/.git/*'
    find "$src" -type f -name '*.md' -not -path '*/node_modules/*' -not -path '*/.git/*' \
      \( -path '*/commands/*' -o -path '*/.claude/commands/*' -o -path '*/agents/*' -o -path '*/plugins/*' -o -path '*/.codex/*' -o -path '*/prompts/*' \) \
      -not -iname 'README.md' -not -iname 'SKILL.md' -not -path '*/references/*' -not -path '*/reference/*' -not -path '*/docs/*' -not -path '*/examples/*' -not -path '*/templates/*' -not -path '*/assets/*' -not -path '*/scripts/*'
  } | sort -u | while read -r f; do
    rel=${f#$src}
    case "$(basename "$f" | tr A-Z a-z)" in
      skill.md) name=$(basename "$(dirname "$f")");;
      *) name=$(basename "$f" .md);;
    esac
    printf '%s\t%s\t%s\t%s\n' "$s" "$rel" "$name" "$(desc_of "$f")"
  done
done
