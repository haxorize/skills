# Evidence travels with the claim

Depends: `committing`, `review-changes`, `implement`, `receiving-review`
Why not a hook or lint: the claims this governs are made in chat output, which no gate sees.

A self-report — a status line, a count, a "done", a "tests pass" — carries its evidence **in the same message**, or it carries the marker `UNVERIFIED:`. There is no third state; a confident sentence with no evidence and no marker is the failure.

- **Re-measure every count at write time.** A number stated from memory is a guess wearing a number's clothes. If it matters enough to report, it matters enough to run the command again now — and the count comes with the command and its verbatim output, inline, once. That is the whole evidence for a count; no proof blocks, no receipts, no command logs.
- **Recall check.** A summary of a change enumerates `git log <base>..HEAD --oneline` and every commit appears somewhere in it. A commit the summary does not reflect was missed, and the miss is reported, not absorbed.
- **Name your own corrections.** When a number or claim you stated earlier turns out wrong, say "earlier I said 34; it is 17" — never restate the right figure as if it had always been so.
- **Inspection is not execution.** Having read a test, a script, or a command is not having run it. "I ran X" means X ran in this session, and its output is what you cite.
- **A claim about the transcript needs a transcript grep.** "You said", "we agreed", "as discussed" cite the turn. Memory of a conversation is the least reliable evidence in it.
- **After a command that exits 0 regardless, verify the effect, not the status.** `sed -i` on a pattern that matched nothing, `az boards work-item update` on a field it ignored, a `git push` to the branch that was already up to date: check the file, the item, the remote.
- **A correction binds its whole category, immediately.** Told that one count was wrong, re-measure every count in the message — including the ones used to check the others.
- **Prose is a first draft.** A report written at the end of long work is a hypothesis about what happened; say so where the evidence is thin rather than letting the register imply certainty.
