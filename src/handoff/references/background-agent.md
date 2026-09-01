# Handing off to a background agent

Open this only when the user asks for the work to continue unattended rather than be picked up in a fresh interactive session.

Don't save a doc — launch a background agent seeded with the handoff as its prompt:

```sh
claude --bg --name "<descriptive name>" "<handoff content>"
```

`--name` labels the agent in the job list and session picker. The agent starts in the current working directory; the user manages it with `claude agents` — hand them that exact command (or the specific attach/tail command) right after launching, and repeat it in your final message.

Seed the prompt with explicit boundaries: don't push, merge, close work items, or post to external services unless the handoff says to. An unattended agent inherits none of the conversation's implicit ones — the rules in [subagent-brief.md](subagent-brief.md) go in quoted — the three its header names for an agent with no caller. A short load-bearing rule from a canonical doc is carried as the doc's line **verbatim** — a paraphrased brief drifts — while anything longer stays a pointer to the doc.

Seed three disciplines for the unattended stretch:

- **The completion audit.** Before declaring the objective done, run the completion audit: treat done as unproven, derive the requirements from the objective, name the authoritative evidence per requirement, and inspect it at matching scope — a narrow check never supports a broad claim, and a green test or clean search counts only after confirming it covers the requirement. The audit proves completion rather than failing to find remaining work. Its form is [completion-audit.md](completion-audit.md), the same file `implement` writes at close.
- **The blocked threshold.** "Blocked" is earned only when the same blocking condition has survived three consecutive attempts to move it — never merely because the work is hard, slow, uncertain, or would benefit from clarification. Once earned, declare it and stop; grinding past a real block is the mirror failure.
- **No quiet narrowing.** An edit is aligned only if it makes the requested final state more true — never swap in a goal that trips the quiet-narrowing tripwire (`DOMAIN.md`) because it is more likely to pass.
