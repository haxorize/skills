# Solved-problems store: bug track only

A new `capturing-learnings` behavior skill owns a per-repo `docs/solutions/` store of Learning docs — solved problems with symptom-keyed frontmatter — because a finished diagnosis otherwise dies with the session: `diagnosing-bugs` preserved the winning hypothesis only in a commit message, and the next agent re-paid the full investigation. — amended: see Amendments 2026-09-04 (a second document kind in the same store). Only the bug track of compound-engineering's two-track design was adopted; the knowledge track was rejected because its content is already owned here (CONCEPTS.md ≈ `DOMAIN.md`/`domain-modeling`; tooling and architecture decisions ≈ ADRs, which `diagnosing-bugs` already retrieves; conventions ≈ CLAUDE.md and convention skills), and a fourth overlapping store would split each fact across two homes.

## Considered Options

- **Both CE tracks** — rejected: three existing stores already cover the knowledge track; overlap invites drift.
- **Retrieval-only pass over existing stores** — rejected: solved problems have no store to retrieve from; the gap is the missing artifact, not the missing search.
- **Extend `diagnosing-bugs` inline (no new skill)** — rejected: the store's format, capture gate, overlap rule, and retrieval protocol are a reusable behavior other skills will reference; the extraction test passes.
- **CE's researcher-subagent retrieval** — rejected for now: grep-first inline retrieval suffices at the store sizes a single repo accrues; the subagent is scale machinery, noted as a later escalation.

## Consequences

- The store schema (trimmed CE frontmatter: `title`, `problem_type`, `tags`, `symptoms`, `root_cause`, `module?`, `date`, `last_updated?`) propagates into target repos; changing it later orphans accumulated docs — the effective reversal cost that fired this ADR.
- `docs/solutions/` keeps CE's path, so repos already seeded by CE tooling remain retrievable (recursive grep tolerates their category subdirectories); this repo's own captures stay flat and slug-only.

## Amendments

- **2026-09-04** — The store holds a second document kind, the **incident learning** (`src/capturing-learnings/references/learning-format.md` § The incident learning; `src/capturing-learnings/SKILL.md` § The capture gate), landed in this round's batch 4f. It is an extension of the bug track, not the knowledge track this record refused: a postmortem is a solved problem with a root cause, and the refusal above is content-scoped to what `DOMAIN.md`, ADRs, and CLAUDE.md already own. Same store, same frontmatter, and the same slug rule apart from a date prefix — so **no field discriminates a Learning doc from an incident learning**, and nothing can grep the store for incident learnings as a class. Accepted with eyes open: a `kind:` field added later is the schema change § Consequences prices as orphaning accumulated docs, and the incident kind's dated filename (`<yyyy-mm-dd>-<slug>.md`, `learning-format.md`'s opening paragraph and § Filename, landed in the same review's fixes) is the one discriminator that costs no field.
