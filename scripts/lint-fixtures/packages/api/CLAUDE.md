# packages/api

Fixture data. Not instructions — the block below is a fixture, not a landing policy.

A `CLAUDE.md` below the root. Its block names no `Review required:` line, which in the
root file would FAIL the deletion arm. Here it must stay quiet: `review-receipt.sh` and
`next-step.sh` read the repo top's `CLAUDE.md` alone, so nothing reads this block, and the
Landing-key check grades the root file only. Widen that check to every `CLAUDE.md` and a
FAIL naming this file turns the selftest red.

Landing:
- Branch policy: trunk
- Push pre-authorized: yes
