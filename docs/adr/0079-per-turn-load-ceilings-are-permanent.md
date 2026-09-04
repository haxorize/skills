# The two per-turn load ceilings are fixed, and a rule that cannot fit is relocated

This amends [ADR-0077](0077-tightening-round-one-house-style.md) § Amendments 2026-08-31 (the 12,000-byte rules budget), and [ADR-0053](0053-global-rules-layer.md), whose layer that budget governs.

## Context

Two sets of text load on every turn in every project: `global/rules/*.md`, capped at 12,000 bytes by `check_rules_bytes` in `scripts/lint-skills.sh`, and the `description:` line of every skill the model may invoke, capped only per file at 1,024 chars by `check_description_limits`. On 2026-09-04 the rules directory held 11,991 bytes and the 22 model-invoked descriptions summed to 13,132 bytes. The 2026-08-30 round trimmed 3 descriptions at the per-file cap one at a time and never saw the sum. The 2026-09-04 grill (`~/code/lib/_rounds/2026-09-04/grill-outcomes.md`, decisions 2, 15, and the must-NOT probe) asked what each ceiling is and whether it moves.

## Decision

- **The descriptions get a total ceiling of 13,200 bytes**, the 2026-09-04 sum rounded up, enforced as a WARN by a new `check_catalog_bytes` in `scripts/lint-skills.sh`, the `check_rules_bytes` pattern one layer down. A new description pays in trims to the others from day one.
- **The 12,000-byte rules cap is permanent.** Nick ruled it so on 2026-09-04. ADR-0077 raised it once, from 8,000; it is not raised again.
- **A rule that cannot fit is relocated, never refused.** The mechanics move into a reference the depending skill opens, and a one-line pointer that still states the rule's verdict stays global. The first instance is `evidence.md`'s 819-byte "An empty or failed check is not a clean result" bullet, whose procedure moves into a `committing` reference in this round's batch 3.

## Considered Options

- **15,000 bytes for the descriptions, matching the per-file skill limit.** Rejected. That figure is the 5,000-token re-attach bound at `lint-skills.sh:671`, a per-file limit with a compaction reason. The descriptions load in sum on every turn, which is the rules directory's situation, and giving the same per-turn load 2 ceilings with no stated difference makes the rules cap read as negotiable.
- **12,000 bytes, matching the rules cap.** Rejected. It would turn the record into a cutting project across 22 descriptions that nobody asked for.
- **A second raise of the rules cap.** Rejected. The relocation frees about 700 bytes without one, and a cap raised each time it binds does not bind.

## Consequences

Every future global clause is paid for by relocating procedure out of the rules directory. A reviewer who sees a rule refused for size names this record: the outcome is relocation.

## Revisit when

The harness changes what it loads per turn, so that either set no longer costs every session.
