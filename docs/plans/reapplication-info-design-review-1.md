VERDICT: NEEDS_REVISION

## Summary Assessment

The design is well-reasoned in its core decision to present information rather than a timer, and the scientific framing is mostly responsible. However, there is a significant internal contradiction: the codebase already contains a `reapplicationTime()` algorithm that produces the exact kind of scientifically-unsupported time-based output the design argues against, and the design explicitly says "No algorithm changes." This must be addressed, or the app will simultaneously tell users that time-based reapplication is scientifically invalid while computing a time-based reapplication value behind the scenes.

## Critical Issues (must fix)

### 1. Internal contradiction with existing `reapplicationTime()` algorithm

The design states "No algorithm changes" and "No time-based reapplication interval," yet `SunscreenAlgorithm.reapplicationTime()` (lines 267-278 of SunscreenAlgorithm.swift) already exists and computes exactly the kind of arbitrary time-based interval the design argues has no scientific basis. It returns 120/90/60 minutes based on UV thresholds -- pure heuristic with no citations. The `SunscreenResult` struct stores the output in `reapplicationMinutes`, and both ContentView (line 299) and WatchContentView (line 69) compute it on every render cycle.

Currently `reapplicationMinutes` is dead code -- it is computed but never displayed anywhere. But having it exist while adding a modal that says "there is no scientifically validated algorithm for reapplication timing" is contradictory and a maintenance hazard. Someone could surface that value in UI at any time.

The design should explicitly decide: remove `reapplicationTime()` and the `reapplicationMinutes` field, or at minimum acknowledge the contradiction and plan its deprecation.

### 2. Misleading characterization of the JDD 2018 study findings

The design says: "A clinical trial found SPF 70 retained SPF 64 after 8 hours -- even after exercise and water immersion. The chemical protection barely degrades."

This cherry-picks the best-case result. The same study found:
- At the FDA-standard 2 mg/cm2 application: SPF 70 retained SPF 64 (the cited figure)
- At realistic 1 mg/cm2 application: SPF 70 retained only SPF 26
- Overall decline across both products was 15-40%

Presenting only the 2 mg/cm2 result while simultaneously telling users "most people under-apply" in the very next point is internally inconsistent. At realistic application amounts, SPF degradation is substantially worse. The "barely degrades" characterization is overstated for real-world use.

Recommendation: Either present the realistic-application numbers alongside the lab numbers, or reframe as "Under laboratory application amounts, SPF 70 retained SPF 64 after 8 hours -- but at amounts people actually apply, retention was lower." The scientific honesty standard the user set demands this nuance.

### 3. Misleading comment in existing codebase that the design perpetuates

Line 385 of ContentView.swift has the comment `// Reapplication time` above code that actually displays **safe exposure time** (the time before sunburn without sunscreen). The design proposes placing the new reapplication info button "below the existing 'Apply within X to avoid burn' text" -- which is the safe-exposure-time text, not reapplication time. These are fundamentally different concepts (time before initial burn vs. when to reapply already-applied sunscreen).

The design should be precise about this distinction. Users who tap "What about reapplication?" after seeing "Apply within 45min to avoid burn" need to understand these are different concepts: the 45 minutes is about unprotected exposure, not sunscreen wearing off.

## Suggestions (nice to have)

### 1. Consider mentioning photodegradation variability in the modal

The "Scientific basis" section at the bottom of the design correctly notes that photodegradation rates vary by formulation (avobenzone vs mineral). This is a strong argument against a timer, but the user-facing modal content does not mention it. Adding a brief note like "Different sunscreen ingredients degrade at different rates, making a one-size-fits-all timer unreliable" would strengthen the educational value.

### 2. The PLOS ONE citation is a weak match for the under-application claim

The PLOS ONE 2018 study ("Sunscreen use optimized by two consecutive applications") found people applied 0.60 mg/cm2 -- roughly 30% of the 2 mg/cm2 standard, not "about half." The "half" figure is commonly cited from other literature (e.g., Autier et al. 2007). The PLOS ONE study is really about how two consecutive applications improve coverage. Consider either finding a more directly supporting citation for the "half" claim, or adjusting the text to "about a quarter to a half."

### 3. Six `.sheet` modifiers on one view -- consider future refactoring

Adding a sixth `.sheet` to ContentView is fine for now but worth noting. SwiftUI sheet presentation can have subtle issues when many sheets compete on the same view, especially on older iOS versions. No action needed for this feature, but a note in the design acknowledging ContentView's growing complexity would be useful context.

### 4. The button placement may need a fallback for the nighttime/zero-UV case

The button is gated on `result.needsSunscreen == true`. Users who open the app at night or in low-UV conditions have no way to access the reapplication information. Consider whether the modal should also be accessible from `featuresSection` (alongside "Walkthrough," "Add widget," etc.) so it is always reachable. Users who applied sunscreen earlier in the day might want this information at night.

### 5. Consider bridging to the FDA/AAD "every 2 hours" guideline

The opening line ("The common advice is to reapply every 2 hours -- but the science is more nuanced than that") could be read as dismissing FDA/AAD guidance. While the design's scientific basis section correctly explains the rationale, the modal content itself does not circle back to acknowledge why the guideline exists (conservative safety margin, under-application compensation). A brief closing note like "The 2-hour guideline exists as a conservative safety margin -- it may be more frequent than necessary for some situations, but erring on the side of caution is reasonable" would avoid positioning the app as contradicting official health guidance.

## Verified Claims (things I confirmed are correct)

1. **Button color `#4A90E2` matches existing "change" links.** Confirmed -- ContentView uses this exact hex in five places for the location change, reset, and time change buttons.

2. **DoctorBackedView pattern is correct.** The design accurately describes following its structure: NavigationView, ScrollView, Done toolbar button, gold-colored links, disclaimer text. The existing view at `App/DoctorBackedView.swift` uses exactly this pattern.

3. **No existing reapplication UI is displayed.** Despite `reapplicationMinutes` being computed, no view in the app, watch, or widget reads or displays this value. The design is correct that adding an informational modal does not conflict with any currently visible UI.

4. **The "Apply within X to avoid burn" text exists where described.** ContentView heroSection line 387 shows this text, gated on `result.needsSunscreen` and `safeExposureMinutes > 0`, confirming the design's proposed button placement is viable.

5. **New file does not need project.yml changes.** The `App/` directory is already a source path for the main target (project.yml line 18: `- path: App`). Adding `App/ReapplicationInfoView.swift` will be picked up automatically by XcodeGen.

6. **SPF is indeed a dose ratio, not a time multiplier.** The design's scientific basis correctly characterizes SPF as MED protected / MED unprotected, matching the algorithm's own use of MED values in SunscreenAlgorithm.swift.

7. **The FDA/AAD "every 2 hours" guideline lacks a specific supporting study.** This is accurate -- the guideline is a conservative recommendation, not derived from a specific clinical trial measuring reapplication timing.
