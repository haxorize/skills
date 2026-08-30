#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-history
cat ~/.bash_history
# ruleid: sh-history
cat ~/.zsh_history
# ruleid: sh-history
cat ~/.claude/history.jsonl
# ruleid: sh-history
cat ~/.claude.json
