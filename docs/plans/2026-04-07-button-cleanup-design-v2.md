# Button Cleanup: Eliminate Features Section (v2)

## Changes from Previous Version

1. **Sheet-to-overlay conflict resolved** (critical): SettingsView now uses closure callbacks (`onReplayWalkthrough`, `onWidgetGuide`) passed from ContentView. When tapped, the settings sheet dismisses first, then a `DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)` delay triggers the overlay — matching the existing `chainWidgetGuideAfterTour` pattern.

2. **Skin type quiz duplicate removed** (critical): Section 2 ("Skin Type Quiz in Controls Card") was describing a link that already exists at line ~523 of ContentView.swift. The existing blue italic "What's my skin type?" link is kept as-is — no restyle, no move. The only action is removing the duplicate row from the features section.

3. **Share icon placement specified**: The share icon appears only in the authorized state of the hero section, positioned below the result text (below the safe-exposure-time line or below YES/NO when there is no safe-exposure line). Placed as a standalone small button, not inline with the large text.

4. **confirmationDialog title specified**: Uses the title "Share your sunscreen status".

5. **Notifications in Settings uses navigation push**: Tapping the notifications row inside SettingsView performs a NavigationLink push to the existing `NotificationSettingsView`, not an inline embed.

6. **TutorialStep references fully enumerated**: All 5 locations that reference `.notifications` are listed with their required changes.

7. **Reapplication guide trade-off acknowledged**: The reapplication guide becomes unreachable when sunscreen is not needed. This is intentional — users who don't need sunscreen have no reason to read about reapplication timing.

---

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

- Add a small `square.and.arrow.up` SF Symbol button in the hero section, **only in the authorized state** (the `else` branch that shows YES/NO).
- Position: below the result text block. Specifically, below the safe-exposure-time text when `result.needsSunscreen` is true, or below the YES/NO text when it is false. Above the reapplication link if both are visible.
- Styled in `textColor.opacity(0.6)` — subtle, discoverable, not visually heavy. Font size `.system(size: 20)`.
- On tap: presents a `confirmationDialog` with the title **"Share your sunscreen status"** and two options:
  - "I need sunscreen right now!" / "I don't need sunscreen right now!" (varies based on `result.needsSunscreen`)
  - "You need sunscreen right now!" / "You don't need sunscreen right now!" (varies based on `result.needsSunscreen`)
- Selected option triggers the existing `showShareSheet()` logic with `shareText(perspective:)`.
- Requires a `@State private var showShareConfirmation = false` on ContentView.

### 2. Skin Type Quiz — No Change (Remove Duplicate Only)

The "What's my skin type?" link already exists in the controls card (line ~523 of ContentView.swift), styled as a blue italic link matching other interactive links in the app (change/reset location, change time). This link is kept exactly as-is — no restyle, no repositioning.

The only action is removing the duplicate "What skin type am I?" row from the features section.

### 3. Reapplication Guide — No Change (Intentional Trade-off)

- The existing "What about reapplication?" link below the hero result text (visible only when `result.needsSunscreen == true`) stays as-is.
- Remove the duplicate row from the features section.
- **Acknowledged trade-off**: The reapplication guide becomes unreachable when sunscreen is not needed. This is intentional — users who don't currently need sunscreen have no actionable reason to read about reapplication timing. The guide is most useful in context, right when the user sees "YES".

### 4. Settings Row (New)

- A standalone tappable row between "Backed by doctors" and the footer.
- Gear icon (`gearshape` SF Symbol) + "Settings" label.
- Styled similarly to the "Backed by doctors" button: stroked rounded rectangle with `textColor.opacity(0.7)` text and `textColor.opacity(0.3)` stroke.
- Requires a `@State private var showSettings = false` on ContentView.
- Opens a `.sheet(isPresented: $showSettings)` containing `SettingsView`.
- The settings row gets the scroll ID `"settings"` and the `SpotlightAnchorKey` anchor preference for `.settings`.

### 5. SettingsView (New View)

A new `SettingsView.swift` file. Presented as a sheet from ContentView.

**Init parameters:**
- `isPresented: Binding<Bool>` — to dismiss the sheet
- `preferences: UserPreferences` — to read notification state
- `notificationManager: NotificationManager` — passed through to NotificationSettingsView
- `onReplayWalkthrough: () -> Void` — closure called when user taps "Replay walkthrough"
- `onWidgetGuide: () -> Void` — closure called when user taps "Widget setup guide"

