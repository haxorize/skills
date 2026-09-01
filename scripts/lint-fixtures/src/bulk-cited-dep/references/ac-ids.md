# The ungrouped sibling copy

There are two copies of this file, one under each of two fixture skills, and no entry in
`sibling_groups` lists either path — which is what the membership check fires on. Neither
path is named here, because the two copies are byte-identical and a file naming one of
them would name itself. Its basename is deliberately one the real registry DOES group —
so the basename test this fixture replaced stayed quiet on it, and the path test fires.
If `ac-ids.md` ever leaves `sibling_groups` in `scripts/lint-skills.sh`, this fixture
still fires but stops discriminating the two readings; rename both copies to another
grouped basename then.

The two copies are byte-identical so that nothing but the membership rule is at stake.
