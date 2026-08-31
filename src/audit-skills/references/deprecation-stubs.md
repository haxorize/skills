# Judging a Deprecation stub

Open this only when the skill under audit is a Deprecation stub — a retired name kept for one window so typed muscle memory lands somewhere. The body has already settled that a stub takes none of the Team-fit test; what is here is the second script run and the retire-or-extend rule, because its typist is the whole population.

The count comes from its own window, not the audit's: run `scripts/skill-usage.sh` a second time, at the root of the repo the entry's `readlink` resolves into, with `--since <the date the stub landed>`, since the audit's since-last-audit window can start after the stub did and miss typings that extend it. **Get that date from the repo, never from recall**: `git log --diff-filter=A --follow --format=%ad -- <path to the stub>` prints when it was added. Zero typed invocations of its name in that read's typed column retires it; any typing extends it one more window.

That column is one machine's: read it on every machine the typist works from, and a figure carrying `+` is a floor, not a total — so it is never a zero.
