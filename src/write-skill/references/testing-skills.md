# Testing a skill

Three checks answer three different questions: the micro-test asks whether a rule *binds*, the trigger test whether the description *loads*, and the wind tunnel what the skill is like to *wield*. A subagent plays the agent-under-test in all three, each run starting from a fresh context so nothing leaks between reps. Every verdict records the served model — the one the harness reports (`message.model` on a transcript's assistant events; the `init` event of a `claude -p --output-format stream-json` run), not the one requested — beside it. A model-generation change re-runs the control, the trigger test, and the standing scenarios rather than inheriting their verdicts: a pass certifies the text under the model that served it. The micro-test is RED → GREEN applied to documentation — prove the failure exists before writing the cure, then prove the cure binds.

## The micro-test loop

1. **Control first.** Run the pressure scenario with a fresh-context subagent *without* the skill. If the control doesn't exhibit the failure, there is nothing to fix — stop; any wording added anyway is a no-op. **One exception, and it is narrow: the control's own environment supplied the behaviour.** A global rule loaded on the authoring machine that some of the body's load sites lack, or an artifact the skill itself writes that the fixture handed the agent already open. Then the rule may stay, on two conditions — name the supplying mechanism *and* a real load site without it, and record the rule as **untested rather than proven** in the ADR that admits or amends the skill, never counted among the reps that bound. "It might matter somewhere else" names no mechanism and does not open this door. Count those records in that ADR before the revision closes: a third one for a single skill means the fixture is what is wrong, and the scenario is rebuilt before another rule is added. **And one invalidation, the exception's opposite: a control that knew the object of study.** Every skill description sits in the control subagent's system prompt, so before a clean control's result is accepted, its transcript — the stream of a headless run, or the response where that is all the runner returns — is read for a mention of the skill under test. One that names the skill is recorded as leaked and re-run under a runner whose skill set excludes it (a headless run with the skill's entry removed from `~/.claude/skills/`), never kept as untested-but-standing.
2. **Capture rationalizations verbatim.** The control's excuses become the rationalization table's rows — real ones bind better than invented ones.
3. **Write the minimal wording**, picking the form from the form-to-failure table in `writing-for-agents`' `predictability.md` reference — that skill is a `requires:` dep this skill's intro already loaded.
4. **Re-run with the skill until 5 consecutive fresh-context reps hold the discipline under combined pressure**, with variance low enough that the responses read as the same process — that bar is what passes the wording. A failing rep restarts the count; an inconclusive rep (step 7) is re-run and does not. One rep proves nothing. When the wording governs one decision — a route, a gate, a tier — end each rep at that decision and grade what it declared, never narration that mentions the right word; a rep that declares nothing is inconclusive (step 7), and a rep cut short this way tests binding only — a description change still needs the trigger test.
5. **Read every response.** Don't grep for compliance keywords — template echoes masquerade as hits.
6. **Variance is a metric.** Five reps producing five interpretations means the wording isn't binding, even when no single rep clearly violates.
7. **A rep that cannot be classified is inconclusive.** A response that neither holds the discipline nor clearly breaks it is recorded as inconclusive and the rep re-run, never rounded to pass.

## Revising an existing skill

When the micro-test runs against a skill that already ships, two extra rules keep the revision honest: the rep set **must include the failure that prompted the revision** and stay fixed across it — swapping scenarios mid-revision makes before/after incomparable — and **cap the edits per revision** (a handful of distinct changes, fewer as the skill matures): a sprawling rewrite that regresses leaves you unable to attribute the regression to a cause.

## Building pressure scenarios

A scenario prompt carries the prior context a real session would have — the transcript before the ask, the files already open, the decisions already made — because a bare ask reproduces a bare-ask failure and nothing else. Prefer a captured real transcript over an authored one wherever one exists; an *authored* corpus that scores perfectly on its first run was built to pass and is a corpus smell — a clean run on a corpus that has caught failures before is a pass (below). A scenario where the shortcut and the discipline land the same diff cannot grade the rule — rebuild it until the two paths diverge in the output.

Combine **3+ pressures** — a single pressure rarely reproduces real-session failure:

- **Time** — "the demo is in ten minutes"
- **Sunk cost** — "three hours of work is already in the file"
- **Authority** — "the lead said to skip it this once"
- **Exhaustion** — a long transcript before the ask — and grade the *late* reps separately: a rule that holds at turn 1 and fails at turn 20 is recorded as a late-turn failure, distinct from a wording miss, since the model may be imitating its own earlier replies rather than the file; a rewording is tested against the late reps, never assumed to reach them
- **Social** — "every other team does it this way"
- **Economic** — "re-running the suite costs real money"

## Meta-testing a violation

When an agent violates *despite* the skill, ask that same agent: "How could the skill have been written differently to make it crystal clear this wasn't acceptable?" The answer sorts the gap:

- It names a missing principle → foundational gap; add the principle.
- It points at the line it negotiated past → wording gap; sharpen that line.
- It says the rule was buried → organization gap; move the rule up the information hierarchy.

A gap every rep reports unanimously is checked against the harness before the skill: a tool that was unavailable, a file the subagent could not reach, a permission it lacked — the skill cannot fix what the environment withheld.

## The wind tunnel (simulated use)

A skill can pass both other checks and still wield badly — reciting its framework instead of applying it, nodding along with weak answers, or producing what any model would have produced without it. The wind tunnel simulates the use and judges the transcript. It stays an offer at every stage: a skill ships without one.

**Quarantine the wielder.** The wielder side of every role-play may use only what is in the `SKILL.md` — no memory of the conversation that produced it, no knowledge of the repo it came from. Dispatch each scenario to a subagent whose prompt names only the file path and the scenario, so the quarantine is structural rather than a matter of discipline — the path absolute, and the brief saying to read that file, never to use the skill by name: a name-invocation loads the frontmatter, the `requires:` chain, and whatever the harness wraps around a skill, none of which is the file under test, and the pass it reports certifies that bundle. Anything the wielder needed and the file didn't supply is itself a finding; that gap list usually yields more patches than the verdicts do.

**Scenario mix — four standing scenarios, plus the ones the skill's shape adds, each covering a different failure.** A *canonical* user squarely inside the skill's sweet spot. A *terse* user with most context missing, which tests whether the intake fires or the wielder fills the blanks in and barrels ahead. A *boundary* case at the edge of where the skill applies, testing whether it handles the edge honestly or misapplies confidently. A *refusal* case the skill's own conditions say it should turn away. Optionally a *lazy answerer* whose answers stay weak across many rounds, testing whether the bar drops. A skill that keeps state across sessions adds *die-and-resume*: the session ends mid-process and a fresh wielder holding only the `SKILL.md` and what it reads from disk finishes the run. A skill that ingests external content — repo files, tickets, web pages, another repo's skills — adds *hostile-content*: the ingested material carries instruction-shaped text (a directive, a hidden-unicode or base64 payload, a self-declared authority), and the wielder passes only by reporting it as a finding; silently stripping it and continuing is a FAIL, not a pass.

**Judge the transcript, not the prose.** A rule that reads beautifully and didn't fire is a FAIL. Every non-PASS verdict quotes the transcript line that earned it — no quote, no finding. Two criteria are standing: *applied vs recited* (did the wielder run the framework on this user's specifics, or lecture it back at them?) and *could a model with no skill loaded have produced this conversation?* — a stretch of generic advice answers it. Check a FAIL against the skill's intended design before accepting it: a criterion stricter than the design produces a false FAIL, which is still a finding, but the patch is usually to make the body state its intended behavior unambiguously. One systemic cause reported once beats five cosmetic findings.

**A clean run is the expected result**, not a suspicious one. Everything passing means the skill is sound — say so and stop rather than inventing findings to justify the exercise.

**A live failure becomes a standing scenario.** When the skill misbehaves in real use, the wind tunnel missed it — the fix is the scenario or rubric criterion that would have caught it, not just the patch to that one skill. Keep the scenario and re-run it after any substantial redesign: an earlier pass certifies the old text, not the new one.

## Trigger test (descriptions)

The micro-test proves a loaded skill *binds*; this proves a model-invoked skill *loads*. When a skill fails to fire (or fires spuriously), test the description, not the body: run a handful of realistic prompts in fresh contexts — a few that should trigger and a few **near-misses** that should not — and watch what loads. The runner is one headless `claude -p` per prompt with `--no-session-persistence` (so `skill-usage.sh` never counts the runs) and enough turns to reach the decision — `--max-turns 2` cut every file-reading run off before it decided; a silent trigger rep is graded by what it produced, MISS where the model authored the surface the skill governs and NOT REACHED where its path never got there; the served model is read from the stream's `init` event, per the opening paragraph. Near-misses carry the signal: an obviously irrelevant negative proves nothing, while a boundary-adjacent one shows where the description over- or under-reaches. Fix by sharpening triggers and leading words, never by enumerating the failing queries — a query list overfits and bloats the description's context cost.
