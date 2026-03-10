import WidgetKit
import WeatherKit
import CoreLocation

struct WatchWidgetEntry: TimelineEntry {
    let date: Date
    let needsSunscreen: Bool
    let uvIndex: Double
    let safeExposureMinutes: Int?

    static var placeholder: WatchWidgetEntry {
        WatchWidgetEntry(date: Date(), needsSunscreen: false, uvIndex: 0, safeExposureMinutes: nil)
    }
}

struct WatchWidgetProvider: TimelineProvider {
    let locationManager = CLLocationManager()

    func placeholder(in context: Context) -> WatchWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchWidgetEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func getLocation() -> CLLocation? {
        if let location = locationManager.location {
            return location
        }
        let defaults = UserDefaults(suiteName: "group.com.sunscreenfyi.shared")
        guard let lat = defaults?.object(forKey: "lastLatitude") as? Double,
              let lon = defaults?.object(forKey: "lastLongitude") as? Double else {
            return nil
        }
        return CLLocation(latitude: lat, longitude: lon)
    }

    private func mapCloudCover(_ fraction: Double) -> CloudCover {
        switch fraction {
        case 0..<0.25: return .clear
        case 0.25..<0.50: return .scattered
        case 0.50..<0.875: return .broken
        default: return .overcast
        }
    }

    private func fetchEntry() async -> WatchWidgetEntry {
        guard let location = getLocation() else {
            return .placeholder
        }

        let preferences = UserPreferences()
        let weatherService = WeatherKit.WeatherService.shared

        do {
            let weather = try await weatherService.weather(for: location)
            let uvIndex = Double(weather.currentWeather.uvIndex.value)
            let cloudCover = mapCloudCover(weather.currentWeather.cloudCover)

            let needs = SunscreenAlgorithm.needsSunscreen(
                uvIndex: uvIndex,
                skinType: preferences.skinType,
                durationMinutes: preferences.durationMinutes,
                cloudCover: cloudCover,
                surface: preferences.surface,
                elevationFeet: preferences.elevationFeet,
                otherFactors: preferences.otherFactors
            )
            let safeTime = SunscreenAlgorithm.safeExposureTime(
                uvIndex: uvIndex,
                skinType: preferences.skinType,
                cloudCover: cloudCover,
                surface: preferences.surface,
                elevationFeet: preferences.elevationFeet,
                otherFactors: preferences.otherFactors
            )

            return WatchWidgetEntry(
                date: Date(),
                needsSunscreen: needs,
                uvIndex: uvIndex,
                safeExposureMinutes: safeTime
            )
        } catch {
            return .placeholder
        }
    }
}
