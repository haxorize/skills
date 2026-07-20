# Mine unmerged branches only for direct lineage or dormant main

The 2026-07-19 branch-coverage audit of the mined repos under `~/code/lib` found sweep coverage complete on every main tip but untested on unmerged branches — where real material was hiding (wayfinder's research-inline redesign, adopted in part into `chart-course`). Standing policy for future sweeps: read a repo's unmerged branches only when (a) the repo is the direct upstream of a ported skill (wayfinder → `chart-course`, ce-pov → `adoption-verdict`), or (b) main is dormant and branches carry the only delta (how superpowers' `tdd-writing-good-tests` material was found); otherwise sweeps are main-only. Exhaustive branch mining was rejected as disproportionate — unreleased WIP hasn't survived its own author's merge bar, and compound-engineering-plugin alone carries 499 unmerged branches — and pure main-only was rejected because it demonstrably missed the wayfinder material.

## Consequences

CLAUDE.md carries the revisit trigger: materially editing a ported skill starts with an upstream diff — main and branches — since the last-swept point. As of this ADR: wayfinder at main `9603c1c` (branches audited 2026-07-19), ce-pov at main `4927d7a1`.

**2026-07-20** — `chart-course` edited under ADR-0035 (terminology only: its tickets defined as the Charting sub-type of the new **Ticket** term). Upstream diff waived: wayfinder was swept the day before and the edit carries no behavioral delta.
