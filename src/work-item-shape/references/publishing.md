# Publishing

The procedure around a tracker create, for the skills that perform one. Tracker *resolution* — the three modes and the required fields — is [tracker-resolution.md](tracker-resolution.md).

Every create, update and link goes through `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py` — `work-item-shape` owns the one copy. It carries every rule with one right answer — prefix, tags, labels, conversion, read-back, links — and `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py <command> --help` lists them. None is applied by hand, and no raw `gh issue create` or `az boards work-item create` goes out beside it. Claim, close and label edits go through it too (`assign`, `close`, `label`), and a tag apply after a create is `update --field "System.Tags=A; B"`. Pass `--workdir <scratchpad>` on every create and update so the converted files land there.

## Publish gate

No create call goes out until all four hold:

- **A confirming turn exists to cite.** The user approved the draft in a turn you can point to; "looks good" on an earlier version, or approval of the plan the draft came from, is not approval of this body. Never create mid-grill — the grill settling is not the ask.
- **A dedupe search ran.** Run `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py search --terms "<the title's key terms>"` and show any near match; a match means update or link, not a second item.
- **The approval ask names the undo.** The ask that seeks the confirming turn names the command that deletes the item it is about to create (`gh issue delete <n>` / `az boards work-item delete --id <n>`), so the cost of a wrong yes is visible before it is given.
- **The draft shown is the draft published.** Any edit after the confirming turn — a reworded criterion, a changed parent — re-shows the body and waits for a fresh confirmation. The publish report cites the confirming turn.

## Flags the script cannot derive

- **`--debt`** when the item's work pays down debt — a deferral's follow-up, a placeholder's replacement, a flag's removal, a cleanup a review parked. ADO tags it `debt` and GitHub labels it, so the board filters for it.
- **`--title` in single quotes** (`--title '…'`, an apostrophe inside written `'\''`). The title is the one value that still crosses the shell, and a backtick or `$` inside double quotes is expanded there.
- **A title's leading `[bracket]`** is the item's domain, and on ADO its contents become the primary tag. Draft it without the `Title prefix:`; the script prepends the prefix after deriving the tags.

## When a required field is missing

The script exits 1 naming the missing CLAUDE.md line. Relay it as an "add this to CLAUDE.md" message — never guess a project, area path, or label set.

## When the write is blocked

A blocked tracker write (auth, sandbox, policy), or exit 4 for no `gh` or `az` on PATH, re-runs the same command with `--dry-run`. That makes no tracker call and prints every call the write needs, with the converted body files at their absolute scratchpad paths. Those lines are the manual-commands block — never a body pasted into chat. Exit 4 naming no Markdown converter is different: stop and ask for `pandoc` (or Python's `markdown` module) to be installed, because raw Markdown never goes into an HTML-rendering field.

## Transport safety

A create call is not idempotent. The script exits 1 after one failed create and never retries it: the error may have arrived after the write committed, and a blind retry double-files. Run `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py search` for the title before trying again. Never cite a query result or command output you didn't actually run this session, and never attach a link you haven't resolved.

A rich-text body travels as a file, never through the shell. Hand the script the Markdown by its scratchpad path: `--body <scratchpad>/description.md`, and `--field "<Reference>=@<scratchpad>/acceptance.md"` (or `@<scratchpad>/repro.md`) for each further rich-text field. A bare `description.md` resolves against the repo, where a stale copy would publish. The script converts each into `<workdir>/<type>-<slug>/`, passes it by absolute path, and reads the item back.

**Exit 5 means written but incomplete:** the item exists, `id=` and `url=` print first, then one `incomplete=` line. Never re-run the create — that double-files.

- **`incomplete=readback:<field>`** — the field came back empty or as a literal `@path`, a failed publish. Fix the file and patch with `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py update <id> --field "<Reference>=@<scratchpad>/<file>"`.
- **`incomplete=link:<parent>`** — the item landed unlinked. Surface both numbers, and re-run `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py link --parent <parent> --child <id>`.

Acceptance criteria — `to-feature` and `to-story` only; ADO Tasks and Bugs have none, and `chart-course` publishes none — travel as their own `--field "Microsoft.VSTS.Common.AcceptanceCriteria=@<scratchpad>/acceptance.md"`, never inside the description. Buried criteria aren't queryable, and child items' `Covers:` lines then point at IDs no field holds.

Before the first publish against a new ADO project, run `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py show <existing-id>` on an item of the tier being published and confirm the reference names in the template's field mapping are present.

## First item of a batch alone

A batch of creates — a `to-tasks` run, a Feature followed by its Stories — publishes its first item alone, and you open that item as the tracker renders it before the next create goes out. A mangled render (a GitHub body whose markdown broke, an `incomplete=readback` exit 5) stops the batch until the body is patched with `update` and the first item re-checked; only then are the rest created, from the fixed body. Every item created before the check carries the same defect. An `incomplete=link` exit 5 does not stop the batch: report both numbers, re-run the link, and continue — a missed link is never tightened into a publish failure.
