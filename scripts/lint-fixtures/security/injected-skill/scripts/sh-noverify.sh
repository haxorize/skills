#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-noverify
curl -k https://example.invalid/a
# ruleid: sh-noverify
curl -fsSLk https://example.invalid/b
# ruleid: sh-noverify
curl -kv https://example.invalid/b2
# ruleid: sh-noverify
curl --insecure https://example.invalid/c
# ruleid: sh-noverify
wget --no-check-certificate https://example.invalid/d
# ruleid: sh-noverify
export NODE_TLS_REJECT_UNAUTHORIZED=0
# ruleid: sh-noverify
export GIT_SSL_NO_VERIFY=true
# ruleid: sh-noverify
export GIT_SSL_NO_VERIFY=1
# ruleid: sh-noverify
GIT_SSL_NO_VERIFY=True git clone https://example.invalid/r.git
