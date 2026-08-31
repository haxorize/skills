# DOMAIN.md format

Use this structure when writing `DOMAIN.md`.

```markdown
# Domain

## <Group Name>

| Term        | Definition                                              | Aliases to avoid      |
| ----------- | ------------------------------------------------------- | --------------------- |
| **Order**   | A customer's request to purchase one or more items      | Purchase, transaction |
| **Invoice** | A request for payment sent to a customer after delivery | Bill, payment request |

## <Another Group>

| Term         | Definition                                  | Aliases to avoid       |
| ------------ | ------------------------------------------- | ---------------------- |
| **Customer** | A person or organization that places orders | Client, buyer, account |

## Relationships

- An **Invoice** belongs to exactly one **Customer**
- An **Order** produces one or more **Invoices**
- A **Shipment** is tied to a single **Fulfillment**

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
>
> **Domain expert:** "No — an **Invoice** is only generated once a **Fulfillment** is confirmed. A single **Order** can produce multiple **Invoices** if items ship in separate **Shipments**."
>
> **Dev:** "So if a **Shipment** is cancelled before dispatch, no **Invoice** exists for it?"
>
> **Domain expert:** "Exactly. The **Invoice** lifecycle is tied to the **Fulfillment**, not the **Order**."

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User** — these are distinct concepts: a **Customer** places orders, while a **User** is an authentication identity that may or may not represent a **Customer**.
```

## Notes

- Group terms into multiple tables when natural clusters emerge (by subdomain, lifecycle, or actor). One table is fine if all terms belong to a single cohesive domain — don't force groupings.
- Use **bold** for term names in `Relationships` and `Flagged ambiguities` sections.
- Keep the example dialogue to 3-5 **Dev**/**Domain expert** exchanges that clarify boundaries between related concepts.
- Definitions: present tense, defining what the term IS — not what it does. Open on the definition in one sentence; further sentences earn their place only by discriminating the term from a neighbour, recording a scope the name does not carry, or naming the authority that settles it. A definition that has grown past that is a sign the entry is carrying spec or process detail that belongs elsewhere.

## Multi-context repos

If the repo has multiple bounded contexts, the root `DOMAIN.md` is an index:

```markdown
# Domain

This repo spans multiple bounded contexts. Each context has its own `DOMAIN.md`.

## Contexts

- [Billing](src/billing/DOMAIN.md) — orders, invoices, payments
- [Fulfillment](src/fulfillment/DOMAIN.md) — shipments, warehouses, carriers
- [Identity](src/identity/DOMAIN.md) — users, sessions, roles
```

Each nested `DOMAIN.md` follows the format above. Cross-context terms (terms that mean different things in different contexts) get an explicit note in `Flagged ambiguities` of each context.

## Cross-repo siblings

For cross-repo setups (e.g., separate API and UI repos under one product), each repo's `DOMAIN.md` is self-contained. Cross-reference the sibling in prose at the bottom:

```markdown
## Cross-repo

The UI consumes terms from this domain via the generated client. See `../<sibling-repo>/DOMAIN.md` for UI-side terminology.
```

No parent map file.
