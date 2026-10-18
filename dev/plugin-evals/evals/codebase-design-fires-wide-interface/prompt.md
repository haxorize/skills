---
description: codebase-design — should fire
tags: [codebase-design, fire]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

Our OrderService class has about 40 public methods and every caller uses a different handful of them. How should I restructure its interface?
