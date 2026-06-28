# Story — ADO Hierarchy

Steps that only apply when `Hierarchy: required` is set (ADO default). Skip if using GitHub without opting in via CLAUDE.md.

## Step 2a — Snapshot lookup

After resolving the parent Feature ID:

```bash
az boards work-item show <feature-id> --output json
```

Parse `System.Description`. Extract content between `<!-- BEGIN STORY MAP -->` and `<!-- END STORY MAP -->`; text above the `---` separator is the Snapshot.

If invoked with a story reference (e.g., `Story 2`, `S2`), search the Snapshot for a matching heading (e.g., `### Story 2`).

- **Match found (Planned Story):** Extract the entry's scope paragraph, `Covers:` line, and shared names as drafting source material (steps 3–6). Record the full matched heading line for the stamp in Step 10.
- **No match or no story reference (Emergent Story):** Draft from conversation context. The Append-region append in Step 10 applies.

If the parent has no story-map markers but has a headed decomposition section (literally `<h2>Story Decomposition</h2>` in the HTML or `## Story Decomposition` as a Markdown heading — not an informal list or any other structure), treat as Emergent Story. If the parent has neither markers nor a headed decomposition section (or no parent), skip this step and treat as Emergent Story.

## Step 10 — Update parent's story map

**Planned Story** (Snapshot match in step 2a): Fetch the parent Feature's current description. Locate the matched `### Story N — <title>` heading. Append the new tracker ID:

```
### Story 2 — short title — [#<id>](https://dev.azure.com/...)
```

Do not modify any other Snapshot content. **The description returned by the ADO API is already HTML** — make the stamp as a targeted string replacement on the raw HTML. In the fetched HTML, locate the heading text and append ` — <a href="https://dev.azure.com/...">#{id}</a>` directly. Write the modified HTML to a temp file and patch:

```bash
az boards work-item update --id <feature-id> --description "$(cat /tmp/feature_desc.html)"
```

**Never pass the fetched description through pandoc or a Markdown converter.** It is already HTML; re-converting will double-encode any `<code>`, `<hr>`, and other HTML tags already present.

**Emergent Story** (no Snapshot match): After publishing, fetch the parent Feature's description. Locate `<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->`; append an entry below the separator with this Story's tracker ID, scope summary, parent Feature AC IDs it covers (`Covers: AC1, AC3`), and shared names. The Snapshot above the separator is immutable.

**HTML safety for both cases:** Convert **only the newly authored content** from Markdown to HTML (using the pandoc or Python one-liner from `story-template-ado.md`). Append or splice the resulting HTML fragment into the existing description HTML. Never pass the combined content — fetched description plus new entry — through a Markdown → HTML converter (it double-encodes the existing HTML).

Three cases:

- **Has markers:** append using the standard marker-bounded region.
- **No markers, but has a headed `## Story Decomposition` section:** append to end of description; warn: "Parent feature has no story-map markers — appended to the end of the description. Consider adding `<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->` markers." An informal list or any other structure does not qualify.
- **No markers and no headed decomposition section (or no parent):** skip silently.

On failure: revision conflict → retry once with fresh fetch; permission denied → surface immediately (no retry); other error → surface with the published Story ID for manual update. The Story always publishes regardless.
