#!/bin/bash
# Enumerate skills/commands/plugins under a lib dir, one TSV line per entry: source<TAB>relpath<TAB>name<TAB>description. Usage: enum.sh [lib-dir] [skip-regex]
export LC_ALL=en_US.UTF-8
LIB="${1:-$HOME/code/lib}"
SKIP="${2:-^_rounds}"   # regex of directory names to skip (pass sources already reported)
UNPARSED_F="$(mktemp)" || { echo "enum.sh: mktemp failed; cannot track unparsed entries" >&2; exit 3; }
trap 'rm -f "$UNPARSED_F"' EXIT   # entries desc_of could not parse; counted to stderr at exit (ADR-0075: the enumerator reports its own blind spot)
SKILL_PRUNE=( -name node_modules -o -name .git -o -name docs )   # docs/<lang>/ holds translated copies of the same skills
CMD_PRUNE=( "${SKILL_PRUNE[@]}" -o -name references -o -name reference -o -name examples -o -name templates -o -name assets -o -name scripts )
desc_of() { # print description from frontmatter, else first heading, else first nonblank body line; CRLF-safe, UTF-8-safe
  local f="$1" d
  d=$(tr -d '\r' < "$f" | awk 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1{print}' | awk '
    /^description:[[:space:]]*([>|][^[:space:]#]*)?[[:space:]]*(#.*)?$/ {m=1; next}
    /^description:/ {sub(/^description:[[:space:]]*/,""); print; exit}
    m && /^[[:space:]]+/ {sub(/^[[:space:]]+/,""); printf "%s ", $0; next}
    m && /^[[:space:]]*$/ {next}
    m {exit}')
  if [ -z "$d" ]; then d=$(tr -d '\r' < "$f" | grep -m1 -E '^#' | sed 's/^#* *//'); fi
  if [ -z "$d" ]; then d=$(tr -d '\r' < "$f" | awk 'NR==1&&$0=="---"{fm=1; next} fm&&$0=="---"{fm=0; next} fm{next} /^[[:space:]]*$/{next} {print; exit}'); fi
  printf '%s' "$d" | sed -e 's/[[:space:]]*$//' -e 's/\\"/"/g' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/" | tr '\t' ' ' | cut -c1-300 | iconv -c -f UTF-8 -t UTF-8
}
for src in "$LIB"/*/; do
  s=$(basename "$src"); [[ "$s" =~ $SKIP ]] && continue
  {
    find "$src" \( "${SKILL_PRUNE[@]}" \) -prune -o -type f -iname 'SKILL.md' -print
    find "$src" \( "${CMD_PRUNE[@]}" \) -prune -o -type f -name '*.md' ! -iname 'README.md' ! -iname 'SKILL.md' \
      \( -path '*/commands/*' -o -path '*/agents/*' -o -path '*/plugins/*' -o -path '*/.codex/*' -o -path '*/prompts/*' \) -print
  } | sort -u | while read -r f; do
    rel=${f#"$src"}
    case "$(basename "$f" | tr A-Z a-z)" in
      skill.md) name=$(basename "$(dirname "$f")");;
      *) name=$(basename "$f" .md);;
    esac
    d="$(desc_of "$f")"
    [ -n "$d" ] || printf '%s\n' "$f" >> "$UNPARSED_F"
    printf '%s\t%s\t%s\t%s\n' "$s" "$rel" "$name" "$d"
  done
done
UNPARSED_N=$(wc -l < "$UNPARSED_F" | tr -d ' ')
echo "enum.sh: $UNPARSED_N entries with no parsable description" >&2
# 2 is the taxonomy's "not everything checked": rows went out with an empty description field.
[ "$UNPARSED_N" -eq 0 ] || exit 2
