# A global rule whose dependant cites only the rules directory (fixture)

Depends: `unused-dep`
Why not a hook or lint: this file exists to make the citation check fire when the dependant mentions the bare `~/.claude/rules/` directory and never this rule's path or stem — the form the check stopped accepting.
