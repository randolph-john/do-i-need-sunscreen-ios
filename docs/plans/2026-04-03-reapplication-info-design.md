# Reapplication Info Modal — Design Document

## Goal

Add a "What about reapplication?" button to the hero section that opens a modal explaining the science of sunscreen reapplication. The key insight: there is no scientifically validated algorithm to calculate precise reapplication timing based on SPF/UV/skin type, so rather than building a timer with false precision, we inform users with what the research actually shows.

## Placement & Trigger

- Button appears in `heroSection` of ContentView, below the existing "Apply within X to avoid burn" text
- Only visible when `result.needsSunscreen == true`
- Styled as a subtle italic blue link (`#4A90E2`), matching existing "change" links
- Tapping opens a `.sheet` modal

## Modal Content: `ReapplicationInfoView`

### Title (nav bar): "Sunscreen reapplication"

### Opening line
"The common advice is to reapply every 2 hours — but the science is more nuanced than that."

### Section 1: "What the research shows"
Three findings, each with a bold headline + 1-2 sentence explanation:

1. **Sunscreen itself is durable.** A clinical trial found SPF 70 retained SPF 64 after 8 hours — even after exercise and water immersion. The chemical protection barely degrades.
2. **Physical removal is the real problem.** Swimming, sweating, toweling off, and friction physically wipe sunscreen away. This matters more than any timer.
3. **Most people under-apply.** Studies show people apply about half the tested amount, effectively halving their SPF. Reapplication partly compensates for this.

### Section 2: "When to reapply"
Activity-based checklist (no time-based interval):

- **Immediately** after swimming, heavy sweating, or toweling off
- **After any activity** that could rub it off (sand, clothing friction, touching your face)

### Section 3: "Sources"
Links to key studies, styled with gold links matching DoctorBackedView:

1. "Realistic Sunscreen Durability: A Randomized, Double-blinded Controlled Clinical Study" — Journal of Drugs in Dermatology (2018) — https://jddonline.com/articles/realistic-sunscreen-durability-a-randomized-double-blinded-controlled-clinical-study-S1545961618P0116X/
2. "Sunscreen use optimized by two consecutive applications" — PLOS ONE (2018) — https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0193916
3. "Sunscreen: How to Help Protect Your Skin from the Sun" — FDA — https://www.fda.gov/drugs/understanding-over-counter-medicines/sunscreen-how-help-protect-your-skin-sun
4. "How to apply sunscreen" — American Academy of Dermatology — https://www.aad.org/public/everyday-care/sun-protection/shade-clothing-sunscreen/how-to-apply-sunscreen

### Footer disclaimer
"This app provides general guidance based on scientific research. Always consult with healthcare professionals for personalized medical advice."

## Implementation

1. Add `@State private var showReapplicationInfo = false` to ContentView
2. Add button in `heroSection` after the "Apply within X" text, gated on `result.needsSunscreen`
3. Create `App/ReapplicationInfoView.swift` — new sheet modal following `DoctorBackedView` pattern (NavigationView, ScrollView, Done button, same typography)
4. Add `.sheet(isPresented: $showReapplicationInfo)` alongside existing sheets

## What this does NOT include

- No reapplication timer or countdown
- No SPF input from the user
- No algorithm changes
- No widget changes
- No changes to shared code

## Scientific basis for design decisions

- **No time-based reapplication interval**: The commonly cited "every 2 hours" is an FDA/AAD conservative guideline without a specific supporting study. Clinical evidence (JDD 2018) shows sunscreen retains 60-91% of its SPF after 8 hours. The main degradation mechanism is physical removal, not chemical breakdown.
- **Activity-based reapplication only**: Evidence supports that swimming, sweating, and mechanical friction are the primary causes of sunscreen loss. FDA water-resistance testing uses 40/80-minute immersion windows, confirming activity as the key trigger.
- **No SPF-based calculation**: SPF is a dose ratio (MED protected / MED unprotected), not a time multiplier. Using it to calculate reapplication time would give users false precision. Photodegradation rates vary enormously by formulation (avobenzone vs mineral filters), making any generic formula unreliable.
