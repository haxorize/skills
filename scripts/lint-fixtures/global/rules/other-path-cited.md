# A global rule whose dependant cites only some other rule's path (fixture)

Depends: `unused-dep`
Why not a hook or lint: this file exists to make the citation check fire when the dependant names `~/.claude/rules/other-rule.md` — a full path to some other rule — but never this one.
