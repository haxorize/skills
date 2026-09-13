# Sizing — the worked examples and the three tests

Open this when § Sizing's signals fire — a split is being proposed, the scope-reduction vocabulary shows in a draft, or a rider, a claimed must-have, or a bug against committed work is on the table. The rules are in the body; this file holds what they look like.

## Too big

An "and" in the title is the plain case. A bundling verb hides one: *manage*, *handle*, *maintain*, *support* — each names a bag of deliverables, so "manage subscriptions" is create, change, and cancel until the title says which. Criteria that pass only together show the same thing: "the export runs nightly" and "the report carries the new column" are two deliverables wearing one title.

A checkout sliced signup, then cart, then payment — one step per item — looks vertical, since each step touches every layer, and delivers nothing until the last step lands. The first slice runs the whole workflow at its crudest — every step present, each in its simplest form — and later slices add the intermediate steps.

## The scope-reduction vocabulary

The phrases that mark deferred work hiding in a body: "v1", "for now", "hardcoded", "placeholder", "will be wired later", "temporary", "quick version", a flag with no removal item. Each either names deferred work that lands explicitly in out-of-scope or a follow-up item, or it quietly under-delivers the decision the item claims to implement. A body can cite its parent decision and still deliver a fraction of it — the citation is not the delivery.

## The three tests

**The rider.** The trigger is the defect or need itself: the same defect found on a second path is in scope, and an improvement noticed because the file was open is not. For the borderline addition, ask whether it would ship on its own merits if the main change did not exist: no makes it decoration on someone else's diff — cut from this change, one line in the tracker note, no item; yes cuts it from this change too and files it as its own item with its own criteria, never a rider. The owner can add the second item; the owner cannot merge the two into one change.

**The claimed must-have.** A requirement everyone calls a must-have is tested against the item's core tasks: which one becomes impossible without it? A named task keeps it; "worse but possible" demotes it, however senior the claimant, and the demotion is recorded with the claimant, the evidence given, the workaround, and what evidence would reverse the call — a falsifiable claim instead of a fight.

**The bug arriving against committed work.** Two questions, each answered with its reasoning before the yes or no: is this bug more important than the item in progress, and than the next planned one? Two noes defer it into the backlog with nothing interrupted. Either yes escalates it to fuller classification — severity, blast radius, workaround — never to an immediate interrupt.
