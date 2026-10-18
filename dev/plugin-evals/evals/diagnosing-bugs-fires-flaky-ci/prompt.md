---
description: diagnosing-bugs — should fire
tags: [diagnosing-bugs, fire]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

Our checkout integration test passes locally but times out on CI about one run in five. Nothing in the test changed recently. Help me figure out why.
