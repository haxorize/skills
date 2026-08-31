# Writing the description — the branch details

The branch is decided at `write-skill` § Invocation axis; open the section below for the kind the skill is.

## Model-invoked

State what the skill is, then list the **triggers** — one per genuinely distinct branch. Synonyms renaming one branch are duplication; collapse them. Before adding a trigger phrase, grep it across this repo's other descriptions (`grep -il '^description:.*<phrase>' src/*/SKILL.md`): a phrase a sibling already carries splits the load between the two, and is the sibling's to keep or yours to rephrase. `scripts/lint-skills.sh` fails a **double-quoted** phrase two or more model-invoked descriptions share, naming every one of them; a backticked or unquoted trigger clause is compared by nothing, so for those the grep is the check. It reads only the trigger half: a phrase quoted inside a disambiguating `Not for…` tail is routing a reader *away* from the sibling that owns it, and is exempt. Open the trigger list with `Use when` (or `Use after` / `Use only`) — this is the repo's normative trigger marker, and `scripts/lint-skills.sh` keys on it to tell model-invoked from user-invoked descriptions. Front-load the leading words you actually use when you want the skill. Describe scope and triggers, **never the workflow** — if it summarizes the process, the agent follows the description as a shortcut and skips the body. Good: `Project conventions for this FastAPI + async SQLAlchemy API. Use when creating endpoints, models, schemas, or services.` Bad (workflow): `Gather requirements, draft SKILL.md, then iterate.`

**Anti-triggers:** when a model-invoked skill borders territory the model should handle without it, name the exclusion in the description ("Don't invoke this for steps the agent can perform itself") — one negative trigger is cheap; an over-firing skill is not.

## User-invoked

The description is a one-line human-facing summary; the craft above does not apply. One duty binds the body instead:

A user-invoked skill also handles the ask it *didn't* get: when the invocation bundles a second intent outside the skill's job ("...and also fix the flaky test"), the skill does its own job, then names the deferred intent visibly — and the skill or route that owns it — without executing it. Silently doing it is scope creep; silently dropping it loses the user's ask.

## Frontmatter pitfalls

Read this section when writing or editing the frontmatter block — either invocation kind; a body-only revision never opens it.

Frontmatter parses as strict YAML. The `description:` value sits on its own line: a block scalar (`>`, `|`, with any suffix) or a continuation onto an indented next line is read as its first line alone by every one-line reader, `scripts/lint-skills.sh` included, which fails both shapes. The other hazard is an unquoted `: ` (colon **followed by a space**) in `description:` — YAML reads it as a nested mapping and GitHub's preview renders "Error in user YAML." A colon with no trailing space (`http://`, `3:1`) is harmless, and colons inside backtick code-spans are fine (`scripts/lint-skills.sh` strips code-spans before scanning). Separate clauses with em-dashes. Bad: `ADO: creates Tasks.` Good: `ADO — creates Tasks.`
