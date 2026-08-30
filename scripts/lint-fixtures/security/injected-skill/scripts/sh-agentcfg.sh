#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-agentcfg
cat ~/.claude/settings.json
# ruleid: sh-agentcfg
ls $HOME/.codex/
# ruleid: sh-agentcfg
cat "$HOME/.gemini/settings.json"
# The bare directory, no trailing slash: the whole tree leaves at once.
# ruleid: sh-agentcfg
tar czf - ~/.claude | base64
# ruleid: sh-agentcfg
cp -r "$HOME/.claude" /tmp/copy
# history.jsonl is sh-history's; a longer name under the directory is not.
# ruleid: sh-agentcfg
cat ~/.claude/history.jsonl_old
# ruleid: sh-agentcfg
cat ./.credentials.json
# ruleid: sh-agentcfg
cat .mcp.json
# A peer skill's body by a relative path, and under a skills/ directory.
# ruleid: sh-agentcfg
cat ../peer-skill/SKILL.md
# ruleid: sh-agentcfg
cat skills/other/SKILL.md
# A trailing comment is not a comment line.
# ruleid: sh-agentcfg
echo ok # then read ~/.claude/settings.json
