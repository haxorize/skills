#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove .claude/skills/mine-skills/scripts/enum.sh still finds every entry a
# mining round counts on, and still describes each one the way the round reads.
#
# enum.sh is the first thing a mining round runs and the last thing anyone
# checks: its output is a TSV nobody diffs, so a description-gathering arm that
# silently stops matching costs the round a whole source class and looks like a
# quiet upstream. Three arms degrade invisibly — the frontmatter `description:`
# (plain, quoted, and block-scalar forms), the `#` heading fallback, and the
# first-nonblank-body fallback — and each falls back to the next, so a broken
# arm shows up as a *worse* description rather than an empty one. Every arm is
# graded on a row that the arm below it would answer differently.
#
# This builds a throwaway lib dir with one source per behavior and runs the
# real script against it. No network, no clone, no ~/code/lib.
#
# Covered here: the four find arms (SKILL.md at any depth; commands/, agents/,
# plugins/, .codex/ and prompts/ .md files) and the four prune arms
# (node_modules, .git, docs, and — for command-shaped files only — references,
# reference, examples, templates, assets, scripts, so a SKILL.md under
# references/ is still found while a command under it is not); README.md
# excluded; the skip regex (default `^_rounds` and a caller's own); the name
# rule (SKILL.md takes its directory's name, case-insensitively, everything
# else its own stem); the description arms in precedence order, block scalars
# (`>` and `|`, with and without a trailing comment), a `description:` whose
# value carries a colon, CRLF input, tab flattening, surrounding-quote
# stripping, the 300-character cut, the four-field TSV shape, and the stderr
# unparsable count, and the exit-status contract (2 when an entry went out with
# an empty description, 0 when none did). NOT covered: the UTF-8 iconv scrub (no fixture carries
# invalid bytes), and whether the real ~/code/lib parses — this grades the
# script, not the corpus.
#
# Thirteen mutations of enum.sh were run against this file on 2026-09-01 and
# all thirteen red. The thirteenth is the exit-0 half of the exit-status
# contract (an unconditional `exit 2`), added after the first twelve: its row
# had been written inside the temp-directory guard's failure branch, where it
# could never run, while this header and the close both claimed both sides
# were graded. The other twelve: the block-scalar arm dropped, references/
# pruned for skills as
# well as commands, the heading fallback dropped, the 300-character cut
# dropped, the unparsable tracking dropped, the tab flattening dropped, the
# skip regex ignored, the exit-status contract dropped, the SKILL.md name rule
# reading the file stem instead of its directory, the command path arms
# narrowed to commands/ alone, the README.md exclusion dropped, and the
# surrounding-quote strip dropped. That list's "exit-status contract dropped"
# was `exit 2` made `exit 0`, which reds the exit-2 row — which is why twelve
# mutations never reached the unreachable one.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../../.." && pwd)"
# shellcheck source=../../../../scripts/selftest-lib.sh
. "$repo_root/scripts/selftest-lib.sh"

enum="$repo_root/.claude/skills/mine-skills/scripts/enum.sh"
if ! tmp="$(selftest_tmpdir)"; then
  # selftest_skip has already set skipped=1, so this close can only take the
  # PARTIAL arm; the clean string is passed because the helper's signature
  # requires it, and never prints. selftest_close exits on every path, so
  # nothing follows it here.
  selftest_skip "mktemp -d produced no usable directory — no row in this script was exercised."
  selftest_close \
    "enum.sh self-test clean" \
    "enum.sh self-test PARTIAL — see the SKIP lines above for what went ungraded."
fi
[ -n "${ENUM_SELFTEST_KEEP:-}" ] || trap 'rm -rf "$tmp"' EXIT
[ -z "${ENUM_SELFTEST_KEEP:-}" ] || echo "keeping $tmp" >&2

lib="$tmp/lib"

# put <relative path> — writes a file under the fixture lib, creating parents.
put() { mkdir -p "$lib/$(dirname "$1")"; cat > "$lib/$1"; }

# --- one source per find/prune arm -------------------------------------------
put owner-repo/skills/alpha/SKILL.md <<'EOF'
---
name: alpha
description: Plain frontmatter description.
---
# Alpha
EOF

# A SKILL.md under references/ is still a skill: only the COMMAND arm prunes
# references/, so narrowing SKILL_PRUNE to match CMD_PRUNE reds here.
put owner-repo/references/nested/SKILL.md <<'EOF'
---
description: A skill under references/ is still found.
---
EOF

