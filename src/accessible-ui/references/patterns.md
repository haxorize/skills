# Widget contracts the default output skips

Each contract is what the widget must expose, the criteria it exercises, and the run that verifies it. The markup is illustrative — the project's component library supplies the real one, and the contract is what that component must satisfy. Each carries a **Native** line, written in Apple platform terms — SwiftUI and UIKit, where the accessibility tree is built from traits, labels, and values rather than roles and ARIA, and the run is VoiceOver rather than a browser screen reader. Another platform's API names are not here; what carries over is the contract above the Native line, not the call.

## Toggle chip / filter pill (4.1.2, 2.1.1, 1.4.1, 1.4.11)

A chip that filters or toggles is a button with a pressed state; a styled `<div>` with an `onClick` and an "active" class exposes nothing.

```html
<button type="button" aria-pressed="true">Cardiology</button>
```

- `aria-pressed` flips with the visual state in the same update; a chip that is one of a mutually exclusive set is a radio group (`role="radiogroup"` with `aria-checked` radios) instead.
- The pressed look differs from the unpressed by more than color (a check mark, a border weight), and the selected border or fill meets 3:1 against its neighbors.
- Run: Tab to each chip, Space toggles it, a screen reader announces "pressed" / "not pressed" on each change.
- Native: a `Button` (never an `HStack` with `.onTapGesture`, which is a control with no role) carrying `.accessibilityAddTraits(.isSelected)` or `.isToggle` when pressed, removed when not; VoiceOver reads "selected" on the swipe through the row.

## Live region for status messages and counts (4.1.3)

A region that is injected together with its text announces nothing in most screen readers; the region exists first, empty, and the text arrives later.

```html
<p role="status" id="results-status"></p>
<!-- later, after the filter applies: -->
<script>document.getElementById('results-status').textContent = '12 results';</script>
```

- `role="status"` already implies polite and atomic; adding `aria-live` and `aria-atomic` beside it restates it. One region per page for each kind of message (status, alert), rendered in the initial tree; components set its text rather than mounting their own.
- Pick the first that fits: focus is moving there anyway (no region needed); the message belongs to one control (`aria-describedby` on it); non-urgent and untied (`role="status"`); urgent and untied (`role="alert"`).
- A framework that re-renders the region on every state change unmounts and remounts it — keep the element stable across renders and change only its text node; a message that repeats word for word is cleared and re-set on a later frame, since writing an identical string announces nothing.
- Run: apply the filter with a screen reader running; the count is spoken without focus moving.
- Native: `AccessibilityNotification.Announcement("12 results").post()` (`UIAccessibility.post(notification: .announcement, …)` in UIKit) once the result is in; announce once, after the view has settled, never per tick of a loading state.

## Search box and every other field (1.3.1, 3.3.2, 4.1.2, 2.5.3)

`placeholder` is not a label: it disappears on the first keystroke, fails contrast by default, and is not read as the name by every screen reader.

```html
<label for="member-search">Search members</label>
<input id="member-search" type="search" placeholder="Name or member ID">
```

- An icon-only field gets a visually hidden `<label>` (a `.sr-only` class — hidden by clipping, never by `display: none` or `visibility: hidden`, which take the label out of the accessibility tree along with the pixels and leave the field with no name at all) or an `aria-label`; a field with visible text never gets an `aria-label` that omits that text.
- A component that can render twice on one page derives the ids that tie its parts together — `for`, `aria-labelledby`, `aria-describedby`, `aria-controls` — once per instance. The ids written out in this file are illustrative; hard-coded in a component, the second card's label and status region bind silently to the first card's, and the control keeps its visible label while losing its accessible name.
- Run: a screen reader reads the name on focus; with the page zoomed to 200%, the label is still visible.
- Native: a visible label view paired with the field, or `.accessibilityLabel` when the field has no visible text; `.accessibilityLabel` that replaces visible text breaks the speakable-name rule — extra context goes in `.accessibilityHint`; `textContentType` (`.oneTimeCode`, `.password`, `.emailAddress`) fills 1.3.5 and 3.3.8.

## Dialog and drawer (2.4.3, 2.1.2, 1.3.2, 4.1.2)

Opening a modal moves focus into it, fences the rest of the page, and on close returns focus to the opener; a modal that does none of these is a layer the keyboard user falls behind.

```html
<dialog aria-labelledby="confirm-title">
  <h2 id="confirm-title">Remove this card?</h2>
  ...
  <button type="button" data-close>Cancel</button>
</dialog>
```

- `<dialog>` opened with `showModal()` gives the trap, `Escape`, and inertness for free; a hand-built modal sets `role="dialog"`, `aria-modal="true"`, `inert` on the page root's other children, and traps Tab itself.
- Initial focus goes to the first meaningful control or the title, never to the close button when a destructive action waits; close returns focus to the element that opened it, which the opener records before showing.
- A drawer that does not block the page is not modal: no trap, no `aria-modal`, but still `Escape` to close and focus return.
- Run: open with the keyboard, Tab cycles inside, Escape closes, focus lands back on the opener, a screen reader reads the title on open.
- Native: a sheet or alert sets `@AccessibilityFocusState` to its title on appear (`UIAccessibility.post(notification: .screenChanged, argument: titleView)` in UIKit), carries `.accessibilityAddTraits(.isModal)` (`accessibilityViewIsModal` in UIKit), and on dismiss VoiceOver focus returns to the presenting control.

