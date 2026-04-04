import SwiftUI

struct ReapplicationInfoView: View {
    @Binding var isPresented: Bool

    private let findings: [(title: String, description: String)] = [
        ("Sunscreen itself is durable",
         "SPF 70 stays at SPF 64 after 8 hours, even after exercise and water immersion."),
        ("Physical removal is the real problem",
         "Swimming, sweating, and toweling off wipe sunscreen from your skin. That's how protection is lost, not the sunscreen breaking down chemically."),
        ("Most people under-apply",
         "Most people apply less than half the recommended amount. Apply enough the first time and skip the reapplication.")
    ]

    private let reapplyTriggers: [(icon: String, text: String)] = [
        ("figure.pool.swim", "After swimming"),
        ("drop.fill", "After heavy sweating"),
        ("hands.and.sparkles.fill", "After toweling off or rubbing your skin"),
        ("checkmark.circle", "Otherwise, you don't need to reapply")
    ]

    private let sources: [(title: String, journal: String, year: String?, url: String)] = [
        ("Realistic Sunscreen Durability: A Randomized, Double-blinded Controlled Clinical Study",
         "Journal of Drugs in Dermatology",
         "2018",
         "https://jddonline.com/articles/realistic-sunscreen-durability-a-randomized-double-blinded-controlled-clinical-study-S1545961618P0116X/"),
        ("Sunscreen use optimized by two consecutive applications",
         "PLOS ONE",
         "2018",
         "https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0193916"),
        ("Sunscreen: How to Help Protect Your Skin from the Sun",
         "U.S. Food & Drug Administration",
         nil,
         "https://www.fda.gov/drugs/understanding-over-counter-medicines/sunscreen-how-help-protect-your-skin-sun"),
        ("How to apply sunscreen",
         "American Academy of Dermatology",
         nil,
         "https://www.aad.org/public/everyday-care/sun-protection/shade-clothing-sunscreen/how-to-apply-sunscreen")
    ]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // When to reapply
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When to reapply")
                            .font(.system(size: 20, weight: .semibold))

                        ForEach(Array(reapplyTriggers.enumerated()), id: \.offset) { _, trigger in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: trigger.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#FFD700"))
                                    .frame(width: 24)
                                Text(trigger.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                        }
                    }

                    // What the research shows
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What the research shows")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.top, 8)

                        ForEach(Array(findings.enumerated()), id: \.offset) { _, finding in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(finding.title)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(finding.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // The two hour rule
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The two hour rule")
                            .font(.system(size: 15, weight: .semibold))
                        Text("The FDA and AAD recommend reapplying every 2 hours, but the evidence suggests this rule of thumb is overly cautious.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    // Sources — pushed just offscreen
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sources")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)

                        ForEach(Array(sources.enumerated()), id: \.offset) { _, source in
                            Link(destination: URL(string: source.url)!) {
                                (Text(source.title)
                                    .foregroundColor(Color(hex: "#FFD700"))
                                + Text(" — " + source.journal + (source.year.map { " (\($0))" } ?? ""))
                                    .foregroundColor(.secondary))
                                    .font(.system(size: 11))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding(.top, max(0, geometry.size.height - 520))
                    Text("This app provides general guidance based on scientific research. Always consult with healthcare professionals for personalized medical advice.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            } // GeometryReader
            .navigationTitle("Sunscreen reapplication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}
