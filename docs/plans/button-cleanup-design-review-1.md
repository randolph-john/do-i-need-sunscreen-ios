VERDICT: NEEDS_REVISION

## Summary Assessment

The overall goal of eliminating the features section is sound and will meaningfully declutter the UI, but the design has a critical presentation conflict (launching overlays from within a sheet), a factual error about existing UI, and underspecifies the new SettingsView enough that implementation will hit questions immediately.

## Critical Issues (must fix)

### 1. WidgetGuideView and walkthrough cannot be launched from inside a Settings sheet

The design says SettingsView (presented as a `.sheet`) should contain buttons for "Replay walkthrough" and "Widget setup guide." Both of these are currently triggered via state variables (`showTour`, `showWidgetGuide`) that drive full-screen overlays attached to the root `ZStack` via `.overlayPreferenceValue`. 

SwiftUI does not allow an overlay on the root view to display on top of a presented sheet. If the user taps "Replay walkthrough" inside the Settings sheet, the sheet would need to dismiss first, and only then should `showTour` be set to `true`. The same applies to `showWidgetGuide`. The design does not specify this dismiss-then-trigger coordination pattern, and naive implementation (just setting the bool) will result in the overlay appearing behind the sheet or not at all.

**Recommendation:** Explicitly specify that tapping "Replay walkthrough" or "Widget setup guide" in Settings must (a) dismiss the Settings sheet, and (b) after dismissal completes, set `showTour`/`showWidgetGuide` to true. This requires either a completion callback on the sheet dismissal or a brief `DispatchQueue.main.asyncAfter` delay pattern (which the codebase already uses for `chainWidgetGuideAfterTour`). Define how SettingsView communicates these actions back to ContentView -- likely via closures or binding callbacks passed into the view, rather than having SettingsView directly mutate ContentView state.

### 2. "Skin Type Quiz in Controls Card" already exists -- design describes adding something that is already there

The design's section 2 says: "Add a 'What's my skin type?' text link in gold below the skin type selector inside the controls card." This button already exists at line 523 of ContentView.swift, inside the controls card's skin type slider section, styled as a blue italic link. The design either intends to restyle it (change from blue to gold, change position from inline to below) or is unaware it exists.

**Recommendation:** Clarify whether this section means (a) the existing link is sufficient and only the duplicate in the features section needs removal, or (b) the existing link should be restyled. If restyling, specify the exact change (color from `#4A90E2` to `#FFD700`? Move from HStack next to label to below the slider?). The current blue italic style matches other interactive links in the app (change/reset location, change time), so switching to gold may break visual consistency.

## Suggestions (nice to have)

### 1. Share icon placement and accessibility need more detail

The design says "a small `square.and.arrow.up` SF Symbol near the main result text in the hero section" but does not specify where "near" means. The hero section has multiple layout states (loading, not-determined, denied, authorized). The share icon should only appear in the authorized state, and the design should specify whether it goes next to the title, next to the YES/NO text, or as a trailing overlay. On small screens, adding an icon next to the 120pt YES/NO text could look awkward. Consider placing it as a small button in the top-right of the hero section instead.

Also, the `confirmationDialog` needs a title string (required by the SwiftUI API). The design should specify what that title should be (e.g., "Share result" or "Share your sunscreen status").

### 2. Settings row accessibility and discoverability

The design says the Settings row should be "styled similarly to the Backed by doctors button." Currently `backedByDoctorsButton` uses a stroked rounded rectangle with `textColor.opacity(0.7)` text. This is intentionally subtle. Having Settings also be this subtle may make it hard to discover for users who want to manage notifications. Consider whether Settings should be slightly more prominent, or whether the footer is a better home (since it already has tappable links and users scroll past it anyway).

### 3. Reapplication guide becomes unreachable when sunscreen is not needed

The design removes the reapplication row from the features section and relies solely on the "What about reapplication?" link in the hero section. But that link is conditionally shown only when `result.needsSunscreen == true` (line 391). This means users who don't currently need sunscreen have no way to access the reapplication guide at all. This may be intentional (why read about reapplication if you don't need sunscreen?), but it is a regression from the current design where the features section always shows the reapplication guide. The design should explicitly acknowledge this trade-off.

### 4. SettingsView needs more implementation detail

The design says SettingsView contains "Daily notifications -- existing enable/configure flow." Currently `NotificationSettingsView` is a standalone sheet with a `NavigationView`, `Form`, toolbar, and its own Done button. Does SettingsView embed this view inline, or does tapping "Daily notifications" in Settings open `NotificationSettingsView` as a nested navigation push? If SettingsView is a simple list with 3 items, the notification settings likely need to be a navigation push from within the Settings sheet. The design should specify this navigation pattern.

### 5. The `TutorialStep` enum rename from `.notifications` to `.settings`

The design mentions updating the enum case but does not call it out as a breaking rename. Since `TutorialStep` is `Int`-backed with `case notifications` at position 3, renaming to `.settings` is fine as long as the raw value stays the same. But the design should note that the `SpotlightAnchorKey` preference currently uses `.notifications` as the dictionary key (line 686 of ContentView), and all references to `.notifications` in both files need to change. There are 4 references in SpotlightOverlayView.swift (enum case, title, description, scrollID) and 1 in ContentView.swift (anchorPreference). This is straightforward but worth enumerating to avoid missing one.

### 6. Consider keeping `goldButtonLabel` if it would be useful in SettingsView

The design says to delete `goldButtonLabel` if unused elsewhere. Even after this change, the gold gradient button style appears in multiple places (share confirmation, other views). Consider extracting it into a reusable modifier rather than deleting it. This is minor and can be decided during implementation.

## Verified Claims

- **The `featureRow()` helper is only used within `featuresSection`** -- confirmed, only appears in ContentView.swift within the features section. Safe to delete.
- **The `goldButtonLabel()` helper is only used within `featuresSection`** -- confirmed, all 6 call sites are inside `featuresSection`. Safe to delete.
- **The `showShareSheet()` method is only called from `featuresSection`** -- confirmed, lines 758 and 775 are the only call sites, both inside the share result feature row. The method itself should be kept since the design reuses it via the confirmation dialog.
- **Walkthrough step 4 (`.notifications`) currently scrolls to `"features"` ID** -- confirmed at SpotlightOverlayView.swift line 34.
- **The anchor preference for `.notifications` is on the first featureRow (daily notifications row)** -- confirmed at ContentView.swift line 686.
- **The `chainWidgetGuideAfterTour` pattern already exists** -- confirmed, the codebase already uses a dismiss-then-trigger pattern with `DispatchQueue.main.asyncAfter` delay (lines 129-133 of ContentView.swift). This pattern should be reused for the Settings sheet interactions.
- **The reapplication link in the hero section is conditional on `result.needsSunscreen`** -- confirmed at line 391.
