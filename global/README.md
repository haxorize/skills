# `global/` — rules that fire with no skill loaded

A skill's rule binds only while the skill is loaded. The rules in `rules/` govern chat output and ad-hoc turns — the places where no skill is in force — so they live above the skills, in the user's `~/.claude/rules/`, and hold on every turn in every project.

## Admission rule

**`global/` holds only rules a skill depends on.** Each `rules/*.md` file carries two lines near its top, and lint checks the first:

- `Depends:` — the skills in `src/` that depend on this rule and cite it instead of restating it, in the forms `scripts/lint-skills.sh`'s header names; lint checks both that each name resolves and that the named skill carries the citation. A rule with no depending skill leaves the directory.
- `Why not a hook or lint:` — what the rule checks that no mechanism can see. A rule a hook *could* enforce belongs in `hooks/`, not here.

Without this gate the directory becomes a second CLAUDE.md, and every rule here is paid for on every turn the user spends anywhere.

The five rules (each file's `Depends:` line is the one list of its dependants):

- [`evidence.md`](rules/evidence.md) — evidence in the same message as the claim, `UNVERIFIED:` for anything not re-checked, counts re-measured at write time.
- [`recommend-and-proceed.md`](rules/recommend-and-proceed.md) — three bins for a question: fact, judgment, preference or outward act.
- [`no-unasked-commits.md`](rules/no-unasked-commits.md) — no commit, push, tracker write, message, or loop without an ask or a `Landing:` pre-authorisation.
- [`large-write-chunking.md`](rules/large-write-chunking.md) — per-section writes with a resume pointer; a truncated artifact is discarded, never shown.
- [`outbound-dash-sweep.md`](rules/outbound-dash-sweep.md) — a message drafted as the user ends on one grep for dashes and tool residue; a hit means the draft is not done.

## Hooks

`hooks/` holds hook scripts for the class of failure a hook can see: a tool call whose shape, or whose precondition on disk, is wrong before it runs. Three ship:

- `rename-safety.sh` — a `PreToolUse` check on Bash that blocks in-place mass edits (`sed -i`, `perl -pi`, and `xargs` feeding either) and says to use the edit tools; its header states the exact contract, the opt-in, and the fail-open rule.
- `commit-bypass.sh` — a `PreToolUse` check on Bash that blocks the three command-line shapes that skip the repo's hooks (`--no-verify` and its prefixes, `git commit -n`, `-c core.hooksPath=`), seen through quotes, `bash -c`, `eval`, variables, and shell-fed heredocs; always on, no opt-in, fail-open. A mention inside a message or note passes. `git config` writes and `GIT_CONFIG_*` overrides are outside its contract — the header says so.
- `review-receipt.sh` — a `PreToolUse` check on Bash that blocks `git push` when the nearest `CLAUDE.md` says `Review required: yes` (`no` opts a package out; the line belongs in the `Landing:` block but is read anywhere outside a fence) unless a `review-changes` report for the repo in the landing zone carries a `Reviewed-tree:` stamp equal to the tree of the commit being pushed (`address-findings` re-stamps after its fix pass); its header is the contract — the stamp's form and the one-liner that computes it, what it cannot see, the opt-in forms, and the fail-open rule. Content, not time: review the dirty tree, fix, commit it whole, push.

Each has a `*-selftest.sh` beside it running an expect/reject payload table — run it after changing a rule.

Hooks are wired in `~/.claude/settings.json`, and **`install.sh` never edits that file**. It prints the snippet; you paste it. **The snippet's path is this checkout** — a `git pull` that edits `hooks/` changes the live hook with no re-consent; the post-merge hook prints one line naming any such change. An *uncommitted* edit under `hooks/` is live the moment it is saved, with no commit, no pull, and no announcement at all, so a hook edit runs `bash global/hooks/<hook>-selftest.sh` before the session's next gated act — including the push of the edit itself.

## Install

```bash
bash scripts/install.sh
```

The installer symlinks `rules/*.md` into `~/.claude/rules/` additively — it prunes only links that point into this repo's `global/`, and never touches `~/.claude/CLAUDE.md` — then prints the `settings.json` block for each hook until `settings.json` names it. The opt-in post-merge hook (`bash scripts/setup-hooks.sh`, see the repo README) re-runs the installer after every merging pull (not `pull --rebase`), so the rules track the repo.

To wire a hook, paste the printed block into `~/.claude/settings.json` under `hooks` (one entry per hook; the other hooks take the same shape):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash /absolute/path/to/skills/global/hooks/rename-safety.sh" }
        ]
      }
    ]
  }
}
```

and opt in where a hook asks for it: `touch .claude/rename-safety` at a repo's root for `rename-safety`, a `Review required: yes` line in its `CLAUDE.md` `Landing:` block for `review-receipt`.
