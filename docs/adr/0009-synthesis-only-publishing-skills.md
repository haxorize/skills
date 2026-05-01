# Synthesis-only stance for publishing skills (no-interview)

## Context

The prior per-repo `write-feature-spec` and `spec-to-tasks` skills interviewed users — walked through scope, modules, acceptance criteria, etc. via Q&A. Two problems: interviewing duplicates the work already done in upstream grilling sessions (`grill-me`, `grill-and-record`), and interview output quality scales with how thoroughly the user invests in answering on the spot. When publishing follows a real grilling session, re-asking the same questions is friction. When it doesn't, the publishing skill silently lowers the bar by accepting thin answers — the team ships an underspecified Story instead of the system pushing back.

## Decision

`to-feature`, `to-story`, `to-tasks`, and `to-bug` are synthesis-only. They draft from existing conversation context plus codebase exploration; they do not interview. If context is thin, the skill says so and points back to `grill-me` or `grill-and-record` rather than half-interviewing inline. Self-review (no placeholders, no contradictions, scope check, ambiguity check, domain-language match against `DOMAIN.md`) is the quality gate that replaces interview thoroughness.

## Considered Options

- **Hybrid: synthesize when context is rich, interview when thin** — rejected. The threshold is fuzzy and the model would frequently misjudge it. Pointing back to `grill-me` produces better output and a clearer mental model than half-grilling inline.
- **Always interview (status quo from `write-feature-spec`)** — rejected. Duplicates upstream work and creates an off-ramp for skipping the deeper grilling that actually improves quality.
- **Always synthesize, no fallback** — rejected. When context is genuinely thin (cold-start, fresh session, no prior grilling), the skill must redirect rather than fabricate.

## Consequences

- Publishing skills run fast when conversation context is rich — no Q&A loop, just synthesis + draft + self-review + publish.
- Upstream grilling becomes the load-bearing step. Teams that skip grilling get worse output; the system makes that visible at publish time rather than hiding it under interview thoroughness.
- Cross-Story consistency emerges from full-conversation context — Phase 2's password-reset Story correctly carved out the `email_notifications_enabled` guard introduced by an earlier notification-toggle Story without being told. This is a property of the architecture, not a knob.
- `from-work-item` (ADR-0004) is the cold-start variant for implementation work, where the parent context lives on the tracker rather than in conversation. The publishing skills have no analogous mode because the parent context they need lives in the ongoing conversation by definition.
