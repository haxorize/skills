# Solved-problems store: bug track only

A per-repo `docs/solutions/` store of Learning docs — solved problems with symptom-keyed frontmatter — exists because a finished diagnosis otherwise dies with the session: `diagnosing-bugs` preserved the winning hypothesis only in a commit message, and the next agent re-paid the full investigation. The store, its capture gate, overlap rule, and retrieval protocol live in `diagnosing-bugs`' `references/learnings.md`, with the doc format in `references/learning-format.md`; `respond-to-incident` and `adoption-verdict` read the reference by installed path. Only the bug track of compound-engineering's two-track design was adopted; the knowledge track was rejected because its content is already owned here (CONCEPTS.md ≈ `DOMAIN.md`/`domain-modeling`; tooling and architecture decisions ≈ ADRs, which `diagnosing-bugs` already retrieves; conventions ≈ CLAUDE.md and convention skills), and a fourth overlapping store would split each fact across two homes.

The store holds a second document kind, the **incident learning** (`learning-format.md` § The incident learning): an extension of the bug track, not the knowledge track this record refused, since a postmortem is a solved problem with a root cause, and the refusal above is content-scoped to what `DOMAIN.md`, ADRs, and CLAUDE.md already own. Same store, same frontmatter, and the same slug rule apart from a date prefix, so **no field discriminates a Learning doc from an incident learning**, and nothing can grep the store for incident learnings as a class. That is accepted: a `kind:` field added later is the schema change § Consequences prices as orphaning accumulated docs, and the incident kind's dated filename (`<yyyy-mm-dd>-<slug>.md`) is the one discriminator that costs no field.

## Considered Options

- **Both CE tracks** — rejected: three existing stores already cover the knowledge track; overlap invites drift.
- **Retrieval-only pass over existing stores** — rejected: solved problems have no store to retrieve from; the gap is the missing artifact, not the missing search.
- **A standalone `capturing-learnings` skill** — the original form, retired in the 2026-10-12 round (grill Q25): its own triggers ("that worked", "it's fixed") never loaded it on its own, no repo under `~/code` had a `docs/solutions/` folder after about three months, and its description cost 344 bytes on every turn. A reference inside `diagnosing-bugs` keeps the retrieval at the loop's start and the gate at its close for no per-turn cost; a fix made outside a diagnosis is captured only when someone asks.
- **CE's researcher-subagent retrieval** — rejected for now: grep-first inline retrieval suffices at the store sizes a single repo accrues; the subagent is scale machinery, noted as a later escalation.

## Consequences

- The store schema (trimmed CE frontmatter: `title`, `problem_type`, `tags`, `symptoms`, `root_cause`, `module?`, `date`, `last_updated?`) propagates into target repos; changing it later orphans accumulated docs — the effective reversal cost that fired this ADR.
- `docs/solutions/` keeps CE's path, so repos already seeded by CE tooling remain retrievable (recursive grep tolerates their category subdirectories); this repo's own captures stay flat and slug-only.
