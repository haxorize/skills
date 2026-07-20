# Domain — Skills Repo

Ubiquitous-language glossary for the entire skills repo. Covers the six main areas of work the skill suite supports — shaping backlog work (Feature/Story/Task/Bug publishing), charting foggy efforts (chart-course), design improvement (improve-design), recording decisions (ADRs), implementation (TDD), and tutored learning (teach-me) — plus the meta-vocabulary of the skills themselves.

## Skill mechanics

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Skill** | A Claude-Code-loadable behavior packaged as a directory with a `SKILL.md` root file | Plugin (Claude-Code term, distinct), Macro |
| **`SKILL.md`** | The mandatory root file of a Skill (≤200 lines), carrying YAML frontmatter and imperative-voice instructions | — |
| **Description** | The ≤1024-char frontmatter field the agent reads to decide whether to load a Skill | Summary, Tagline |
| **Frontmatter** | The YAML metadata block at the top of `SKILL.md` (`name:`, `description:`) | Header, Metadata block |
| **Reference file** | A supplementary doc under `references/<name>.md` (≤200 lines each) | Helper file, Sub-doc |
| **Repo-agnostic skill** | A Skill that works in any project without per-repo config | Universal skill, Generic skill |
| **Convention skill** | A project-local, **Model-invoked** Skill encoding the conventions of a specific stack (e.g., a `database` Skill for Alembic patterns); global skills discover and invoke it **by role**, named in CLAUDE.md `## Convention skills` | Stack skill, Project skill |
| **Hoist** | The act of making a Repo-agnostic skill globally available by symlinking it into `~/.claude/skills/` | Promote (different stage), Install |
| **Failure-driven escalation** | The `write-skill` wording rule: judgment-framing is the default; a hard prohibition (paired with a rationalization table and red-flags list) is reserved for a rule the agent demonstrably skips under pressure | Blanket caps ban (the prior rule), Authority-by-default |
| **Form-to-failure table** | The authoring decision table mapping a skill's observed failure type to the wording form that fixes it; the table lives in `write-skill`'s `great-skills.md`, the single source of truth | — |
| **Micro-test** | The cheap wording check run while authoring a discipline skill: execute the pressure scenario *without* the skill as a control (no control failure → nothing to fix), then 5+ fresh-context reps with the wording; high variance across reps is itself the failure signal | A/B test (broader), Eval (overloaded) |
| **Trigger test** | The description check for a Model-invoked skill that misfires or fails to fire: a handful of realistic should-trigger prompts plus near-miss should-not-trigger negatives, run in fresh contexts — the near-misses carry the signal; fixed by sharpening triggers, never by enumerating queries | Trigger eval (the official heavyweight form — 20 queries, train/test splits) |
| **Undertriggering** | The default description failure mode: the model handles a query itself rather than loading the applicable skill — what trigger-rich, front-loaded descriptions fight | — |

## Skill modes & verbs

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Synthesis-only** | A Skill mode that drafts from existing conversation context without interviewing | — |
| **Grilling session** | An interactive interview that stress-tests a plan | Interview, Q&A |
| **False yes** | A non-answer confirmation closing a Grilling session — "sounds good", "whatever you think", "I guess" — that hands the decision back to the agent; recovered by diagnosing the kind: *hasn't-decided* gets re-asked with two concrete options, *can't-evaluate* (repeated deferrals on questions needing domain judgment) gets a **Decision map** first | Soft approval, Hedged yes |
| **Decision map** | `grilling`'s response to a can't-evaluate deferral: 3–7 items, each a decision in the territory the user can't weigh — what it is in their vocabulary, why it matters for this plan, the realistic options, a recommended default; unpicked items take the default, recorded as an explicit assumption. An undecided expert never gets one — options, not teaching | Blindspot pass (upstream CE name), Teaching pass (implies tutorial) |
| **Pre-mortem** | The grilling closing question — "it's a year from now and this flopped; what went wrong?" — asked before declaring the decision tree resolved, to surface branches the tree missed | Retrospective (backward-looking, different artifact) |
| **Fixation** | Attention concentrated on the current problem frame so new output becomes local variations of it — the trigger for `diverging`; the trigger is fixation signals (iterations circling one idea, a binary with two bad options), never stakes | Local optimum (different mechanism), Tunnel vision (informal) |
| **Fire test** | `diverging`'s per-move check: could this output have been produced without the move? If yes the move didn't fire — commit harder or re-diagnose the stuck-pattern; re-diagnosis after a miss is not menu-rotation | — |
| **Sweep mode** | A non-interactive Skill mode that refreshes a derived artifact by scanning its source corpus | Bulk pass |
| **Update mode** | Single-artifact maintenance mode invoked via `--update <work-item-id>` (see ADR-0003) | Patch, Edit, Revise |
| **Reconcile mode** | Multi-artifact diff mode invoked via `--reconcile <story-id>`, proposing adds/closures/edits across child Tasks (see ADR-0003) | Sync, Realign |
| **Cold-start** | A fresh Claude Code session entering a work item with no prior conversation context | Fresh session |
| **Cold-reader pass** | The pre-publish verification a `to-*` publisher runs against author blindness (after drafting, you see what you meant, not what you wrote): a fresh-context subagent sees only the drafted work item and answers "what would you build?", naming ambiguities and assumed context; gaps loop back into the draft | Skeptical reader (`handoff`'s different move — the next session re-verifies *facts*, not comprehensibility), Reader test, Peer review (human act) |
| **Cold-start loader** | A Skill that fetches a published Work item back into the conversation as implementation context — embodied by `from-work-item` | Loader (when used alone) |
| **Archaeological mode** | `backfill-adrs`'s mode for recovering un-recorded decisions from git history | — |

## Skill invocation

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Invocation** | The axis that splits every Skill by *who can reach it* — the human only, or the model too | Triggering, Activation |
| **User-invoked skill** | A Skill reachable **only by a human typing its name**; carries `disable-model-invocation: true`, which hides its `description` from the model. The description is **human-facing** (a one-line summary, no trigger list). Its job is to **orchestrate**. | Manual skill, Human-only skill |
| **Model-invoked skill** | A Skill reachable by **model or user** (the default — omit `disable-model-invocation`). The `description` is **model-facing** and keeps rich trigger phrasing so auto-invocation fires. Holds reusable discipline. | Auto skill, Agent skill |
| **Orchestrator skill** | A (typically User-invoked) Skill — `grill-me`, `grill-and-record`, `harden-domain`, `improve-design` — that drives a workflow end-to-end and delegates reusable discipline to Behavior skills | Wrapper, Entry skill |
| **Behavior skill** | A Model-invoked Skill holding a reusable discipline the model can reach for autonomously (`grilling`, `domain-modeling`, `codebase-design`) | Core skill (acceptable shorthand), Discipline skill (acceptable), Helper skill |
| **Declared dependency** | A Behavior skill that an Orchestrator names as required; `scripts/install.sh` resolves it so the Orchestrator's Prose invocation always finds it. Relaxes ADR-0007 atomicity from "lone skill" to "skill + its declared deps" | Skill import, Require |
| **Prose invocation** | The soft, Claude-mediated mechanism by which one Skill instructs Claude to run another (`Run the /grilling skill`). There is no hard cross-skill include; it works only if the target is a Model-invoked skill **and** installed. Splits by severity into **Load-bearing delegation** and **Opportunistic reference** | Cross-skill call, Skill reference (clashes with Reference file) |
| **Load-bearing delegation** | A **Prose invocation** whose target carries the invoking skill's actual work — a thin-shell Orchestrator delegating its whole job (`grill-and-record` → `grilling`, `implement` → `tdd`). A silent non-load is high-severity (the skill proceeds on a half-remembered discipline), so it is phrased as an explicit imperative plus a **Load gate** and lives **only in User-invoked Orchestrators**, where a human watches the `Launching skill:` line. The runtime mechanism is still the model deciding to call the **Skill** tool — there is no hard primitive (see ADR-0019) | Hard call (no such primitive) |
| **Opportunistic reference** | A **Prose invocation** that borrows its target softly — a vocabulary citation (`diagnosing-bugs` uses `codebase-design`'s "seam") or a gated end-of-run offer (`diagnosing-bugs` → `adr`). A silent non-load degrades gracefully, so it stays a plain-backtick mention with **no imperative and no Load gate**; slashing vocabulary trains a spurious load, and slashing a pre-consent offer fires it early | Soft call (clashes with Prose invocation's softness) |
| **Load gate** | The self-check appended to a **Load-bearing delegation** instructing the model to stop and load if it did not just see the target's `Launching skill:` line — the cheap guard against a silent non-load | — |
| **Background-lens behavior** | A **Behavior skill** whose discipline runs *interleaved inside* a host loop without transferring control, so it can be **Prose-invoked** into a running loop at no rhythm cost (`domain-modeling` loads as a concurrent lens inside `grilling`). The orthogonal-to-load-bearing axis: it governs whether a host can delegate the behavior *at all*, not how reliably it loads (see ADR-0020) | Sub-loop, Inline behavior |
| **Gated action** | A skill or skill-step that *stops to confirm and then writes*, transferring control via its own gate-confirm flow — **Prose-invoking** it mid-loop interrupts the host's rhythm, so a host loop **inlines** the action even while delegating the surrounding **Background-lens behavior** (`grill-and-record` delegates `domain-modeling`'s glossary lens but inlines the ADR write rather than calling `/adr`) | — |
| **Extraction test** | The rule for when an Orchestrator's discipline becomes a separate Behavior skill: a real second consumer exists. *Reuse is the reason to extract, not the test for staying Model-invoked* — that test is "could the model usefully reach for this autonomously?" | — |
| **Pairs-only naming** | The convention that an extracted Behavior skill takes a discipline/gerund name (`grilling`, `domain-modeling`, `codebase-design`, `feedback-loops`) while its Orchestrator keeps an action name (`grill-me`, `harden-domain`, `improve-design`); standalone skills (`to-feature`, `from-work-item`, `tdd`, `adr`, `write-skill`) are not renamed | Strict-global naming (rejected) |

