# Target modes beyond uncommitted self-review

Opened from §1 only when the target is a teammate's PR, an already-landed commit, a self-review whose changes are already committed, or a change with fix commits already on top — and from the Notes on **any re-review**, uncommitted work against `HEAD` included, for what a revision may withdraw (the last paragraph below). A first self-review of *uncommitted* work stays inline in §1.

## A teammate's PR

Fetch the PR diff (`gh pr diff <n>`, or the tracker's equivalent). When the PR carries earlier review threads, read the author's replies with their own red flags: a boilerplate "I've addressed your concern" that never engages the substance, a commit body that is the issue text verbatim rather than the author's own understanding, and a fix that doesn't match the feedback given, with no explanation of why.

In PR mode the review's conventions — `DOMAIN.md`, `docs/adr/`, `CLAUDE.md`'s review block — come from the PR's own refs like every other file it reads, never from whatever is checked out here: fetch the head as a ref, not a checkout (`git fetch origin pull/<n>/head:refs/review/<n>`, or the tracker's file-at-ref read), then `git show refs/review/<n>:<path>`. A file the PR did not change is not exempt, and every path resolves against this checkout too, so nothing warns.

**No tree stamp at all.** Say why in the header ("no tree stamp — PR mode; the reviewed tree is not this machine's"). The stamp is a receipt that lets a local push through, and a review of someone else's branch must never mint one for whatever happens to be sitting in your working tree.

## An already-landed commit

Audit a merged change; base = the commit's parent (or merge-base). The tree stamp for committed work — a landed commit, or a self-review whose changes are already committed — is `git rev-parse <target>^{tree}`, the tree the diff actually covered. The working-tree one-liner is wrong here: it folds in uncommitted dirt the review never read, so the stamp would never equal the reviewed commit's tree and the push of the reviewed work would block until the *unreviewed* dirt was committed too.

## Fixes already on top of the change

The base is a choice, so make it out loud: the pre-fix base reviews the whole change with its fixes folded in, while the fix commits alone review only what the last round produced. Both are legitimate targets; an unstated one isn't, because the reader can't tell reviewed-and-clean from never-looked-at. Name the base and the file set it covers in the report.

A re-review withdraws a blocking finding only when the revision contains a concrete fix for the exact deficiency, or the original application of the criteria was mistaken — the author's disagreement alone never downgrades it.
