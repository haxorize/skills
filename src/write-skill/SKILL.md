---
name: write-skill
description: Create new agent skills with proper structure and size constraints. Use when user wants to create, write, or build a new skill.
---

# Writing Skills

## Workflow

1. **Gather requirements** — what domain, what use cases, any reference material?
2. **Draft the skill** — SKILL.md with references if needed
3. **Review with user** — present draft, iterate

## Skill structure

```
skill-name/
├── SKILL.md              # Main instructions (required, ≤200 lines)
├── references/           # Detailed docs (if needed)
│   ├── topic-a.md        # Each ≤200 lines
│   └── topic-b.md
└── scripts/              # Deterministic helpers (if needed)
    └── helper.py
```

## SKILL.md template

```md
---
name: skill-name
description: Brief description. Use when [specific triggers].
---

# Skill Name

## [Gate / Publication constraints / etc.]

[Optional: conditions that govern when or how the skill runs]

## Workflow

[Step-by-step process — the most common section name across the suite]

## Notes

[Optional: edge cases, degradation behavior, cross-skill interactions]

## References

[Links to reference files: See [references/topic.md](references/topic.md)]
```

## Size constraints

- **SKILL.md**: ≤200 lines. If it grows past this, move detail into `references/`
- **Reference files**: ≤200 lines each. Split by topic, not arbitrarily
- **Description**: ≤1024 chars. Describe the domain/scope and triggers — not the workflow steps.

## Description guidelines

The description is the **only thing the agent sees** when deciding which skill to load. It must be specific enough to distinguish from other skills.

**Describe scope and triggers, never the workflow.** If the description summarizes the process (e.g., "interview the user, explore the codebase, then submit"), the agent can follow the description as a shortcut and skip reading the skill body entirely.

Good: `Project conventions for this FastAPI + async SQLAlchemy API. Use when creating endpoints, models, schemas, or services.`

Bad (too vague): `Helps with API development.`

Bad (summarizes workflow): `Gather requirements, draft SKILL.md, then iterate with the user. Use when creating a skill.`

## Frontmatter pitfalls

The frontmatter parses as strict YAML. The specific hazard is an unquoted `: ` — a colon **followed by a space** — in the `description:` value: YAML reads it as a nested mapping and GitHub's preview renders "Error in user YAML." A colon with no trailing space (`http://`, `3:1`) is harmless, and colons inside backtick code-spans are fine — `scripts/lint-skills.sh` strips code-spans before scanning, so `` `to-tasks --update` `` is safe. When separating clauses, use em-dashes.

Bad: `description: Stress-test plans. ADO: creates Tasks under a Story. GitHub: creates issues.`

Good: `description: Stress-test plans. ADO — creates Tasks under a Story. GitHub — creates issues.`

## Skill bodies don't cite repo ADRs

Skills are symlinked from this repo into `~/.claude/skills/` and run from inside *the user's* project — not from this repo. Markdown links from a skill body to `../../docs/adr/<NNNN>-...` resolve to `~/docs/adr/...` once hoisted (broken), and even a bare prose mention like "See ADR-0001" points at nothing the user has in their own project.

Lineage runs ADR → skill, not skill → ADR. Each ADR's prose names the skill(s) it shapes; that's the durable record. A future maintainer wondering "is there an ADR for this mechanism?" greps `docs/adr/` from inside this repo and finds it. The reverse pointer breaks the moment the skill is hoisted — don't write it.

## Writing style

- **Imperative voice** for instructions ("Write one test"; not "You should write one test").
- **Explain the why** alongside the what. An agent that understands the reason can generalize to edge cases; one following rote rules can't.
- **Avoid stacked `ALWAYS` / `NEVER` / `MUST` in caps.** If you're reaching for them, that's a signal to reframe — explain the constraint and let the model apply judgment. Reserve hard prohibitions for genuine safety/correctness rules.
- **One concrete example from this codebase** beats several generic or templated ones.

## When to add scripts

- Operation is deterministic (validation, formatting, code generation)
- Same code would be generated repeatedly
- Scripts save tokens vs generating the same code each time

## When to split into references

- SKILL.md exceeds 200 lines
- Content has distinct subtopics (e.g., migrations vs schema design)
- Some content is only needed occasionally

## Sharing a reference across skills

When two skills need the same reference (e.g. a shared format doc), don't reach for a repo-root shared folder or a symlink between skills. Skills install individually — a user symlinks one skill's directory into `~/.claude/skills/` without the rest of the tree — so anything outside that skill's own `references/` doesn't travel with it.

Instead, duplicate the file byte-identically into each skill's `references/`, and register the group in `scripts/lint-skills.sh` (`sibling_groups`) so any drift between copies fails lint. The duplication tax only stays bounded for short, stable docs — don't share high-churn content this way.

## Review checklist

- [ ] Description includes "Use when..." triggers
- [ ] SKILL.md ≤200 lines
- [ ] Each reference file ≤200 lines
- [ ] No generic best-practices the model already knows
- [ ] Encodes project-specific decisions, not textbook knowledge
- [ ] Concrete examples from the actual codebase
