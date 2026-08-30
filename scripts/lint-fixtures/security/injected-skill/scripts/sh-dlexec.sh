#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# Each download form paired with a mode change, instances six blank lines apart;
# the last pair sits exactly five lines apart, the window's edge.
# ruleid: sh-dlexec
curl -fsSL https://example.invalid/h -o /tmp/h
chmod +x /tmp/h






# ruleid: sh-dlexec
wget https://example.invalid/h -O /tmp/h
chmod 755 /tmp/h






# ruleid: sh-dlexec
curl https://example.invalid/h --output /tmp/h
chmod u+x /tmp/h






# ruleid: sh-dlexec
wget --output-document=/tmp/h https://example.invalid/h
install -m 0755 /tmp/h /usr/local/bin/h






# ruleid: sh-dlexec
curl https://example.invalid/h > /tmp/h
chmod 0700 /tmp/h






# ruleid: sh-dlexec
curl https://example.invalid/h >> /tmp/h
chmod a+x /tmp/h






# ruleid: sh-dlexec
curl https://example.invalid/h | tee /tmp/h
chmod +x /tmp/h






# The reversed order: the mode first, the download within five lines of it.
# ruleid: sh-dlexec
chmod +x /tmp/h
curl https://example.invalid/h -o /tmp/h






# The window's edge: the chmod five lines after the download.
# ruleid: sh-dlexec
curl https://example.invalid/h -o /tmp/edge
echo one
echo two
echo three
echo four
chmod +x /tmp/edge
