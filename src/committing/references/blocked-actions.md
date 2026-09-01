# The blocked-action protocol

Opened only when a commit, push, or tracker write fails for an environmental reason (auth, sandbox, policy, network), or a `commit-msg` hook rejects the message. Sandboxes, credential policies, and permission classifiers block outward actions routinely; this is the protocol for that failure path.

1. **Stop that step.** Do not retry variants, switch protocols, or find another way through. A blocked action is a decision the environment already made, not an error to route around.
2. **Record it as a claim:** "blocked by X" carries the verbatim error, per the claims rule.
3. **Continue with what isn't blocked.**
4. **A blocked tracker write lands as a file**, frontmatter carrying the create fields, and the manual-commands block carries the one command that consumes it (`--body-file` / `--description @<file>`) — the shape the publishers' `publishing.md` sibling gives under `## When the write is blocked`; for a close or a comment, the frontmatter carries the item ID and the command is the update call.
5. **End with one manual-commands block.** Every command the human must run by hand, copy-pasteable, with its directory, gathered at the end of the report, never scattered through it. Not a description of what to do; the command.

**A rejected commit message is not a blocked action.** A `commit-msg` hook rejecting your message is the one exception to rule 1: nothing in the environment refused you, and the thing at fault is a message you wrote and can rewrite. Read the rule the rejection names, fix the message, and commit again — reporting "blocked by commit-msg" and stopping leaves the change staged and unlanded for the user to finish by hand. Rewriting the *message* is the whole remedy; `--no-verify` and unsetting `core.hooksPath` are not, and `commit-bypass` refuses the first.

**When you believe the check itself is wrong**, that is a finding, not an obstacle to route around: say which rule fired, on which line, and why the message is right — then stop and let the user decide. Do not disable the hook to get past it, and do not damage a correct message to satisfy an incorrect rule.

Report what actually happened: what landed, what's staged, what's waiting on a manual step. A change that is committed but unpushed gets described that way, never as shipped.
