# Model-invoked vs user-invoked skill split

## Context

Every skill in this repo was historically **model-invoked**: each `SKILL.md` carried a trigger-rich, model-facing `description` ("Use when the user wants…"), so the agent could auto-load any of them. Two problems followed. First, consequential orchestrators — the `to-*` publishers that write real work items to a tracker — could auto-fire without an explicit human go-ahead. Second, there was no clean separation between a skill that **orchestrates a workflow** (something a human deliberately starts) and a skill that holds **reusable discipline** (something the model should reach for mid-task). Matt Pocock's skills repo split exactly this axis, and Claude Code supports it natively via the `disable-model-invocation` frontmatter field.

Confirmed from the Claude Code docs: setting `disable-model-invocation: true` *hides the skill's description from the model entirely* — the skill becomes reachable only by a human typing its name, and is invisible both to auto-invocation and to prose invocation by other skills.

## Decision

Classify every skill on one **invocation** axis:

- **User-invoked** (`disable-model-invocation: true`) — reachable only by a human. The `description` is **human-facing**: a one-line summary with no trigger list. Job: orchestrate.
- **Model-invoked** (default) — reachable by model or user. The `description` stays **trigger-rich / model-facing** so auto-invocation fires. Job: hold reusable discipline.

Classification policy: workflow orchestrators and consequential publishers are **user-invoked**; reusable disciplines the model should autonomously reach for are **model-invoked**. The test for staying model-invoked is *"could the model usefully reach for this autonomously?"* — reuse is the reason to **extract** a skill, not the test for its invocation type (see ADR-0016).

Because a user-invoked skill's description is hidden, **a user-invoked skill may invoke model-invoked skills (via soft, Claude-mediated prose invocation) but never another user-invoked skill.**

Roster: user-invoked — `grill-me`, `grill-and-record`, `harden-domain`, `improve-design`, `backfill-adrs`, `to-feature`, `to-story`, `to-tasks`, `to-bug`, `glapi-test-pass`, `from-work-item`, `write-skill`, plus new orchestrators `implement` and `review-changes`. Model-invoked — `adr`, `tdd`, plus extracted behaviors `grilling`, `domain-modeling`, `codebase-design`, `feedback-loops`.

`write-skill` is **user-invoked**, not model-invoked: it is a deliberately-reached authoring reference. Because the skills are installed globally, a model-invoked description would pay context load every turn in every repo while skill-authoring is rare outside this one; no other skill declares it as a dependency; and the action name `write-skill` is the user-invoked naming form. (Matt's equivalent `writing-great-skills`, which folds into ours, is likewise user-invoked.)

`improve-design` is renamed from the existing `deepen` (the only existing-skill rename in this split): once its driving behavior `codebase-design` absorbed quality framings beyond module-depth, `deepen` read too narrow. `improve-architecture` was declined — the skill operates on module *design* vocabulary (depth/seam/adapter) and explicitly avoids system-architecture terms (component/service/boundary), and pairs cleanly with the `codebase-design` behavior.

## Considered Options

- **Tag-only** (classify, don't restructure) — rejected: leaves grilling logic duplicated across `grill-me` and `grill-and-record`; forgoes the reusable-behavior layer.
- **Full decompose** (split every orchestrator into wrapper + core) — rejected: contradicts the extraction test (extract on real reuse, not speculatively) and multiplies the sibling-ref surface.
- **Hybrid** (chosen) — tag all skills now; extract a behavior into its own model-invoked skill only where a real second consumer exists.

## Consequences

- The `to-*` publishers lose the ability to auto-fire — intentional. The model can still *suggest* them in prose ("this looks ready for /to-story"); only a human triggers the write.
- Every `SKILL.md` description is rewritten to match its invocation type (human-facing vs trigger-rich). `scripts/lint-skills.sh` gains a check for this.
- `README.md` and any bucket indexes regroup into **User-invoked** / **Model-invoked** sections.
- A naming convention follows (pairs-only): extracted model-invoked cores take discipline/gerund names; user-invoked orchestrators keep action names; standalone skills are not renamed.
- Enables the behavior-extraction and declared-dependency model in ADR-0016.
