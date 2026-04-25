# skills

Personal collection of repo-agnostic agent skills, hoisted into `~/.claude/skills/` for use across projects.

## Skills

- **`adr`** — Architecture Decision Records.
- **`deepen`** — Module-deepening refactor proposals.
- **`grill-me`** — Stress-testing a plan or design through interview.
- **`ubiquitous-language`** — DDD-style domain glossary authoring.
- **`write-skill`** — Conventions for writing new skills.

## Install

Symlink each skill directory into `~/.claude/skills/`:

```bash
cd ~/code/skills
for skill in */; do
  ln -s "$(pwd)/${skill%/}" ~/.claude/skills/
done
```

Or link a single skill:

```bash
ln -s ~/code/skills/grill-me ~/.claude/skills/
```

## Notes

- Several skills reference `UBIQUITOUS_LANGUAGE.md` (from the `ubiquitous-language` skill) and `docs/adr/` (from the `adr` skill). They degrade gracefully in projects that don't use those conventions.
