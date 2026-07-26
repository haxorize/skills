# Story — Update mode

`--update <story-id>` patches an existing Story in place. Skips tracker resolution (uses the Story's existing project), parent resolution (already linked), and approach selection (already chosen at creation). Runs codebase exploration only when the proposed change expands scope.

## Cold-start

Fetch the current Story body, AC field, and parent Feature body:

- **ADO:** `az boards work-item show <story-id> --output json` — pull `System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, and the parent relation. Then `az boards work-item show <parent-feature-id> --output json` — pull description and AC field.
- **GitHub:** `gh issue view <story-number> --json body,title`. Resolve parent via the `Parent: #N` line; fetch parent body the same way.

Parse:

- **Active Story AC IDs** from the AC field (ADO) or `## Acceptance criteria` section (GitHub).
- **Removed Story AC IDs** from `## Removed acceptance criteria` in the Story description body (not the AC field on ADO — ADO's AC field is overwritten on each update, making the description body the stable home for removed history).
- **Active parent Feature AC IDs** — validates that `Covers:` references in the parent's story map resolve cleanly.
- `.claude/queue.md` entries (or memory equivalent) that mention this Story's tracker ID — surface as cold-start context.

## AC ID handling on revision

AC IDs are append-only across the active list and `## Removed acceptance criteria`:

- **Edit-in-place** keeps the same AC ID. Default for wordsmithing or tightening.
- **Substantive change** (semantics shift, not wording): prompt the user — edit-in-place (keep ID) or remove+add. Remove+add moves the old AC to `## Removed acceptance criteria` with strike-through, the removal date, and a one-line reason. The new AC takes the next unused integer past `max(active ∪ removed)`.
- **New AC** always takes the next unused integer.
- **Removed AC** moves to `## Removed acceptance criteria` (description body, not the AC field). Never reuse its ID; never renumber gaps.

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

- **ADO:** Convert Markdown → HTML using the tempfile pattern from step 9 (write to file, pass via `$(cat ...)`). Always patch the title — scope changes that trigger `--update` frequently invalidate the prior title:
  ```bash
  az boards work-item update --id <story-id> \
    --title "<updated-title>" \
    --description "$(cat desc.html)" \
    --fields "Microsoft.VSTS.Common.AcceptanceCriteria=$(cat acs.html)"
  ```
- **GitHub:** `gh issue edit <story-number> --title "<updated-title>" --body-file <draft>`.

On ADO, read the AC field back after patching, per step 9 — a patch can bury criteria in the description just as a create can.

## Naming-drift queue

If the patch introduces names differing from siblings (other Stories under the same parent Feature, or Tasks under this Story), append an entry per [naming-drift-queue.md](naming-drift-queue.md), which also covers surfacing the drift as a self-review warning and the never-block rule.