## Menu and dropdown revealed on hover (2.1.1, 1.4.13, 4.1.2)

A hover-only reveal has no keyboard path; the trigger is a button that opens on click and Enter, and the content is dismissible with Escape and stays open while the pointer is over it.

- Trigger: `<button aria-expanded="false" aria-controls="menu-id">`, flipping `aria-expanded` on open; `aria-haspopup` only when the popup is a real menu (`role="menu"` with `menuitem` children and arrow-key movement), which a list of links is not.
- Hover reveal, if kept for pointer users, is additive to the click path, never the only one; the popup does not close when the pointer crosses the gap between trigger and content.
- Run: Tab to the trigger, Enter opens, arrow keys or Tab move through items, Escape closes and returns focus to the trigger.
- Native: a `Menu` or a `Button` that presents; a long-press-only or hover-only (pointer on iPadOS) reveal has a tap path; `accessibilityCustomActions` exposes a swipe-row's actions to VoiceOver.

## Focus indicator over a sticky header (2.4.7, 2.4.11, 1.4.11)

A sticky header or toolbar hides the focused element that scrolls behind it; the focus ring exists but nothing shows it.

- `scroll-padding-top` on the scroll container equal to the sticky height, so `focus()` and Tab scroll the element clear of the overlay.
- The indicator has 3:1 contrast against the adjacent colors in each theme (1.4.11), drawn with `:focus-visible`; `outline-offset` keeps it off a colored background.
- 2.4.13 Focus Appearance is AAA and owns the 2 CSS pixel perimeter figure: a ring that meets 2.4.7, 2.4.11, and 1.4.11 and not 2.4.13 is an AA pass with an AAA note, not a failure.
- Run: Tab through the page with the header stuck; no focused element is entirely hidden behind it (2.4.11 is the AA bar; fully unobscured is 2.4.12, AAA).
- Native: keyboard focus on iPadOS and macOS draws the system ring; a custom `.focusable()` view with a custom ring meets the same 3:1; a pinned header in a `ScrollView` respects `safeAreaInset` so the focused row scrolls clear.

## Tabs, toolbars, and other composites (2.1.1, 2.4.3, 4.1.2)

A composite is one tab stop; arrow keys move inside it. Two tab stops per tab, or every tool in a toolbar in the tab order, is the default output.

- One of roving `tabindex` (the active item `0`, the rest `-1`) or `aria-activedescendant` on the container — never both; a `role="tablist"` carries `role="tab"` children with `aria-selected` and `aria-controls`, and each `role="tabpanel"` is labelled by its tab.
- An inactive panel, a collapsed accordion body, and a closed disclosure are `hidden` or `inert`, not `opacity: 0` or `height: 0`, which leave their controls in the tab order.
- A control that toggles keeps one name (not "Show"/"Hide" swapping) and flips its state attribute — a disclosure flips `aria-expanded` — because swapping the name *and* flipping the state announces the state twice and lets the two disagree ("Play, pressed"); site navigation is `<nav>` with links and `aria-current="page"`, never `role="menu"`.
- Run: one Tab lands on the composite, arrows move the selection, Tab leaves it; a screen reader reads "tab 2 of 4, selected".
- Native: a segmented `Picker` or `TabView` gives this for free; a custom tab strip marks the selected item `.isSelected`, groups with `.accessibilityElement(children: .contain)`, which keeps the children reachable where `.combine` and `.ignore` collapse them into one element — so a container holding controls takes neither — and hidden content is removed from the hierarchy, not just faded.

## Option groups and form errors (1.3.1, 3.3.1, 3.3.2, 3.3.3, 3.2.2)

- A set of related radios or checkboxes sits in a `<fieldset>` with a `<legend>` that asks the question; radios share a `name` so the group is one tab stop with arrow movement; a lone consent checkbox needs no fieldset; "pick at least one" is checked at submit, not with `required` on each box. A field's format or constraint — the date form, the digit count, what the plan will accept — is text beside the field, tied to it with `aria-describedby` and still on screen while it is being filled, never only a placeholder, a dialog already dismissed, or a step already left behind.
- An error names the field and says what to change (3.3.3), renders in text beside the field, referenced by `aria-describedby` with `aria-invalid="true"` set and the value preserved, and a failed submit moves focus either to a focusable error summary whose items link to the fields or to the first invalid field.
- Validation runs on `input` or blur, never on every keystroke of an untouched field and never `keydown` (dictation, paste, and autofill fire no key); a `<select>` never navigates on `change` alone; the submit button is never disabled as validation.
- `autocomplete` tokens on identity fields (1.3.5); paste is never blocked on a password or one-time code, and `current-password` / `one-time-code` are set (3.3.8); a multi-step form keeps what was entered when the person goes back (3.3.7).
- Run: submit with a required field empty; focus lands on the summary or the field, a screen reader reads the field's name, "invalid", and the message; fix the field and the value typed elsewhere is still there.
- Native: a `Picker` or grouped `Toggle`s carry a group label via `.accessibilityLabel` on the container; an error sets the field's `.accessibilityValue` or hint and is announced once; `textContentType` as above.

