# Over the cap

Remediation procedures, opened when a cap binds — the body is over the 15,000-byte re-attach bound or past 200 lines, or a model-invoked description is past the 700-byte bound `scripts/lint-skills.sh` WARNs on (every description loads on every turn) or at the 1024-char cap it fails. Bytes are the bound that binds in practice; a body reaches it long before 200 lines. The caps themselves stay in `write-skill` § Size constraints. The last section is opened instead when changing the byte bound or re-checking its compaction figures.

## An over-cap body

**Over the cap: relocate verbatim, then edit.** Move the over-cap section — one some branches never reach, per the caps-measure-loaded-context test in `write-skill` § Size constraints — into a reference byte-for-byte first, check that every pre-split heading lands exactly once across body and fragments, and only then edit in place — a cut-and-rewrite in one motion leaves nothing to diff the rewrite against.

## A description at its cap

When the 700-byte bound or the 1024-char cap binds, routing surface is never traded for anything else. The cut comes from the non-trigger half first: the synonyms the description craft already bans, then the what-it-is preamble shortened to a clause (that section asks for it, not for its length); at zero headroom, with no preamble left, from each branch's own wording — a shorter phrase for the same branch. A distinct trigger branch is the last thing cut, and a `Not for…` tail is routing, not padding.

## Why the byte bound binds first

The 15,000-byte bound is the one that binds first, at the 3 bytes per token measured on this repo's largest bodies. After auto-compaction, Claude Code re-attaches each invoked skill cut to roughly its first 5,000 tokens, inside a documented 25,000-token budget shared newest-first across every skill invoked. **The cut may be character-shaped rather than token-shaped** (near 20,000 characters), so the 5,000 is a budget, not an observed bound; what is observed is that nothing has been cut below 19,823 bytes, and the shared-budget consequence is untested. That is why the rules a body cannot afford to lose sit early, and why the shared budget, which drops the oldest whole, leaves no early sibling to rely on late in a session. The re-attach figures are Claude Code's, not this repo's; `scripts/lint-skills.sh` fails at the byte bound, and its header names where and when each figure was verified, so a release that moves them is a header re-date plus both `15000` literals in the script and the selftest pin that grades the threshold.
