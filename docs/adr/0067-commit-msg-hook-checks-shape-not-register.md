# The commit-msg hook checks message shape, and deliberately not register

Status: accepted (2026-08-28)

The house commit style was being missed in practice. `committing` holds it, but the style itself lives one link away in `references/commit-style.md`, and reaching it takes two soft steps: the model has to reach for the skill on its description, then follow the link. `committing` is **model-invoked**, so it can carry no load gate of its own — a gate lives in the caller, and a skill the model reaches autonomously has no caller to put one in. We added `scripts/git-hooks/commit-msg`, which rejects a message that breaks the deterministic half of the style and names the reference file in the rejection, so the block is also the load instruction. It is the watcher a model-invoked skill cannot carry, and it is the same shape as the `review-receipt` hook one layer down: neither can judge quality, both force the step to have happened.

**The gate.** *Surprising without context* — clears: the obvious reading of a style checker is that it checks the style, and this one deliberately checks less than half of it. *Real trade-off* — clears: the alternative was leaving the rule prose-only and strengthening the load path instead, which a rational team would pick to avoid a gate that gives false assurance. *Hard to reverse* — fails; deleting a hook file costs nothing. Two of three, so this is its own record rather than an amendment.

**What it does not check, on purpose.** One logical change per subject, whether the body's *why* was non-obvious enough to need writing, the register, and every entry in `writing-for-humans`' `tell-catalog.md` — "Tricolon habit", "Faux-insight setup", "Empty emphasis". Those need a reader, and the observed complaint ("the message wasn't written for humans") is mostly in that half. A hook that appeared to cover it would be worse than none.

**So the style doc is not pruned against it.** `write-skill`'s **Scaffolding** rule says a rule the tooling enforces is a cache of that enforcement, which would normally license trimming the prose once a checker exists. That rule holds only where the check fails the exact violation, and here it fails a strict subset. The hook's own header and `CLAUDE.md` both say so, because the pruning pressure will recur every time someone reads the two side by side.

**A git hook rather than a Claude Code hook.** A `PreToolUse` hook on Bash — the shape the three hooks under `global/hooks/` take — sees only what is on the command line, so a message supplied through an editor or a file is invisible to it. The `commit-msg` hook sees the final message however it arrived. It also covers commits made by hand, not only the agent's. `commit-bypass.sh` already blocks `--no-verify`, so this layer was agent-proof before it was written.

**The imperative-opener check warns rather than blocks**, because it is a wordlist heuristic over the "Added/Adds/Updated/Fixes" family and will sometimes be wrong about a legitimate subject. Every other rule is exact and blocks.

## Consequences

- `bash scripts/setup-hooks.sh` now enables two hooks, not one. Opting in for auto-hoist also starts rejecting commit messages — the README says this where the opt-in is described, since it is the surprising half.
- The hook is inert until that opt-in runs; `core.hooksPath` is per-clone and uncommitted, so the work-machine mirror needs its own.
- Writing the self-test found a live defect the hook shipped with for an hour: the git-comment strip used a BRE alternation BSD `sed` does not support, so on macOS it never stripped anything. A short comment line violates no rule, which is why the first fixture passed either way. Making the fixture's comment lines long enough to trip the wrap rule turned an inert row into a graded one and surfaced the bug — the argument for grading a check by mutation rather than by reading it.

## Revisit when:

`commit-style.md`'s deterministic half changes, or the tell catalog gains an entry that is genuinely greppable — the split between the two halves is what this record decides, and it is drawn where machine-checkability falls today.
