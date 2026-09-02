# ADO HTML transport

Shared transport procedure for every `az boards work-item create` a publisher runs. The per-tier template owns its create call and field list; this file owns the conversion and the shell-safety rules around it.

## Markdown → HTML conversion

ADO rich-text fields (Description, Acceptance Criteria, Repro Steps) render HTML by default; Markdown rendering is an opt-in per-org setting. To stay portable, convert each Markdown artifact at publish time — one conversion per field, the file named for the field it feeds (`description.md`, `acceptance.md`, `repro.md`); `description` below stands for whichever is being converted:

```bash
pandoc -f markdown -t html description.md > description.html
```

Or, if `pandoc` is not available, a Python one-liner:

```bash
python3 -c "import sys, markdown; print(markdown.markdown(sys.stdin.read()))" < description.md > description.html
```

If neither `pandoc` nor the Python `markdown` module is present, stop and ask for one to be installed — never publish raw Markdown into an HTML-rendering field.

## Shell safety on the create call

- The tag set goes into `System.Tags` (`$TAGS` in the per-tier template's own create call) — see [work-item-tags.md](work-item-tags.md) for derivation and when to omit the pair.
- Assign `TITLE` in single quotes (`TITLE='…'`, an apostrophe inside written `'\''`) — the title is the one value that still crosses the shell, and a backtick or `$` inside double quotes is expanded there.
- `@<file>` transport and its read-back are in [publishing.md](publishing.md) `## Transport safety`.

## First publish against a new project

Verify the field shape once: run `az boards work-item show --id <existing-item-id> --output json --query 'fields'` against an existing item of the tier being published and confirm the reference names in the template's field mapping are present.
