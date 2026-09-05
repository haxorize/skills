# Done conditions by work type

Open this only when the item is a bug, a performance item, a research spike, or operations work; a plain User Story pins nothing here.

| Work type | The criteria must pin |
|---|---|
| **Bug** | Reproduction before fix — a check that fails before the change and passes after |
| **Performance** | Metric, threshold, measurement method, run count, and the correctness criterion the optimization must not break, stated as its own pass/fail criterion ("under 200 ms" *and* "no result dropped") — all five, because a bare number is met by losing what it measured. The threshold also says what it is relative to: trunk, only where trunk runs the same scenario; where it cannot, an absolute budget for the added work and the user-visible end state — and the item says which, because a ratio over unlike scenarios reads as a pass and is a number about nothing |
| **Research or spike** | The decision the work must enable, and the evidence standard that settles it |
| **Operations** | The healthy end state, the observation window, the rollback trigger — the three lines `ship`'s post-deploy watch reads off the item before the deploy |
