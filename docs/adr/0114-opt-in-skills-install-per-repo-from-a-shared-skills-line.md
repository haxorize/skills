# Opt-in skills install per repo from a `Shared skills:` line

Status: accepted (2026-10-17)

## Decision

- **Nine skills are opt-in**: `accessible-ui`, `aeo`, `audit-aeo`, `health-literacy`, `phi-safe-code`, `product-description`, `rebuild-contract`, `respond-to-incident` and `roll-out`. The list has one home, the `opt_in_skills` line of `scripts/install.sh`, and `lint-skills.sh` reads it from there.
- **`install.sh` never links an opt-in skill into `~/.claude/skills/`.** The global run removes a link left from before a skill was opt-in, and only a link that points at this checkout's copy; a link to anything else is left alone.
- **`install.sh --project <repo>` installs them into one repo.** It reads the `Shared skills: a, b` line of the repo's `CLAUDE.md`, links each named opt-in skill into `<repo>/.claude/skills/`, and lists each link once in the repo's `.git/info/exclude`, so the repo's tracked files never change. An opt-in skill's opt-in dependencies follow it into the repo; its global dependencies do not, since the global install already has them. A name on the line that is not opt-in is skipped with a message. A repo that is not a git work tree, or whose `CLAUDE.md` has no `Shared skills:` line, exits 3.
- **A global skill may not require an opt-in one.** Its requirement would be unmet in every repo that does not list the dependency. `lint-skills.sh`'s `check_requires_resolve` FAILs the edge, and `install.sh` WARNs on it. The rule is why `roll-out` and `respond-to-incident`, which require `phi-safe-code`, are opt-in themselves, and why `rebuild-contract`, which requires `product-description`, is too. `onboard-me` went the other way: it stopped calling `product-description` and only reads a description that already exists.
- **`onboard-repo` writes the line.** At setup it asks whether the repo handles member data, and a yes puts `phi-safe-code` on the repo's `Shared skills:` line. Its questions on member-facing copy and on a UI people operate put `health-literacy` and `accessible-ui` there the same way.
- **Placement and the invocation axis do not change.** Every skill stays flat in `src/<name>/`, with no new frontmatter key and no tier, and every model-invoked opt-in skill stays model-invoked.

**Why.** The 5 model-invoked opt-in skills carry 3,590 B of description (`grep -m1 '^description:' src/<name>/SKILL.md | wc -c`, summed, 2026-10-17). Claude Code loads those bytes on every turn of every session, in repos that never use the skills. The grill's ask 21 counted where they load: `accessible-ui` 42 times, all in the accessibility repos; `aeo` once; `health-literacy` never (`~/code/lib/_rounds/2026-10-12/grill-recs.md:299`). The 4 user-invoked opt-in skills cost no per-turn bytes. They are opt-in because each requires an opt-in skill.

**Who decided.** Nick, at the 2026-10-12 grill and on 2026-10-17. Ask 21 recommended a command that takes the skill names (`install.sh --project <repo> <skill>…`), with the installer never reading a `CLAUDE.md`, and recommended keeping `phi-safe-code` global. Nick chose the `Shared skills:` line read by the installer (Q41), and put `phi-safe-code` and `product-description` on the per-project list (Q42), against the recommendation. The recommendation's reason was that a missing line silently loses the PHI safeguard; `onboard-repo`'s question carries that risk. On 2026-10-17 Nick added `roll-out`, `respond-to-incident` and `rebuild-contract`, and chose to drop `onboard-me`'s call over making `product-description` global again.

**The gate.** No record owned install scope; [ADR-0055](0055-first-domain-skill-phi-safe-code.md), [ADR-0060](0060-third-domain-skill-accessible-ui.md) and [ADR-0090](0090-batch-5-admissions-2026-09-12.md) own placement, which is neighboring ground, so this is a new record. Hard to reverse: each listed repo carries a `Shared skills:` line and exclude entries, both machines rerun the installer, and another repo's edit gate names the per-project command. Surprising without context: a reader finds skills in `src/` that are absent from `~/.claude/skills/`.

## Considered Options

- **Keep `phi-safe-code` global**, the grill's recommendation. Rejected by Nick (Q42): the skill's description loads in every repo, member data or not, and the missing-line risk moves to a question `onboard-repo` asks at setup.
- **Name the skills on the command line** (ask 21's shape). Rejected (Q41): a line in the repo records which skills it uses, so a rerun on a new machine needs nobody to remember the list.
- **Commit the links into the repo.** Rejected: a teammate without a skills checkout would get dangling links in the tree. `.git/info/exclude` keeps them local to the machine that made them.
- **A Domain-skill tier, `src/domain/<name>/`.** Rejected: 4 of the 9 opt-in skills are not Domain skills, so a tier by kind would not match the list. Install scope is a property of where a skill is used, not of what it encodes.
- **Make `product-description` user-invoked instead.** Rejected on 2026-10-17: `rebuild-contract` calls it, and lint fails a Skill-tool call into a user-invoked skill. Being opt-in already removes its description from repos that do not list it, and the grill kept it model-invoked so a PM or BA asking in plain words reaches it (`grill-recs.md:544`).
- **Mark each opt-in skill in its frontmatter** rather than listing them in `install.sh`. Unexamined beyond this: the list was built first, and lint reading it keeps a single copy.

## Deferred

- Whether Claude Code loads a skill that is a symbolic link inside a project's `.claude/skills/`: `UNVERIFIED:`, lifted by Nick's first session in a repo after `install.sh --project` (register D17).
- The accessibility UI repo's install line and edit-gate message (`a11y-health-ui/CLAUDE.md:39`, `:131`; `skill-gate.mjs:348`) name the per-project command: that repo's change and record (Batch 24b).
- Which work repos list `health-literacy` and `aeo`: Nick names them when he runs `--project` there.

Revisit when: a symlinked project skill fails to load, which moves the install to a copy; or a repo that handles member data is found without `phi-safe-code` on its line, which re-opens Q42.

## Consequences

- ADR-0055's and ADR-0060's placement paragraphs, ADR-0060's placement trigger and ADR-0090's placement consequence now say that install scope is decided here and placement stays flat. ADR-0060's trigger was a loop that special-cases Domain skills; `install.sh` now special-cases a list, and the list is not drawn by kind.
- [ADR-0065](0065-product-description-model-invoked-not-onboard-me-phase-0.md) loses `onboard-me` as a caller: `rebuild-contract` is the only one, and the KT session is no longer one of its three moments. [ADR-0064](0064-onboard-me-read-only-kt-session.md) and [ADR-0069](0069-rebuild-contract-pre-rewrite-contract-in-repo.md) say the same from each caller's side. This record undoes the "delegating the product description" clause of ADR-0064's title, and ADR-0064 is retitled to the clause that holds, a read-only KT session over a repo.
- `audit-skills` adds the opt-in skills to its inventory from each owning repo's `opt_in_skills` line, since `ls ~/.claude/skills` no longer lists them, and counts their usage by name.
- `DOMAIN.md` gains an **Opt-in skill** row. The term avoids "project-scoped", which `audit-skills` uses for a repo's own skills.
- After this lands, Nick reruns `install.sh` on both machines, which unlinks the 9 skills from `~/.claude/skills/`. Then he runs `install.sh --project` once per repo that lists them.
