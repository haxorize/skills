# Standalone entry points — the tie-breaks

Open this only when two standalone routes both plausibly fit, or when the ask is a *topic* and the choice is between learning it, being pitched it, and interviewing someone about it. `which-skill` § Standalone lists every route and is enough on its own to pick one.

## Topic-shaped asks split three ways

- **`/teach-me <topic>`** takes a topic you can name and teaches it across sessions, standalone or grounded in a codebase as its textbook. A repo you cannot yet name a mission for goes to **`/onboard-me`** first, which produces the topics.
- **`/explain`** is for when you stopped following: the last explanation didn't land, so it comes back with the missing context, in the plain, neutral register `writing-for-humans` sets for a doc, using `DOMAIN.md` vocabulary. It is not a shortener.
- **`/explain <topic>`** is the cold branch — the shape of a thing before you meet it, same register, shorter by design. A topic you mean to *learn* across sessions is `/teach-me <topic>`, not this.

## The rest, where the boundary is easy to miss

- **`/ask-for-me`** pairs with a `chart-course` Errand when the blocker is someone else's knowledge. The register items an `/offboard-engineer` capture leaves for the departing engineer are raw material pasted into its interview, not an intake it reads.
- **`/evaluation-ledger`** keeps one row per claim with its source, the date seen, its `marketed` / `verified` / `contradicted` status, and an expiry the sweep reads every session. The decision memo is drafted from the rows alone; where it decides adopt-or-not, its recommendation is the `adoption-verdict` grade, which it declares and calls. A watch — a rule set or a vendor landscape with no adopt-or-not — is the same ledger with one candidate.
- **`/merge-quiz`** runs before merging a change you did not watch being built: a report grouped by intent, a section on the paths the diff does not show, and 5–8 questions on interaction effects you answer before approving. Two failed rounds is a verdict on the change — split or simplify it — not on you.
- **`/write-skill`** owns the invocation axis, package structure, descriptions, the size cap, and the review checklist a skill-change review reports against. The prose conventions themselves are `writing-for-agents`', which it declares and which fires on its own whenever you draft a skill body, `CLAUDE.md`, or a reference file.
- **`/audit-skills`** audits the whole *installed* collection under `~/.claude/skills/`: a Keep / Improve / Update / Retire / Merge verdict per skill, on Overlap, Currency, Actionability, Scope fit, and Usage. A project-scoped skill sharing an installed skill's name is listed beside it and the verdict is written for the pair. Distinct from `audit-tests` (a test suite) and `find-skills` (discovery).
