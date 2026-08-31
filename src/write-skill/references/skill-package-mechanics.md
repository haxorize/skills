# Skill package mechanics

Branch-gated packaging rules — each section names the case that opens it; a skill that bundles no script, keeps no state, and shares no reference never reads this file.

## Scripts

Read this section only when the skill bundles a `scripts/` helper or its body tells the agent to run a script from the owning repo.

Scripts are **black boxes**: they exist to be *run*, not read — don't ingest a large helper into context unless running it first proved a custom variant necessary. The signal to bundle one: repeated runs of the skill independently writing the same helper. A body that tells the agent to run a script living in this repo rather than in the skill's own `scripts/` (`scripts/security.sh`) states how a session in another project reaches it: the skills are symlinked into `~/.claude/skills/`, so `readlink ~/.claude/skills/<name>` names the skill's directory inside the owning repo (`…/skills/src/<name>` — the repo root is two levels up), and the invocation is written from that root — a bare `scripts/…` resolves only from this repo's root.

## Skills that keep state across sessions

Read this section only when the skill's process spans sessions or builds an artifact item by item.

When a skill's process spans sessions or builds an artifact item by item, the file is the memory and the chat is not — long sessions forget, and a compacted context loses the middle. Have the skill create its working file as soon as the **first** item settles and append after each one, never write it all at the end. The file opens with an explicit in-progress marker recording where the walk stopped, plus any plan a resumed session must inherit (a grouping, an ordering); finalizing removes the marker. Two sibling shapes carry the same requirement for other work styles: a whole-draft artifact keeps a reviewed-through pointer in that header, and a skill that edits standing files writes a dated log line per applied change plus one closing line at the end of the walk — log lines with no closing line tell the next session a walk died mid-run. Whatever the shape, resumable-from-disk-alone is the bar, and die-and-resume is the wind-tunnel scenario that proves it.

## Sharing a reference across skills

Read this section only when two or more skills need the same inert reference file (a format, a template).

When two skills need the same *inert* doc (a format, a template), don't reach for a repo-root shared folder or a symlink between skills — skills install individually, so anything outside a skill's own `references/` doesn't travel with it. Duplicate the file byte-identically into each skill's `references/`, and register the group in `scripts/lint-skills.sh` (`sibling_groups`) so drift fails lint. The duplication tax only stays bounded for short, stable docs. (Reusable *discipline* is the other case — that becomes a model-invoked skill reached via `requires:`, not a duplicated file.)
