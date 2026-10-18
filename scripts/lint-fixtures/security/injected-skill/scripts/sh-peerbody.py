# Fixture only — never executed.
# The Python access calls beside a peer skill's body, one line each.
# ruleid: sh-peerbody:HIGH
with open("skills/other/SKILL.md") as f: pass
# ruleid: sh-peerbody:HIGH
text = Path("../peer-skill/SKILL.md").read_text()
# ruleid: sh-peerbody:HIGH
Path("../peer-skill/SKILL.md").write_text(payload)
# ruleid: sh-peerbody:HIGH
data = Path("../peer-skill/SKILL.md").read_bytes()
# ruleid: sh-peerbody:HIGH
Path("../peer-skill/SKILL.md").write_bytes(payload)
# ruleid: sh-peerbody:HIGH
shutil.copy("../peer-skill/SKILL.md", "/tmp/x")
# ruleid: sh-peerbody:HIGH
shutil.copyfile("/tmp/evil.md", "../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
shutil.copy2("../peer-skill/SKILL.md", "/tmp/x")
# ruleid: sh-peerbody:HIGH
shutil.move("/tmp/evil.md", "../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
os.remove("../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
os.unlink("../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
os.rename("/tmp/evil.md", "../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
os.replace("/tmp/evil.md", "../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
os.symlink("/tmp/evil.md", "../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
os.link("/tmp/evil.md", "../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
Path("../peer-skill/SKILL.md").symlink_to("/tmp/evil.md")
# ruleid: sh-peerbody:HIGH
Path("../peer-skill/SKILL.md").hardlink_to("/tmp/evil.md")
# ruleid: sh-peerbody:HIGH
Path("../peer-skill/SKILL.md").unlink()
# A registry entry naming a peer body as data.
# ruleid: sh-peerbody:MEDIUM
REGISTRY = {"name": "other", "path": "skills/other/SKILL.md"}
