# Lint fixture tree

The fixture ground for every self-test under `scripts/`: a miniature repo root — `src/`, `global/`, `scripts/`, `.claude/`, and the root's own `README.md` and `DOMAIN.md` — that `scripts/lint-skills-selftest.sh` points `scripts/lint-skills.sh` at via `LINT_ROOT`, plus three subtrees that are other self-tests' fixtures and never `LINT_ROOT`'s: `adr/`, `usage/`, `security/`. Nothing here is a real skill — every file exists to make a check fire, or to prove a check stays quiet on a form it is supposed to exempt.

This file doubles as the fixture's README-coverage target, so the roster check has
something to read: `which-skill`, `broken-links`, `undeclared-dep`, `unused-dep`, `quoted-dep`, `fixture-discipline`, `call-forms`, `slash-on-model-invoked`, `bulk-cited-dep`, `folded-description`, `literal-description`, `continued-description`, `oversize-body`, `shared-trigger-straight`, `shared-trigger-curly`, `shared-trigger-scalar`, `shared-trigger-not-for`, `ledger-legend`, `ledger-consumer`.

`global/rules/` holds ten rule fixtures. Nine grade the `Depends:` admission check: one with no line, one naming a skill that does not exist, one naming a skill (`quoted-dep`) that names it only inside a fenced block, three naming a skill (`unused-dep`) whose body has every non-citation form — the bare `~/.claude/rules/` directory (`dir-only-cited`), some other rule's full path (`other-path-cited`), and this rule's stem as an unmarked word (`bare-stem-cited`) — and two well-formed rules that must stay quiet — `broken-links` cites `well-formed` by backticked stem, `undeclared-dep` cites `path-cited` by path — and one that grades the check's plumbing rather than its pattern: `early-cited` names `bulk-cited-dep`, which cites it in its opening lines and then follows that citation with three long `references/` files. Reading that through `grep -q` under `pipefail` killed the producer with SIGPIPE the moment the early match landed and the reader closed the pipe, and the check reported a citation that was there as missing; the small fixtures could not show it, because their producers finished writing before the reader walked away. The tail is sized past a Linux pipe's fixed 64 KiB capacity and `scripts/lint-skills-selftest.sh` asserts that length, so trimming it fails loudly instead of turning the row into a no-op. The tenth, `body-checked.md`, is the body checks' rule-class fixture described below; `broken-links` cites it by stem, so it is a third rule this check must pass over in silence.

`src/undeclared-dep/` invokes `fixture-discipline` by the Skill-tool form without declaring it; `src/quoted-dep/` mentions it only in a quoted string, an arrow-parenthesised aside, and a fenced block, and must stay quiet on the requires check (it is also the dependant `uncited-depends.md` names, and must fire there — the two messages differ in their suffix, `/SKILL.md` versus `/`); `src/unused-dep/` declares it and never names it, and its `references/shell-transport.md` passes HTML to a tracker CLI through `$(cat …)`, which the rich-text transport check must flag.

The two invocation-form fixtures come after that pair. `src/slash-on-model-invoked/` names `fixture-discipline` in the retired slash form, which the slash-on-model-invoked check must flag; `src/call-forms/` writes the Skill-tool call in the three shapes a one-name imperative regex misses — a gerund, two names in one clause, and a user-invoked target the model cannot reach. Both scans read the same masked text, so `quoted-dep` carries each exempt shape in both forms, and carries the two slash forms that are correct unmasked — a user-invoked skill and a built-in — which grade the slash check's own guards.

The pass-2 classifier's per-class routing has its own nine fixtures — six in this root,
three in `lint-fixtures-clean/` — because every other fixture here sits in one class, a
skill body, and a classifier that stopped checking any other class stayed green. Every
file under `global/rules/` goes through that arm and is graded by all four body checks;
`global/rules/body-checked.md` is the only one that fires, on a broken link, an ADR
token and HTML through the shell, and it also carries the retired slash form of a
model-invoked name under a *Must stay quiet* heading, because `global/rules/` is the
one class the slash sweep deliberately skips and an exemption nobody exercises is not an
exemption. `.claude/skills/repo-local/` is the only repo-local skill, and the slash sweep
is the only check that reaches it — `lint-fixtures-clean/.claude/skills/repo-local/`
is its quiet half, naming a user-invoked skill and a built-in. `src/broken-links/references/load-gated.md`
carries a load gate in a *reference* file under a model-invoked owner, the half of that
check no `SKILL.md` fixture can reach. `src/stray-note.md` is a markdown file at depth
one under `src/` with no owning `SKILL.md` beside it — the only input that arm has — and
it fires on an ADR token; `lint-fixtures-clean/src/stray-note.md` is its quiet half. The
last two in this root are `DOMAIN.md` and this file, described in the closing paragraph,
whose quiet half is `lint-fixtures-clean/DOMAIN.md`.

