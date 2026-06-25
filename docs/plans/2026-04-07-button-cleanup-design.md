# Button Cleanup: Eliminate Features Section

## Goal

Remove the 6-row "features section" button dump at the bottom of the app and redistribute its items to where they contextually belong. The result is a cleaner, less overwhelming bottom half of the screen.

## Current State

The `featuresSection` contains 6 vertically stacked rows:
1. Daily notifications — Enable button
2. Skin type quiz — Take quiz button
3. Walkthrough — Start button
4. Add widget — Add button
5. Reapplication guide — Learn more button
6. Share result — Two gold buttons (me/you perspectives)

This sits between the controls card and "Backed by doctors" button, taking up significant vertical space.

## New Layout

The `featuresSection` is deleted entirely. The bottom of the screen flows:

**UV Graph → Controls Card → Backed by Doctors → Settings → Footer**

### 1. Share Icon in Hero Area

- Add a small `square.and.arrow.up` SF Symbol near the main result text in the hero section.
- Styled in `textColor` (not gold) — subtle, discoverable, not visually heavy.
- On tap: presents a `confirmationDialog` with two options:
  - "I need sunscreen right now!" / "I don't need sunscreen right now!"
  - "You need sunscreen right now!" / "You don't need sunscreen right now!"
- Selected option triggers the existing `showShareSheet()` logic.

### 2. Skin Type Quiz in Controls Card

- Add a "What's my skin type?" text link in gold below the skin type selector inside the controls card.
- Always visible (not conditional).
- Tapping opens the existing `SkinTypeQuizView` sheet.

### 3. Reapplication Guide — No Change

- The existing "What about reapplication?" link below the hero (visible only when `result.needsSunscreen == true`) stays as-is.
- Remove the duplicate row from the features section.

### 4. Settings Row (New)

- A standalone tappable row between "Backed by doctors" and the footer.
- Gear icon (`gearshape` SF Symbol) + "Settings" label.
- Styled similarly to the "Backed by doctors" button for visual consistency.
- Opens a `.sheet` containing:
  - **Daily notifications** — existing enable/configure flow
  - **Walkthrough** — "Replay walkthrough" button
  - **Add widget** — "Widget setup guide" button (opens existing `WidgetGuideView`)

## What Gets Deleted

- The entire `featuresSection` computed property
- The `featureRow()` helper (if unused elsewhere)
- The `goldButtonLabel()` helper (if unused elsewhere)

## What Gets Added

- Share icon + `confirmationDialog` in `heroSection`
- "What's my skin type?" link in `controlsCard`
- `SettingsView` sheet (new, simple list with 3 items)
- Settings row between "Backed by doctors" and footer

## Walkthrough Update

The current 4 walkthrough steps in `SpotlightOverlayView.swift`:

1. `.answer` — hero section (no change)
2. `.inputs` — controls card (no change)
3. `.timeLocation` — UV info section (no change)
4. `.notifications` — currently points at features section, scrolls to `"features"` ID

Step 4 needs updating. Replace `.notifications` with `.settings` — spotlight the new settings row. Update:
- `scrollID`: change from `"features"` to `"settings"` (new scroll ID on the settings row)
- `title`: "Settings" or keep "Daily Reminders"
- `description`: "Set up notifications, replay the walkthrough, or add a widget."
- Move the `SpotlightAnchorKey` preference from the old features section to the new settings row
