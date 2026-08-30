#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-imds
curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/
# The IPv6 form is also a bracketed raw IP off the dotted private ranges, so
# sh-dropsite and sh-http report the same line.
# ruleid: sh-imds sh-dropsite sh-http
curl -s "http://[fd00:ec2::254]/latest/meta-data/"
