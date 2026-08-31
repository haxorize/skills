# Native lines for the widget contracts

Open this only when the change is built for a native platform — SwiftUI or UIKit, or another platform whose accessibility tree is built from traits, labels, and values rather than roles and ARIA — never on a web change. Each section mirrors a contract heading in [patterns.md](patterns.md): the contract there is what carries over; the call here is Apple's, and the run is VoiceOver rather than a browser screen reader. Another platform's API names are not here.

Two body rules land here too. The fourth rung of **Reach for the most proven implementation first** is reached on native by declaring the standard control as the custom view's accessibility representation rather than assembling the traits by hand. And under **Text scales**, use the platform's scaling styles (a system text style, or a custom font declared relative to one — Dynamic Type on Apple platforms) with the container's paddings and icon sizes scaling alongside it, so the largest accessibility size still lays out; the platform's own target minimum — 44 pt on Apple platforms, 48 dp on Android — sits above 2.5.8's 24 CSS pixels, so a control that clears the criterion can still fail the guideline a native review applies, which is a suggestion under **A failure is a criterion**, never a ledger line.

## Toggle chip / filter pill

A `Button` (never an `HStack` with `.onTapGesture`, which is a control with no role) carrying `.accessibilityAddTraits(.isSelected)` or `.isToggle` when pressed, removed when not; VoiceOver reads "selected" on the swipe through the row.

## Live region for status messages and counts

`AccessibilityNotification.Announcement("12 results").post()` (`UIAccessibility.post(notification: .announcement, …)` in UIKit) once the result is in; announce once, after the view has settled, never per tick of a loading state.

## Search box and every other field

A visible label view paired with the field, or `.accessibilityLabel` when the field has no visible text; `.accessibilityLabel` that replaces visible text breaks the speakable-name rule — extra context goes in `.accessibilityHint`; `textContentType` (`.oneTimeCode`, `.password`, `.emailAddress`) fills 1.3.5 and 3.3.8. The field's text scales with Dynamic Type: a fixed-point font on the field or its label caps the person's own text-size setting.

## Dialog and drawer

A sheet or alert sets `@AccessibilityFocusState` to its title on appear (`UIAccessibility.post(notification: .screenChanged, argument: titleView)` in UIKit), carries `.accessibilityAddTraits(.isModal)` (`accessibilityViewIsModal` in UIKit), and on dismiss VoiceOver focus returns to the presenting control.

## Menu and dropdown revealed on hover

A `Menu` or a `Button` that presents; a long-press-only or hover-only (pointer on iPadOS) reveal has a tap path; `accessibilityCustomActions` exposes a swipe-row's actions to VoiceOver.

## Focus indicator over a sticky header

Keyboard focus on iPadOS and macOS draws the system ring; a custom `.focusable()` view with a custom ring meets the same 3:1; a pinned header in a `ScrollView` respects `safeAreaInset` so the focused row scrolls clear.

## Tabs, toolbars, and other composites

A segmented `Picker` or `TabView` gives this for free; a custom tab strip marks the selected item `.isSelected`, groups with `.accessibilityElement(children: .contain)`, which keeps the children reachable where `.combine` and `.ignore` collapse them into one element — so a container holding controls takes neither — and hidden content is removed from the hierarchy, not just faded.

## Option groups and form errors

A `Picker` or grouped `Toggle`s carry a group label via `.accessibilityLabel` on the container; an error sets the field's `.accessibilityValue` or hint and is announced once; `textContentType` as above.

## Loading and toasts

`.accessibilityHidden(true)` on skeletons; an `Announcement` for the outcome, never moving VoiceOver focus because something loaded; a toast with an action is a view VoiceOver can reach, not an overlay that disappears on a timer.

## Images and icons

`Image(decorative:)` or `.accessibilityHidden(true)` for decoration, `.accessibilityLabel` stating the meaning for the rest; an `Image` inside a `Button` with a `Label` is hidden behind the label's text.

## Clickable card

One `Button` or `NavigationLink` wrapping the card, collapsed into a single element — `.accessibilityElement(children: .combine)` concatenates every descendant's label, so a row that should be named by its title alone takes `.ignore` with an explicit `.accessibilityLabel` instead. Collapsing is available here only because a correctly built card holds no controls of its own; the `.contain` rule for composites still binds a container that does. A second action is `.accessibilityAction(named:)` in SwiftUI, a `UIAccessibilityCustomAction` in UIKit, rather than a nested control.

## Binding submission

`.confirmationDialog` in SwiftUI or a `UIAlertController` with `.actionSheet`/`.alert` carries the confirmation, its destructive choice marked `role: .destructive` (SwiftUI) or `UIAlertAction.Style.destructive` so VoiceOver speaks the consequence rather than only the verb; the reviewable alternative is a summary screen before the commit, and the reversible one is the system undo — `UndoManager`, or a shake-to-undo the view registers — never a toast that disappears on its own timer.

## Data tables and charts

`Table` and `Chart` in SwiftUI expose rows and marks, and a framework chart's spoken description and audio graph are built from the label strings its marks were given — so those strings are the words a reader hears, the series and axis names rather than "X" and "Y"; a custom chart sets `.accessibilityChartDescriptor` or, failing that, a label with the summary and a table view behind a "View data" button. Table text and chart labels use text styles that scale with Dynamic Type, so the largest accessibility size still lays out.
