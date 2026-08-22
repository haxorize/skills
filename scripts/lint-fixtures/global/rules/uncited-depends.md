# A global rule whose dependant never cites it (fixture)

Depends: `quoted-dep`
Why not a hook or lint: this file exists to make the citation check fire — `quoted-dep` exists but names this file's stem only inside a fenced block, which is not a citation.
