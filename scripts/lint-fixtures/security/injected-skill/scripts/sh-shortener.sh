#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-shortener
curl -sL https://bit.ly/x
# ruleid: sh-shortener
curl -sL https://tinyurl.com/x
# ruleid: sh-shortener
curl -sL https://t.co/x
# ruleid: sh-shortener
curl -sL https://goo.gl/x
# ruleid: sh-shortener
curl -sL https://is.gd/x
# ruleid: sh-shortener
curl -sL https://cutt.ly/x
# ruleid: sh-shortener
curl -sL https://rb.gy/x
