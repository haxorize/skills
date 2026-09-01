# Native sub-issue links for GitHub hierarchy

On GitHub, `to-story`, `to-tasks`, and `to-bug` add each newly published issue as a native sub-issue of its resolved parent — amended: see Amendments 2026-09-01 — extending ADR-0023's principle (built-in relations as an additive projection) from ADO blocking dependencies to GitHub hierarchy. The projection is a convenience layer: the `Parent: #N` body line remains the source of truth that `from-work-item` reads on cold-start, and a failed sub-issue call surfaces both issue numbers for manual linking without blocking or rolling back the publish.

## Considered options

- **Native relation as source of truth (drop the `Parent: #N` line)** — rejected: `from-work-item` resolves parents from the body it has already fetched (no extra API call), the line keeps the parent visible in the rendered issue, and the body survives contexts where the sub-issue write failed.
- **Prompting for a parent on GitHub now that hierarchy is native** — rejected: parentless issues are a legitimate GitHub workflow; `Hierarchy: required` stays an explicit CLAUDE.md opt-in, so the no-prompt default is unchanged.
- **Reconcile/backfill pass for missed links** — rejected for the same reason as ADR-0023's story-relation reconcile: the projection is additive and partial by design; a failed link is surfaced at publish time for manual repair, never re-derived later.

## Consequences

The two parent representations are deliberately redundant — do not "clean up" the `Parent: #N` line in favor of the native link, and do not tighten link failure into a publish failure. The linking mechanics (database-ID lookup, failure handling) live once in the `github-sub-issues.md` sibling reference shared byte-identically by the three publishing skills.

## Amendments

- **2026-08-09** — The sibling group has a fourth member: `chart-course` carries its own byte-identical `github-sub-issues.md` copy, adopted when [ADR-0028](0028-chart-course-decision-ticket-maps.md) made GitHub Decision tickets native sub-issues of their map. "The three publishing skills" above reads as the group's membership at authoring time; `scripts/lint-skills.sh` guards all four copies.

- **2026-09-01** — The sibling group has a **fifth** member, and a publisher gained an outward tracker write with no record. The 2026-08-30 tightening round added `src/to-feature/references/github-sub-issues.md` and a fifth path to `sibling_groups`, so `to-feature` now adds a resolved parent's new issue as a native sub-issue on the same terms as the other three; the opening sentence and [ADR-0007](0007-self-contained-skill-bundles.md)'s tally were both left naming four. The behavior is right — a Feature published under a resolved parent should project the same relation the other tiers do — and the gap was recording, found by the Batch A review rather than by any check: `lint-adrs.sh` reads pointer symmetry, never membership counts.

