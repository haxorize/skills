# Stress Prototype

One finished component, rendered in **every state real content puts it in**, side by side on one page. One load, no switcher, nothing asserts — the user's eyes are the observation. The question is not what it should look like but whether it survives the content it is about to meet. In other vocabularies this is a kitchen-sink page or a content state matrix: every empty state, edge case, and responsive width of one component, on one page.

Wrong branch? The routing table is in [SKILL.md](../SKILL.md).

## When this is the right shape

- A component built against three tidy fixture rows is about to show member names, drug names, addresses, and zero-claim states.
- A layout has only ever been seen at the width of the developer's monitor.
- A truncation, overflow, or empty-state defect was just found in one component and the question is where else it hides.

## Process

### 1. Name the component and its states

Write the state list at the top of the page, one line each, on two axes. Start from the default set and add the product's own; every state on the list is drawn, and one left out is named as left out, never silently dropped.

Content states — what the component is given:

- **Empty** — zero items; an empty string in every text slot; every optional field absent.
- **One** — a single item, so the plural copy and the grid both meet their edge.
- **Many** — forty items, or the realistic upper count where it is known.
- **Unbreakable** — a 60-character string with no spaces in every text slot: a long email, a URL, the longest drug name the product carries.
- **Long prose** — a paragraph where a sentence was expected.
- **Extremes** — 0, a negative, 1,000,000, a currency amount with cents, a date at a year boundary.
- **Loading** and **error**, where the component has them.
- **Longer locale** — the German or Finnish rendering, roughly a third longer, where the product localises; a right-to-left locale where it ships one.

Container states — the room it is given:

- **Default** — the width it was built at.
- **Narrow** — a 320 px container.
- **Squeezed** — beside a sibling that takes the room (a flex row with a greedy neighbour).
- **Wide** — a 1600 px container: does it stretch into a ribbon?

Interaction states — focus, hover, disabled, selected — and colour schemes are left out on purpose: they are questions about the design, which is the UI branch's.

### 2. Build the page

A grid: content states down, container states across, one cell per pair — a labelled container at the column's width holding the component with the row's fixture. The defects this page exists to find live at the pairs — an unbreakable string in a 320 px cell, forty rows squeezed by a greedy sibling — so the grid is the whole product, never one axis at a time. Every cell is visible without interaction; the comparison across cells is the point, so no tabs and no switcher. Side by side means one page, not one viewport: the wide column scrolls.

Mount it as a throwaway route under the routing convention the project already uses, named so it is obviously a prototype, gated out of production builds (`process.env.NODE_ENV !== 'production'` or the project's equivalent), and reached under the command the project already uses to run the app. The route is deleted at step 5.

Fixtures are synthetic and shaped like the domain — a hyphenated surname, a real drug name's length, a plausible claim count — never copied from a production record. Lorem ipsum fails the test by construction: it has no long words and no empty cases.

### 3. Look, with the user

Walk the grid with them. A cell that breaks is named with its state pair and what broke — overflow, truncation with no affordance, a collapsed layout, a wrap that is unreadable, a zero rendered as blank, a label separated from its value. "Looks fine" is a verdict per cell, not per page.

This branch has no unattended path: the observation is a person's eyes. When the user is not reachable, build the page, list the cells that look broken to you as candidates, and stop — the verdict per cell is theirs.

### 4. Fix in the component, not in the fixture

Shortening the fixture until the cell looks right is the classic non-fix. The fix lands in the component; reload; the page is the loop — every cell read again after each fix, until none breaks.

### 5. Capture the answer

As `prototype`'s "When done" section describes: the states that broke and what was decided, with the page on the prototype branch; then delete the route from the working branch. A snapshot test per state pair that mattered is the natural next step — that is `tdd`'s work, not this page's.

## Anti-patterns

- **Lorem ipsum, or fixtures trimmed to fit.** The content is the test.
- **A switcher.** States that can only be seen one at a time cannot be compared.
- **Assertions.** A page that asserts is a test suite, and belongs in one.
- **Fixing the fixture.** See step 4.
- **One state per commit.** The page is one load; a state added later is added to the same grid.
