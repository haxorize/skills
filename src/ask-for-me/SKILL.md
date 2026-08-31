---
name: ask-for-me
description: Turn a decision you can't answer alone into a Markdown questionnaire for the person who can — a brief interview about the send (who it goes to, what you need back, what silence decides), then a drafted document that pulls out what they know and you don't. Invoke it again with the filled-in answers to check nothing was missed.
disable-model-invocation: true
requires: writing-for-humans
---

# Ask For Me

Turn something the user can't answer alone into a **discovery questionnaire** — a Markdown document they hand to one person to fill in async, or fill out together in a meeting. The recipient holds knowledge the user lacks; the questionnaire pulls it out of them.

**Grill the send, not the subject.** Interview the user only about the *send*, which they can always answer — never about the subject, which by definition they can't. The questions in the document then target the **gap** between what the recipient knows and what the user needs.

## Workflow

1. **Who is it going to?** Ask, in one exchange, the recipient's role, expertise, and relationship to the user. This fixes the questionnaire's tone and how much context it must carry. Also ask what happens if nothing comes back: doing nothing needs no meeting and no approval, so it is the outcome most likely to occur, and the questionnaire's *How to answer* section names the date by which an unanswered send becomes the decision, and which decision that is. Done when you know who the recipient is, what they know that the user doesn't, and what silence decides.

2. **What do you need back?** Ask, in one exchange, the specific decisions or facts the user can't resolve alone and needs from this person. Done when you have a concrete list of what the user must walk away able to do or decide.

3. **Write the questionnaire.** Draft questions aimed at the gap from steps 1–2, following [references/questionnaire-template.md](references/questionnaire-template.md); the document is human-facing prose — call the Skill tool with `writing-for-humans` at the first draft if it isn't already live — and it ends on the dash sweep the global rule `~/.claude/rules/outbound-dash-sweep.md` prescribes. Write it to `questionnaire-<slug>.md` in the current directory (slug from the topic). Done when the file exists and every item the user named in step 2 is covered by a question.

4. **Check the returns.** When the user brings the filled-in questionnaire back, check every question got an answer before treating the send as resolved — follow up on just the missed ones, never silently default them — the default step 1 recorded fires only when nothing came back at all. Done when every question has an answer or a named follow-up.

## Pairing with chart-course

When a `chart-course` decision ticket is blocked on knowledge someone outside the effort holds, an **Errand** ticket can resolve through this skill: the questionnaire is the checklist handed to the human, and the filled-in answers become the Errand's resolution, linked as an asset.

## Pairing with offboard-engineer

When an `offboard-engineer` capture ends with register items the departing engineer will answer in writing, those items and their offered readings arrive pasted in as the subject — raw material, not an input format. Run the interview as ever: step 1 usually collapses to a confirmation (the recipient is the departing engineer, and the register already says what silence leaves unrecoverable), and the pasted items become step 2's list of what must come back. The filled-in returns go to that skill's register through its `start`, not through step 4 here.
