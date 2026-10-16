# The per-turn load ceilings are fixed, and a rule that cannot fit is relocated

## Context

Three sets of text load on every turn in every project: this repo's `CLAUDE.md`, the `global/rules/*.md` layer [ADR-0053](0053-global-rules-layer.md) set up, and the `description:` line of every skill the model may invoke. Each description was capped only per file, at 1,024 chars by `check_description_limits`, and nothing capped the sum: the 2026-08-30 round trimmed 3 descriptions at the per-file cap one at a time and never saw the total. The rules cap had already been raised once, from 8,000 to 12,000 bytes, by [ADR-0077](0077-tightening-round-one-house-style.md). The 2026-09-04 grill (`~/code/lib/_rounds/2026-09-04/grill-outcomes.md`, decisions 2, 15, and the must-NOT probe) asked what each ceiling is and whether it moves.

## Decision

All four ceilings are enforced by `scripts/lint-skills.sh`:

- **The 12,000-byte rules cap is permanent**, a FAIL in `check_rules_bytes`. Nick ruled it so on 2026-09-04; it is not raised again.
- **The model-invoked catalog has a total ceiling of 14,400 bytes**, a WARN in `check_catalog_bytes`. It measures whole `description:` lines (key, space, value, newline). A user-invoked skill costs the catalog nothing.
- **A model-invoked description is bounded at 700 bytes**, a WARN in `check_description_limits`. Past that, the bytes are preamble and synonym lists rather than triggers.
- **`CLAUDE.md` is bounded at 6,000 bytes**, a WARN in `check_claude_md_bytes`.
- **The three layers together get a budget of 30,000 bytes per turn**, about 8,240 tokens at the 3.64 bytes per token `write-skill` § Size constraints measured, some 4% of a 200,000-token window. It is a WARN in `check_context_budget`, which prints the sum as the `launch-loaded surface` line. The per-layer caps are independent of it and of each other (6,000 + 12,000 + 14,400 = 32,400), so a tree can pass every per-layer check and still trip the combined WARN. That is the point: `CLAUDE.md` growth and a new description compete for the same bytes.

The budget measures only what this repo controls. It never counts MCP tool schemas, built-in tool definitions, or the system prompt, so a session that feels heavy under a green check is measured live with `/context all`.

**A rule that cannot fit is relocated, never refused.** Its mechanics move into a reference the depending skill opens, and a one-line pointer that still states the rule's verdict stays global. The first instance was `evidence.md`'s "An empty or failed check is not a clean result" bullet, which went from 820 to 315 B when its procedure moved into a `committing` reference. Once the rules directory has no fat left, the next clause does not trim; it displaces a rule, and that is a ruling for Nick rather than a fix-pass edit. The first such displacement, ratified on 2026-09-26, removed `no-unasked-commits`' closing pointer to `committing`, which the file's own `Depends: committing` line already carried.

**The layer that grew pays.** A description or a `CLAUDE.md` line that would take the sum past 30,000 bytes pays first, by relocation or trim in the layer that grew. The catalog ceiling and the 30,000-byte budget move only by an edit to this record that quotes the `check_context_budget` line at its tree.

A headroom figure is true only at the tree that measured it. The session budgeting a new clause or description re-runs `bash scripts/lint-skills.sh | grep launch-loaded` (or `cat global/rules/*.md | wc -c`) rather than trusting a number written earlier.

## Why the catalog and budget figures are what they are

The catalog ceiling started on 2026-09-04 at 13,200 bytes, the day's sum of 13,132 over 22 description lines rounded up. That was never a budget argued from load, which is why it was a WARN and why it could move. On 2026-09-13 the 948-byte description of the `aeo` Domain skill took the catalog from 13,197 to 14,145 B. Nick chose to raise the ceiling to 14,400 rather than trim about 950 B across the other 22 descriptions: those had already been cut to their trigger halves in the 2026-09-04 fix passes, and trading routing surface for a number nobody argued is the wrong side of the bargain.

The 30,000-byte budget was argued on the same day as the whole surface. At the tree that admitted `aeo` the `launch-loaded` line read 29,385 B: `CLAUDE.md` 3,266 + `global/rules/` 11,974 + catalog 14,145, about 8,072 tokens.

On 2026-10-15 the 2026-10-12 round cut both layers without moving either figure: the rules lost their `Depends:` lines to a sidecar and were condensed, and seven descriptions were trimmed with every trigger kept. The `launch-loaded` line then read 23,580 B: `CLAUDE.md` 3,368 + `global/rules/` 8,161 + catalog 12,051. The one description still over 700 bytes, `health-literacy`, waits on a re-probe of its triggers.

## Considered Options

- **15,000 bytes for the descriptions, matching the per-file skill limit.** Rejected. That figure is the 5,000-token re-attach bound in `scripts/lint-skills.sh`, a per-file limit with a compaction reason. The descriptions load in sum on every turn, as the rules directory does, and two per-turn layers with different ceilings and no stated reason for the difference make the rules cap read as negotiable.
- **12,000 bytes for the descriptions, matching the rules cap.** Rejected. It would turn the record into a cutting project across 22 descriptions that nobody asked for.
- **A second raise of the rules cap.** Rejected. The first relocation freed 505 B without one, and a cap raised each time it binds does not bind.
- **Trimming about 950 B from other descriptions to admit `aeo` under 13,200.** Rejected, for the reason above.

## Consequences

- Every future global clause is paid for by relocating procedure out of the rules directory, or by displacing a rule. A reviewer who sees a rule refused for size names this record: the outcome is relocation.
- Spends are not logged here. The lint checks are the gate, and git history holds each figure at its tree; a spend nobody recorded in this file is not a review finding.
- The selftest rows for the catalog ceiling and the combined budget live in `scripts/lint-skills-selftest.sh`.

## Revisit when

The harness changes what it loads per turn, so that one of these layers no longer costs every session; or `bash scripts/lint-skills.sh | grep launch-loaded` reads the three-layer sum within 300 B of the 30,000-byte budget, or over it.
