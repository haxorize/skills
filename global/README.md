# `global/` — rules that fire with no skill loaded

A skill's rule binds only while the skill is loaded. The rules in `rules/` govern chat output and ad-hoc turns — the places where no skill is in force — so they live above the skills, in the user's `~/.claude/rules/`, and hold on every turn in every project.

## Admission rule

**`global/` holds only rules a skill depends on.** Each `rules/*.md` file carries two lines near its top, and lint checks the first:

- `Depends:` — the skills in `src/` that cite this rule instead of restating it. A rule with no depending skill leaves the directory.
- `Why not a hook or lint:` — what the rule checks that no mechanism can see. A rule a hook *could* enforce belongs in `hooks/`, not here.

Without this gate the directory becomes a second CLAUDE.md, and every rule here is paid for on every turn the user spends anywhere.

The four rules:

| Rule | Depends |
|---|---|
| [`evidence.md`](rules/evidence.md) — evidence in the same message as the claim, `UNVERIFIED:` for anything not re-checked, counts re-measured at write time | `committing`, `review-changes`, `implement`, `receiving-review` |
| [`recommend-and-proceed.md`](rules/recommend-and-proceed.md) — three bins for a question: fact, judgment, preference or outward act | `grilling`, `implement`, `committing` |
| [`no-unasked-commits.md`](rules/no-unasked-commits.md) — no commit, push, tracker write, message, or loop without an ask or a `Landing:` pre-authorisation | `committing` |
| [`large-write-chunking.md`](rules/large-write-chunking.md) — per-section writes with a resume pointer; a truncated artifact is discarded, never shown | `handoff`, `to-feature`, `to-story`, `to-tasks`, `to-bug`, `writing-for-humans` |

## Hooks

`hooks/` holds hook scripts for the one class of failure a hook can see: a tool call whose shape is wrong before it runs. One ships:

- `rename-safety.sh` — a `PreToolUse` check on Bash that blocks `sed -i` and `xargs` piped into `perl` or `sed` mass renames, lists the files the command would touch, and says to use the edit tools. Opt-in by directory (it reads `.claude/rename-safety` or the `RENAME_SAFETY_DIRS` variable) and fail-open: a malformed payload or an unreadable directory lets the command through.

Hooks are wired in `~/.claude/settings.json`, and **`install.sh` never edits that file**. It prints the snippet; you paste it.

## Install

```bash
bash scripts/install.sh
```

The installer symlinks `rules/*.md` into `~/.claude/rules/` additively — it prunes only links that point into this repo's `global/`, and never touches `~/.claude/CLAUDE.md` — then prints the `settings.json` block for the hook. The opt-in post-merge hook (`bash scripts/setup-hooks.sh`, see the repo README) re-runs the installer on every pull, so the rules track the repo.

To wire the rename hook, paste the printed block into `~/.claude/settings.json` under `hooks`:

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

and opt a directory in with `touch .claude/rename-safety` at its root.
