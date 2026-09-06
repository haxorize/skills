# Open findings

Additive: a finding here is carried by later sweeps, never re-raised as new. A finding that stops reproducing is marked closed with the commit that closed it; one that never reproduced — the check was wrong, not the corpus — is marked `withdrawn` instead. Withdrawn is not fixed, and neither is ever dropped. Each row's counts are measured at the tree its `Closed by:` commit names; the file carries no single `Measured-tree:` line because it accumulates across trees by construction. IDs are `H-<nnn>`, assigned once across the life of this file and never reused — the scheme `sweep-corpus` § 3 declares. Closing runs outside a sweep, per `sweep-corpus` § Closing a finding.

## Open

_None._

## Closed

### H-001 — README.md:222's mutation-table-row-count claim — **withdrawn**; its disk figures fixed

Raised by: doc-claim check, sweep 2026-09-05.
Quoted: "`security-selftest.sh`, which copies and edits the scanner **75 times** and writes a 10 MB archive and a 1.1 MB file".
Ground as filed: `grep -cE '^ *mutation(_exit)? "' scripts/security-selftest.sh` → 74; the file self-pins at 74 (`scripts/security-selftest.sh:582`).

**The primary claim is withdrawn — the check was wrong, not the corpus.** The sentence's subject is *copies of the scanner*, not *rows of the mutation table*, and there are 75: `:467` and `:568` are the two mutation helpers that copy it once per row (74 between them), and `:598` copies it a 75th time to `lock-read.sh`. Measured by running it, 2026-09-05:

```
$ bash -x scripts/security-selftest.sh 2>/tmp/sst.err; echo "exit=$?"
exit=0
$ grep -aoF 'cp scripts/security.sh' /tmp/sst.err | wc -l
      75
```

The 74-row pin is real and green; it just does not grade the sentence that was flagged. Graded against a pin over a different noun, this was the `evidence.md` failure mode *a check parses the way its consumer parses* — committed by the check, and the reason a withdrawal is recorded here rather than a fix.

**The secondary claims in the same clause were real and are fixed.** Two 1.1 MB files are written (`:587`, `:595`), not one — sequentially, the first removed at `:594`, so peak disk is 1.1 MB; and there are two archives, whose members unpack to 10.5 MB (`:666`) and 20 MB (`:678`), both `ZIP_DEFLATED` runs of a single byte and so kilobytes on disk. The old text named one archive at the smaller figure. `README.md:222` now reads "copies and edits the scanner 75 times — once per mutation-table row, plus one — and writes two 1.1 MB files one at a time, plus two compressed archives whose members unpack to 10.5 MB and 20 MB".

Closed by: the 2026-09-05 fix-pass commit (SHA written by the follow-up commit, per `sweep-corpus` § Closing a finding).

### H-002 — global/README.md:13's dependants grep omitted the files the same sentence counts — **fixed**

Raised by: doc-claim check, sweep 2026-09-05.
Quoted: "`recommend-and-proceed.md` names 5 while more do, three of them overriding its bin 1 outright … for the dependants of a rule, run `grep -rl <filename> src/ .claude/skills/`".
Ground as filed: that grep returned 6 files; the three overriders — `src/offboard-engineer/SKILL.md:21`, `src/onboard-me/SKILL.md:26`, `src/rebuild-contract/SKILL.md:23` — cited the rule by bare name, so the recipe could not re-derive the census the sentence stated.

Fixed on both sides, because the recipe alone could not close it. The recipe is now lint's own two accepted forms (ADR-0053:40), with `<stem>` defined and lint's narrower scope stated; and the sentence no longer claims the recipe returns a census of dependants — "three of them overriding its bin 1 outright" is now marked as an observation about what those bodies say. Separately, **five** bodies leaned on the rule without citing it in any form lint accepts — the three above plus `src/audit-skills/SKILL.md:69` and `src/handoff/SKILL.md:54`, the last two missed by the finding as filed — and all five now cite it by installed path, the form `src/handoff/SKILL.md:34` already used for `large-write-chunking`. `Depends:` is unchanged at five names; citing is not declaring. Measured after: recipe 11, bare-name 11.

Recorded in [ADR-0077](../adr/0077-tightening-round-one-house-style.md) § Amendments, 2026-09-05, which also corrects that record's two stale figures for the old recipe.

Closed by: the 2026-09-05 fix-pass commit (SHA written by the follow-up commit).

### H-003 — bare "ledger" in `.claude/skills/mine-skills/SKILL.md` — **fixed**

Raised by: cross-reference check (alias arm), sweep 2026-09-05.
Quoted: "write the ledger rows a grill can ratify" (`.claude/skills/mine-skills/SKILL.md:3`), with bare uses also at `:9`, `:31`, `:39`.
Ground: `DOMAIN.md` § Flagged ambiguities requires bare "ledger" to be qualified and states the enumeration is not closed; the **Evaluation ledger** row carries `bare "ledger"` in its normative alias column. `DOMAIN.md` writes an explicit anaphora carve-out for `chart-course`'s bare "ticket" and `onboard-me`'s bare "map"; none existed for this one.

Fixed by the carve-out, narrowed. `DOMAIN.md:501` now exempts *a bare `ledger`* inside `mine-skills` prose and says the other senses there name their owner — a universal that holds, where "every ledger is the **Mining round**'s" did not: `:19` carries two that are not, the memory ledger `skill-mining-sources` and ADR-0034's amendment ledger, the second being a sense the same bullet enumerates separately. The enumeration gained both round-ledger senses, the **Mining round** row `:389` gained a `bare "ledger"` alias cell so a reader arriving at the term finds the carve-out, and the two sites outside the carve-out's reach were qualified instead: `mine-skills`' `description:` field (a field, not prose, surfaced standalone in a roster) and `README.md:163`'s blurb, neither of which has the antecedent anaphora needs.

The disposition was the user's, taken 2026-09-05 in the fix-pass session; the finding as filed left it open as a judgment.

Closed by: the 2026-09-05 fix-pass commit (SHA written by the follow-up commit).
