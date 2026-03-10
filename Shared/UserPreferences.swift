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

    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
            reloadWidgets()
            NotificationCenter.default.post(name: Notification.Name("NotificationPreferencesChanged"), object: nil)
        }
    }

    @Published var notificationHour: Int {
        didSet {
            defaults.set(notificationHour, forKey: "notificationHour")
            reloadWidgets()
            NotificationCenter.default.post(name: Notification.Name("NotificationPreferencesChanged"), object: nil)
        }
    }

    @Published var notificationMinute: Int {
        didSet {
            defaults.set(notificationMinute, forKey: "notificationMinute")
            reloadWidgets()
            NotificationCenter.default.post(name: Notification.Name("NotificationPreferencesChanged"), object: nil)
        }
    }

    @Published var notificationDurationMinutes: Double {
        didSet {
            defaults.set(notificationDurationMinutes, forKey: "notificationDurationMinutes")
            reloadWidgets()
            NotificationCenter.default.post(name: Notification.Name("NotificationPreferencesChanged"), object: nil)
        }
    }

    @Published var notificationStartHour: Int {
        didSet {
            defaults.set(notificationStartHour, forKey: "notificationStartHour")
            reloadWidgets()
            NotificationCenter.default.post(name: Notification.Name("NotificationPreferencesChanged"), object: nil)
        }
    }

    @Published var notificationStartMinute: Int {
        didSet {
            defaults.set(notificationStartMinute, forKey: "notificationStartMinute")
            reloadWidgets()
            NotificationCenter.default.post(name: Notification.Name("NotificationPreferencesChanged"), object: nil)
        }
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

        self.notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")

        let savedHour = defaults.object(forKey: "notificationHour") as? Int ?? 8
        self.notificationHour = savedHour

        let savedMinute = defaults.object(forKey: "notificationMinute") as? Int ?? 0
        self.notificationMinute = savedMinute

        let savedNotifDuration = defaults.double(forKey: "notificationDurationMinutes")
        self.notificationDurationMinutes = savedNotifDuration > 0 ? savedNotifDuration : 60

        let savedStartHour = defaults.object(forKey: "notificationStartHour") as? Int ?? 12
        self.notificationStartHour = savedStartHour

        let savedStartMinute = defaults.object(forKey: "notificationStartMinute") as? Int ?? 0
        self.notificationStartMinute = savedStartMinute
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
