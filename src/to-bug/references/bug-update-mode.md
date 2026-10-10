# Bug — Update mode

`--update <bug-id>` short-circuits the create flow and patches an existing Bug in place. Skips tracker resolution (uses the Bug's existing project), parent resolution (already linked or parentless), and severity resolution (already set; surface as cold-start context, prompt only on explicit change). Codebase exploration runs only when the proposed change expands the implicated layers.

## Cold-start

Fetch the current Bug body, repro steps, severity, and parent (if any):

- **ADO:** `az boards work-item show <bug-id> --output json --expand relations` — pull `Custom.Notes`, `Microsoft.VSTS.TCM.ReproSteps`, `Microsoft.VSTS.Common.Severity`, `System.State`, and the parent relation (`System.LinkTypes.Hierarchy-Reverse`). Where `Custom.Notes` comes back empty, read `System.Description` instead: a Bug whose `Custom.Notes` is empty keeps its body in `System.Description`, and that is the only copy.
- **GitHub:** `gh issue view <issue-number> --json body,title,labels,state`. Severity is read from the `sev:*` label; type confirmed by the `bug` label.

## Self-review (in `--update` mode)

Re-run all step 6 checks. The public-repo warning (step 7) re-runs if the body or repro changed and the tracker is GitHub.

## Patch

- **ADO:** convert Markdown → HTML for description and repro (using the pandoc or Python one-liner from [ado-html-transport.md](ado-html-transport.md)), each to a file, then `az boards work-item update --id <bug-id> --fields "Custom.Notes=@description.html" "Microsoft.VSTS.TCM.ReproSteps=@repro.html"` — `Custom.Notes` is the target org's custom Bug body field ([bug-template-ado.md](bug-template-ado.md) § Field mapping). When severity changed, add `"Microsoft.VSTS.Common.Severity=<n - Label>"` inside the same `--fields` list — never a second `--fields` flag, which replaces the first.
- **Patch the field the body was read from.** Where the cold-start read fell back to `System.Description`, write back there, not to `Custom.Notes`: patching the other field leaves the old body in place and the Bug carries two. Moving a Bug's body from `System.Description` onto Notes is a migration, not a side effect of an unrelated edit.
- **GitHub:** `gh issue edit <issue-number> --body-file <draft>`. Severity-label changes are applied via `gh issue edit --remove-label <old> --add-label <new>` only if explicitly changed.

State is never transitioned by `to-bug --update` — that's the team's process on the board.

## Naming drift

Run `work-item-shape`'s **Naming drift** rule over the patch.
