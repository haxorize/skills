# The stage ladder and the trail

Read this before the first trail write, and again on a resume. `01-behavior-index.md` is the live artifact of the whole run; this file is the ladder it walks, the folder that holds it, and how a resume picks it up.

## Inventory first, then read deeply

Coverage on a system too large to hold in context comes from enumerating first and reading second. **Never a read-everything pass** — reading widely and shallowly ends out of context with a document of headings and no rules.

**Pass 1 is mechanical.** Enumerate with the stack's own listing commands and a grep — the route table, `--help`, the schema, the job schedule, config keys, permission checks, error types, feature flags, test names — into `01-behavior-index.md`: one line per candidate behavior, each with a stable ID (`C-014`, carried unchanged into the trail and the contract) and a state (`open`, `specified`, `excluded`, `deferred`, `unknown`). Nothing is dropped: an entry the inclusion test excludes is marked `excluded`, which is a warning a reimplementer can act on, where a quietly deleted entry is a hole they find in production. The index is the **coverage denominator** — the only honest way to say at the end how much of the system was specified.

**Estimate before Pass 2.** From the index, estimate the contract's length; past roughly 3,000 lines, stop and scope down to one bounded context and write a smaller, complete contract. Compression is where the rules die: what gets cut to save space is the edge case, and the edge case is why the document exists.

**Pass 2 is targeted.** Work the index, read only what each entry needs, write findings into the numbered trail file as each stage completes, and mark each entry as you go. Tests first: **tests state intent, code states behavior**, so a good suite is a spec someone already wrote — and where they disagree, that is a [conflict], not a choice. Classify the system at Pass 1 — service, frontend, CLI, library, pipeline, worker, mobile, a mix — and let the type decide what "capability" means at Stage 2; a mix names the pieces and scopes to the dominant one.

## The ladder

Each stage narrows what the next has to decide. Work them in order, except where `00-boundary.md` says otherwise — a boundary that names no human observer makes a stage's user-facing half empty, and the boundary settles that, not the stage number. A run that stops early — the session ends, or the estimate forced a scope-down — says which stages were never reached rather than reporting the ones it did as the whole. A stage is complete only when its criterion is met; announcing one complete on a directory listing is how a contract ends up 80% framing and 20% rules.

| Stage | Done when |
| --- | --- |
| 0 · Boundary & scope | Every observer is named with a fidelity per surface, in- and out-of-scope areas are listed, and `00-boundary.md` exists |
| 1 · Behavior inventory | `01-behavior-index.md` holds one entry per candidate behavior across every surface the boundary named, each with an ID and a state, and you can state the count |
| 2 · Capabilities — the bulk of the run | Every in-scope entry carries the uniform capability entry's nine fields — trigger, actor, preconditions, rules, effects, outputs, edge cases, undefined, evidence — in the shape `contract-format.md` fixes, which is read here and not at `stop`; or the entry's index state is `excluded`, `deferred`, or `unknown`, each with its reason. No entry is left `open` and unread |
| 3 · Domain, state & invariants | Each core entity has a meaning, an identity rule, its lifecycle with legal transitions, and its invariants; every derived value has its formula written out; and what is persisted, what survives a restart, what is atomic with what, and what is deleted or retained is stated — the spine's *State & persistence* section is built from this stage and nowhere else |
| 4 · Integrations, jobs & side effects | Every outbound call, scheduled task, queue consumer, webhook, email, and export has its trigger, its guarantees (ordering, idempotency, delivery), its failure and retry behavior, and its observable effect |
| 5 · Configuration, permissions & errors | Every behavior-changing key has its default and precedence; the actor × capability matrix is complete, denials included; every user-visible error has its trigger, its code or message, and whether it is retryable |
| 6 · Non-functional contract | Rate limits, size and pagination caps, timeouts, concurrency and consistency guarantees, retention and deletion, and compliance-driven behavior are each stated or recorded as not found — and so is every item on `obligation-rulings.md`'s stack-behavior list, swept one by one rather than waited on |
| 7 · Suspect behaviors & open questions | Every [suspect] has what happens, why it looks unintended, and whether anything outside can see it; every [unknown] names what would settle it |

## Where the record lives

```
docs/rebuild-contract/<target-slug>/
├── 00-boundary.md                 ← observers, fidelity per surface, scope in and out; updated every stage
├── 01-behavior-index.md           ← the enumeration and coverage denominator; every entry has a state
├── 02-capabilities.md             ← the deep pass, both axes, citations
├── 03-domain-and-state.md
├── 04-integrations-and-jobs.md
├── 05-config-permissions-errors.md
├── 06-nonfunctional.md
├── 07-suspect-and-unknown.md      ← [suspect], [conflict], [unknown], questions for a human
└── contract.md                    ← the deliverable, written only at `stop`
```

**One target, one folder.** The folder name is a slug you derive — the service or bounded context's name, lowercased and hyphenated — never the argument as typed. A monorepo with four deployables is four runs and four contracts; one contract covering four systems is too big to read whole and too entangled to rebuild from in pieces. There is no index file: the directory is the list.

Files `00`–`07` are the **working trail** — raw, doubly tagged, full of citations and [unknown]s, written as each stage completes and never polished. **Stamp every file** one line under its heading with the commit (`git rev-parse --short HEAD`) and the date, noting that citations are line numbers at that commit; where there is no `.git`, stamp the date alone and say so. `01-behavior-index.md` opens with a marker naming the stage in progress, removed at `stop`, so a resumed session knows where the walk stopped from the disk alone.

**Resuming:** read `00-boundary.md` and `01-behavior-index.md`; the index states what is unresolved. Where the stamp's commit differs from `git rev-parse --short HEAD`, say so in the first turn and re-verify anything you build on before extending it.
