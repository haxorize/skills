# `global/` — rules that fire with no skill loaded

A skill's rule binds only while the skill is loaded. The rules in `rules/` govern chat output and ad-hoc turns — the places where no skill is in force — so they live above the skills, in the user's `~/.claude/rules/`, and hold on every turn in every project.

## Admission rule

**`global/` holds only rules a skill depends on.** Each `rules/*.md` file has an entry in [`rules/DEPENDS`](rules/DEPENDS) — `<stem>: <skill>, <skill>`, the skills in `src/` that depend on this rule and cite it instead of restating it, kept out of the rule because a rule's bytes load on every turn and the sidecar's never do — in the forms `scripts/lint-skills.sh`'s header names; lint checks both that each name resolves and that the named skill carries the citation. A rule with no depending skill leaves the directory.

Admission is decided by the `Why not a hook or lint:` control, recorded per rule in [ADR-0053](../docs/adr/0053-global-rules-layer.md) rather than in the rule file — an admission edits that record in place: what the rule checks that no mechanism can see. A rule a hook *could* enforce belongs in `hooks/`, not here. The control is a count, never a judgment that prose "should hold": over the artifacts the rule governs — the commits, writes, questions, or drafts of a stated window of at least 30 days — how many a mechanism would have fired on and how many of those were the failure, stated with the window and the corpus, so a rule held by prose alone is caught dying by the history it was supposed to shape, since each artifact looks normal on its own. This count-based control decides one rung: whether a rule stays prose *here*, over history. `src/writing-for-agents/references/predictability.md`'s control run — a micro-test showing the prose missing a failure before the rung above prose is built — decides whether a *skill's* prose rule binds at all; different evidence for different rungs, and a rule reaching `global/` has both behind it.

Without this gate the directory becomes a second CLAUDE.md, and every rule here is paid for on every turn the user spends anywhere.

The five rules (each rule's `DEPENDS` entry names the skills lint checks cite back — it is the forward list, not a census: `evidence.md` names 8 in its entry while more files cite it, and `recommend-and-proceed.md` names 5 while more do, three of them overriding its bin 1 outright — an observation about what those bodies say, not a figure the recipe below returns. The figures are not written here, because a census in prose beside the grep that computes it is a number the reader cannot re-derive from the instruction they were just given — for the citations of a rule, run ``grep -rlE '~/\.claude/rules/<stem>\.md|`<stem>`' src/ .claude/skills/``, where `<stem>` is the rule's filename without `.md`. Those two forms are the ones `scripts/lint-skills.sh`'s header names — the home § Admission rule above points at, quoted here because the recipe is unusable without them — and the stem as an unmarked word is neither; lint checks them per name in the rule's `DEPENDS` entry, under `src/<dep>/` and outside fenced blocks, so this sweep is the wider one and finds citers lint never looks at):

- [`evidence.md`](rules/evidence.md) — evidence beside the claim, `UNVERIFIED:` for anything not re-checked and `UNVERIFIABLE` for a check this session cannot run, counts re-measured at write time, a `Measured-tree:` line on a generated report, a deferral written into a durable record.
- [`recommend-and-proceed.md`](rules/recommend-and-proceed.md) — three bins for a question: fact, judgment, preference or outward act.
- [`no-unasked-commits.md`](rules/no-unasked-commits.md) — no commit, push, tracker write, message, loop, or script that changes files outside the repo without an ask or a `Landing:` pre-authorization.
- [`large-write-chunking.md`](rules/large-write-chunking.md) — the truncation invariant and a chat answer that pauses at a section break; the per-section file mechanics live in `handoff` § Where to write it.
- [`outbound-dash-sweep.md`](rules/outbound-dash-sweep.md) — a message drafted as the user ends on one run of `writing-for-humans`' `dash-sweep.sh` over the draft, for dashes and tool residue; a hit means the draft is not done.

## Hooks

`hooks/` holds hook scripts for the class of failure a hook can see: a tool call whose shape, or whose precondition on disk, is wrong before it runs; a sensor that sees a turn after it ran; and two that add a line of context after the fact and never block. Seven ship:

- `rename-safety.sh` — a `PreToolUse` check on Bash that blocks in-place edits (`sed -i`, `perl -pi`, `ruby -i`, however the flag reaches the program) to files in an opted-in directory, and points at the Edit tool; one BSD-form substitution on one listed file runs, as does any edit whose files all lie outside. Its header states the in-place shapes, the opt-in, and the fail-open rule.
- `commit-bypass.sh` — a `PreToolUse` check on Bash that blocks the three command-line shapes that skip the repo's hooks (`--no-verify` and its prefixes, `git commit -n`, `-c core.hooksPath=` and its `--config-env` spelling), however the flag reaches git; always on, no opt-in, fail-open. A mention inside a message or note passes. `git config` writes and `GIT_CONFIG_*` overrides are outside its contract — the header says so.
- `review-receipt.sh` — a `PreToolUse` check on Bash that blocks `git push` when the nearest `CLAUDE.md` says `Review required: yes` (`no` opts a package out; the line belongs in the `Landing:` block but is read anywhere outside a fence) unless a `review-changes` report for the repo in the landing zone carries a `Reviewed-tree:` stamp equal to the tree of the commit being pushed (`address-findings` re-stamps after its fix pass); its header is the contract — the stamp's form, read through `bash src/review-changes/scripts/tree-stamp.sh --stamps <report>` (the same reader `--verify` uses) and accepting only `Reviewed-tree` lines, the script that computes it, what it cannot see, the opt-in forms, and the fail-open rule. Content, not time: review the dirty tree, fix, commit it whole, push.
- `friction-log.sh` — a `Stop` hook, no matcher: after each agent turn it reads the session transcript from a per-session cursor, and when a user turn since then, or a prompt the user typed while the agent was working, is correction-shaped ("no, don't", "I said", "from now on", a tool call denied with guidance — the signal table is in `friction-log.py`) it hands the agent one instruction: judge the flagged turns, and append one line per real correction to `~/.claude/friction/log.md` in the shape the `debrief` skill defines. It never writes the log, never grades, and never proposes a fix; `stop_hook_active` is its loop guard; fail-open, no opt-in. The shell file is the wrapper and its header is the contract; the scan is `friction-log.py` beside it, which the wrapper execs and which loads `session-hook-lib.py` for its payload read, session-id check, breadcrumb and cursor write; its selftest checks the line shape against `src/debrief/SKILL.md` byte for byte.
- `staged-secrets.sh` — a `PreToolUse` check on Bash that blocks the agent's own `git commit` when what it would commit (the staged diff, plus what an `-a` or a `git add` in the same command would stage) holds a token-shaped string or a key-shaped file; the block names the file, the line and the shape, never the value. Always on, fail-open, and no program the target repo configures runs. Its header carries the shape tables and what it cannot see.
- `context-nudge.sh` — a `UserPromptSubmit` hook, no matcher: past 150k context tokens it adds one line telling the agent to offer `/handoff` at the next phase boundary, and past 200k one saying to offer it now; each fires once per session. Always on, fail-open, never blocks a prompt; the scan is `context-nudge.py` beside it.
- `repeat-failure.sh` — a `PostToolUseFailure` hook, no matcher: on the third Bash failure in a row with the same key (the command's head and the error's class, never the command's text) it adds one line saying the failure is structural, so stop retrying and hand the user the command and error. Always on, fail-open, never blocks; the scan is `repeat-failure.py` beside it.

The two context hooks keep per-session state under `${HOOK_STATE_DIR:-~/.claude/hook-state}/<hook>/`; they and `friction-log.py` share their scaffolding through `session-hook-lib.py`.

The four `PreToolUse` hooks tokenize the command line through one scanner, `hook-lib.sh` / `hook-lib.py`: how a flag reaches a program — a quote, a wrapper, `bash -c`, `eval`, a shell-fed heredoc, `find -exec`, `xargs`, a variable, a compound statement — is the lib's contract, stated in its header, and each hook holds only its own shape. Every hook but `friction-log` sources `hook-lib.sh` for its payload read and fail-open breadcrumb, and `repeat-failure.py` also loads `hook-lib.py` by path and calls its `program_segments` to segment the failed command (the lib's header lists both of its entry points). The lib files (`hook-lib.sh`, `hook-lib.py`, `session-hook-lib.py`, `selftest-lib.sh`) and the scan halves (`friction-log.py`, `context-nudge.py`, `repeat-failure.py`) are not hooks; a hook is the script whose header carries an `# Install note:` line, which is how `install.sh` and the post-merge hook tell them apart, and an `# Event:` line naming the event it is wired to — a hook with none installs as a `PreToolUse` check on Bash, so a `Stop` or `SessionStart` hook written without the line lands on the wrong event. Each hook has a `*-selftest.sh` beside it — the four `PreToolUse` selftests run an expect/reject payload table over the shared `selftest-lib.sh` harness; the other three run their own fire/quiet tables; every mutation table sources `scripts/selftest-lib.sh` by its repo path for `selftest_mutate` and `selftest_expect_killed`, so the selftests run from a whole checkout — run it after changing a rule, and after changing a lib run every hook selftest whose hook sources or loads it.

Hooks are wired in `~/.claude/settings.json`, and **`install.sh` never edits that file**. It prints the snippet; you paste it. **The snippet's path is this checkout** — a `git pull` that edits `hooks/` changes the live hook with no re-consent; the post-merge hook prints one line naming any such change. An *uncommitted* edit under `hooks/` is live the moment it is saved, with no commit, no pull, and no announcement at all — an edit to a lib changes every hook that reads it at once — so a hook edit runs `bash global/hooks/<hook>-selftest.sh` (an edit to a scan half such as `friction-log.py` is an edit to that hook and runs its selftest), and a lib edit runs the selftest of every hook that reads it (`pre-commit` queues a superset: every hook file that names the lib, which can include one that only mentions it), before the session's next gated act — including the push of the edit itself.

## Install

```bash
bash scripts/install.sh
```

The installer symlinks `rules/*.md` into `~/.claude/rules/` additively — it prunes only links that point into this repo's `global/`, and never touches `~/.claude/CLAUDE.md` — then prints the `settings.json` block for each hook until `settings.json` names it. The opt-in git hooks (`bash scripts/setup-hooks.sh`, see the repo README) re-run the installer after every merging pull (not `pull --rebase`), so the rules track the repo — and the same opt-in enables a `commit-msg` hook that re-breaks an over-long body prose line in place and rejects a commit message still breaking the house style.

To wire a hook, paste the printed block into `~/.claude/settings.json` under `hooks` (one entry per hook; the other `PreToolUse` hooks take the same shape, and `friction-log`, `context-nudge` and `repeat-failure` go under their events (`"Stop"`, `"UserPromptSubmit"`, `"PostToolUseFailure"`) with no `matcher` key — the installer prints it grouped by event):

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
