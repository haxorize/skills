# The BAA gate's five questions

Open this only when the change sends PHI to a counterparty outside the entity's own systems — a vendor API, SaaS, observability backend, crash reporter, OCR or speech service, or model provider — and that counterparty's business-associate status is not already settled by the project's convention skill. The body's rule stands: the sink is blocked by default until the gate clears, and a data-flow row with an unanswered BAA column is a blocked change.

Answer the five questions in order:

1. **Is this PHI at all?** De-identified data and a true conduit (a carrier that never accesses content) leave the gate here.
2. **On whose behalf does the recipient act, and is a BAA needed?** A vendor acting for the entity is a business associate by definition; a covered entity receiving for treatment or payment needs none.
3. **Is that BAA signed before the first byte, and does it bind the recipient's own subcontractors?**
4. **Is this the minimum necessary for the purpose?**
5. **Is the access auditable?**
