// Fixture only — never executed.
// The node fs calls beside a peer skill's body, one line each.
// ruleid: sh-peerbody:HIGH
fs.readFile("../peer-skill/SKILL.md", cb);
// ruleid: sh-peerbody:HIGH
const body = fs.readFileSync("../peer-skill/SKILL.md", "utf8");
// ruleid: sh-peerbody:HIGH
fs.writeFile("../peer-skill/SKILL.md", payload, cb);
// ruleid: sh-peerbody:HIGH
fs.writeFileSync("../peer-skill/SKILL.md", payload);
// ruleid: sh-peerbody:HIGH
fs.appendFileSync("../peer-skill/SKILL.md", payload);
// ruleid: sh-peerbody:HIGH
fs.copyFileSync("/tmp/evil.md", "../peer-skill/SKILL.md");
// ruleid: sh-peerbody:HIGH
fs.createReadStream("../peer-skill/SKILL.md").pipe(sock);
// ruleid: sh-peerbody:HIGH
src.pipe(fs.createWriteStream("../peer-skill/SKILL.md"));
// A manifest entry whose key is a verb word: data.
// ruleid: sh-peerbody:MEDIUM
const entry = { source: "skills/other/SKILL.md" };
