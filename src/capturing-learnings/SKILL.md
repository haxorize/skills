---
name: capturing-learnings
description: Capture a solved problem as a retrievable Learning doc in docs/solutions/, and search past learnings by symptom. Use when a hard-won fix is verified ("that worked", "it's fixed", a diagnosis loop just closed), or when another skill needs the retrieval protocol over past solved problems.
---

# Capturing Learnings

A solved problem dies with the session unless it lands where the next agent can grep it. This skill owns the **solved-problems store** — `docs/solutions/` at the target repo's root, one Learning doc per problem — on both sides: capturing a new learning and retrieving past ones.

The store is flat and lazily created at first capture. Doc format, filename, frontmatter fields, and update mechanics live in [references/learning-format.md](references/learning-format.md).

## The capture gate

All three must hold — confirm out loud which are met before drafting; if any is missing, say why and stop. A direct ask ("the team documents every fix") doesn't waive the gate — name the failing criterion first and let the human overrule explicitly; a store padded with trivia buries the learnings worth retrieving:

1. **Verified** — the fix is in and the original symptom is confirmed gone (the reproduction loop re-ran green). Never capture an unverified theory.
2. **Expensive** — the diagnosis took real investigation: multiple hypotheses, failed attempts, a non-obvious root cause. If the error message alone led to the fix, a search engine already owns it.
3. **Recurrence-plausible** — the class of problem can bite again in this repo or its siblings: the pattern is used repeatedly, or the trigger is easy to re-create.

## Capture workflow

1. **Apply the gate** (above).
2. **Search before writing.** Run the retrieval protocol (below) against the new problem, extending the grep with the now-known root cause (`root_cause:`, `tags:`) — an existing doc can share the root cause under different symptoms. No store yet → nothing to overlap; continue. The **overlap rule**: same root cause *and* same fix approach as an existing doc → **update it** per [references/learning-format.md](references/learning-format.md); otherwise a new doc. Never write a duplicate — two docs describing one problem drift apart.
3. **Draft** per [references/learning-format.md](references/learning-format.md).
4. **First capture in a repo — discoverability check.** If this doc creates the store, check whether the repo's `CLAUDE.md` (or `AGENTS.md`) would lead a fresh agent to it. If not, draft a one-line descriptive addition in the closest existing section — e.g. `docs/solutions/ — solved problems keyed by symptom frontmatter` — descriptive, never imperative ("always search before…" causes redundant reads). Skip this check on later captures.
5. **Show the draft** (plus the instruction-file line when step 4 produced one) and save on approval.

## Retrieval protocol

How any skill reads the store — grep-first, cheapest signal first:

1. If `docs/solutions/` doesn't exist, report that and end the search — absence is a valid result, not an error.
2. Grep recursively (the store may carry category subdirectories from other tooling), case-insensitive, one pass over the frontmatter: the observed error strings with synonyms OR-ed (`(timeout|hang|stall)`); rank hits by matched field — `symptoms:` strongest, then `tags:`, `root_cause:`, `title:`.
3. Read only the frontmatter (first ~15 lines) of candidate files; full-read only the strong matches.
4. Return at most 5 distilled matches — each as root cause + fix + what didn't work, with its freshness flagged (`last_updated:` if present, else `date:`) — never raw doc dumps.
5. A match **informs** the present investigation; it never overrides present evidence — a stale learning can be confidently wrong.
