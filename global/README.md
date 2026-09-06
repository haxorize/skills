# `global/` — rules that fire with no skill loaded

A skill's rule binds only while the skill is loaded. The rules in `rules/` govern chat output and ad-hoc turns — the places where no skill is in force — so they live above the skills, in the user's `~/.claude/rules/`, and hold on every turn in every project.

## Admission rule

**`global/` holds only rules a skill depends on.** Each `rules/*.md` file carries a `Depends:` line near its top — the skills in `src/` that depend on this rule and cite it instead of restating it, in the forms `scripts/lint-skills.sh`'s header names; lint checks both that each name resolves and that the named skill carries the citation. A rule with no depending skill leaves the directory.

Admission is decided by the `Why not a hook or lint:` control, recorded per rule in [ADR-0053's amendments](../docs/adr/0053-global-rules-layer.md) rather than in the rule file: what the rule checks that no mechanism can see. A rule a hook *could* enforce belongs in `hooks/`, not here. The control is a count, never a judgment that prose "should hold": over the artifacts the rule governs — the commits, writes, questions, or drafts of a stated window of at least 30 days — how many a mechanism would have fired on and how many of those were the failure, stated with the window and the corpus, so a rule held by prose alone is caught dying by the history it was supposed to shape, since each artifact looks normal on its own. This count-based control decides one rung: whether a rule stays prose *here*, over history. `src/writing-for-agents/references/predictability.md`'s control run — a micro-test showing the prose missing a failure before the rung above prose is built — decides whether a *skill's* prose rule binds at all; different evidence for different rungs, and a rule reaching `global/` has both behind it.

Without this gate the directory becomes a second CLAUDE.md, and every rule here is paid for on every turn the user spends anywhere.

The five rules (each file's `Depends:` line names the skills lint checks cite back — it is the forward list, not a census: `evidence.md` names 8 on that line while more files cite it, and `recommend-and-proceed.md` names 5 while more do, three of them overriding its bin 1 outright — an observation about what those bodies say, not a figure the recipe below returns. The figures are not written here, because a census in prose beside the grep that computes it is a number the reader cannot re-derive from the instruction they were just given — for the citations of a rule, run ``grep -rlE '~/\.claude/rules/<stem>\.md|`<stem>`' src/ .claude/skills/``, where `<stem>` is the rule's filename without `.md`. Those two forms are the ones `scripts/lint-skills.sh`'s header names — the home § Admission rule above points at, quoted here because the recipe is unusable without them — and the stem as an unmarked word is neither; lint checks them per name on the `Depends:` line, under `src/<dep>/` and outside fenced blocks, so this sweep is the wider one and finds citers lint never looks at):

- [`evidence.md`](rules/evidence.md) — evidence beside the claim, `UNVERIFIED:` for anything not re-checked and `UNVERIFIABLE` for a check this session cannot run, counts re-measured at write time, a `Measured-tree:` line on a generated report, a deferral written into a durable record.
- [`recommend-and-proceed.md`](rules/recommend-and-proceed.md) — three bins for a question: fact, judgment, preference or outward act.
- [`no-unasked-commits.md`](rules/no-unasked-commits.md) — no commit, push, tracker write, message, or loop without an ask or a `Landing:` pre-authorization.
- [`large-write-chunking.md`](rules/large-write-chunking.md) — the truncation invariant and a chat answer that pauses at a section break; the per-section file mechanics live in `handoff` § Where to write it.
- [`outbound-dash-sweep.md`](rules/outbound-dash-sweep.md) — a message drafted as the user ends on one grep for dashes and tool residue; a hit means the draft is not done.

## Hooks

`hooks/` holds hook scripts for the class of failure a hook can see: a tool call whose shape, or whose precondition on disk, is wrong before it runs. Three ship:

- `rename-safety.sh` — a `PreToolUse` check on Bash that blocks in-place mass edits (`sed -i`, `perl -pi`, `ruby -i`, however the flag reaches the program) and says to use the edit tools; its header states the in-place shapes, the opt-in, and the fail-open rule.
- `commit-bypass.sh` — a `PreToolUse` check on Bash that blocks the three command-line shapes that skip the repo's hooks (`--no-verify` and its prefixes, `git commit -n`, `-c core.hooksPath=` and its `--config-env` spelling), however the flag reaches git; always on, no opt-in, fail-open. A mention inside a message or note passes. `git config` writes and `GIT_CONFIG_*` overrides are outside its contract — the header says so.
- `review-receipt.sh` — a `PreToolUse` check on Bash that blocks `git push` when the nearest `CLAUDE.md` says `Review required: yes` (`no` opts a package out; the line belongs in the `Landing:` block but is read anywhere outside a fence) unless a `review-changes` report for the repo in the landing zone carries a `Reviewed-tree:` stamp equal to the tree of the commit being pushed (`address-findings` re-stamps after its fix pass); its header is the contract — the stamp's form and the one-liner that computes it, what it cannot see, the opt-in forms, and the fail-open rule. Content, not time: review the dirty tree, fix, commit it whole, push.

All three tokenize the command line through one scanner, `hook-lib.sh` / `hook-lib.py`: how a flag reaches a program — a quote, a wrapper, `bash -c`, `eval`, a shell-fed heredoc, `find -exec`, `xargs`, a variable, a compound statement — is the lib's contract, stated in its header, and each hook holds only its own shape. The two lib files and `selftest-lib.sh` are not hooks; a hook is the script whose header carries an `# Install note:` line, which is how `install.sh` and the post-merge hook tell them apart. Each hook has a `*-selftest.sh` beside it running an expect/reject payload table over the shared `selftest-lib.sh` harness — run it after changing a rule, and run all three after changing a lib.

Hooks are wired in `~/.claude/settings.json`, and **`install.sh` never edits that file**. It prints the snippet; you paste it. **The snippet's path is this checkout** — a `git pull` that edits `hooks/` changes the live hook with no re-consent; the post-merge hook prints one line naming any such change. An *uncommitted* edit under `hooks/` is live the moment it is saved, with no commit, no pull, and no announcement at all — an edit to a lib changes all three hooks at once — so a hook edit runs `bash global/hooks/<hook>-selftest.sh`, and a lib edit runs all three, before the session's next gated act — including the push of the edit itself.

## Install

```bash
bash scripts/install.sh
```

The installer symlinks `rules/*.md` into `~/.claude/rules/` additively — it prunes only links that point into this repo's `global/`, and never touches `~/.claude/CLAUDE.md` — then prints the `settings.json` block for each hook until `settings.json` names it. The opt-in git hooks (`bash scripts/setup-hooks.sh`, see the repo README) re-run the installer after every merging pull (not `pull --rebase`), so the rules track the repo — and the same opt-in enables a `commit-msg` hook that rejects a commit message breaking the house style.

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
