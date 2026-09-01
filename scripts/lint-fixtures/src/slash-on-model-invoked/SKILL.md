---
name: slash-on-model-invoked
description: Fixture that writes a model-invoked skill in the slash form — the shape the convention switch retired.
disable-model-invocation: true
---

# Slash on Model-Invoked

Run the `/fixture-discipline` skill now. A human cannot type that: `fixture-discipline` is
model-invoked, so the slash form both misdirects the model and hides the call from the
used-but-undeclared scan.

Three more slash forms, one per alternative of the dangling-name arm. `/no-such-command`
names no skill in either tree and is on no roster, so it fires. `/compact` names no skill
either and must stay silent, because slash_exempt carries it as a Claude Code built-in.
`/checkout-page` is a route rather than a command and stays silent, because the marker naming it sits on this same physical line. <!-- slash-exempt: checkout-page -->

`/order-status` is the same shape and fires, because the marker naming it is on the NEXT
line rather than its own — a marker exempts the line that carries it and no other, the
scope `<!-- spelling-exempt: word -->` has.
<!-- slash-exempt: order-status -->

The references beneath this skill are pointed at from here, so the orphan check
grades its one deliberate orphan and not this tree's whole reference set:

- [retired-form](references/retired-form.md)
