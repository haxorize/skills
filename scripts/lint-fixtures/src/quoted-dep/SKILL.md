---
name: quoted-dep
description: Fixture whose only Skill-tool and slash mentions are quoted, parenthesised or fenced, plus the two slash forms that are correct unmasked — and all must stay quiet; it also quotes "walk the tree", the phrase the two shared-trigger fixtures share, and a user-invoked description is never read for that check.
disable-model-invocation: true
---

# Quoted Dep

A quoted example stays exempt: "Call the Skill tool with `fixture-discipline`" and "Run the `/fixture-discipline` skill" are how the guide quotes the live form and the retired one, and so is an aside (`caller` → Call the Skill tool with `fixture-discipline`, never `/fixture-discipline`).

Both scans read the same masked text, so each exempt shape carries both forms: drop a mask
and the quoted or parenthesised mention fires on one scan or the other. The masks are
line-based, so each construct above stays on one line — a quoted span or an aside that
wraps is not masked at all.

Two slash forms are correct with no mask, and grade the slash check's own guards:
`/quoted-dep` names a user-invoked skill, which is exactly who the slash form is for, and
`/compact` is a built-in that resolves to no skill directory.

```md
Call the Skill tool with `fixture-discipline` now, and never write `/fixture-discipline`.
The global `uncited-depends` rule is named only here, inside a fence, which is not a citation.
```
