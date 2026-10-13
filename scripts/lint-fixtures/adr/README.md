# ADR fixture

`scripts/lint-adrs-selftest.sh` points `scripts/lint-adrs.sh` at this directory. Every numbered file exists to make one check fire or to prove one exempt form stays quiet; `README.md` is the one unnumbered file the linter must leave alone. Numbers start at 9001 so a citation search for a live record's number never lands here, and the gaps are the numbers of fixtures retired with the amendment checks.

Firing: `9001` twice (duplicate number); `9002`→`9003` (successor never links back); `9004` (two dangling supersession links, one in capitals); `9011` and `9012` (empty Revisit line, inline and heading form); `9040` (a plain cross-reference to a record that does not exist — not a supersession link, so it is the one link the supersession check leaves alone). `9004` draws a second FAIL from the cross-reference check as well as its own: a dangling supersession link is also a dangling citation, and the two messages name different repairs.

Quiet: `9016` (inline Revisit with text), `9017` (heading-form Revisit with a paragraph), `9041` (a cross-reference that resolves, beside the three forms the check exempts: a path out of this directory, an outbound URL, and the `[ADR N](N-slug.md)` placeholder).
