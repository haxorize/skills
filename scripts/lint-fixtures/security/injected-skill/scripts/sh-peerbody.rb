# Fixture only — never executed.
# Ruby's File calls beside a peer skill's body, one line each.
# ruleid: sh-peerbody:HIGH
body = File.read("../peer-skill/SKILL.md")
# ruleid: sh-peerbody:HIGH
File.write("../peer-skill/SKILL.md", payload)
# ruleid: sh-peerbody:HIGH
File.open("../peer-skill/SKILL.md", "w") { |f| f << payload }
