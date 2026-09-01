# Cited only from a hoisted rule (fixture)

Open this only when reading why `check_reference_orphans` carries `global` among its
scan roots. Nothing under `src/house-style/` links this file: its only pointer is the
installed-path citation in `global/rules/body-checked.md`. Delete `global` from
`orphan_scan_roots` and this file starts reading as "linked from nowhere", which is
what makes that scan root an assertion rather than a line nobody grades.