The ledger-vocabulary pair grades the three evaluation-ledger checks — `check_evaluation_ledger_authority`, `check_evaluation_ledger_rule_agreement` and `check_evaluation_ledger_consumers`. `src/ledger-legend/`
owns the legend (`references/legend-line.md`) and a stored-status rule in its `SKILL.md`
that disagrees with it on one member, so the two-authority row fires; its
`references/unanchored-in-legend-dir.md` enumerates two of three and carries no ledger
word at all, which is the only place the rule that every file inside the legend's own
skill is read gets exercised. `src/ledger-consumer/` drops a status on an anchored line,
and carries seven `references/` files. Four fire, each anchored by exactly one of the
four alternatives the anchor pattern accepts — a `docs/evaluation/` path, the
`evaluation-ledger` slug, the spaced prose form, and the bare `ledger.md` file name — so
dropping any one alternative takes exactly one of them quiet and leaves the rest red.
Three must stay quiet: one names a single status on an anchored line (a reference, not an
enumeration), one enumerates two inside a fenced block, which is documentation of the
format rather than a claim about the vocabulary, and one names two statuses of an
unrelated vocabulary with nothing anchoring it. The clean root holds the agreeing half, and
`scripts/lint-skills-selftest.sh` also builds three throwaway copies of that root, each
broken in exactly one way, because the branches that return early and the check's effect on
the exit status cannot be graded in a tree where a dozen other checks already force exit 1.

`global/hooks/` holds the hook-selftest fixtures: `orphan-hook.sh` (an `# Install note:` header and no selftest), `unexec-hook.sh` whose selftest exists without the exec bit, and two that must stay quiet — `quiet-lib.sh`, a `*-lib.sh`, and `unmarked-helper.sh`, which carries no `# Install note:` and so is not a hook whatever its name. `scripts/` holds the script-selftest fixtures the same way: `orphan-tool.sh` with no selftest, `unexec-tool.sh` whose selftest lacks the exec bit, and the quiet `quiet-lib.sh` and `install.sh`. `src/folded-description/`, `src/literal-description/` and `src/continued-description/` carry the three description shapes a one-line frontmatter reader truncates; `src/oversize-body/` sits just past the 15,000-byte re-attach bound, which draws the byte-size WARN and no FAIL — and pins the bound from above, as `lint-fixtures-clean/src/near-cap/` pins it from below. `adr/` is `scripts/lint-adrs-selftest.sh`'s fixture and `usage/` is `scripts/skill-usage-selftest.sh`'s; each has its own README.

The four `src/shared-trigger-*/` skills are the shared-trigger-phrase check's ground, and each carries one property the check must have. `shared-trigger-straight` writes the phrase in straight double quotes; `shared-trigger-curly` writes it in curly quotes and another case, so it is the only place the curly branch of the extractor's alternation and the case fold are exercised — normalizing those smart quotes silently retires both; `shared-trigger-scalar` wraps its whole description in a YAML double-quoted scalar, the form the colon check exempts, so the check is graded on a description whose spans are escaped. All three carry the same phrase, so the check must name all three in one FAIL line — which is also the only place more than two carriers are rendered. `shared-trigger-not-for` carries that phrase in a disambiguating "Not for…" tail, the form `write-skill` prescribes for routing a reader *away* from a sibling, and must stay quiet; `quoted-dep` carries it in a user-invoked description and must stay quiet for a different reason. `scripts/lint-skills-selftest.sh` asserts each of those properties is still present, so an edit that weakens one fails there rather than quietly turning a row into a no-op.

`security/injected-skill/` and `security/clean-skill/` are `scripts/security-selftest.sh`'s fixture, and they grade themselves: every instance carries an annotation on the line before it — `# ruleid: <id>` (`//` in JavaScript, `<!-- -->` in markdown, several ids space-separated when one line draws several rules) names the rule the next non-blank line must draw, and `# ok: <id>` names the rule it must not. The injected side is wrong on purpose and carries one annotated instance per *alternative* of every rule the scanner names — each drop-site host, each credential-store and home-path form, each download form paired with each mode change, each member of the homoglyph table, each script extension under `scripts/ext/` — in a file named for the rule (`scripts/sh-imds.sh`; an alternative that only reads plausibly in another language takes that extension with the same stem, `sh-noverify.js`); a file that cannot carry a comment (a manifest, a fake ELF under `bin/`, the two bytecode-named files, a UTF-16 file) is graded from the selftest's `NO_COMMENT_TABLE` instead, and every finding in such a file must match a row. The clean side is right on purpose: the benign neighbor of each rule, sitting near its threshold (a download with the chmod six lines away against the five-line window, a 190-char hex hash against the 200 floor, a regex range and a Cyrillic word beside an escape against the homoglyph rule), and any finding there is a red. The selftest pins the expectation count exactly, so adding or removing an instance is a deliberate edit there; the selftest's header states what the grading does not cover. Nothing in either runs, and no file carries the executable bit.

`src/house-style/` (the skill `house-style`) carries the house-style checks' ground: one firing instance of each — the descriptive "the X skill" form, a suggestion site naming a user-invoked skill bare, an artifact filename with an uppercase letter and an underscore, an ALL-CAPS label this tree's `DOMAIN.md` never registered, a `§` pointer into a file that carries no such heading, and a title-cased H2 — and beside each the neighbor that must stay quiet: a model-invoked name at the same suggestion site, a repo-convention filename, a registered label, a pointer that resolves, a British form inside a code span, and two headings whose mid-word capitals are an acronym and a numbered label. `src/broken-links/references/orphaned.md` is the orphan check's whole input, and every other reference in this tree is linked from its owner so that check grades one file rather than the tree.

Edit these fixtures only to add coverage. Weakening one to make the self-test pass is the
failure the self-test exists to catch.

`README.md` and `DOMAIN.md` are in the walk for the slash sweep and nothing else, and
each carries one retired slash form so that class is graded rather than assumed: this
line writes `/fixture-discipline`, a model-invoked name, and must fire.
