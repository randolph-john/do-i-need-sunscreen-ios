import SwiftUI

struct DoctorBackedView: View {
    @Binding var isPresented: Bool

    private let factors: [(title: String, description: String)] = [
        ("UV Index Measurement",
         "Real-time UV radiation levels from your exact location, updated hourly to reflect current atmospheric conditions."),
        ("Skin Type Classification",
         "Based on the scientifically-validated Fitzpatrick scale, which categorizes skin's response to UV exposure across six phototypes."),
        ("UV Dose Integration",
         "Calculates cumulative UV exposure over your planned outdoor duration using an advanced integration algorithm that accounts for changing UV levels throughout the day."),
        ("Minimal Erythema Dose (MED)",
         "Determines the UV radiation threshold that causes sunburn for your specific skin type, derived from dermatological research."),
        ("Cloud Cover Effects",
         "Adjusts UV exposure based on cloud density, accounting for both UV attenuation and scattering effects from atmospheric conditions."),
        ("Surface Reflection",
         "Incorporates UV albedo from surrounding surfaces like snow, sand, water, and grass, which can significantly increase total UV exposure."),
        ("Altitude Adjustment",
         "Accounts for increased UV intensity at higher elevations, where the thinner atmosphere provides less UV protection."),
        ("Time-Weighted Analysis",
         "Considers the specific time of day and duration of outdoor exposure, factoring in the sun's angle and intensity variations.")
    ]

    private let papers: [(title: String, journal: String, year: String?, url: String)] = [
        ("UV radiation and the skin",
         "Photochemical & Photobiological Sciences",
         "2018",
         "https://pubs.rsc.org/en/content/articlehtml/2018/pp/c7pp00374a"),
        ("Fitzpatrick Skin Type and Minimal Erythema Dose",
         "eScholarship University of California",
         nil,
         "https://escholarship.org/uc/item/5925w4hq"),
        ("Sunburn Protection Factor (SPF): Mathematics and In Vitro Methods",
         "PMC - National Center for Biotechnology Information",
         "2018",
         "https://pmc.ncbi.nlm.nih.gov/articles/PMC6069363/"),
        ("Spectral UV Albedo for Environmental Surfaces",
         "ResearchGate",
         nil,
         "https://www.researchgate.net/figure/Spectral-UV-albedo-for-a-sand-b-earth-c-grass-and-d-snow-The-data-has-been_fig1_326469577"),
        ("UV Exposure and Protection Against Skin Damage",
         "PMC - National Center for Biotechnology Information",
         "2019",
         "https://pmc.ncbi.nlm.nih.gov/articles/PMC6736991/")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Our sunscreen recommendations are powered by a sophisticated algorithm that integrates multiple scientific factors to provide personalized UV protection guidance.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    // Algorithm Factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Algorithm factors")
                            .font(.system(size: 20, weight: .semibold))

                        ForEach(Array(factors.enumerated()), id: \.offset) { _, factor in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(factor.title)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(factor.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Scientific Research
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scientific research")
                            .font(.system(size: 20, weight: .semibold))

                        Text("Our methodology is based on peer-reviewed research from leading dermatological and photobiological journals:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        ForEach(Array(papers.enumerated()), id: \.offset) { _, paper in
                            VStack(alignment: .leading, spacing: 2) {
                                Link(destination: URL(string: paper.url)!) {
                                    Text(paper.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#FFD700"))
                                        .multilineTextAlignment(.leading)
                                }
                                HStack(spacing: 0) {
                                    Text(paper.journal)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    if let year = paper.year {
                                        Text(" (\(year))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.bottom, 4)
                        }
                    }

                    // Disclaimer
                    Text("This app provides general guidance based on scientific research. Always consult with healthcare professionals for personalized medical advice.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Evidence-based UV protection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}
