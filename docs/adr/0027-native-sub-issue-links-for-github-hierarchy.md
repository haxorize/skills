# Native sub-issue links for GitHub hierarchy

On GitHub, `to-story`, `to-tasks`, `to-bug` and `to-feature` add each newly published issue as a native sub-issue of its resolved parent, and `chart-course` does the same for a Decision ticket under its map ([ADR-0028](0028-chart-course-decision-ticket-maps.md)), extending ADR-0023's principle (built-in relations as an additive projection) from ADO blocking dependencies to GitHub hierarchy. The projection is a convenience layer: the `Parent: #N` body line remains the source of truth that `from-work-item` reads on cold-start, and a failed sub-issue call surfaces both issue numbers for manual linking without blocking or rolling back the publish.

## Considered options

- **Native relation as source of truth (drop the `Parent: #N` line)** — rejected: `from-work-item` resolves parents from the body it has already fetched (no extra API call), the line keeps the parent visible in the rendered issue, and the body survives contexts where the sub-issue write failed.
- **Prompting for a parent on GitHub now that hierarchy is native** — rejected: parentless issues are a legitimate GitHub workflow; `Hierarchy: required` stays an explicit CLAUDE.md opt-in, so the no-prompt default is unchanged.
- **Reconcile/backfill pass for missed links** — rejected for the same reason as ADR-0023's story-relation reconcile: the projection is additive and partial by design; a failed link is surfaced at publish time for manual repair, never re-derived later.

## Consequences

The two parent representations are deliberately redundant — do not "clean up" the `Parent: #N` line in favor of the native link, and do not tighten link failure into a publish failure. The linking mechanics (database-ID lookup, failure handling) live once in `work-item-shape`'s `tracker.py`: its `link` command, which `create --parent` also runs, and which every skill that publishes a GitHub issue runs by installed path. A failed link inside a create exits 5 (written but incomplete) after printing the new issue's `id=`, naming both issues, and tells the caller to re-run `link`, never the create; a failed `link` run on its own exits 1.
