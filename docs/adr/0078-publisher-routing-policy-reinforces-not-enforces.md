# The publisher routing policy is a reinforcement in `CLAUDE.md`, not the mechanism that enforces it

Status: accepted (2026-08-31)

The 2026-08-31 tightening batch made `onboard-repo` write a fixed prose policy into every downstream repo's `CLAUDE.md` `Issue tracker:` block — that work items are created only through the `to-*` publishers and never with raw `gh`/`az` calls — and made `work-item-shape` quote that line back verbatim, asserting it "holds even when this discipline never loads." That is a normative line written into other people's repositories, and it shipped with no record, no `DOMAIN.md` row, and no README row. The review of the batch escalated it rather than ranking it, because settling it means answering four questions a reviewer cannot answer.

This record answers them.

The record clears the ADR gate on all three criteria. **Hard to reverse:** every repo onboarded from here carries the line verbatim, and un-writing it means editing repositories this suite does not own. **Surprising without context:** a block of prose inside a key-value block invites a reader to treat it as a parsed field. **A real trade-off:** a `Landing:`-style key, a `## Convention skills` row, or `work-item-shape`'s own description could each have carried the policy instead, and the choice between a reinforcement and an enforcement mechanism decides what happens when the line is absent.

## The `Issue tracker:` block owns it, not the `Landing:` key

The block's subject is how work items are *created* — which tracker, which prefixes, which labels, which tiers exist. The `Landing:` key's subject is how a *change* lands: branch policy, PR, push, ticket close, review, defects. Routing a filing ask is a creation-side question, so it sits with the other creation-side lines. Putting it under `Landing:` would make that key answer two unrelated questions and force `committing` to read a line it never acts on.

The line is prose inside a block whose other entries are `key: value`. That is admitted deliberately: the policy has no value to parse, nothing reads it mechanically, and ADR-0076 admits a trigger — which this is — into `CLAUDE.md`. A reader who wants the parsed fields is not misled, because no consumer looks the line up by key.

## It is cited, never quoted back

`work-item-shape` no longer reproduces the 45 words. `CLAUDE.md` is loaded on every turn, so a skill body restating one of its lines copies a lookup that already costs nothing — the caching failure `writing-for-agents` names — and puts the same string in three places (`onboard-repo`, `work-item-shape`, and every wired repo's `CLAUDE.md`) with no lint tying them. The body now points at the block instead.

The sentence that justified the quote argued against itself: it said the line "holds even when this discipline never loads," and the case where `work-item-shape` never loads is exactly the case where its restatement cannot help.

## An already-onboarded repo never gains the line, and that is correct

`onboard-repo` step 3 never adds a field to a block that already exists — the skill appends, and leaves what is there for the user to edit. So no repo wired before this change acquires the policy line, and none will.

That is the right behavior, and it is only tolerable because of the ruling below: the line is a **reinforcement**, not the mechanism. `work-item-shape`'s own routing gate is the mechanism, and it binds on the work's shape whether or not any line is present. A repo without the line loses a reminder, never the routing.

## The publishers name the publisher and stop; they do not refuse

Asked to file with raw `gh`/`az`, the routing gate names the right publisher, says what ad-hoc drafting would skip, and waits. It does not refuse the user's stated direction, and no skill is wired to block the call.

Refusal was rejected on two grounds. It would put a hard stop behind a discipline that is model-invoked, so the stop would be absent exactly when someone bypasses the pipeline deliberately — unenforceable where it matters. And it would override a direction the user gave in their own words, which the recommend-and-proceed rule reserves to the user: the gate's job is to make the cost visible, not to withhold the act.

## Consequences

- The policy line is registered in `DOMAIN.md` as the **Routing policy line** and in `README.md`'s Conventions list, so a reader of the config contract can learn it exists and a hand-edit has a spelling to match.
- `work-item-shape/SKILL.md` cites the block rather than quoting it, leaving one authored copy (`onboard-repo`) and one per wired repo.
- Repos onboarded before 2026-08-31 carry no such line. Nothing backfills them; `work-item-shape`'s routing gate covers them.
- Because the line reinforces rather than enforces, deleting it from a downstream `CLAUDE.md` costs a reminder and changes no behavior — which is what makes writing it into other people's repos acceptable at all.

## Deferred

- Whether `onboard-repo` should offer to *update* an existing `Issue tracker:` block when it finds one missing fields — a general question about the write-never-overwrite rule, not specific to this line, and one that touches every field step 2 asks for.
