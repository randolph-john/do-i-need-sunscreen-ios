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

    private func fetchEntry(completion: @escaping (SunscreenEntry) -> Void) {
        let locationManager = CLLocationManager()
        guard let location = locationManager.location else {
            completion(.placeholder)
            return
        }

        let preferences = UserPreferences()
        let weatherService = WeatherKit.WeatherService.shared

        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                let uvIndex = Double(weather.currentWeather.uvIndex.value)

                let cloudFraction = weather.currentWeather.cloudCover
                let cloudCover: CloudCover
                switch cloudFraction {
                case 0..<0.25: cloudCover = .clear
                case 0.25..<0.50: cloudCover = .scattered
                case 0.50..<0.875: cloudCover = .broken
                default: cloudCover = .overcast
                }

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
