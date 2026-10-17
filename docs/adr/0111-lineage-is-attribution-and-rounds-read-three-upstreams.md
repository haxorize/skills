# Lineage is attribution, and a mining round reads three upstreams

This supersedes [ADR-0034](0034-branch-mining-lineage-or-dormant-main.md), which had every material edit of a ported skill start with a diff of its upstream, main and branches, from a swept point kept in that record's dated amendment chain.

`docs/lineage.md` says where each ported or borrowed skill came from, under what license, and which record admitted it. Nothing in it is diffed before an edit. Upstream material reaches this repo only through a **Mining round**, which reads three upstreams: mattpocock/skills (the default branch, plus unmerged branches whose tip is newer than the last read and whose own changes touch a ported path), compound-engineering-plugin, and nvidia/skillspector (default branch only). The other eight are attribution only and are read again only when Nick names one for a round. Each upstream's last-read commit is one row of `docs/lineage.md` § Upstreams, overwritten by the round that reads it; git history is the log, and the dated entries stop.

**Why.** The edit-time diff had stopped finding anything the round sweep did not. The 2026-10-12 round listed 1,219 branch heads across the ten upstreams other than Matt Pocock's and folded nothing from them; in compound-engineering, 119 heads touched a borrowed file and the 7 that were read gave nothing to adopt. Matt's repo is the exception: 10 of its 134 heads touched a ported path, and they gave 4 of the 9 ideas worth adapting from it. The local skills have also outgrown what they were ported from (the local `SKILL.md` bodies measured 12,964 B for `tdd` against 3,629 upstream and 14,193 B for `handoff` against 940, by `wc -c` at `2324390`, the tree the round's `portfolio.tsv` measured; in the tree that last edited this sentence they are 12,958 B and 11,930 B), so a diff at edit time mostly shows that the two differ. The eight quiet upstreams had no change on a ported path this round. ADR-0034 had grown to 41,058 B, a table per round. Nick answered yes on 2026-10-12 (the round's grill, ask 13).

**The gate.** It undoes ADR-0034's title decision, so it is a new record rather than an edit.

## Considered Options

- **Keep the edit-time diff and only trim the branch policy.** Rejected: the round already reads every upstream that moves, so the edit-time diff repeats it, and no instrument showed how often it ran.
- **Keep all eleven upstreams on the round's reading list.** Rejected: the eight quiet ones cost a delta read each per round and gave nothing.
- **Keep the dated swept-point log, in the lineage file instead of the record.** Rejected: git history of one table already keeps every earlier commit.

## Consequences

- `CLAUDE.md` loses the lineage line from its always-loaded file: 2,948 B to 2,838 B (`wc -c`). The section keeps the `writing-for-agents` trigger under a new heading.
- The `pre-commit` hook no longer prints a lineage notice when a ported skill is staged, and its selftest no longer grades one.
- `mine-skills` step 2 reads § Upstreams instead of this record's chain, and writes each read row back.
- An upstream fix from one of the eight quiet repos reaches this repo up to one round late, or not at all until someone names it.
- `docs/lineage.md` keeps its two tables, ported and ideas only, because the ported table's "Name there" cells and the second table's license terms are the attribution owed. It grows by the § Upstreams table: 43,657 B to 44,987 B (`wc -c`).

Revisit when: one of the eight attribution-only upstreams changes a ported path and the change would have been adopted, or a teammate editing a ported skill asks for the upstream diff in front of them.
