# The `to-*` publishers are model-invoked

`to-feature`, `to-story`, `to-tasks` and `to-bug` are model-invoked, so an engineer can ask for a work item in plain words ("file a bug for this", "break story 4812 into tasks") and the right publisher loads without anyone typing `/to-*`. This reverses the publisher clause of [ADR-0015](0015-model-invoked-vs-user-invoked-split.md), which kept them user-invoked so that a tracker write could not auto-fire, and the one-funnel argument of [ADR-0044](0044-work-item-shape-extracted-behavior.md), which had `work-item-shape`'s wide description catch every creation ask and stop to name the publisher. Nick decided this on 2026-10-20, after his team's standup raised typing the command as friction ("make all /to-* skills model-invoked"). He chose all four publishers at once over the two-publisher pilot the previous session recommended.

The safety ADR-0015 relied on moves from the invocation type to the write itself. No create call goes out until `work-item-shape/references/publishing.md` § Publish gate holds: a turn in which the user approved this exact draft, a dedupe search, and an approval ask that names the delete command for the item about to exist. A publisher that fires on its own therefore drafts and asks, and the human's yes is still the only thing that writes to the tracker. What changes is who starts the draft, not who approves the publish.

The measurement behind it is in `~/code/lib/_rounds/2026-10-12/probes/d87/` (run 2026-10-20, Sonnet 5.5 and Opus 5.5, a roster of every model-invoked description plus the four new ones, in a repo wired to an ADO tracker). The 14 plain-words creation asks fired the right publisher alone on both models, 28 of 28, with no wrong-tier fire. The 10 near misses ("is this a bug?", "what should this story say", "implement story 4812") fired no publisher, 0 of 20. The four descriptions cost 1,704 bytes on every turn: `scripts/lint-skills.sh` measured the launch-loaded surface at 16,795 bytes before and 18,499 bytes after, at `6445111`.

The same probe found the one thing that would undo the change. `onboard-repo` wrote a routing policy line into every wired repo's `CLAUDE.md` ending "name the right publisher and stop", and with that line in context Opus fired 6 of 14 creation asks and Sonnet 12 of 14, each Opus miss citing the line. The line now ends "load the right publisher", and with it in context both models fired 14 of 14 creation asks and none of the 10 near misses. Repos onboarded with the old wording need it edited by hand; Nick approved the rewrite on 2026-10-20.

**The gate.** Hard to reverse: the routing policy line now lives in other repos' `CLAUDE.md` files, which this repo cannot reach, and engineers learn to ask in plain words rather than type a command. Surprising without context: a reader of ADR-0015 expects consequential publishers to be user-invoked. A real trade-off: one wide funnel that stops and names a command (ADR-0044's choice) covers the phrase space with one description and keeps every tracker write behind a typed command, and a team can reasonably prefer that.

## Considered Options

- **Keep the funnel and the typed command (ADR-0044).** Rejected: the friction is the typing itself, and the funnel's answer to a casual ask is still "type `/to-story`".
- **Pilot `to-story` and `to-bug` first.** Rejected by Nick: probing all four costs the same as probing two, and the probe came back clean for all four.

## Consequences

- A model-invoked skill is named as ``Call the Skill tool with `to-story` `` wherever the model fires it; lint fails the `/to-story` slash form for a model-invoked skill. The callers that printed a `/to-*` command for a human to type (`inventory-cvits`, `triage-cvits`) now call the publisher, whose Publish gate still asks before each write.
- The publishers drop their `Launching skill: work-item-shape` load gate: a model-invoked skill has no human watching for the line.
- `work-item-shape`'s routing gate loads the publisher rather than stopping to name it.

Revisit when: a publisher drafts or asks on a message that asked for no work item, seen in a session, or a re-run of the `probes/d87/` kit fires a publisher on a near miss.
