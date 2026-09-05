# Expand–contract sequencing

Opens only when step 5's detection fires: the Story hides a wide mechanical refactor — one change whose blast radius fans across the codebase, where a single edit breaks every call site at once so no tracer-bullet slice can land green.

Sequence it instead:

- An **expand** Task adds the new form beside the old (nothing breaks).
- **Migrate** Tasks move call sites over in batches sized by blast radius (per package, per directory), each blocked by the expand, CI green throughout because the old form still exists.
- A final **contract** Task deletes the old form once no caller remains, blocked by every migrate batch.

The same sequence carries a data migration: **expand** the schema (a nullable column, a concurrently built index — DDL alone, never a backfill in the same step), **backfill** in batches sized by row count and each block's lock time, then **contract** once nothing reads the old shape. Production migrations are forward-only and immutable once run; a migration is tested against production-sized data before it ships, and a large table's migration Task names the lock it takes and for how long.

If even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify Task — green is promised only there.