## Work item types

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Epic** | The top-of-hierarchy work item in ADO | — |
| **Feature** | A PRD-shaped work item that decomposes into multiple User Stories | PRD (overloaded), Capability |
| **User Story** | A single-feature spec sized to one delivery slice | Story (accepted shorthand), Spec |
| **Task** | A vertical-slice unit of implementation work under a User Story | Subtask, Step |
| **Bug** | An issue-shaped work item describing observed defective behavior | Defect, Issue |
| **KTLO Feature** | A "keep the lights on" Feature — a recurring per-PI bucket for one of {security vulnerabilities, tech debt, support requests, bug fixes}. Carries no AC field and no Story map; body is slim (Scope, Out of scope, Cadence/SLA, Constraints, Notes). | Bucket Feature, Maintenance Feature, Enabler Feature (overloaded — SAFe's Enabler is foundational-tech work, not maintenance) |
| **Work item** | The tracker-neutral umbrella term for any of the above | Item, Ticket |

## Acceptance criteria

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Acceptance criterion (AC)** | A testable success condition on a Feature, User Story, or Bug | Requirement, Spec line |
| **AC ID** | A stable, append-only identifier for an AC (`**AC1:**`, `**AC2:**`, ...) | AC number (implies renumbering) |
| **`## Covers`** | The Task body section listing the parent AC IDs the Task addresses | Refs, Implements |
| **Active AC** | An AC currently in force on a Feature, User Story, or Bug — not in `## Removed acceptance criteria` | Live AC (overloaded — sounds runtime) |
| **Removed AC** | An AC moved to the `## Removed acceptance criteria` section (see ADR-0002 for format) | Deleted AC, Dropped AC |

## Story shape

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **User-facing story** | A User Story with a real user role and stated user-visible goal | — |
| **Non-user-facing story** | A User Story for refactor, infra, observability, dependency-upgrade, or security-hardening work | Internal story, Tech-debt story |
| **Connextra user-story line** | The body-leading sentence on user-facing stories: `**User story:** As a [role], I want [goal] so that [benefit].` | Persona line |
| **`## User-facing behavior`** | The body section on non-user-facing stories describing the externally-visible outcome (or its absence) | Behavior section |

## Story map

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Story map** | The section of a Feature description listing decomposed Stories, a coverage matrix, a naming table, and dependency edges | Decomposition list (the artifact, not the act) |
| **Story decomposition** | The act of breaking a Feature into User Stories during `to-feature` step 6 | Story breakdown |
| **Snapshot** | The Story-map region above the snapshot separator, rewritten exclusively by `to-feature --update` | — |
| **Snapshot separator** | The `---` divider between the Snapshot and the Append region | Separator (when used alone) |
| **Planned Story** | A User Story whose scope is listed in the parent Feature's Snapshot, identified by a matching `### Story N` heading; `to-story` stamps the tracker ID inline on that heading and skips the Append-region append | Decomposed Story |
| **Emergent Story** | A User Story that arises after Feature publication with no corresponding Snapshot entry; `to-story` appends it to the Append region below the Snapshot separator | — |
| **Admission test** | The publish gate `to-feature` and `to-tasks` apply during decomposition: an item is published only when its scope can be stated precisely *now* — blocked-but-sharp is admissible, unsharpened scope stays as prose in the parent until it graduates (for Stories, as an **Emergent Story**), never a placeholder item | — |
| **Append region** | The mutable Story-map region below the Snapshot separator, receiving entries only for Emergent Stories | — |
| **Coverage matrix** | The Story-map sub-artifact mapping each child Story to the parent Feature ACs it covers | AC matrix |
| **Naming table** | The Story-map sub-artifact listing names shared across Stories (route paths, query keys, model names) | Shared-names table |
| **Dependency edges** | The Story-map sub-artifact recording which Stories depend on which siblings | Dependency graph (acceptable but less specific) |
| **Deferred decomposition** | A Feature published without a Story map, marked `Story Decomposition: deferred at Feature creation.` | — |

## Charting (chart-course)

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Chart** | The map artifact of a `chart-course` effort — one work item (ADO Feature / GitHub issue labeled `chart:map`, both carrying `Chart-type: map` in the body) indexing decisions made, fog, and out-of-scope rulings; its children are Decision tickets. An index, not a store: it gists each decision and links the ticket holding the detail. Discovery work, never the implementation Feature its Destination produces — the two link both ways (`Discovery:` line on the successor) | Map (acceptable shorthand), Enabler exploration (SAFe's nearest concept — acceptable when speaking SAFe), Wayfinder map (upstream name), Plan |
| **Destination** | What reaching the end of a Chart looks like — the spec, decision, or in-place change the effort is finding its way to. Named first; fixes the effort's scope | Goal (unsharpened), End state |
| **Decision ticket** | A child work item of a Chart (ADO User Story / GitHub sub-issue) holding one question whose resolution is a decision, sized to one session — never a build slice. Typed by its `Chart-type:` body line — one of grilling, prototype, research, errand | Ticket (when used alone), Spike (accepted team-facing shorthand for the research/prototype types only — grilling and errand tickets aren't spikes), Chart task |
| **Errand** | The Decision-ticket type for manual work that must happen before a decision can be made — provisioning access, signing up for a service, moving data so its shape can be seen. It *does* rather than decides, and earns its place only by unblocking a decision, never by delivering the Destination | Task (pinned to the work-item sense), Chore |
| **Fog of war** | The deliberately uncharted part of a Chart: decisions you can tell are coming but can't yet state precisely, written into the map's `Not yet specified` section. The admission test is whether the *question* can be stated precisely now, not whether it can be answered | Backlog (wrong axis), Unknowns |
| **Frontier** | The set ready to work *now* — in a Chart, the open, unblocked, unclaimed Decision tickets; in `grilling`'s batch cadence, the questions whose prerequisite decisions are already settled | Ready queue, Next up |
| **Claim** | Assigning a Decision ticket to whoever is driving it, before any work — assignment *is* the claim; an open, unassigned ticket is unclaimed | Lock, Checkout |
| **Claims recheck** | The end-of-session pass in `chart-course`, either mode: reread every assertion the session wrote — resolution comments, Decisions-so-far gists, facts later tickets depend on — against live tracker state and linked assets, fixing what doesn't hold, before stopping | Handoff review, Sanity check |
| **`Chart:` title marker** | The literal token baked into an ADO Chart or Decision-ticket title before `Title prefix:` resolution (`[App] Chart: <question>`), guarding against a board reader mistaking a question for build work. GitHub carries the typing in `chart:*` labels instead | `[chart]` (bracket namespace is taken by app/service prefixes) |

## Slicing & implementation

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Vertical slice** | A thin end-to-end cut through every Layer, shaped to exactly one **Task** — built **Tracer bullet** first, then behavior by behavior (never Layer by Layer) | Slice (when used alone), Cut |
| **Tracer bullet** | The first behavior built within a Vertical slice — the thinnest end-to-end path that proves the slice works | First test, Initial path |
| **Layer** | A horizontal stratum of the codebase (Data, Backend, Client, UI, Tests) | Tier, Stack |
| **Expand–contract** | The slicing pattern for a wide mechanical refactor whose blast radius breaks every call site at once (so no Vertical slice can land green): an *expand* Task adds the new form beside the old, *migrate* Tasks move call sites in blast-radius-sized batches (each blocked by the expand), and a *contract* Task deletes the old form once no caller remains | Parallel change (acceptable synonym), Big-bang refactor (the anti-pattern this replaces) |
| **`## Layers touched`** | The Story- or Task-body section enumerating affected Layers | Affected modules |
| **HITL** | "Human-in-the-loop" mode of a Task or Decision ticket — requires a live human (UX-sensitive, ambiguous, security-relevant; a HITL Decision ticket only resolves through exchange with the human — the agent never stands in for their side) | Manual |
| **AFK** | "Away-from-keyboard" mode of a Task or Decision ticket — safely driven by the agent alone | Auto, Unattended |
| **RED / GREEN / REFACTOR** | The TDD cycle: failing test, minimal pass, behavior-preserving improvement | Test-first, BDD cycle |
| **Tautological test** | A test whose assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`), so it passes by construction; expected values come from an independent source of truth — a known-good literal, a worked example, the spec | Mirror assertion (acceptable synonym), Self-fulfilling test |
| **Change detector** | A test only intentional decisions can fail — a constant's value, exact message wording, private structure: it fires on every redesign and sleeps through bugs; test the behavior that depends on the decision instead | Brittle test (broader), Pinning test (deliberate legacy characterization — a different move) |
| **Mutation check** | `tdd`'s closing pass: mentally mutate the production code (wrong constant or argument, wrong branch, missing side effect, empty return, missing validation) — each realistic mutation should fail at least one test; an uncaught mutation marks unprotected behavior or a Tautological test | Mutation testing (the automated, tool-driven form) |
| **Inner loop** | The fast test command (unit / type checks) used during RED/GREEN for behaviors testable without I/O | Unit-loop |
| **Outer loop** | The slower test command (integration / browser / E2E) used when the slice crosses I/O boundaries | E2E-loop, Integration-loop |
| **Build path** | The choice inside `implement` for the loaded slice: the **TDD path** (a Testable slice → `tdd`) or the **direct path** (docs, scripts, config, glue → built without test-first) | — |
| **Testable slice** | A Vertical slice whose behaviors warrant RED → GREEN → REFACTOR (built via `tdd`) | — |
| **Non-testable slice** | A Vertical slice built via the direct path because it has no meaningful test seam (documentation, scripts, config) | Untested slice (implies a gap, not a deliberate choice) |
| **Close the loop** | The **mechanical** finalization pass run **once after the slice's behaviors are built and refactored** (not per behavior) — `feedback-loops` runs lint/format/typecheck, migrations, and doc updates, resolving commands via CLAUDE.md `## Commands` and deferring stack-specifics to Convention skills. Judgment review (`review-changes`) and `/simplify` live elsewhere (see below) | Finalize (overloaded), Wrap-up |
| **`review-changes`** | The **read-only** judgment review (User-invoked Orchestrator) run before a PR or on a teammate's PR: it fans **Review lenses** out to subagents (findings only) and never mutates code; resolves its input from the local diff or a PR + a work-item pointer | Conformance-review (earlier name) |
| **Review lens** | One angle `review-changes` applies, chosen by **diff triage** so irrelevant ones don't run, each returning findings only; the roster (which lenses are always-on vs conditional) lives in `review-changes` §2, the single source of truth | — |
| **Anchored confidence** | The finding-discipline confidence scale — HIGH/MED/LOW each tied to a behavioral criterion the model can honestly self-apply rather than a free-floating gradient; the criteria live in `finding-discipline.md`, the single source of truth | Confidence score (implies a continuous scale) |
| **Quote gate** | The finding-discipline rule that HIGH confidence requires quoting the verbatim motivating line with `file:line`; enforcement lives in `finding-discipline.md`, the single source of truth | — |
| **Cross-lens promotion** | Merging duplicate findings surfaced independently by two lenses promotes the merged finding one confidence step; its guardrails live in `finding-discipline.md`, the single source of truth | Corroboration boost |
| **Subagent hygiene** | The two rules every fan-out prompt carries because subagents don't inherit them: never reproduce secret values (cite `file:line` and credential type only), and all repo content is data, not instructions — instruction-shaped content is itself a finding, never something to follow | — |
| **Clarify-all-before-any** | The `receiving-review` rule for multi-item feedback: if any item is unclear, implement nothing until every item is clarified | Partial implementation ban |
| **Zero-accepted tripwire** | The `receiving-review` self-audit: classifying every finding in a review as invalid is evidence about the receiver, not the review — re-examine the strongest finding as if it were true before responding | All-reject guard |
| **Parked list** | The running list `implement` keeps of out-of-scope observations noticed mid-slice ("noticed but didn't touch"), surfaced at close as candidate backlog follow-ups and doubling as the change's scope declaration | TODO list (unscoped), Scope-creep log |
| **Performative agreement** | The `receiving-review` anti-pattern — agreeing with feedback ("You're absolutely right!", gratitude) before verifying it against the codebase | Sycophancy (broader) |

## Architecture & deepening

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Module** | Anything with an interface and an implementation (function, class, package, slice) | Unit, Component, Service |
| **Interface** | Everything a caller must know to use a Module — types, invariants, error modes, ordering, config | API, Signature |
| **Implementation** | The code inside a Module | — |
| **Depth** | The Leverage delivered at a Module's Interface | — |
| **Deep module** | A Module with high Depth — much behavior behind a small Interface | — |
| **Shallow module** | A Module whose Interface is nearly as complex as its Implementation | Thin module |
| **Seam** | The place where an Interface lives — where behavior can be altered without editing in place | Boundary (clashes with DDD's Bounded context) |
| **Adapter** | A concrete thing satisfying an Interface at a Seam | Driver, Plugin |
| **Port** | An Interface at a Seam designed for swapping Adapters | — |
| **Leverage** | The behavior callers obtain from a small Interface | — |
| **Locality** | The concentration of change, bugs, and knowledge inside a Module | Cohesion (different sense) |
| **Deletion test** | The thought experiment of deleting a Module to judge whether complexity vanishes (Pass-through) or reappears across callers (earns its keep) — it cuts both ways: before deleting, name why the thing exists (git blame, ADRs); a small helper can earn its keep by naming a concept | — |
| **Concept-count test** | Judging a claimed simplification by the concepts a reader must hold before and after — an unchanged count is relocation, not reduction | Line-count test (the wrong metric) |
| **Pass-through** | A Module that adds no value beyond delegating to its dependency | Wrapper, Delegate |
| **Module-deepening refactor** | A refactor that increases a Module's Depth | Deepening (acceptable shorthand) |
| **Architectural friction** | The signal that deepening might help — bouncing between many small files, shallow interfaces, untestable seams, cross-module domain leaks | Smell (distinct from **Code smell (Fowler)**), Pain point |
| **Code smell (Fowler)** | A code-level cleanup heuristic from the fixed *Refactoring* ch. 3 catalog that `review-changes`' smell-baseline lens matches against a diff, keeping Fowler's names (his Middle Man is this glossary's **Pass-through**) | Smell (bare — ambiguous) |
| **In-process dependency** | A Module's dependency that is pure computation or in-memory state | — |
| **Local-substitutable dependency** | A dependency with a local test stand-in (PGLite for Postgres, in-memory filesystem) | — |
| **Remote-but-owned dependency** | A dependency on your own service across a network | Internal API (overloaded) |
| **True external dependency** | A third-party service you don't control (Stripe, Twilio) | Vendor dependency |

## Decisions & documentation

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **ADR (Architecture Decision Record)** | A short markdown record of a single non-obvious design choice, kept under `docs/adr/<NNNN>-<slug>.md` | Decision doc (vague), RFC (different scope) |
| **ADR gate** | The three criteria a decision must meet to warrant an ADR — hard to reverse, surprising without context, result of a real trade-off | Decision filter, ADR criteria |
| **Slug** | The short kebab-case summary in an ADR filename | Title, Name |
| **`## Considered Options`** | The optional ADR section listing rejected alternatives | Alternatives |
| **`## Consequences`** | The optional ADR section noting non-obvious downstream effects | Implications |
| **Status frontmatter** | The optional ADR field (`proposed | accepted | superseded by ADR-NNNN`) | — |
| **Sweep window** | The git-history range scanned by `backfill-adrs` (default: last 90 days OR last 200 commits, whichever is shorter) | Lookback window |
| **ADR debt** | The accumulated un-recorded architectural decisions in a repo before ADR practice begins | Decision debt |
| **`DOMAIN.md`** | The repo-root glossary of ubiquitous language | ULang.md (deprecated; renamed during the skills restructure) |
| **Glossary** | The set of canonical Domain terms within `DOMAIN.md` | Vocabulary, Lexicon |
| **Bounded context** | (DDD) A subdomain with its own ubiquitous language | Context (when used alone — too generic) |
| **Ubiquitous language** | (DDD) The shared vocabulary between developers and domain experts within a Bounded context | Domain language (acceptable casual usage) |
| **Sibling reference file** | A `references/<name>.md` file duplicated byte-identically across multiple skills (`domain-format.md`, `adr-format.md`); ADR-0007 records the duplication, `scripts/lint-skills.sh` enforces equality | Shared reference (no source-of-truth — they are siblings, not a copy-of) |
| **Learning doc** | A solved-problem record under `docs/solutions/<slug>.md` — symptom-keyed frontmatter plus a Problem / What didn't work / Fix / Prevention body | Solution doc (compound-engineering's — CE's — two-track sense), Learning solutions, Postmortem (different scope) |
| **Solved-problems store** | The `docs/solutions/` directory of Learning docs in a target repo — new captures land flat at its root; category subdirectories from other tooling are tolerated | Knowledge base (too broad), Learnings folder |
| **Capture gate** | The three criteria a solved problem must meet to warrant a Learning doc — verified fix, expensive diagnosis, recurrence-plausible | Preconditions (CE's advisory form) |
| **Retrieval protocol** | The grep-first search over Learning-doc frontmatter; its steps live in `capturing-learnings`, the single source of truth | Learnings research (CE's subagent form) |
| **Overlap rule** | The update-vs-create decision at capture — same root cause and same fix approach → update the existing Learning doc; otherwise create | Dedup score (CE's 5-dimension rubric) |
| **Adoption verdict** | The graded, project-grounded answer `adoption-verdict` renders on an external-adoption question — exactly one grade (Adopt / Trial / Hold / Reject / Not-our-problem), led in plain words with the label attached | Recommendation (unsharpened), POV (CE's broader shape set) |
| **Two-floor gate** | The Adoption-verdict validity check: a **Project floor** (one concrete verified project fact — incumbent + touchpoint, verified absence + integration point, or a prior decision) and an **External floor** (one external source read this session), independent pass/fail — a failed floor returns a Hold subtype, never a graded verdict at lowered confidence | Grounding gate (CE's name), Evidence bar |
| **Reversibility tier** | The three-level classification sizing an Adoption verdict's workup — two-way door / one-way bounded / one-way high-stakes; stated in the verdict, so a shallow Tier-1 answer reads as deliberate rather than lazy | Risk level (different axis — reversibility, not likelihood) |
| **Reversal trigger** | The Tier-2/3 Adoption-verdict schema field naming what observation would flip the grade | — |
| **Adversary pass** | The correction-cost-gated second opinion offered after a Tier-2/3 Adoption verdict: one fresh-context subagent seeded with only the verdict and its citations, instructed to refute it — fresh context beats self-critique because the author cannot unsee their own reasoning; Tier 1 never offers | Cross-model panel (CE's machinery), Second opinion (vague) |

## Teaching & learning

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Learning workspace** | The per-topic directory `<Learning root>/<slug>/` holding all of one topic's teaching state (mission, lessons, records, progress) — always outside any work repo | Teaching workspace (Matt Pocock's cwd-based model), Study folder |
| **Learning root** | The configurable parent of all Learning workspaces (default `~/learning/`) | — |
| **Mission** | The grilled "why" behind a topic, captured in the workspace `MISSION.md`; every Lesson is judged against it | Goal (unsharpened), Objective |
| **Lesson** | One self-contained, date-stamped HTML teaching unit in `lessons/` — a point-in-time consumable, never maintained after the fact | Course, Module (clashes with the Ousterhout sense) |
| **Learning record** | A dated, numbered insight record in `learning-records/` — what the learner now believes, the evidence, and the misconception it replaced; the Learning-workspace analogue of an ADR, written inline by `teach-me` | Journal entry, TIL |
| **Retrieval warm-up** | The default opening of every resumed teaching session — due-for-review free recall bracketed by confidence ratings, before any new material | Review session (implies re-reading, the weaker move) |
| **Topic glossary** | The Learning workspace's own `DOMAIN.md`, maintained by the `domain-modeling` lens; Repo-grounded topics read the repo's glossary instead | — |
| **Cheat sheet** | A compressed, printable reference sheet in `cheatsheets/` — the revisited artifact, lazily re-verified when a new Lesson touches it | Reference doc (collides with Reference file), Reference material |
| **Practice** | The middle leg of `teach-me`'s knowledge/practice/wisdom triad — retention-building effortful retrieval | Skills (collides with Skill, the unit) |
| **Grounding** | The `MISSION.md` declaration of a topic's source of truth — External (resources) or Repo-grounded (a named codebase as textbook) | Mode (overloaded) |

## Tracker integration

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Tracker** | An issue/work-item system (ADO or GitHub) | Issue tracker (use Tracker), System |
| **Tracker dispatch** | The per-Tracker selection of template + CLI inside each `to-X` Skill | Tracker handler |
| **Tracker resolution** | The act of identifying which Tracker to use, in one of three modes (Declared / Bootstrap-on-ask / No-repo CLI-only) | Tracker setup |
| **Declared (mode)** | Tracker-resolution mode used when CLAUDE.md already carries an `Issue tracker:` block — read the block, dispatch automatically, no prompts | Configured mode |
| **Bootstrap-on-ask** | Tracker-resolution mode used when a repo is present but lacks an `Issue tracker:` block — ask once inline, preview an appended `## Issue tracker` section, write only on confirmation, never overwrite | First-run prompt |
| **No-repo CLI-only mode** | Tracker-resolution mode used when no git repo is present — ask once, save as a `reference` memory keyed by tracker context, publish via tracker CLI without touching files | CLI-only |
| **ADO (Azure DevOps)** | Microsoft's work-item tracker, with typed work-item types and a field-rich state machine | TFS, VSTS (deprecated names) |
| **Jira Align** | A PI-level dependency/risk tracker that two-way syncs with ADO at the Feature level | — |
| **GitHub** | An issue-based tracker that uses labels rather than types for shape distinctions | gh, GH |
| **Two-way sync** | Bidirectional content propagation between trackers | Bidirectional sync |
| **`Hierarchy: required`** | The Tracker config (default for ADO) where every work item must have a parent | Strict hierarchy |
| **`Hierarchy: optional`** | The Tracker config (default for GitHub) where parent linking is opt-in | Loose hierarchy |
| **Sibling repo** | A repo declared adjacent to the current one in `CLAUDE.md`'s `## Sibling repos` section | Linked repo, Related repo |
| **PI workspace** | A directory dedicated to cross-team backlog construction, declaring Sibling repos but holding no code itself | Backlog repo, Planning workspace |
| **Label-precheck** | A GitHub-specific publish step ensuring every `Default labels:` value exists on the repo before `gh issue create` | Label sync |
| **Severity label** | A GitHub label representing a Bug's severity (e.g., `sev:critical`), declared per repo in CLAUDE.md's `Severity labels:` block; ADO uses the native `Microsoft.VSTS.Common.Severity` field instead | Severity tag, Sev label |
| **In-progress signal** | The CLAUDE.md `In-progress signal:` declaration telling `to-tasks --reconcile` how to distinguish open-and-being-worked from open-and-not-yet-started GitHub issues; defaults to assignee-presence when absent | WIP signal, Status signal |
| **Iteration** | The ADO sprint assignment for a work item (field `System.IterationPath`), declared per-repo via the CLAUDE.md `Iteration:` block | Sprint (acceptable casually; **Iteration** is the field name) |
| **Field reference name** | The stable, process-template-invariant ADO field identifier (`System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, `Microsoft.VSTS.Common.Severity`, `Microsoft.VSTS.TCM.ReproSteps`) that publishing skills target instead of the per-org display name (see ADR-0008) | Display name (rejected per ADR-0008) |
| **GLAPI gate** | The Greenlight API production deployment gate — blocks a prod deployment if any User Story linked via commits in the build lacks a passing test point in the team's PI test plan; automated by the `glapi-test-pass` skill | Greenlight gate (informal only), deploy gate |
| **Test Case** | An ADO work item of type `Test Case`, created by `glapi-test-pass` to satisfy the GLAPI gate; linked to the User Story via a `Tested By` relation. Terminal state: `Closed` | — |
| **Test point** | The ADO object linking a Test Case to a specific suite within a test plan; carries an `outcome` field (`unspecified` → `passed`). Captured as `TEST_POINT_ID` during gate automation | — |
| **Requirement test suite** | An ADO test suite of `suiteType: requirementTestSuite`, scoped to one User Story (`requirementId`); created under the PI test plan's root suite during gate automation | Story suite (informal) |
| **PI test plan** | The ADO test plan for the current Program Increment; name follows the pattern `<team>_Stories_<PI label>`. The GLAPI gate checks test points within this plan | Sprint test plan (wrong scope — PI spans multiple sprints) |

## Drift & consistency

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Naming drift** | Cross-sibling work-item name divergence (Story B uses `userId`, Story C uses `accountId`) | Inconsistency (too generic) |
| **Terminology drift** | `DOMAIN.md` vocabulary changes between sessions that leave Task text using retired terms | Vocabulary drift |
| **Scope drift** | Feature- or Story-scope shift over refinement cycles | Scope creep (different connotation) |
| **Stale reference** | A `Covers: ACx` line pointing to a Removed AC | Dangling reference |
| **Unsupported claim** | A `verify-docs` verdict — a doc claim that matches the current code but has no test backing it, so nothing protects it from future drift; surfaced as a missing test, not just a doc bug | Untested claim |
| **Cross-repo blocker** | A Task annotation marking dependence on a contract change in a Sibling repo (`Blocked by: ../<sibling-repo> — contract change required`) | Cross-repo dependency |
| **Naming-drift queue** | A durable list of pending sibling `--update`s, offered when a publish surfaces drift | Update queue, Pending list |

## Reconcile mechanics

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Stale Covers** | Reconcile bucket — a child Task whose `## Covers` references at least one Removed AC ID | Outdated Covers |
| **Unknown Covers** | Reconcile bucket — a child Task whose `## Covers` references an AC ID that does not exist on the parent | Bad Covers, Invalid Covers |
| **Healthy Task** | Reconcile bucket — a child Task whose `## Covers` refs all resolve to Active ACs | Healthy (when used alone — too generic) |
| **Uncovered AC** | A parent Active AC referenced by no child Task; reconcile proposes a new Task or a `## Covers` edit on an existing one | Orphan AC |
| **Mark, never delete** | Suite-wide discipline — closing or transitioning to Removed instead of deleting work-item records, so reconcile preserves an audit trail in the body | Soft-delete (overloaded — means tombstoning in DB land) |

## Relationships

- A **Skill** is a directory containing a `SKILL.md` plus optional **Reference files** under `references/`; **Repo-agnostic skills** in this repo are **Hoist**ed to `~/.claude/skills/`, **Convention skills** stay per-repo.
- Every **Skill** is exactly one of **User-invoked** or **Model-invoked** — the **Invocation** axis. A **User-invoked skill** may reach **Model-invoked skills** via **Prose invocation**, but never another **User-invoked skill** (its `description` is hidden, so nothing can reach it). An **Orchestrator skill** delegates to **Behavior skills**; the **Extraction test** (a real second consumer) decides when a discipline graduates from inline text to its own **Behavior skill**.
- A **Declared dependency** is a **Behavior skill** an **Orchestrator skill** requires; `scripts/install.sh` resolves it. **Format docs** (inert data — `domain-format.md`, `tracker-resolution.md`) stay **Sibling reference files** (ADR-0007); only **behaviors** become **Behavior skills**.
- Every **Prose invocation** is either a **Load-bearing delegation** or an **Opportunistic reference**. A **Load-bearing delegation** may appear **only in a User-invoked Orchestrator** — a human typed the command and watches the `Launching skill:` line, so a silent non-load is caught; it must never sit in a **Model-invoked skill**, where an auto-reached chain has no watcher. Consequently a **Model-invoked skill's Declared dependencies** must all be **Opportunistic references** (`diagnosing-bugs` borrows `codebase-design` vocabulary and offers `adr` at the end — it never delegates its substance). See ADR-0019.
- A reference whose **target is a User-invoked skill** (`implement` naming `review-changes`, a `to-*` skill naming `grill-me`) is **not a Prose invocation** but a *human suggestion* — the model cannot reach a User-invoked skill (its `description` is hidden, ADR-0015), so the text names what the human should type and never carries a **Load gate**. Built-in slash commands (`/code-review`, `/simplify`, `/security-review`) are always installed and likewise need no gate; the two-tier convention governs this repo's **Behavior skill** invocations.
- The `/skill-name` **slash form** and the **Load gate** are independent signals: the slash marks that a reference is actually *invoked* (a **Load-bearing delegation**, a **Model-invoked skill**'s own soft delegation like `tdd` → `/feedback-loops`, or a human suggestion the person types), while the gate marks that the load must be *verified*. **Vocabulary**, **boundary** mentions, and pre-consent **offers** stay plain-backtick; only a **Load-bearing delegation** in a **User-invoked Orchestrator** takes the gate.
- Two orthogonal axes govern a **Prose invocation**. The **Load-bearing vs Opportunistic** axis governs *load reliability* (does a silent non-load break the caller?). The **Background-lens-behavior vs Gated-action** axis governs *whether the host can delegate at all*: a **Background-lens behavior** runs concurrently inside the host loop and delegates freely (even as a **Load-bearing delegation**), while a **Gated action** transfers control and so must be **inlined** by a host loop that needs to protect its rhythm. `grill-and-record` shows both — it delegates `domain-modeling` (Background lens, Load-bearing) yet inlines the ADR write (a Gated action), declining `/adr` (ADR-0020).
- `implement` (Orchestrator skill) is the entry point `from-work-item` hands off to. It builds the **one Vertical slice** it is handed (the loaded **Task**, or a single-slice **User Story**): it picks a **Build path** (`tdd` for a Testable slice, direct otherwise), runs `/simplify` in the refactor step, then runs **Close the loop** once via `feedback-loops` (a Behavior skill). `tdd` invokes `feedback-loops` only as an end-of-cycle nudge (ADR-0010), so standalone use still finalizes; `implement` invokes it explicitly once. Judgment review is a separate step: `implement` *suggests* `review-changes` before the PR — it cannot invoke it, since both are User-invoked.
- A **User Story** belongs to exactly one **Feature** under `Hierarchy: required`; parent linking is optional under `Hierarchy: optional`.
- A **Task** belongs to exactly one **User Story** — never directly to a **Feature**.
- A **Feature** contains zero or more **User Stories** in its **Story map** (a **Snapshot** above the **Snapshot separator**, an **Append region** below).
- A **KTLO Feature** is a **Feature** that sits outside the to-X publishing path — drafted via `grill-me` against a versioned `docs/ktlo/<category>.md`, published manually, with no AC field and no **Story map**. Child **User Stories** parent to it via `to-story --parent <ktlo-feature-id>` and behave normally; the parent's missing ACs are structural (a **Task**'s `## Covers` references its parent **Story**'s ACs, not the **Feature**'s).
- A **Story map** carries a **Coverage matrix**, a **Naming table**, and **Dependency edges** between the child Stories.
- **Dependency edges** project onto ADO's built-in `Predecessor`/`Successor` relations, but only once both endpoint **User Stories** are published — `to-story` adds the relation when each edge's second endpoint lands. The relation graph is an additive, partial projection of the **Story map** (the source of truth), never an independent record (ADR-0023). A **Task**'s in-project blocker projects the same way; only the timing differs — `to-tasks` publishes in dependency order so its projection is always complete, while a **Cross-repo blocker** never projects (it names a **Sibling repo**, not an in-project work item).
- A **User Story** is classified as **user-facing** (body leads with a **Connextra user-story line**) or **non-user-facing** (body leads with a **`## User-facing behavior`** section).
- An **AC** belongs to exactly one **Feature**, **User Story**, or **Bug**, and is identified by a stable, append-only **AC ID**.
- A **Task** **Covers** one or more parent ACs (referenced by **AC ID**); a `Covers` reference to a **Removed AC** is a **Stale reference**.
- **Reconcile mode** buckets each child Task as **Healthy Task**, **Stale Covers**, or **Unknown Covers**, and each parent **Active AC** as covered or **Uncovered**.
- **Mark, never delete** governs every reconcile-driven removal — Tasks transition to Removed (ADO) or close with `--reason not_planned` (GitHub); the body record persists.
- A **Bug** can be parented to a **Feature**, a **User Story**, or be parentless — tracker-config dependent.
- A **Vertical slice** is the shape of exactly one **Task**; within it, the **Tracer bullet** is the first behavior built and the **RED → GREEN → REFACTOR** cycle operates per behavior. Build increments inside a slice are **behaviors**, never sub-slices.
- **Reconcile mode** operates on all **Tasks** under one **User Story**; **Update mode** operates on exactly one work item.
- **Tracker resolution** runs once per session in one of three modes — **Declared (mode)**, **Bootstrap-on-ask**, or **No-repo CLI-only mode**; **Tracker dispatch** then selects the per-Tracker template and CLI for the resolved Tracker.
- **Field reference names** are immutable across ADO process templates; display names are not — publishing skills target the former.
- A **Cold-start loader** (`from-work-item`) does not mutate any work item; it pulls a published work item back into the conversation — revisions go through the corresponding `--update` mode on the publishing Skill. The only file write is an appended `## Issue tracker` block to `CLAUDE.md` when the Bootstrap-on-ask flow runs.
- A **Sibling reference file** is enforced byte-identical by `scripts/lint-skills.sh`; ADR-0007 records why duplication exists (symlink-per-skill install) and the lint mechanizes the editorial discipline.
- A **Cross-repo blocker** annotates a **Task** whose Vertical slice cannot land until a **Sibling repo** ships a contract change.
- **Two-way sync** propagates content between **ADO** and **Jira Align** at the **Feature** level — markup that survives the round-trip cleanly is not guaranteed.
- A **Severity label** is GitHub-only; on ADO, severity rides the native field and the `Severity labels:` block is ignored.
- An **In-progress signal** is GitHub-only; on ADO, `--reconcile` reads `System.State` directly and the `In-progress signal:` line is ignored.
- A **Module** has exactly one **Interface** and one **Implementation**; **Depth** is measured at the Interface and corresponds to the **Leverage** callers receive.
- A **Port** is an **Interface** at a **Seam** with ≥2 **Adapters**; a single-Adapter Seam is just indirection, not a Port.
- A **Module-deepening refactor** typically merges or absorbs **Pass-through** Modules into a **Deep module**; the **Deletion test** decides which is which.
- An **ADR** belongs to exactly one repo's `docs/adr/` directory and is identified by a sequential number; the **Slug** is independent of the number.
- An **ADR** passes the **ADR gate** if and only if all three criteria hold; failing one drops the candidate.
- The **Sweep window** governs how far back `backfill-adrs` scans; **ADR debt** is the un-recorded surplus inside that window.
- A `DOMAIN.md` file lives at the root of a **Bounded context**; multi-context repos have nested `DOMAIN.md` files per context with the root acting as an index.
- `capturing-learnings` (Behavior skill) owns the **Solved-problems store**: the **Capture gate** admits a **Learning doc** (mirroring the **ADR gate**), the **Overlap rule** decides update-vs-create, and the **Retrieval protocol** is how any skill reads the store; `diagnosing-bugs` declares it — retrieval on the way in, a capture offer on the way out.
- A matched **Learning doc** informs an investigation, never overrides it — past learnings seed hypotheses, present evidence wins.
- `adoption-verdict` (Behavior skill) renders an **Adoption verdict** that must clear the **Two-floor gate**; its **Reversibility tier** sizes the workup and gates the **Adversary pass**. It consumes precedent before grading — `docs/adr/`, the **Solved-problems store** (via the **Retrieval protocol**), `DOMAIN.md` — and it is `grilling`'s complement: the grill extracts the user's decisions, the verdict is the agent's own defended position.
- A **Learning workspace** belongs to the **Learning root**, never to a work repo (see ADR-0026); `teach-me` (User-invoked Orchestrator) owns it, delegating **Mission** intake to `grilling` (Load-bearing delegation) and the **Topic glossary** to `domain-modeling` (Background-lens behavior, scoped to the workspace as its root), while writing **Learning records** inline — the same Gated-action inlining as `grill-and-record`'s ADR write.
- A Repo-grounded topic reads its repo's `DOMAIN.md` and ADR log as teaching material but never writes into the repo.
- A **Learning record** is admitted by `teach-me`'s own gate, not the **ADR gate**, and lives in the **Learning workspace**, never `docs/adr/`.

## Example dialogue

> **Dev:** "I just finished grilling Story 2 and noticed Story 1 used the wrong route name. Do I block the publish?"
>
> **Domain expert:** "No — that's **naming drift**, not a blocker. Publish Story 2 with the correct name. The skill warns and adds Story 1 to the **naming-drift queue** so you can re-grill its rename via `to-story --update` later. Both Stories are **user-facing**, right? They lead with a **Connextra user-story line**?"
>
> **Dev:** "Yes. What about Story 1's child Tasks? They reference `**AC2:**`, and Story 2's grilling reworded that AC."
>
> **Domain expert:** "If AC2 was removed entirely, it moves to `## Removed acceptance criteria` with strike-through. Reconcile will bucket those Tasks as **Stale Covers** — that's exactly what `to-tasks --reconcile` exists for. It diffs all Tasks under Story 1 against the current Story spec and proposes closures or rewrites, respecting work-item state. **Mark, never delete** — closed Tasks transition to Removed (ADO) or close with `--reason not_planned` (GitHub); the body record persists."
>
> **Dev:** "And one of those Tasks waits on a sibling repo's API change first."
>
> **Domain expert:** "That's a **cross-repo blocker** — annotate the Task with `Blocked by: ../<sibling-repo> — contract change required`. Reconcile won't close it; the Task waits until the sibling ships. The **Snapshot** above the **Snapshot separator** stays untouched — that record is rewritten only by `to-feature --update`."
>
> **Dev:** "Tomorrow I'm picking up that sibling work in a fresh session — what loads me back in?"
>
> **Domain expert:** "`from-work-item <task-id>`, the **Cold-start loader**. It reads the Task body, the parent Story's **Active ACs** (filtered by your `## Covers`), the parent Feature's Problem/Goals, the local `DOMAIN.md`, and ADRs matched against `## Layers touched`. ADO state comes from `System.State` directly; on GitHub the **In-progress signal** decides open-vs-being-worked. It's read-only — revisions still go through `to-tasks --update`."

## Flagged ambiguities

- **"Story"** is shorthand for **User Story**; both are accepted in conversation, but ADO's typed work item is **User Story**. Use the full form in template references, ADRs, and `SKILL.md` files; **Story** is fine in casual speech.
- **"User story"** appears in two distinct places: (1) the work-item type **User Story** (title case), (2) the bold prefix on a **Connextra user-story line** (`**User story:** As a [role], I want ...`). Typography disambiguates; in prose, prefer **User Story** for the work item and **Connextra user-story line** for the prefix.
- **"Slice"** alone is ambiguous — it can mean **Vertical slice** (the shape of one **Task**), **Layer** (a stratum), or "section of a document." Prefer **Vertical slice** for the Task shape and **Layer** for the stratum. A build increment *within* a slice is a **behavior** (the first is the **Tracer bullet**), never a "slice."
- **"Drift"** must always be qualified — **naming drift**, **terminology drift**, or **scope drift**. The unqualified word is too vague.
- **"Update"** is the canonical verb for the `--update` Skill mode. **Patch**, **edit**, and **revise** were considered and rejected (see ADR-0003).
- **"Iteration"** and **"Sprint"** are used interchangeably in casual speech, but **Iteration** is the formal ADO field name (`System.IterationPath`). Prefer **Iteration** in tracker-config contexts.
- **"Hierarchy"** is overloaded: the work-item parent-child structure (Epic → Feature → User Story → Task) versus the `CLAUDE.md` `Hierarchy: required` configuration flag. Context usually disambiguates; in `SKILL.md` text, the config-flag usage dominates.
- **"Issue"** is the GitHub-flavored synonym for **work item**. Use **work item** in tracker-neutral contexts; **issue** when GitHub-specific.
- **"Reconcile"** vs **"Sync"** — **Reconcile** is the Skill verb for diffing Tasks against a current Story; **Sync** refers exclusively to **Two-way sync** between trackers (Jira Align ↔ ADO). Don't use Sync for the Skill operation.
- **"Tracker"** vs **"Tracker dispatch"** vs **"Tracker resolution"** — **Tracker** is the system itself (ADO / GitHub); **Tracker dispatch** is the in-Skill mechanism that picks templates and CLI for that system; **Tracker resolution** is the act of identifying which Tracker to use (one of three modes — **Declared (mode)**, **Bootstrap-on-ask**, **No-repo CLI-only mode**).
- **"Healthy"** alone is too generic — prefer **Healthy Task** in reconcile contexts to make the bucket sense unambiguous.
- **"Reference name"** vs **"Reference file"** — **Field reference name** is the immutable ADO field identifier (`System.Description`, ...); **Reference file** is a doc under a Skill's `references/`. **Sibling reference file** is the lint-enforced subclass (ADR-0007). Don't conflate.
- **"Module"** is severely overloaded: in **Architecture & deepening** it carries the Ousterhout sense (anything with an Interface and Implementation); in Python/JS it's a file or package; in some org charts it's a team's area. When ambiguity is possible, qualify the sense — "Ousterhout Module" or "Python module".
- **"Boundary"** vs **"Seam"** — `improve-design` (and `codebase-design`) deliberately avoids **Boundary** for the Seam concept because **Boundary** is reserved for DDD's **Bounded context**. Use **Seam** for the deepening sense, **Bounded context** for the DDD sense, never **Boundary**.
- **"Interface"** is the broader Ousterhout-sense term in this repo (everything a caller must know — types, invariants, error modes, ordering, config); **Port** is the narrower term reserved for Interfaces at Seams that warrant ≥2 Adapters. Don't substitute "API" — that's HTTP-flavored and loses the invariant/error-mode/ordering nuance.
- **"Skill"** vs **"Convention skill"** vs **"Plugin"** — **Skill** is the unit (a directory with `SKILL.md`); **Convention skill** is a category (project-local, encoding stack conventions); **Plugin** is Claude Code's distribution unit (a different concept — don't conflate).
- **"Sweep"** appears as a verb (the act of scanning), a noun (**Sweep window**), and a mode (**Sweep mode**). In Skill descriptions, **Sweep mode** is the canonical noun for the deliberate-pass behavior of `harden-domain` and `backfill-adrs`.
- **"Description"** is overloaded: in Skill **Frontmatter** it's the ≤1024-char field used for Skill loading; in ADO it's the rich-text body field on a work item; in GitHub it's the body of an issue. Context usually disambiguates.
- **"Decision map"** vs **"Decision ticket"** — distinct artifacts that can coexist in one charting session: the **map** is `grilling`'s options sketch for a can't-evaluate deferral; the **ticket** is a Chart child holding one question. Don't shorten either to a bare "decision"; a plain decision tree is neither.
- **"Skill"** vs **"Practice"** — `teach-me`'s pedagogy triad deliberately renames Matt Pocock's knowledge/*skills*/wisdom middle leg to **Practice**: a `SKILL.md` that used "skill" for learner abilities while *being* a **Skill** would collide constantly. Use **Practice** for the pedagogy leg, **Skill** only for the unit.
- **"Cheat sheet"** vs **"Reference file"** vs **"Learning doc"** — a **Cheat sheet** is a learner-facing doc in a **Learning workspace**'s `cheatsheets/`; a **Reference file** is a doc under a Skill's `references/`; a **Learning doc** is a solved-problem record in a repo's `docs/solutions/`. Three different artifacts — don't conflate.
- **"Learning doc"** vs **"Learning record"** — near-identical names, deliberately unrelated formats: a **Learning record** is the **ADR**'s format-sibling (numbered, dated, cited by number); a **Learning doc** is a grep-retrieved lookup entry, never cited by name or number. Don't expect "Learning X" artifacts to share a format — qualify which one is meant.
- **"`DOMAIN.md`"** now names two artifacts: the repo-root glossary and a **Learning workspace**'s **Topic glossary** (same format, different home). Qualify as **Topic glossary** when the teaching sense is meant.
