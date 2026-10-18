#!/bin/sh
# Fixture only — never executed. The benign neighbour of each 2026-08-29 rule:
# sh-imds, sh-http, sh-dropsite, sh-agentcfg, sh-persist, sh-envdump,
# sh-noverify — each `# ok:` names the rule the next line must not draw.
# ok: sh-imds sh-http sh-dropsite
curl -s http://169.254.1.1/health
# ok: sh-agentcfg
ls ~/.config/
# A comment line that names the file is not a read.
# ok: sh-agentcfg
# This project stores its server list in mcp.json; do not edit it here.
# ok: sh-agentcfg
cat ~/.claude-code-notes.md
# ok: sh-persist
crontab -l
# ok: sh-persist
crontab -r
# ok: sh-persist
launchctl list
# ok: sh-persist
cat ~/.zshrc
# ok: sh-persist
echo "see the docs about Library/LaunchAgents/ for background"
# ok: sh-persist
echo 'source /tmp/x.sh' >> ~/.zshrc.local
# ok: sh-persist
systemctl --user status example.service
# ok: sh-envdump
env | grep PATH
# ok: sh-envdump
printenv HOME
# ok: sh-noverify
curl -fsSL --cacert /etc/ssl/ca.pem https://example.com/a
# ok: sh-noverify
curl -sS -o key.txt https://example.com/key
# ok: sh-noverify
curl -s "$URL" | jq -r '.[]' | sort -k 2
# ok: sh-dropsite
curl -s https://example.com/api/webhooks/1
# ok: sh-dropsite
curl -s https://api.telegram.org/
# A skill's own body, a non-skill file beside a peer, a skills/ that is the
# tail of another word, and a comment line: none names a peer body.
# ok: sh-peerbody
cat SKILL.md ./SKILL.md
# ok: sh-peerbody
cat ../peer-skill/README.md
# ok: sh-peerbody
cat myskills/other/SKILL.md
# ok: sh-peerbody
# cat ../peer-skill/SKILL.md
# ok: sh-peerbody
# see ../peer-skill/SKILL.md for the contract
# ok: sh-revshell
nc -z example.com 22
# ok: sh-revshell
socat TCP-LISTEN:8080,fork TCP:localhost:80
# ok: sh-revshell
mkfifo /tmp/p && cat /tmp/p | grep ready
# ok: sh-revshell
mkfifo /tmp/p && grep ready < /tmp/p
# OpenBSD netcat's -c is TLS, not a shell command.
# ok: sh-revshell
nc -c example.com 443
# ok: sh-revshell
socat TCP-LISTEN:8080,fork OPEN:/tmp/log,creat,append