# Command-shaped files: one per path arm the second find names.
put owner-repo/commands/build.md <<'EOF'
---
description: A command under commands/.
---
EOF
put owner-repo/agents/scout.md <<'EOF'
---
description: An agent under agents/.
---
EOF
put owner-repo/plugins/thing.md <<'EOF'
---
description: A plugin under plugins/.
---
EOF
put owner-repo/.codex/codexy.md <<'EOF'
---
description: A .codex entry.
---
EOF
put owner-repo/prompts/asky.md <<'EOF'
---
description: A prompt under prompts/.
---
EOF

# Pruned: each of these must NOT appear.
put owner-repo/node_modules/dep/SKILL.md <<'EOF'
---
description: node_modules is pruned.
---
EOF
put owner-repo/docs/fr/SKILL.md <<'EOF'
---
description: docs/ is pruned (translated copies).
---
EOF
mkdir -p "$lib/owner-repo/.git"
put owner-repo/.git/SKILL.md <<'EOF'
---
description: .git is pruned.
---
EOF
put owner-repo/commands/examples/sample.md <<'EOF'
---
description: A command under examples/ is pruned.
---
EOF
put owner-repo/commands/scripts/helper.md <<'EOF'
---
description: A command under scripts/ is pruned.
---
EOF
put owner-repo/commands/README.md <<'EOF'
---
description: README.md is excluded by name.
---
EOF
# A .md outside every named path arm is not a command.
put owner-repo/notes/loose.md <<'EOF'
---
description: Not under a named command path.
---
EOF

# --- the description arms, in precedence order --------------------------------
put desc-repo/plain/SKILL.md <<'EOF'
---
description: "Quoted, and the quotes come off."
---
EOF
put desc-repo/colon/SKILL.md <<'EOF'
---
description: Before the colon: after it.
---
EOF
put desc-repo/folded/SKILL.md <<'EOF'
---
description: >
  A folded block scalar
  over two lines.
---
EOF
put desc-repo/literal/SKILL.md <<'EOF'
---
description: |   # a trailing comment on the indicator
  A literal block scalar.
---
EOF
put desc-repo/heading/SKILL.md <<'EOF'
---
name: heading-only
---
# The heading is the fallback
Body text nobody reads.
EOF
put desc-repo/body/SKILL.md <<'EOF'
Just a body line, no frontmatter and no heading.
EOF
put desc-repo/tabbed/SKILL.md <<'EOF'
---
description: "A	tab	becomes	a space."
---
EOF
put desc-repo/empty/SKILL.md <<'EOF'
EOF
printf -- '---\r\ndescription: CRLF input is stripped.\r\n---\r\n' > "$lib/desc-repo/crlf-SKILL.md"
mkdir -p "$lib/desc-repo/crlf"; mv "$lib/desc-repo/crlf-SKILL.md" "$lib/desc-repo/crlf/SKILL.md"
# 400 characters: the cut is at 300.
{ printf -- '---\ndescription: '; printf 'x%.0s' $(seq 1 400); printf '\n---\n'; } > "$tmp/long.md"
mkdir -p "$lib/desc-repo/long"; cp "$tmp/long.md" "$lib/desc-repo/long/SKILL.md"
# Lowercase skill.md: the name rule is case-insensitive.
put desc-repo/lowercase/skill.md <<'EOF'
---
description: A lowercase skill.md still takes its directory name.
---
EOF

# --- skipped sources ----------------------------------------------------------
put _rounds/2026-01-01/SKILL.md <<'EOF'
---
description: The default skip regex drops _rounds.
---
EOF
put skipme-repo/s/SKILL.md <<'EOF'
---
description: A caller's own skip regex drops this.
---
EOF

# --- run ----------------------------------------------------------------------
out="$tmp/out.tsv"; err="$tmp/out.err"
bash "$enum" "$lib" > "$out" 2> "$err"
rc=$?
# The fixture carries exactly one entry with no parsable description (the empty
# SKILL.md), and enum.sh's contract is exit 2 for that — "not everything
# checked", rows went out with an empty description field. A run that returns 0
# here has stopped tracking its own blind spot (ADR-0075).
expect_rc "enum.sh over a fixture with one unparsable entry" 2 "$rc"

# field <source> <name> <n>  — the nth field of the row for source+name.
field() { awk -F'\t' -v s="$1" -v n="$2" -v k="$3" '$1==s && $3==n {print $k; exit}' "$out"; }
has() { awk -F'\t' -v s="$1" -v n="$2" 'BEGIN{f=1} $1==s && $3==n {f=0} END{exit f}' "$out"; }

# found <label> <source> <name>
found() { has "$2" "$3" || selftest_fail "$1: no row for source '$2' name '$3'"; }
# absent <label> <source> <name>
absent() { ! has "$2" "$3" || selftest_fail "$1: a row for source '$2' name '$3' should not exist"; }
# desc_is <label> <source> <name> <expected>
desc_is() {
  local got; got="$(field "$2" "$3" 4)"
  [ "$got" = "$4" ] || selftest_fail "$1: description for '$3' is '$got', expected '$4'"
}

