# First Domain skill admitted: `phi-safe-code`, in plain `src/`

Status: accepted (2026-08-22)

The suite admits its first **Domain skill**, working name `phi-safe-code`: the discipline of keeping protected health information out of logs, fixtures, error messages, URLs, analytics events, and model prompts, with secure application logging as a section of it rather than a skill of its own. Three independent mining reads on 2026-08-22 (the everything-claude-code family, the security packs, and the awesome-list inventory) scored it against the Gap-and-stakes test and all three prongs held: the model's default code leaks identifiers into those surfaces unless told otherwise, the failure is a reportable breach, and every team that touches member data would load it. No source pack supplies the skill; the packs are clinic-shaped (EMR, ICD-10, Supabase RLS) and are mined for seed rules only.

The alternative was a separate Humana-only repo holding every Domain skill, keeping this suite purely process-shaped as its `CLAUDE.md` describes it. A rational team would choose that, and it lost on one point: the Gap-and-stakes test admits only gaps that generalise past one employer (any payer, any regulated organisation), and a second repo with one skill in it would not be installed. The org-specific layer, the allowed log-field list and retention figures, stays outside the suite as a project-conventions skill.

Placement is plain `src/<name>/`, flat beside the process skills, with no new frontmatter and no new tier. `install.sh` and every lint loop glob `src/*/SKILL.md`; a nested tier would cost lint, install, and selftest changes before the first body exists. The decision is provisional: a third admitted Domain skill re-opens it, with three bodies to move instead of none.

## Deferred

- The final name: B4b's rename table judges `phi-safe-code` on the stranger-at-autocomplete criterion with every other name.
- Health-literacy copy as the second Domain skill: admitted on hypothesis; the off-path-and-domain admissions session checks prong (a) against 5 member-facing samples before an authoring batch is named.
- Description triggers: the body must fire on payer vocabulary (member, subscriber, claim, eligibility, 834/837, MRN) and on the act (logging, fixtures, error text, analytics, prompts), never only on "PHI" or "HIPAA"; the B9 micro-test checks this.

## Consequences

- The suite is no longer purely repo-agnostic in subject matter; it stays repo-agnostic in mechanism. `CLAUDE.md`'s first line needs the qualifier when B9 lands.
- Two guards bind B9: no org policy numbers in a `src/` body, and no `references/` file that is a regulation digest (that is a pack, which the test rejects).
