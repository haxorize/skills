# Ticket names the assignable tier; Work item keeps the umbrella

The glossary treated "Ticket" as an alias to avoid for **Work item** while `chart-course` claimed the bare word for Decision tickets. **Ticket** is now a first-class term for the assignable subset of work items (User Story, Task, Bug — `DOMAIN.md` owns the full definition), matching team usage; **Work item** remains the umbrella that also covers containers and records. The full flip — Ticket as the umbrella, demoting "work item" to the ADO-specific flavor the way "issue" is GitHub's — was rejected because "Feature ticket" misdescribes containers and bare "Ticket" would collide with Decision ticket.

## Consequences

- Decision ticket becomes a sub-type of Ticket; its bare-"Ticket" alias now redirects to the general term instead of claiming it.
- The cold-start loader is renamed `from-work-item` → `from-ticket`: it always refused Feature / Epic IDs, so the new name states its actual domain (ADR-0004 records the loader under its original name).
- Prose keeps "work item" wherever the container-inclusive umbrella is genuinely meant (hierarchy rules, Chart-as-Feature); "ticket" is used where only the assignable tier is.
- If "Feature ticket" creeps into real usage, the fallback is loosening Ticket's glossary definition — a glossary edit, not a re-rename.
