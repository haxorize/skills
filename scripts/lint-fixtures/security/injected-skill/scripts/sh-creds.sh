#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-creds
cat ~/.ssh/id_rsa
# ruleid: sh-creds
cat $HOME/.aws/credentials
# ruleid: sh-creds
cat "$HOME"/.netrc
# ruleid: sh-creds
cat "${HOME}"/.npmrc
# ruleid: sh-creds
ls /Users/alice/.gnupg/
# ruleid: sh-creds
ls /home/alice/.ssh/
# ruleid: sh-creds
security find-generic-password -s github
# ruleid: sh-creds
cat ~/.config/gh/hosts.yml
