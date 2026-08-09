# Failure-driven escalation for skill wording

## Context

`write-skill` carried a blanket style rule — "avoid stacked `ALWAYS`/`NEVER`/`MUST` in caps; reframe and let the model apply judgment" — while imported evidence (superpowers' A/B wording tests) shows compliance wording is failure-dependent: hard prohibitions measurably help when an agent *skips a rule under pressure* (paired with a rationalization table and red-flags list), and measurably *backfire* when the problem is wrong-shaped output, where a positive recipe wins.

## Decision

Skill wording escalates by observed failure mode. Judgment-framing stays the default; a hard prohibition (with rationalization table and red-flags) is reserved for a rule the agent demonstrably skips under pressure. Two wording rules apply at every escalation level: no nuance clauses ("don't X unless it matters" reopens the negotiation) and no exemption clauses (they fail to scope — the suppressed behavior stays suppressed inside the carve-out). The form-to-failure table (pressure-skip → prohibition; wrong-shaped output → positive recipe; omitted element → REQUIRED template slot; conditional behavior → observable-predicate conditional) lives in `write-skill`'s reference; `tdd`'s delete-the-code stance is the first escalated application.

## Considered Options

- **Keep the blanket caps ban** — rejected: leaves the rule in silent tension with the evidence, and gives pressure-skipped rules (test-first) no stronger form to escalate to.
- **Adopt Authority wording wholesale** (YOU MUST as the default for discipline skills) — rejected: contradicts the suite's no-op pruning philosophy and inflates tone where a positive recipe is the effective form.

## Consequences

- A hard prohibition in a skill body is now a *claim* that the rule is pressure-skipped; reviewers of skill changes can demand that justification.
- Exemptions to an escalated rule live in the *caller* (e.g. `implement`'s direct path exempts non-testable slices), never as a nuance clause inside the escalated rule itself.

## Amendments

- **2026-08-08** — With the [ADR-0040](0040-writing-for-agents-extracted-from-write-skill.md) extraction, the form-to-failure table moved from `write-skill`'s reference to `writing-for-agents`' `predictability.md` reference. The escalation policy itself is unchanged.
