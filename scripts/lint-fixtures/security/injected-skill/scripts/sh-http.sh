#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-http
curl http://example.invalid/plain
# ruleid: sh-http
wget http://example.invalid/plain
