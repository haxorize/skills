# Version gates

Two branch-gated rules for `upgrade-deps`, each opened from the step that names it.

## Registry release-age gate

Where the repo's `CLAUDE.md` `## Registry` block carries `Minimum release age:` (a curating proxy that refuses packages younger than it), that number replaces the 7-day floor and a younger target is not installable: pick the newest version older than the gate, or defer with a review-by date of publish date plus the gate.

## After a runtime major

Drop the backports the new runtime now ships (Python: `dataclasses`, `typing`, `pathlib`, `enum34`, `futures`, on the versions that include them) — a backport left pinned shadows the standard library, and the failure shows up as an import that resolves to the wrong module.
