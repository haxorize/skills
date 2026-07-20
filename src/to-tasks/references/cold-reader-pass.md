# The Cold-reader pass

Self-review can't catch author blindness — after drafting, you see what you meant, not what you wrote. Before presenting the draft, send it through a reader with no such blindness:

- Spawn **one fresh-context subagent** — the cold reader. It gets only the input the calling skill names (what a cold reader of the published artifact would see), never this conversation.
- It answers the calling skill's question, naming ambiguities and context it had to assume.
- Fold real gaps back into the draft. One pass, not a loop.
