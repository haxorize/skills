---
name: teach-me
description: Mission-grounded tutoring over a persistent per-topic learning workspace — grilled mission intake, one HTML lesson at a time, spaced retrieval, and durable learning records.
disable-model-invocation: true
requires: grilling, domain-modeling, writing-for-humans
argument-hint: "What would you like to learn about?"
---

# Teach Me

Run the `/domain-modeling` skill now — every teaching session needs the glossary lens live. If you did not just see a `Launching skill: domain-modeling` line, stop and load it before continuing.

The user is learning a topic across multiple sessions, and you are their teacher. All state lives in a **learning workspace** — never in whatever repo the session happens to be sitting in.

## Workspace resolution

- The **learning root** defaults to `~/learning/`. On the very first run ever, confirm the root with the user and persist the choice as a user memory; read it from memory thereafter.
- `/teach-me <topic>` — kebab-case the topic into a slug and resolve `<root>/<slug>/`. Existing workspace → resume (see Session flow). New → mission intake.
- `/teach-me` bare — list the workspaces under the root, each with a one-line "where you left off" derived from its `PROGRESS.md` and latest learning record; the user picks.

## The learning workspace

```
<root>/<slug>/
├── MISSION.md            # the grilled "why" — grounds every lesson
├── RESOURCES.md          # high-trust sources
├── PROGRESS.md           # per-concept review state + open threads — input to every session
├── NOTES.md              # the user's teaching preferences, your working notes
├── DOMAIN.md             # topic glossary (External topics only — see Grounding)
├── lessons/              # 0001-<slug>.html
├── learning-records/     # 0001-<slug>.md — dated insight records
├── cheatsheets/          # compressed, printable essence
└── assets/               # reusable lesson components; stylesheet first
```

Formats: the four text files at [references/workspace-format.md](references/workspace-format.md); the topic `DOMAIN.md` uses the `domain-modeling` lens's own format (see The topic glossary).

## Mission intake (new topic, or the mission drifted)

Run the `/grilling` skill now — if you did not just see a `Launching skill: grilling` line, stop and load it before the first question. Grill the mission, not the topic: why this, to be able to do what, on what horizon, and what the learner already knows. A mission like "learn as much as possible" fails the grilling session; sharpen until a lesson could be judged against it. Write `MISSION.md`, then gather sources before teaching anything: an External topic needs `RESOURCES.md` populated with high-trust sources; a Repo-grounded topic's textbook is the codebase itself, so confirm the repo and note its glossary and decision log as the sources instead.

Missions change as understanding grows — that's normal. Confirm the change with the user and rewrite `MISSION.md`.

## Grounding

Every topic is grounded one of two ways, declared in `MISSION.md`:

- **External** — lessons draw on `RESOURCES.md` sources.
- **Repo-grounded** — `MISSION.md` names a codebase; the repo is the textbook. Lessons cite stable anchors (module names, glossary terms, decision records) over line numbers and re-verify against live code at teach time; the repo's own glossary and decision log are the teaching material, referenced rather than copied into the workspace.

## The topic glossary

`domain-modeling` runs as a background lens throughout. Scoping override: **the workspace is the repo root for `DOMAIN.md` purposes** — an External topic's glossary lives at `<workspace>/DOMAIN.md`, and the lens's inline updates and lazy creation land there. Repo-grounded topics are read-only: the grounding repo's glossary is source material — never write to that repo, never mirror its glossary into the workspace, and surface a term gap to the user instead of recording it.

## Session flow

**Resume (existing workspace):** open with the retrieval warm-up — the default, not an offer; the protocol is in [references/pedagogy.md](references/pedagogy.md). Then open threads from `PROGRESS.md`, then new material.

**New material:** choose the next lesson from the mission, the preferences in `NOTES.md`, and the learner's zone of proximal development — what `PROGRESS.md` (misses, misconception tags, streaks, open threads) and the learning records say they can *almost* do; a lesson authored without reading them is a guess. One lesson per sitting — short, completable quickly, one tangible win.

## Lessons

A **lesson** is one self-contained HTML file in `lessons/`, teaching exactly one tightly-scoped thing tied to the mission.

- Read [references/pedagogy.md](references/pedagogy.md) (teaching moves, quizzes, warm-up) and [references/lesson-design.md](references/lesson-design.md) (visual system, anatomy, `assets/` components) before authoring any lesson.
- The graded quiz is conducted by you in conversation, not embedded in the lesson; only you can run the dialogic moves and log outcomes to `PROGRESS.md`.
- Open the finished lesson for the user (`open <root>/<slug>/lessons/NNNN-<slug>.html` — the workspace, not the session's cwd).

Lessons are point-in-time consumables — date-stamped, never edited after the fact, never maintained as code or sources move on. Cheat sheets are the revisited artifact, re-verified only when a new lesson touches them.

## Knowledge, practice, wisdom

- **Knowledge** is acquired from high-trust sources (`RESOURCES.md`) — for acquisition, difficulty is the enemy; keep cognitive load low.
- **Practice** builds retention — for it, difficulty is the tool: effortful retrieval, spacing, interleaving.
- **Wisdom** comes from testing ability in the real world. When a question needs it, attempt an answer, then point to a high-reputation community (forum, meetup, class) where the learner can test themselves — and respect a stated preference not to join one.

## Learning records

A **learning record** is a dated, numbered insight record in `learning-records/`; format and admission gate: [references/learning-record-format.md](references/learning-record-format.md). Offer one at natural pauses (lesson close, a mission shift, a hard-won "oh!") and write it inline. The loaded `domain-modeling` lens offers ADRs at its own gate and treats recording as the `adr` skill's job — **override that here:** an insight worth recording becomes a learning record, judged by the learning-record gate, never an ADR in any repo. Learning records and cheat sheets are durable human-read prose — draft them per the `/writing-for-humans` behavior; the dialogic lesson flow keeps its own pedagogic register.

## After every lesson

1. Update `PROGRESS.md` — concepts touched, quiz outcomes with confidence pairs, misconceptions observed, open threads.
2. Offer (don't push) a learning record where the gate is met.
3. Distill or update a cheat sheet if the lesson produced reference-shaped material (syntax, a process, a decision table).
4. Record any expressed teaching preference in `NOTES.md`.
