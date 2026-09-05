# Expand–contract sequencing

Opens only when step 5's detection fires: the Story hides a wide mechanical refactor — one change whose blast radius fans across the codebase, where a single edit breaks every call site at once so no tracer-bullet slice can land green — or a data migration, a schema change plus a batched row migration.

Sequence it instead:

- An **expand** Task adds the new form beside the old (nothing breaks).
- **Migrate** Tasks move call sites over in batches sized by blast radius (per package, per directory), each blocked by the expand, CI green throughout because the old form still exists.
- A final **contract** Task deletes the old form once no caller remains, blocked by every migrate batch.

The same sequence carries a data migration: **expand** the schema (a nullable column, a concurrently built index — DDL alone, never a row move in the same step), **migrate** Tasks move rows in batches sized by row count and each batch's lock time, then **contract** once nothing reads the old shape. Production migrations are forward-only and immutable once run, and that a migration cannot roll back is why the split exists: a deploy rollback (`~/.claude/skills/ship/references/after-landing.md`) rolls back the code, never the migration, and the expanded schema still serves the old code. A migration is tested against synthetic data at production scale — never a production extract, which `phi-safe-code` forbids — before it ships, and a large table's migration Task names the lock it takes and for how long.

If even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify Task — green is promised only there.
