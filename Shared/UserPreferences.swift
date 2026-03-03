import Foundation
import WidgetKit

class UserPreferences: ObservableObject {
    private static let suiteName = "group.com.sunscreenfyi.shared"

    private let defaults: UserDefaults

    @Published var skinType: SkinType {
        didSet { defaults.set(skinType.rawValue, forKey: "skinType"); reloadWidgets() }
    }

    @Published var durationMinutes: Double {
        didSet { defaults.set(durationMinutes, forKey: "durationMinutes"); reloadWidgets() }
    }

    @Published var surface: SurfaceType {
        didSet { defaults.set(surface.rawValue, forKey: "surface"); reloadWidgets() }
    }

    @Published var elevationFeet: Double {
        didSet { defaults.set(elevationFeet, forKey: "elevationFeet"); reloadWidgets() }
    }

    @Published var otherFactors: Set<OtherFactor> {
        didSet {
            let rawValues = otherFactors.map { $0.rawValue }
            defaults.set(rawValues, forKey: "otherFactors")
            reloadWidgets()
        }
    }

    @Published var hasCompletedQuiz: Bool {
        didSet { defaults.set(hasCompletedQuiz, forKey: "hasCompletedQuiz") }
    }

    init() {
        let defaults = UserDefaults(suiteName: UserPreferences.suiteName) ?? UserDefaults.standard
        self.defaults = defaults

        let rawSkinType = defaults.integer(forKey: "skinType")
        self.skinType = SkinType(rawValue: rawSkinType) ?? .typeII

        let duration = defaults.double(forKey: "durationMinutes")
        self.durationMinutes = duration > 0 ? duration : 60

        let rawSurface = defaults.string(forKey: "surface") ?? ""
        self.surface = SurfaceType(rawValue: rawSurface) ?? .none

        self.elevationFeet = defaults.double(forKey: "elevationFeet")

        let rawFactors = defaults.stringArray(forKey: "otherFactors") ?? []
        self.otherFactors = Set(rawFactors.compactMap { OtherFactor(rawValue: $0) })

        self.hasCompletedQuiz = defaults.bool(forKey: "hasCompletedQuiz")
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
