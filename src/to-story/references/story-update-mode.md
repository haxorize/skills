# Story — Update mode

`--update <story-id>` patches an existing Story in place. Skips tracker resolution (uses the Story's existing project), parent resolution (already linked), approach selection (already chosen at creation), the parent's map stamp (step 10), and relation projection (step 11) — a re-snapshot of the parent map is `/to-feature --update`'s job, not this one's. Runs codebase exploration only when the proposed change expands scope.

## Cold-start

Fetch the current Story body, AC field, and parent Feature body:

- **ADO:** `az boards work-item show <story-id> --output json` — pull `System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, and the parent relation. Then `az boards work-item show <parent-feature-id> --output json` — pull description and AC field.
- **GitHub:** `gh issue view <story-number> --json body,title`. Resolve parent via the `Parent: #N` line; fetch parent body the same way.

Parse:

- **Active Story AC IDs** from the AC field (ADO) or `## Acceptance criteria` section (GitHub).
- **Removed Story AC IDs** from `## Removed acceptance criteria` in the Story description body (not the AC field on ADO — ADO's AC field is overwritten on each update, making the description body the stable home for removed history).
- **Active parent Feature AC IDs** — validates that `Covers:` references in the parent's story map resolve cleanly.

## AC ID handling on revision

ID mechanics — append-only, next unused integer, the removed-criteria record — are `~/.claude/skills/work-item-shape/references/ac-ids.md`'s. The revision-specific rule:

- **Edit-in-place** keeps the same AC ID. Default for wordsmithing or tightening.
- **Substantive change** (semantics shift, not wording): prompt the user — edit-in-place (keep ID) or remove+add per the ID mechanics.

## Self-review

Re-run all step 7 checks. Two are additionally load-bearing:

- **Append-only invariant:** the union of post-update active and removed AC IDs is a superset of pre-update active and removed AC IDs; no pre-existing ID has changed text without the user explicitly choosing edit-in-place.
- **`## Layers touched`** still populated for each layer. Any layer that flipped from present to `none`, or vice versa, is a re-snapshot signal.

## Re-snapshot prompt for parent

If the update materially changes scope (added/removed ACs, changed module list, layer reshape visible in the parent's story map), prompt the user to also run `/to-feature --update <parent-feature-id>`. The skill does not auto-cascade.

Sibling `Covers:` references on the parent's emergent-Story entries are not validated here; they're validated when `to-feature --update` next runs.

## Reconcile prompt for child tasks

If the update adds or removes ACs, changes the module list, or reshapes layers, prompt the user to also run `/to-tasks --reconcile <story-id>`. Do not prompt for title-only or wording-only updates.

## Patch

- **ADO:** Patch through the script, which converts each `.md` and reads every rich-text field back. Always patch the title — scope changes that trigger `--update` frequently invalidate the prior title. `update` applies the tracker block's `Title prefix:` itself, idempotently, so pass the drafted title without it:
  ```bash
  python3 ~/.claude/skills/work-item-shape/scripts/tracker.py update <story-id> --type Story --title '<updated title>' \
    --body <scratchpad>/description.md \
    --field "Microsoft.VSTS.Common.AcceptanceCriteria=@<scratchpad>/acceptance.md" --workdir <scratchpad>
  ```
  When `--priority <1-4>` is passed, add `--field "Microsoft.VSTS.Common.Priority=<priority>"` to this one update — the same single-write-path rule as create; without it the field is left untouched. A caller that drafts priority on every run, such as `inventory-cvits`, passes it only to escalate, so an update never lowers a priority someone raised by hand.
- **GitHub:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py update <story-number> --type Story --title '<updated title>' --body <scratchpad>/<draft>.md --workdir <scratchpad>`.

On ADO, an `update` exit 5 with `incomplete=readback:<field>` is a failed patch, just as on a create: fix the file and patch that field again.

The naming-drift check in SKILL.md applies to patches the same as to publishes.
