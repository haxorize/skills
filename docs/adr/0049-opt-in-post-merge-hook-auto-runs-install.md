# Opt-in post-merge hook auto-runs install.sh

## Context

`scripts/install.sh` (ADR-0007, ADR-0016) is user-initiated: after a `git pull` that adds, renames, or removes a skill, the maintainer must re-run it by hand or `~/.claude/skills/` drifts out of sync with `src/`. The failure is silent — a newly pulled skill simply isn't hoisted, and nothing signals the gap until the skill is reached for and missing.

A `post-merge` git hook removes the manual step: git runs it after every merge (including the merge half of a `git pull`), so install.sh re-runs automatically. Two facts constrain how this can be delivered:

- Git hooks live in `.git/hooks/`, which is **not** version-controlled — a committed hook body cannot install itself. The standard workaround is to commit the hook under a tracked directory and point `core.hooksPath` at it.
- Redirecting `core.hooksPath` to a committed directory means **any** hook in that directory — present now, or added by a future pulled commit — executes automatically on its git event, under the user's UID, with no further prompt. Because this repo is symlinked into `~/.claude/skills/`, that execution surface reaches the Claude Code config directory.

That last point is the load-bearing trade-off: convenience (no manual install) is bought with standing consent to auto-execute committed scripts on pull. It is inherent to every committed-hooks setup (Husky, pre-commit, et al.), not specific to this implementation.

ADR-0016 fixed the install *model* — per-skill symlinks, `install.sh` as the resolver, "no plugin migration." This decision is about *when* install runs, and does not move that premise: the symlink model, dependency resolution, and cherry-pick portability are all untouched. An amendment to 0016 would therefore be the wrong instrument; this is a new, additive decision.

## Decision

- **Add an opt-in `post-merge` hook.** `scripts/git-hooks/post-merge` re-runs `install.sh` after a merge. `scripts/setup-hooks.sh` is the one-time, per-clone opt-in that sets `core.hooksPath` to the committed hooks directory. Neither is active until a user runs the setup script.
- **The symlink/per-skill install model of ADR-0007 and ADR-0016 is unchanged.** The hook only automates *invocation* of the existing `install.sh`; it adds no plugin model, no new install mechanism, no change to dependency resolution.
- **Accept the committed-hooks trust trade-off.** For a personal, single-maintainer skills repo, the supply-chain surface is the maintainer's own commits; the convenience is worth the standing-consent cost. The acceptance is made *informed*, not silent: the README opt-in states plainly that enabling the hook auto-runs committed scripts on every pull, and to enable it only on a repo whose commits you trust.
- **The hook never blocks the pull and never fails silently.** A `post-merge` non-zero exit cannot abort a merge (git ignores it), so a failed sync must announce itself with an actionable message rather than scroll past as buried noise.

## Considered Options

- **Amend ADR-0016** — rejected: 0016's premise (the install model) has not moved; the hook is additive automation over it. Amendment is for a standing decision whose premise shifted, which is not this.
- **No ADR (treat as mere tooling)** — rejected: the hook changes *when* install runs and introduces an auto-execution surface; the ADR-gate discipline records exactly this class of change, and the commit-order rule wants the rationale committed before the tooling.
- **Confirmation gate in `setup-hooks.sh`** (prompt before enabling) — rejected as heavier than a personal repo needs; the opt-in *is* the gate, and the README makes its consequence explicit.
- **Opt-in post-merge hook + informed acceptance + new ADR** (chosen).

## Consequences

- New tracked directory `scripts/git-hooks/`. This is the first committed-hook artifact in the repo; future hooks would live here and inherit the same auto-execution property.
- `install.sh` now runs from two contexts (manual and hook-driven); its idempotency and re-run safety, already relied on by ADR-0016, become load-bearing for the automated path too. Pre-existing hardening gaps in `install.sh` (unquoted `requires:` expansion, `prune_stale` prefix matching) gain a lower-friction trigger and are worth tightening, tracked separately.
- The hook fires on *any* merge, not only `git pull` — `git merge <branch>` triggers it too. Documented in the hook comment so the behavior isn't surprising.
- `git pull --rebase` does **not** fire `post-merge`; the manual `bash scripts/install.sh` remains the always-available fallback, stated in the README caveat.

## Amendments

- **2026-08-21** — [ADR-0053](0053-global-rules-layer.md) gives `install.sh` two more jobs, linking `global/rules/` into `~/.claude/rules/` and printing the hook snippet; the post-merge hook re-runs all three, and the trust trade-off above covers them unchanged.
- **2026-08-22** — The hook's scope widens past "invocation of `install.sh`": before the re-hoist it runs four gates (`scripts/lint-skills.sh`, `scripts/lint-selftest.sh`, and both `global/hooks/*-selftest.sh`, which invoke the PreToolUse hooks with synthetic payloads), warning rather than aborting, and prints one line naming any pulled change under `global/hooks/`. That line exists because the `settings.json` snippet points at the live checkout, so a pulled hook edit changes the running PreToolUse check with no re-consent — a trade-off this record's trust paragraph now covers explicitly: the README's opt-in names every script the hook runs, not only `install.sh`.
- **2026-08-22, later** — A fifth gate: `global/hooks/review-receipt-selftest.sh` joined the list with the third hook ([ADR-0059](0059-review-receipt-hook.md)); "both `global/hooks/*-selftest.sh`" above now reads as all three, and the README's trust paragraph names them as "the hook self-tests".
