# Solved-problems store: bug track only

A new `capturing-learnings` behavior skill owns a per-repo `docs/solutions/` store of Learning docs — solved problems with symptom-keyed frontmatter — because a finished diagnosis otherwise dies with the session: `diagnosing-bugs` preserved the winning hypothesis only in a commit message, and the next agent re-paid the full investigation. Only the bug track of compound-engineering's two-track design was adopted; the knowledge track was rejected because its content is already owned here (CONCEPTS.md ≈ `DOMAIN.md`/`domain-modeling`; tooling and architecture decisions ≈ ADRs, which `diagnosing-bugs` already retrieves; conventions ≈ CLAUDE.md and convention skills), and a fourth overlapping store would split each fact across two homes.

## Considered Options

- **Both CE tracks** — rejected: three existing stores already cover the knowledge track; overlap invites drift.
- **Retrieval-only pass over existing stores** — rejected: solved problems have no store to retrieve from; the gap is the missing artifact, not the missing search.
- **Extend `diagnosing-bugs` inline (no new skill)** — rejected: the store's format, capture gate, overlap rule, and retrieval protocol are a reusable behavior other skills will reference; the extraction test passes.
- **CE's researcher-subagent retrieval** — rejected for now: grep-first inline retrieval suffices at the store sizes a single repo accrues; the subagent is scale machinery, noted as a later escalation.

## Consequences

- The store schema (trimmed CE frontmatter: `title`, `problem_type`, `tags`, `symptoms`, `root_cause`, `module?`, `date`, `last_updated?`) propagates into target repos; changing it later orphans accumulated docs — the effective reversal cost that fired this ADR.
- `docs/solutions/` keeps CE's path, so repos already seeded by CE tooling remain retrievable (recursive grep tolerates their category subdirectories); this repo's own captures stay flat and slug-only.
