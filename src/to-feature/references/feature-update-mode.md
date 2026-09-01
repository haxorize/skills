# Feature — Update mode

`--update <feature-id>` short-circuits the create flow. Skips tracker resolution (uses the existing Feature's project), parent resolution, codebase exploration, approach selection, and Feature drafting. Runs only step 6 (decomposition with quiz) and the story-map portion of step 8 (self-review), then patches the Feature description in place.

## Cold-start

Fetch the current Feature description in full so the patch can preserve everything outside the story-map markers.

- **ADO:** `az boards work-item show <feature-id> --output json` — pull `System.Description`. The AC field (`Microsoft.VSTS.Common.AcceptanceCriteria`) is not touched in this mode but read it to display active and removed AC IDs as cold-start context.
- **GitHub:** `gh issue view <feature-number> --json body,title`.

## Patch scope (invariant)

Only the text between `<!-- BEGIN STORY MAP -->` and `<!-- END STORY MAP -->` is replaced. A deferred Feature has no markers — there, replace the single sentinel line `Story Decomposition: deferred at Feature creation.` with a full marker-fenced story map; everything outside the sentinel is preserved the same way. The AC field and every other description body section (Problem, Goals, Non-goals, Approach, Constraints, Removed acceptance criteria) are preserved verbatim. AC IDs and the `## Removed acceptance criteria` history are therefore unaffected by `--update`.

The snapshot section above the `---` separator is one-shot replaced, preserving the tracker-ID stamps `to-story` has anchored onto Snapshot headings — re-draft the plan text, but every heading's ` — <a href="…">#<id></a>` stamp is carried into the corresponding heading of the new snapshot, because `to-story`'s ado-hierarchy Step 11 reads those stamps to project dependency relations and treats an unstamped heading as "not published yet". Emergent-Story entries that `to-story` appended below the separator are carried forward into the new snapshot text — `--update` re-snapshots the plan without losing the record of what shipped.

## Self-review (in `--update` mode)

Re-run the story-map checks from step 8 (every active Feature AC ID covered by at least one Story; no `Covers:` line references a removed AC ID; `### Naming consistency` dedup; dependency acyclicity). Skip the placeholder/contradiction/scope/ambiguity/domain checks — the rest of the body is untouched.

## Patch

- **ADO:** The fetched description is already HTML. Convert **only the new story map section** from Markdown to HTML (using the pandoc or Python one-liner from [ado-html-transport.md](ado-html-transport.md)), splice the result between the `<!-- BEGIN STORY MAP -->` and `<!-- END STORY MAP -->` markers in the existing HTML, write to a file, and patch with its absolute path:
  ```bash
  az boards work-item update --id <feature-id> --description @/absolute/path/description.html
  ```
  (description-only; do not pass `Microsoft.VSTS.Common.AcceptanceCriteria`). **Never pass the full fetched description through a Markdown → HTML converter** — it is already HTML and re-converting will double-encode any `<code>`, `<hr>`, and other HTML tags already present.
- **GitHub:** `gh issue edit <feature-number> --body-file <draft>`.
