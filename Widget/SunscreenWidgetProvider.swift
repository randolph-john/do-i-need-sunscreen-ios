import WidgetKit
import WeatherKit
import CoreLocation

struct SunscreenEntry: TimelineEntry {
    let date: Date
    let needsSunscreen: Bool
    let uvIndex: Double
    let safeExposureMinutes: Int?
    let isPlaceholder: Bool

    static var placeholder: SunscreenEntry {
        SunscreenEntry(
            date: Date(),
            needsSunscreen: false,
            uvIndex: 0,
            safeExposureMinutes: nil,
            isPlaceholder: true
        )
    }
}

struct SunscreenWidgetProvider: TimelineProvider {
    let locationManager = CLLocationManager()

    func placeholder(in context: Context) -> SunscreenEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SunscreenEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        fetchEntry { entry in
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SunscreenEntry>) -> Void) {
        fetchEntry { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date) ?? entry.date
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func getLocation() -> CLLocation? {
        // Try CLLocationManager first
        if let location = locationManager.location {
            return location
        }

        // Fall back to last known location saved by the main app
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

    private func fetchEntry(completion: @escaping (SunscreenEntry) -> Void) {
        guard let location = getLocation() else {
            completion(.placeholder)
            return
        }

        let preferences = UserPreferences()
        let weatherService = WeatherKit.WeatherService.shared

        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                let uvIndex = Double(weather.currentWeather.uvIndex.value)
                let cloudCover = mapCloudCover(weather.currentWeather.cloudCover)

                // Use live cloud cover from WeatherKit, other settings from user preferences
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

                let entry = SunscreenEntry(
                    date: Date(),
                    needsSunscreen: needs,
                    uvIndex: uvIndex,
                    safeExposureMinutes: safeTime,
                    isPlaceholder: false
                )
                completion(entry)
            } catch {
                completion(.placeholder)
            }
        }
    }
}
