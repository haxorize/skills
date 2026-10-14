# Skill package mechanics

Branch-gated packaging rules — each section names the case that opens it; a skill that bundles no script, runs no repo script, keeps no state, shares no reference, and carries no `$` before a digit in its body never reads this file.

## Scripts, and a `$` before a digit

Read this section only when the skill bundles a `scripts/` helper, its body tells the agent to run a script from the owning repo, or its body carries a `$` before a digit.

Scripts are **black boxes**: they exist to be *run*, not read — don't ingest a large helper into context unless running it first proved a custom variant necessary. The signal to bundle one: repeated runs of the skill independently writing the same helper. A body that tells the agent to run a script living in this repo rather than in the skill's own `scripts/` (`scripts/security.sh`) states how a session in another project reaches it: the skills are symlinked into `~/.claude/skills/`, so `readlink ~/.claude/skills/<name>` names the skill's directory inside the owning repo (`…/skills/src/<name>` — the repo root is two levels up), and the invocation is written from that root — a bare `scripts/…` resolves only from this repo's root.

**Spell the interpreter.** A body puts `bash` or `python3` before the script path, however that path is resolved (`bash <repo-root>/scripts/foo.sh`, `python3 <skill-dir>/scripts/foo.py`), never the path alone: a packager or copy that drops the executable bit turns every bare invocation into `Permission denied`.

**No bare `$` before a digit in a body.** Claude Code substitutes `$N` in a skill body with the argument at index N (`$0` is the first), and the docs name no exemption for code blocks; an index with no argument stays literal, so the corruption shows only when the skill is invoked with enough arguments. `awk '{print $1}'` becomes `awk '{print <word>}'`, a prose `$1,240` loses its figure, and `URL="$1"` reads the second argument. In code, pass the value through a named variable on a quoted heredoc (`URL='<url>' bash <<'EOF'`, the block reading `"$URL"`), so the one typed value sits in one place and anything the block fetches is read into a variable, never re-typed into shell quotes — `audit-aeo`'s fetch block is the worked case — or use `cut`; in prose, escape it as `\$1,240`.

## Skills that keep state across sessions

Read this section only when the skill's process spans sessions or builds an artifact item by item.

When a skill's process spans sessions or builds an artifact item by item, the file is the memory and the chat is not — long sessions forget, and a compacted context loses the middle. Have the skill create its working file as soon as the **first** item settles and append after each one, never write it all at the end. The file opens with an explicit in-progress marker recording where the walk stopped, plus any plan a resumed session must inherit (a grouping, an ordering); finalizing removes the marker. Two sibling shapes carry the same requirement for other work styles: a whole-draft artifact keeps a reviewed-through pointer in that header, and a skill that edits standing files writes a dated log line per applied change plus one closing line at the end of the walk — log lines with no closing line tell the next session a walk died mid-run. Whatever the shape, resumable-from-disk-alone is the bar, and die-and-resume is the wind-tunnel scenario that proves it.

## Sharing a reference across skills

Read this section only when two or more skills need the same inert reference file (a format, a template).

When two skills need the same *inert* doc (a format, a template), it lives once, in the `references/` of the skill whose job defines its content — the owner — and every other skill reads it by installed path, `~/.claude/skills/<owner>/references/<file>`. Not a copy, not a repo-root shared folder, not a symlink between skills, and not a relative `../<owner>/` link. The reader adds no `requires:` line: reading a file is not firing a skill, and `scripts/install.sh` links the whole suite, so the owner is there. `check_rule_pointers` in `scripts/lint-skills.sh` fails a pointer whose file does not exist. Where no skill's job defines the content, ask before picking an owner. (Reusable *discipline* is the other case — that becomes a model-invoked skill reached via `requires:`.) One procedure reference is read by installed path too, because the decision record that placed it chose that over a skill: the cold-start loader, `implement/references/load-ticket.md`, which `/grill-me` and `/write-skill` read load-only. The `sibling_groups` copies still in the tree predate this rule and collapse in their own batch; until then they stay byte-identical.
