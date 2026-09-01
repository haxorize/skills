# Smell baseline

The catalog the smell-baseline lens matches against the diff: the fixed Fowler set (*Refactoring*, ch. 3), a fail-fast error-handling family, and one comment row after them. Two rules bind it.

## How to read the catalog

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgment call.** Each smell is a labeled heuristic ("possible Feature Envy"), never a hard violation.

## The catalog

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep traveling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with one typed dispatcher (map/table) both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.
- **Long Function** — the diff grows an already-long function instead of decomposing it; the body outgrows what one reading can hold. → extract steps into named helpers; each name documents intent.
- **Large Class** — a class or module accreting fields and methods for several jobs (a file ballooning under this diff is the file-level tell). → split by responsibility; extract the cluster that changes together.

Beyond the Fowler set, the lens carries a **fail-fast error-handling family** (high-signal on any diff that adds or changes a `try`/`catch` or fallback):

- **Swallowed failure** — a catch that hides the failure signal: returning `null`/`[]`/`false`, absorbing a parse failure, logging-and-continuing, "best effort" silent recovery. → propagate; handle only where the handling is correct *at that layer*. A boundary handler may translate an error — it must never pretend success or silently degrade.
- **Ceremonial catch** — a catch that exists to satisfy lint or style without real handling. → delete it or make it handle; its cost is real-failure camouflage, not style.
- **Canceling side effect** — a handler whose later call undoes a state change an earlier call made (`setComposeMode(true)` then `selectThread(null)`, whose side effect resets the mode), so the final state is not what the control's label promises. → trace the handler's calls in order and check the end state against the promise; drop or reorder the canceling call.
- **Message-matched error** — control flow keyed on an error's message text rather than its code or stable identifier; wording, i18n, and library upgrades all break it silently. → match on the code/type, never the prose.

One row after both families — Fowler's *Comments* smell, narrowed to the `+` side and Follow-up by default:

- **Comment slop** — a comment carrying nothing a reader lacks: a tombstone (`// removed X`, `// no longer needed`), a restatement of the line beneath it, a framing comment (`// helper`, `// for clarity`), a callsite reference (`// used by Y`), a tracker reference (`// handles #123`). → delete it; a comment earns its line by saying why, never what.
