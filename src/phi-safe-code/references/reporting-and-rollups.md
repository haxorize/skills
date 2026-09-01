# Reporting and rollups

Open this only when the change emits a count, a rollup, a chart, a dashboard, or a scheduled extract — never on a change that only logs, stores, or builds a prompt.

A rollup is a PHI output until its small cells and their complements are suppressed: a count re-identifies once the cell is small, and suppressing the small cell alone leaves it recoverable from the total. What reaches a reporting sink is counts and rollups whose small cells are suppressed, and their complements with them — never a row-level extract behind an aggregate label. The suppression threshold is the convention skill's answer and is named in the data-flow row. A drill-through that reaches a row is that row's sink, not the chart's, and is traced as one.

**The rollup's data-flow row.** A rollup has no single source field to key on, so give it a row keyed by its population instead — the query predicate, the fields it groups on, the smallest cell it can emit, and the suppression applied — with the sink, guarantee, and BAA columns unchanged.