# The find arms.
found "SKILL.md at depth"                 owner-repo alpha
found "SKILL.md under references/"        owner-repo nested
found "a command under commands/"         owner-repo build
found "a command under agents/"           owner-repo scout
found "a command under plugins/"          owner-repo thing
found "a command under .codex/"           owner-repo codexy
found "a command under prompts/"          owner-repo asky

# The prune arms and the exclusions.
absent "node_modules pruned"              owner-repo dep
absent "docs/ pruned"                     owner-repo fr
absent ".git pruned"                      owner-repo .git
absent "examples/ pruned for commands"    owner-repo sample
absent "scripts/ pruned for commands"     owner-repo helper
absent "README.md excluded"               owner-repo README
absent "a .md outside the command paths"  owner-repo loose

# The skip regex, default and caller-supplied.
absent "_rounds skipped by default"       _rounds 2026-01-01
found  "a non-skipped source is present"  skipme-repo s
bash "$enum" "$lib" '^(_rounds|skipme-repo)$' > "$tmp/out2.tsv" 2>/dev/null
awk -F'\t' '$1=="skipme-repo"' "$tmp/out2.tsv" | grep -q . &&
  selftest_fail "a caller's skip regex did not drop skipme-repo"

# The name rule.
[ "$(field owner-repo alpha 3)" = alpha ] ||
  selftest_fail "a SKILL.md did not take its directory name"
found "lowercase skill.md takes its directory name" desc-repo lowercase

# The relpath field is relative to the source, not absolute.
[ "$(field owner-repo alpha 2)" = "skills/alpha/SKILL.md" ] ||
  selftest_fail "the relpath field is '$(field owner-repo alpha 2)', not 'skills/alpha/SKILL.md'"

# The description arms.
desc_is "quotes stripped"        desc-repo plain     "Quoted, and the quotes come off."
desc_is "a colon in the value"   desc-repo colon     "Before the colon: after it."
desc_is "a folded block scalar"  desc-repo folded    "A folded block scalar over two lines."
desc_is "a literal block scalar" desc-repo literal   "A literal block scalar."
desc_is "the heading fallback"   desc-repo heading   "The heading is the fallback"
desc_is "the body fallback"      desc-repo body      "Just a body line, no frontmatter and no heading."
desc_is "a tab becomes a space"  desc-repo tabbed    "A tab becomes a space."
desc_is "CRLF stripped"          desc-repo crlf      "CRLF input is stripped."
long="$(field desc-repo long 4)"
[ "${#long}" -eq 300 ] ||
  selftest_fail "the 300-character cut produced ${#long} characters, not 300"

# Every row has exactly four tab-separated fields.
awk -F'\t' 'NF!=4 {print NR": "NF; bad=1} END{exit bad+0}' "$out" ||
  selftest_fail "a row does not carry exactly 4 tab-separated fields"

# The unparsable count on stderr: the empty file is the one entry with no
# description, so a count of 0 here means the tracking arm stopped counting.
grep -q 'enum\.sh: 1 entries with no parsable description' "$err" ||
  selftest_fail "the stderr unparsable count is not 1: $(cat "$err")"
has desc-repo empty ||
  selftest_fail "the unparsable entry was dropped instead of emitted with an empty description"

# The other side of the exit contract: a lib with nothing unparsable exits 0
# and reports a count of 0. Graded on its own fixture, because the fixture
# above carries an unparsable entry by design and can only show the exit-2
# side. Until 2026-09-01 this block sat inside the tmpdir guard's failure
# branch, where it never ran while the close still claimed both sides.
clean="$tmp/clean"; mkdir -p "$clean/one/s"
printf -- '---\ndescription: Parsable.\n---\n' > "$clean/one/s/SKILL.md"
bash "$enum" "$clean" > /dev/null 2> "$tmp/clean.err"
expect_rc "enum.sh over a fixture with nothing unparsable" 0 "$?"
grep -q 'enum\.sh: 0 entries with no parsable description' "$tmp/clean.err" ||
  selftest_fail "the clean run's stderr count is not 0: $(cat "$tmp/clean.err")"

selftest_close "enum.sh self-test clean — every find and prune arm, the skip regex in both forms, the name and relpath rules, all three description arms with their block-scalar and CRLF shapes, the tab flattening, the 300-character cut, the four-field row, the stderr unparsable count, and both sides of the exit-status contract." "enum.sh self-test PARTIAL"
