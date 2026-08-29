# Clean fixture root

A miniature repo root that is **right** on purpose — the mirror of `scripts/lint-fixtures/`, which is wrong on purpose. `lint-skills.sh` exits 0 against this tree, and that is the whole point: it gives `lint-skills-selftest.sh` a root where an induced failure is attributable to the thing induced. The wrong-on-purpose tree cannot do that, because its deliberate violations already force exit 1 there — `lint-skills-selftest.sh` pins how many, so the count lives in one place rather than in prose that drifts.

Keep it clean. A violation added here turns the read-error assertion in `lint-skills-selftest.sh` back into the vacuous check it was written to replace.

## Skill map

- **`clean-skill`** — the one model-invoked skill, carrying a reference file the link extractor must read; its description quotes one phrase twice, which the shared-trigger-phrase check must not read as a duplicate.
- **`near-cap`** — a body just under the 15,000-byte re-attach bound, which must draw no WARN; a threshold that drifts low reds here. Its description and `clean-skill`'s share one backticked span, which the shared-trigger-phrase check compares nothing against — widening that check past double-quoted spans turns this root red.
- **`which-skill`** — the router, present because the router-coverage check requires one; user-invoked, and quoting `clean-skill`'s phrase to prove the shared-phrase check never reads a user-invoked description.

`global/rules/clean-rule.md` is the one global rule, cited by `clean-skill` so the `Depends:` check stays quiet. `global/hooks/paired-hook.sh` (with its `# Install note:`) and its executable `paired-hook-selftest.sh` are the hook-selftest check's quiet form; `scripts/paired-tool.sh` and its executable `paired-tool-selftest.sh` are the script-selftest check's. `adr/` is `scripts/lint-adrs-selftest.sh`'s clean fixture — five records: a link-form pair, a supersession pair that links both ways, and a bold-form pair with its pointer.
