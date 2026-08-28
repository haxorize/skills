# Clean fixture root

A miniature repo root that is **right** on purpose — the mirror of `scripts/lint-fixtures/`, which is wrong on purpose. `lint-skills.sh` exits 0 against this tree, and that is the whole point: it gives `lint-selftest.sh` a root where an induced failure is attributable to the thing induced. The wrong-on-purpose tree cannot do that, because roughly twenty deliberate violations already force exit 1 there.

Keep it clean. A violation added here turns the read-error assertion in `lint-selftest.sh` back into the vacuous check it was written to replace.

## Skill map

- **`clean-skill`** — the one model-invoked skill, carrying a reference file the link extractor must read.
- **`which-skill`** — the router, present because the router-coverage check requires one.
