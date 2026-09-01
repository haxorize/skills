# A markdown file at depth one under src/ (fixture)

No owning SKILL.md sits beside this file, so the load gate has nothing to key on — but
the body checks and the slash sweep still reach it, and this fixture is the only input
that arm has ever had. It cites ADR-0007 by number, which a body may not do, and that
FAIL is what proves the arm still runs.

Deleting `house_style_checks` from the `src/*` arm used to leave the selftest green —
the ADR token above is a body check, and no house-style violation lived at this depth.
So: the run normalises this row before it lands.
