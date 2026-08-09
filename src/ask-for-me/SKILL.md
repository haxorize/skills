---
name: ask-for-me
description: Turn a decision you can't answer alone into a Markdown questionnaire for the person who can — a brief interview about the send (who it goes to, what you need back), then a drafted document that pulls out what they know and you don't.
disable-model-invocation: true
requires: writing-for-humans
---

# Ask For Me

Turn something the user can't answer alone into a **discovery questionnaire** — a Markdown document they hand to one person to fill in async, or fill out together in a meeting. The recipient holds knowledge the user lacks; the questionnaire pulls it out of them.

**Grill the send, not the subject.** Interview the user only about the *send*, which they can always answer — never about the subject, which by definition they can't. The questions in the document then target the **gap** between what the recipient knows and what the user needs.

## Workflow

1. **Who is it going to?** Ask, in one exchange, the recipient's role, expertise, and relationship to the user. This fixes the questionnaire's tone and how much context it must carry. Done when you know who the recipient is and what they know that the user doesn't.

2. **What do you need back?** Ask, in one exchange, the specific decisions or facts the user can't resolve alone and needs from this person. Done when you have a concrete list of what the user must walk away able to do or decide.

3. **Write the questionnaire.** Draft questions aimed at the gap from steps 1–2, following [references/questionnaire-template.md](references/questionnaire-template.md); the document is human-facing prose, drafted per the `/writing-for-humans` behavior. Write it to `questionnaire-<slug>.md` in the current directory (slug from the topic). Done when the file exists and every item the user named in step 2 is covered by a question.

## Pairing with chart-course

When a `chart-course` decision ticket is blocked on knowledge someone outside the effort holds, an **Errand** ticket can resolve through this skill: the questionnaire is the checklist handed to the human, and the filled-in answers become the Errand's resolution, linked as an asset.

When a filled-in questionnaire comes back, check every question got an answer before treating the send as resolved — follow up on just the missed ones, never silently default them.
