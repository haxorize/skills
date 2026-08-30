#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-b64exec
echo aGVsbG8gd29ybGQgdGhpcyBpcyBhIGxvbmcgYmFzZTY0IHN0cmluZyB0byBkZWNvZGU= | base64 -d | sh
# ruleid: sh-b64exec
base64 --decode /tmp/payload | bash
# ruleid: sh-b64exec
echo aGVsbG8gd29ybGQgdGhpcyBpcyBhIGxvbmcgYmFzZTY0IHN0cmluZyB0byBkZWNvZGU= | base64 --decode
