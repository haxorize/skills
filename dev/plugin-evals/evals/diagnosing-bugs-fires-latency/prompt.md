---
description: diagnosing-bugs — should fire
tags: [diagnosing-bugs, fire]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

p95 latency on our /search endpoint doubled after yesterday's deploy and nothing in the diff looks related. Where do I start?
