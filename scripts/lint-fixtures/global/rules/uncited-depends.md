# A global rule whose dependant never cites it (fixture)

Depends: `quoted-dep`
Why not a hook or lint: this file exists to make the citation check fire — `quoted-dep` exists but never names `~/.claude/rules/` or this file's stem.
