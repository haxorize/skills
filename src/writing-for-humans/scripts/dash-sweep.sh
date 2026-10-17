#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# dash-sweep.sh <draft-file> - the outbound dash sweep over one draft drafted as
# the user (global/rules/outbound-dash-sweep.md owns the gate;
# references/outbound-as-the-user.md § The dash sweep says what it finds). One
# command, so a sandbox that refuses $(...), && and ; still runs it.
#
# The sed masks inline code spans and URLs (keeping the query string, where
# tracking residue lives), then reduces a markdown link `[Text](target)` to its
# text; the grep finds an em dash, a double hyphen with a space or no-break
# space on each side, an en dash not between digits (one opening a line counts,
# even before a digit), tool residue (utm_source=, oaicite, turn0search, a
# bracketed placeholder such as [Your Name]), and a zero-width space. A
# parenthetical is a link target only when it holds no space (bar a quoted
# title after one) and is empty or opens on `#` or `?` (a URL the mask cut) or
# holds a `.`, `/`, `:` or `@` (`[The guide](guide.md)`, `[Contact
# Us](mailto:a@b.c)`, `[Docs](https://x.y "Title")`). So `[Insert
# Date](optional)`, `Hi [Your Name](e.g. Jane)` and `On [Insert
# Date](optional: weekday)` still hit, and so does `[Your Name][1]` mid-line.
# A `[Name]:` is a reference definition only with nothing but spaces or tabs
# before it on its line; `Dear [Name]: hello` hits. The no-break space, tab and
# zero-width space are written as byte escapes so BSD grep matches them too.
# This line is the one copy of the pipeline: edit it here, never retype it
# elsewhere, and run dash-sweep-selftest.sh after.
#
# Output: each hit as <line>:<text>, nothing when clean.
# Exit: 0 clean, 1 at least one hit, 3 usage error, 4 the sweep itself failed
# (sed or grep errored), so the draft was not checked.
set -uo pipefail

usage() {
  echo "usage: dash-sweep.sh <draft-file>"
  echo "  prints each hit as <line>:<text>; prints nothing when the draft is clean"
  echo "  exit: 0 clean, 1 hits, 3 usage error, 4 the sweep did not run"
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac
if [ "$#" -ne 1 ]; then usage >&2; exit 3; fi
case "$1" in
  -*) echo "dash-sweep.sh: unknown option: $1 (a file named so: pass ./$1)" >&2; exit 3 ;;
esac
if [ ! -f "$1" ] || [ ! -r "$1" ]; then
  echo "dash-sweep.sh: not a readable file: $1" >&2
  exit 3
fi

sed -E -e 's/`[^`]*`//g' -e 's#https?://[^ )>?]*##g' -e 's%\[([^]]*)\]\(([#?][^ )]*|[^ )]*[./:@][^ )]*)?( +"[^"]*")?\)%\1%g' "$1" | grep -nE '—|( |'$'\xc2\xa0'')--( |'$'\xc2\xa0'')|^–|[^0-9]–|–[^0-9]|–$|utm_source=|oaicite|turn0search|\[[A-Z][A-Za-z ]*\]([^:]|$)|[^ '$'\t''][ '$'\t'']*\[[A-Z][A-Za-z ]*\]:|'$'\xe2\x80\x8b'

status=("${PIPESTATUS[@]}")
if [ "${status[0]}" -ne 0 ]; then
  echo "dash-sweep.sh: sed exited ${status[0]}; the draft was not checked" >&2
  exit 4
fi
case "${status[1]}" in
  0) exit 1 ;;
  1) exit 0 ;;
  *) echo "dash-sweep.sh: grep exited ${status[1]}; the draft was not checked" >&2; exit 4 ;;
esac
