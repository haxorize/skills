---
description: codebase-design — should fire
tags: [codebase-design, fire]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

I'm adding an LLM call that classifies incoming support tickets by urgency. Where should it sit in our backend so the rest of the code doesn't care that it's a model?