## Loading and toasts (4.1.3, 2.2.1, 2.2.2)

- A container that is loading carries `aria-busy="true"` until its content is in, so a partial result is not read before the outcome; skeleton placeholders are `aria-hidden`; one "Loading" announcement and one outcome, never a spinner that announces per frame; a measurable load uses `<progress>`.
- An in-flight control keeps its accessible name: the spinner replaces the label in the pixels, never in the tree, and the control is `aria-busy` or `aria-disabled` rather than `disabled`, which drops focus to the body while the person waits.
- A toast is `role="status"` text in the pre-existing region, never a focus move; `Escape` dismisses it; repeats collapse into one; the action a toast carries is reachable by keyboard, and an Undo offered only in a toast also exists somewhere persistent.
- Run: trigger the load with a screen reader on; exactly two announcements, and focus never moves on its own.
- Native: `.accessibilityHidden(true)` on skeletons; an `Announcement` for the outcome, never moving VoiceOver focus because something loaded; a toast with an action is a view VoiceOver can reach, not an overlay that disappears on a timer.

## Images and icons (1.1.1)

- An `<img>` that carries meaning has `alt` text stating what it conveys, not what it is ("Claim approved", not "green check icon"); a decorative image has `alt=""` and an inline SVG icon beside a text label is `aria-hidden="true"`; an icon that is the whole control gets its name on the control, never on the icon.
- Run: a screen reader reads the meaning or skips the decoration; an image of text is rejected unless the text is also in the DOM.
- Native: `Image(decorative:)` or `.accessibilityHidden(true)` for decoration, `.accessibilityLabel` stating the meaning for the rest; an `Image` inside a `Button` with a `Label` is hidden behind the label's text.

## Clickable card (4.1.2, 2.5.2, 1.3.2)

A card whose whole surface is clickable exposes one control — the title — and reaches it from the rest of the surface; a card that nests a `<button>` or a second `<a>` inside that link is markup no browser announces coherently.

- The card's name is its heading, and the heading is first in reading order even where an image or a badge is first visually.
- One exposed control per card: the surface is made clickable by CSS or a handler that forwards to the title's link, and a decorative "Read more" duplicate is a `<span>` rather than a control, because `aria-hidden="true"` on a focusable element is invalid and leaves it in the tab order — a duplicate that must stay an `<a>` or `<button>` takes `tabindex="-1"` alongside it.
- Activation is on the up-event, never `mousedown` or `pointerdown`, so a press that drags off the card commits nothing (2.5.2).
- The card's text can be selected with the pointer without the card activating.
- Run: Tab reaches one stop per card; a screen reader reads one link named by the title; a drag across the text selects it; press-then-drag-off activates nothing.
- Native: one `Button` or `NavigationLink` wrapping the card, collapsed into a single element — `.accessibilityElement(children: .combine)` concatenates every descendant's label, so a row that should be named by its title alone takes `.ignore` with an explicit `.accessibilityLabel` instead. Collapsing is available here only because a correctly built card holds no controls of its own; the `.contain` rule above still binds a container that does. A second action is `.accessibilityAction(named:)` in SwiftUI, a `UIAccessibilityCustomAction` in UIKit, rather than a nested control.

## Data tables and charts (1.3.1, 1.1.1, 1.4.1, 2.1.1)

- A data table is `<table>` with `<caption>`, `<th scope="col">` and `<th scope="row">`, and `aria-sort` on a sorted column header whose control is a button; a `<div>` grid is either a full `role="grid"` tree with arrow keys or nothing; a row that can be selected carries `aria-selected`; a `<table>` used for layout rather than data carries `role="presentation"`, or every one of its rows is announced as table structure.
- A chart drawn to `<canvas>` has no accessibility tree: the title, a one-sentence summary, and a data table live in the DOM beside it, and any keyboard interaction the chart offers (hover a point, pick a series) lives there too; an SVG chart is one `role="img"` whose name the markup carries — `aria-labelledby` on the `<svg>` referencing the `id` of a `<title>` (and of a `<desc>` for the summary) that is a direct child of the `<svg>`, so the SVG's own name and the reference agree — or a structured set of graphics roles, never both; `aria-live` is never on the chart container; adjacent series meet 3:1 or differ by more than color; a chart that updates live can be paused.
- Run: a screen reader reads the caption, then a header with each cell; the chart's summary and table are reachable without the pointer.
- Native: `Table` and `Chart` in SwiftUI expose rows and marks, and a framework chart's spoken description and audio graph are built from the label strings its marks were given — so those strings are the words a reader hears, the series and axis names rather than "X" and "Y"; a custom chart sets `.accessibilityChartDescriptor` or, failing that, a label with the summary and a table view behind a "View data" button.