**Structure:**
```
NavigationView {
    List {
        // Row 1: Notifications
        NavigationLink(destination: NotificationSettingsView(...)) {
            Label("Notifications", systemImage: "bell")
        }

        // Row 2: Replay walkthrough
        Button {
            isPresented = false   // dismiss sheet
            onReplayWalkthrough()
        } label: {
            Label("Replay walkthrough", systemImage: "hand.point.up.left")
        }

        // Row 3: Widget setup guide
        Button {
            isPresented = false   // dismiss sheet
            onWidgetGuide()
        } label: {
            Label("Widget setup guide", systemImage: "rectangle.on.rectangle")
        }
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") { isPresented = false }
                .fontWeight(.semibold)
        }
    }
}
```

**NotificationSettingsView integration**: The existing `NotificationSettingsView` already wraps itself in a `NavigationView` with its own toolbar. When pushed via `NavigationLink` from SettingsView, its internal `NavigationView` must be removed so it doesn't double-nest. Instead, make `NotificationSettingsView` detect whether it's already in a navigation stack (or add a parameter to control this). The simplest approach: add an `embedded: Bool = false` parameter to `NotificationSettingsView`. When `embedded` is true, it renders as a plain `Form` without wrapping in `NavigationView` or adding a toolbar Done button (the parent navigation handles the back button). When false (the default), it behaves as it does today for any direct sheet presentations.

**Sheet-to-overlay coordination in ContentView:**

When constructing SettingsView, ContentView passes closures that handle the dismiss-then-trigger pattern:

```swift
.sheet(isPresented: $showSettings) {
    SettingsView(
        isPresented: $showSettings,
        preferences: preferences,
        notificationManager: notificationManager,
        onReplayWalkthrough: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showTour = true
            }
        },
        onWidgetGuide: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showWidgetGuide = true
            }
        }
    )
}
```

The closures fire after the sheet's `isPresented` is set to false inside SettingsView. The 0.5-second delay ensures the sheet dismissal animation completes before the overlay appears. This matches the existing `chainWidgetGuideAfterTour` pattern (lines 129-133 of ContentView.swift) which uses `asyncAfter` with a 0.4s delay.

## What Gets Deleted

- The entire `featuresSection` computed property
- The `featureRow()` helper (confirmed: only used within `featuresSection`)
- The `goldButtonLabel()` helper (confirmed: only used within `featuresSection`)
- The `.id("features")` scroll anchor from the VStack
- The `showNotificationSettings` state variable (notifications are now accessed through Settings)
- The `.sheet(isPresented: $showNotificationSettings)` modifier

## What Gets Added

- `@State private var showShareConfirmation = false` on ContentView
- `@State private var showSettings = false` on ContentView
- Share icon + `.confirmationDialog` in `heroSection`
- Settings row (with `"settings"` scroll ID and `.settings` anchor preference) between `backedByDoctorsButton` and `footerSection`
- `.sheet(isPresented: $showSettings)` modifier on ContentView
- `SettingsView.swift` — new file with NavigationView, List, NavigationLink to NotificationSettingsView, and two closure-backed buttons
- `embedded` parameter on `NotificationSettingsView` to support NavigationLink push without double-nesting NavigationView

## What Gets Kept (Unchanged)

- `showShareSheet()` method — still used by the confirmation dialog
- `shareText(perspective:)` method — still used to generate share text
- `SharePerspective` enum — still used
- The "What's my skin type?" blue italic link in the controls card — untouched
- The "What about reapplication?" link in the hero section — untouched

## Walkthrough Update

The current 4 walkthrough steps in `SpotlightOverlayView.swift`:

1. `.answer` — hero section (no change)
2. `.inputs` — controls card (no change)
3. `.timeLocation` — UV info section (no change)
4. `.notifications` — currently points at features section → **rename to `.settings`**, point at new settings row

### All `.notifications` references to update:

**SpotlightOverlayView.swift** (4 references):

1. **Line 9** — Enum case declaration: `case notifications` → `case settings`
2. **Line 16** — Title: `case .notifications: return "Daily Reminders"` → `case .settings: return "Settings"`
3. **Line 23** — Description: `case .notifications: return "Get reminded before you go out."` → `case .settings: return "Set up notifications, replay the walkthrough, or add a widget."`
4. **Line 34** — scrollID: `case .notifications: return "features"` → `case .settings: return "settings"`

**ContentView.swift** (1 reference):

5. **Line 686** — Anchor preference: `.anchorPreference(key: SpotlightAnchorKey.self, value: .bounds) { [.notifications: $0] }` → move this modifier from the deleted first feature row to the new settings row, changing key to `[.settings: $0]`

The raw value stays at `3` (position is unchanged in the enum), so no data migration is needed.
