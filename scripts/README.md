# Conventions for `scripts/` and `scripts/git-hooks/`

This file holds only rules that bind more than one gate. A rule about one script lives in that script's header, and its check roster, scope, and exit codes in its `--help`; why a gate exists goes to an ADR.

## Run the selftest of what you touched

Every `scripts/<name>.sh` and `scripts/git-hooks/<name>` that is not a selftest, a `*-lib.sh`, or `setup-hooks.sh` has a `<name>-selftest.sh` beside it. One name is exempt, `setup-hooks.sh`, because it writes into `.git/hooks` and has no readable surface to grade without a throwaway clone; everything else here is gradeable against a fixture or a redirected `HOME`. `lint-skills.sh` fails one that lacks it — a git hook is any file under `scripts/git-hooks/` whose first line is a shebang, and it must itself be executable — and `post-merge` derives its gate roster from the pairing, so a script is gated the moment its selftest exists. Both walks stop at those two directories: a skill-private script under `.claude/skills/*/scripts/` is reached by no gate. Every file the walks visit opens with `# Conventions for this tree: scripts/README.md` — line 2 after a shebang, line 1 in a sourced library — and `lint-skills.sh` fails one that does not.

- After changing a script or hook, run its `-selftest.sh`.
- After changing a check in `lint-skills.sh` or `lint-adrs.sh`, run that linter's selftest: a lint gate that quietly stopped matching looks identical to a repo with no violations. Each selftest's header names what it grades and what it does not, and that list is the authority.
- After touching `scripts/selftest-lib.sh`, run every `scripts/*-selftest.sh` and every `scripts/git-hooks/*-selftest.sh` — each sources it.
- After touching `scripts/lint-lib.sh`, run `lint-skills-selftest.sh` and `lint-adrs-selftest.sh` — both linters source it for `say_fail` and the failure flag, and `pre-commit`'s derived gate map queues no selftest for a `*-lib.sh`.
- A file no gate walks is gated only by the selftest that runs it: touch such a file, run that selftest.

`selftest-lib.sh`'s header defines a selftest's three outcomes and what each exit status means.

## The exit-code taxonomy

Every script under `scripts/`, every hook under `scripts/git-hooks/`, and every hook selftest under `global/hooks/` renders one of five statuses, and `DOMAIN.md` registers them under this name (`sweep-corpus` reads `exit=` off all three trees):

- **0** — clean.
- **1** — at least one `FAIL`.
- **2** — nothing, or not everything, was checked: a linter over an empty tree, a selftest that left a branch unexercised (`SELFTEST PARTIAL`), a `skill-usage.sh` count carrying a `+` floor.
- **3** — usage error.
- **4** — a check never ran, so the run is not a verdict on anything: the script is broken, or the environment it needs is (an unwritable `TMPDIR` under the failure flag, say). Either fault is a different claim from the corpus being wrong.

A `WARN` never moves the status. `scripts/git-hooks/post-merge` and `sweep-corpus` read the number alone, so the 2 is what tells a narrower clean from a whole one. A script states its own roster in `--help`; it does not restate this table. [ADR-0068](../docs/adr/0068-lint-adrs-enforces-two-way-pointers.md) set 0-3 and [ADR-0072](../docs/adr/0072-shared-trigger-phrase-check-and-never-ran-is-not-clean.md) added 4.

## A check lands with its fixture and its mutation, in both directions

The `Why not a hook or lint:` line in the ten `scripts/lint-fixtures*/global/rules/*.md` fixtures is **inert filler** — no check parses it (`grep -c 'Why not a hook' scripts/lint-skills.sh` → 0), and the real rule files stopped carrying it on 2026-08-31, when the control moved into ADR-0053's amendments. Each fixture's line says what that fixture is for, which is why it stays; do not copy the key into a new rule file.

A new or edited check in any `scripts/*.sh` gate lands with a fixture instance that fires and a mutation that reds its selftest, both ways. Narrowing: an alternative dropped from the pattern, and the instance that stops firing turns the selftest red. Widening: a boundary loosened, and the clean neighbor that starts firing turns it red. So a fixture carries one graded instance per alternative, not one per rule, and the selftest carries the mutation table. Nothing mechanical covers this: the selftest-pairing check proves a selftest exists, never that it can fail — `security-selftest.sh` graded one instance per rule until 2026-08-29, and cutting `_DROP_HOSTS` from twenty-odd host patterns to one left it green.

## Landing a change here

`Review required: yes` in `CLAUDE.md`'s `Landing:` block arms the `review-receipt` hook under `global/hooks/` once it is wired in `~/.claude/settings.json` (`bash scripts/install.sh` prints the snippet): a push needs a `/review-changes` report whose `Reviewed-tree:` stamp equals the tree being pushed, and `/address-findings` re-stamps after its fix pass. So the order is review, fix up, commit the whole tree, push — any edit after the last stamp needs a new one. The `pre-commit` git hook runs `lint-skills.sh` and `lint-adrs.sh` on the paths a commit touches, runs the selftest of each staged script or git hook (every selftest when `selftest-lib.sh` is staged), and prints a lineage notice for a staged skill `docs/lineage.md` lists; `commit-msg` checks message shape and never register, so `src/committing/references/commit-style.md` is not pruned against it.
