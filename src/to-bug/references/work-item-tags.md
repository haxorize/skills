# Work-item tags (ADO)

Derive tags from the **drafted** title — before any `Title prefix:` is prepended — then set `System.Tags` on the `az boards work-item create` call.

## Primary tag — the drafted title's leading bracket

If the drafted title leads with a `[...]` bracket, that bracket's **contents** (trimmed, case preserved) are the primary tag; the brackets themselves never travel — `[HMF Catalog] Add publish wizard…` → tag `HMF Catalog`, not `[HMF Catalog]`. A drafted title with no leading bracket yields no primary tag. Parse before prefixing: a prepended `Title prefix:` may itself carry a bracket, and prefix text is tracker plumbing, not the work item's domain.

## Per-repo declarations

Two optional lines in the CLAUDE.md tracker block adjust the set:

- `Additional tags:` — entries (bracketed or bare), normalized the same way and unioned with the primary tag. They augment, never replace.
- `Never tag:` — bracket contents dropped from the set after derivation, for a repo whose title namespace includes a bracket that must not become a tag.

A repo declaring neither yields just the primary tag, or none.

## The `debt` tag

An item whose work is paying down debt — a deferral's follow-up, a placeholder's replacement, a flag's removal, a cleanup a review parked — carries the tag `debt` beside the derived set, so the tracker can be filtered for it: debt is a ticket, never a register kept elsewhere.

## Applying

Join the deduplicated set with `; ` (ADO's tag separator) and pass it as one more `key=value` pair — `"System.Tags=<tag1>; <tag2>"` — **inside the create call's existing `--fields` flag**. Never add a second `--fields` flag: a repeated flag replaces the earlier one, silently dropping the other fields. An empty set omits the pair entirely.

Tagging is best-effort, stamped once at creation. If the create fails because the org denies tag creation (a derived tag doesn't exist yet and permissions block defining it), retry the create without the `System.Tags` pair and give the user the tag list with the manual command to apply it: `az boards work-item update --id <id> --fields "System.Tags=<tag1>; <tag2>"`. Later drift from a title rename is accepted and not reconciled.
