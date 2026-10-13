# Landing zone and filename shape

The contract `handoff` § Where to write it points here for, and `scripts/landing.sh` beside this directory implements: open this when adding a kind, or writing a file of a kind the script does not name.

One filename shape, `<repo>-<date>-<slug>.<kind>.<ext>`, and **a handoff is the one kind with no kind segment at all**:

- a handoff: `<repo>-<date>-<slug>.md` — **no kind segment**
- a `review-changes` report: `<repo>-<date>-<slug>.review.md`
- an `audit-skills` working file: `skills-<date>-<slug>.audit.md`
- an `ask-for-me` questionnaire: `<repo>-<date>-<slug>.questionnaire.md`
- a `review-architecture` report: `<repo>-<date>-<slug>-<HHMMSS>.design-review.html`

where `<date>` is `YYYY-MM-DD`, `<slug>` names the focus, and `<repo>` is the basename of `git rev-parse --show-toplevel` — except for the `.audit.md` kind, whose subject is the installed skill suite rather than a repo and which therefore takes the fixed word `skills`, so two audits run from different working directories resolve to the same name. The `.design-review.html` kind additionally carries the run's time (`HHMMSS`) at the end of its slug, because that report is timestamped per run and frozen at pick-time, and a date alone would let a second run overwrite the first. A new kind takes a new segment here rather than a name of its own shape.

**Picking one up: a handoff is the file with no kind segment.** Match `<repo>-<date>-<slug>.md` where `<slug>` carries no `.`; that is the positive rule `landing.sh latest` applies, and it is what keeps "the newest handoff" from resolving to a report, an audit working file, or a questionnaire, all three of which are `.md` files sharing the same prefix. A handoff is throwaway — the durable content lives in the artifacts the doc points at — and the fixed names are what let `/review-changes` and `/implement latest` pick up the newest handoff, and `/address-findings` the newest report, without a pasted path.

One fixed **landing zone**, `claude-handoffs/` under the platform temp dir (`$TMPDIR`, else `/tmp`; `landing.sh` runs `mkdir -p`), for the first three kinds. The other two share the shape and land elsewhere, which is stated here rather than left to be discovered from the two skills: an `ask-for-me` questionnaire lands **in the current directory**, because it is handed to a person rather than picked up by a later session, and a `review-architecture` report lands in the **temp root**, not `claude-handoffs/`, because nothing globs for it — it is opened once, by path, in the session that wrote it.

A new kind is added in three places at once: the list above, `landing.sh`'s `--kind` roster, and its selftest.
