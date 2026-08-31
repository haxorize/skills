# Expand–contract sequencing

Opens only when step 5's detection fires: the Story hides a wide mechanical refactor — one change whose blast radius fans across the codebase, where a single edit breaks every call site at once so no tracer-bullet slice can land green.

Sequence it instead:

- An **expand** Task adds the new form beside the old (nothing breaks).
- **Migrate** Tasks move call sites over in batches sized by blast radius (per package, per directory), each blocked by the expand, CI green throughout because the old form still exists.
- A final **contract** Task deletes the old form once no caller remains, blocked by every migrate batch.

If even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify Task — green is promised only there.
