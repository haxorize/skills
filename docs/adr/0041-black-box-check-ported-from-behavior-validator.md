# `validate-behavior` (first `black-box-check`) ported from openclaw's behavior-validator, and run by a fresh helper at `implement`'s close

Nothing in the suite validated the *running* artifact. `audit-tests` audits the test suite, `review-changes` judges the diff, and `feedback-loops` runs checks that already exist, so a UI that only prints success text could pass every gate. openclaw/agent-skills' behavior-validator fills that gap with a discipline that only holds as a whole skill: validation against a behavior contract written *before* testing, source-blindness as a hard rule (implementation-looking evidence is contamination that halts the run), and anti-cheat probes that catch fake or static behavior.

## Decision

We ported it in the 2026-08-08 mining round as a user-invoked skill, trimming the JSON report schema and the workspace-isolation ritual to house prose-report style. It was first named `black-box-check`; [ADR-0057](0057-rename-table-and-discipline-skill-term.md)'s rename table made it `validate-behavior`, since that record renamed the skill kind "behavior" once named, leaving the product sense as the word's only meaning in a skill name.

**It is kept on the Team-fit test** ([ADR-0063](0063-team-fit-test-replaces-retire-on-zero-window.md)): its moment is an engineer proving a change works in the running app rather than in tests. A Skill carries no **Retire-or-extend rule**, because its population includes teammates whose sessions nobody measures, so no usage count on either machine is a verdict on it.

**The user-invoked axis is load-bearing for the discipline.** Source-blindness requires a checker that shares none of the writing session's context. Model invocation loads the skill into that very session, so an auto-reached run is contaminated by construction and is not this check at all. No skill loads it into its own session, and no skill declares it as a dependency.

**It runs at the close of every qualifying work item, from a fresh helper.** When a work item finishes, the repo's `## Commands` carries a `Run:` line, and at least one acceptance criterion is observable in the running product, `implement` dispatches one fresh helper: a new agent, never a fork, since a fork inherits the writing session's whole context. The brief holds only the ticket's criteria verbatim, the `Run:` line, and the path to `validate-behavior/SKILL.md`, and nothing the writing session learned from the source. The helper starts the app, uses it, and reports pass, fail, or could not check per criterion; each verdict becomes the completion audit's evidence for that criterion. The writing session still may not load the skill. A helper given only the ticket shares none of its context, so it may run it. `tdd`'s closing offer for untested behavior is a pointer to that step. Nick chose this on 2026-10-12 (the 2026-10-12 round's grill, Q8, with Q35 placing both fresh checks at `/implement`'s close for every work item).

Reachability was the open problem, and placement is its answer, not a flip of the axis. Typed by hand, the skill ran 0 times across two usage windows on this machine, even after `tdd` named the moment as a branch with its cost stated; a prose offer does not get it run. The one real run worked: a fresh session typed `/validate-behavior` in `a11y-health-ui` against story #70 on 2026-09-04, from cold servers and the `Run:` line `onboard-repo` writes. Bring-up took 1 turn, the run 5 turns in all, and the verdict was FAIL, as the story expected.

**The precondition cost is settled at that run's price.** The shared-instance rule (establish whether two instances can coexist and whose the running one is, with `lsof`, `ps`, and a connection probe before the first probe) and the stable-handles rule both add work before the first user task. On the measured run the whole precondition phase cost one turn, and the port-ownership check cost no turn of its own. A proposed Doctor-style check before the first user task (`U6`, [ADR-0075](0075-transcript-sourced-mining-round.md)'s round) was rejected on the same run: a step added to a one-turn precondition is ceremony.

## Considered Options

- **Fold only the anti-cheat probes into `audit-tests`** — rejected. The probes are trustworthy only *because* the contract predates the run and the checker cannot read the code's story about itself; split from that identity they are decoration, not discipline.
- **Make the skill model-invoked so another skill can load it** — rejected. It answers a reachability problem with a change that destroys the check, since the load lands in the session that wrote the code.
- **Leave it typed by hand, offered by `tdd`** — rejected on 0 typed runs in two usage windows with the offer in place, and 1 in all by 2026-09-04.
- **Retire it** — rejected. It is the suite's only check of the running product, and no other skill covers its job.

## Consequences

- One helper per qualifying work item. Its token cost is unmeasured; the measured run took 5 turns.
- The check is only as blind as its brief. A brief that leaks how the code works, a file path, a function name, the session's own account of the change, makes it no longer source-blind, so the brief carries the ticket's criteria, the `Run:` line, and the skill path, and nothing else.
- A repo with no `Run:` line, or a work item with no criterion observable in the running product, gets no helper; the skill stays available by hand.
- Teammates on the work machine get the same step at their close, at a cost nobody has measured there.

Revisit when: the fresh helper's runs stop finding what the browser suites miss over a stretch of qualifying work items, which would make its per-item cost the thing to cut; or a brief is found to have leaked source detail to the helper, which reopens how the brief is built.
