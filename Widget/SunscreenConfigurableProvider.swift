import WidgetKit
import WeatherKit
import CoreLocation

struct SunscreenEntry: TimelineEntry {
    let date: Date
    let needsSunscreen: Bool
    let uvIndex: Double
    let safeExposureMinutes: Int?
    let isPlaceholder: Bool
    var mode: WidgetMode = .now
    var scheduledTimeLabel: String? = nil

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

struct SunscreenConfigurableProvider: AppIntentTimelineProvider {
    let locationManager = CLLocationManager()

    func placeholder(in context: Context) -> SunscreenEntry {
        .placeholder
    }

    func snapshot(for configuration: SunscreenWidgetIntent, in context: Context) async -> SunscreenEntry {
        if context.isPreview {
            return .placeholder
        }
        return await fetchEntry(mode: configuration.mode)
    }

    func timeline(for configuration: SunscreenWidgetIntent, in context: Context) async -> Timeline<SunscreenEntry> {
        let entry = await fetchEntry(mode: configuration.mode)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date) ?? entry.date
        return Timeline(entries: [entry], policy: .after(nextUpdate))
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

    private func fetchEntry(mode: WidgetMode) async -> SunscreenEntry {
        guard let location = getLocation() else {
            return .placeholder
        }

        let preferences = UserPreferences()
        let weatherService = WeatherKit.WeatherService.shared

        do {
            let weather = try await weatherService.weather(for: location)
            let uvIndex = Double(weather.currentWeather.uvIndex.value)

            let forecast = weather.hourlyForecast.forecast.prefix(48).map { hour in
                HourlyUV(
                    date: hour.date,
                    uvIndex: Double(hour.uvIndex.value),
                    cloudCover: mapCloudCover(hour.cloudCover)
                )
            }

            let startTime: Date
            let duration: Double
            var scheduledTimeLabel: String? = nil

            switch mode {
            case .now:
                startTime = Date()
                duration = preferences.durationMinutes
            case .scheduled:
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = preferences.notificationStartHour
                components.minute = preferences.notificationStartMinute
                let today = calendar.date(from: components) ?? Date()
                startTime = today > Date() ? today : calendar.date(byAdding: .day, value: 1, to: today)!
                duration = preferences.notificationDurationMinutes

                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                scheduledTimeLabel = formatter.string(from: startTime)
            }

            let needs: Bool
            let safeTime: Int?

            if !forecast.isEmpty {
                needs = SunscreenAlgorithm.needsSunscreen(
                    hourlyForecast: Array(forecast),
                    startTime: startTime,
                    skinType: preferences.skinType,
                    durationMinutes: duration,
                    surface: preferences.surface,
                    elevationFeet: preferences.elevationFeet,
                    otherFactors: preferences.otherFactors
                )
                safeTime = SunscreenAlgorithm.safeExposureTime(
                    hourlyForecast: Array(forecast),
                    startTime: startTime,
                    skinType: preferences.skinType,
                    surface: preferences.surface,
                    elevationFeet: preferences.elevationFeet,
                    otherFactors: preferences.otherFactors
                )
            } else {
                let cloudCover = mapCloudCover(weather.currentWeather.cloudCover)
                needs = SunscreenAlgorithm.needsSunscreen(
                    uvIndex: uvIndex,
                    skinType: preferences.skinType,
                    durationMinutes: duration,
                    cloudCover: cloudCover,
                    surface: preferences.surface,
                    elevationFeet: preferences.elevationFeet,
                    otherFactors: preferences.otherFactors
                )
                safeTime = SunscreenAlgorithm.safeExposureTime(
                    uvIndex: uvIndex,
                    skinType: preferences.skinType,
                    cloudCover: cloudCover,
                    surface: preferences.surface,
                    elevationFeet: preferences.elevationFeet,
                    otherFactors: preferences.otherFactors
                )
            }

            return SunscreenEntry(
                date: Date(),
                needsSunscreen: needs,
                uvIndex: uvIndex,
                safeExposureMinutes: safeTime,
                isPlaceholder: false,
                mode: mode,
                scheduledTimeLabel: scheduledTimeLabel
            )
        } catch {
            return .placeholder
        }
    }
}
