import WeatherKit
import CoreLocation

struct HourlyUVData: Identifiable {
    let id = UUID()
    let date: Date
    let uvIndex: Double
    let cloudCover: Double
    let isDaylight: Bool
}

class WeatherService: ObservableObject {
    @Published var uvIndex: Double = 0
    @Published var cloudCover: CloudCover = .clear
    @Published var isDaylight: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hourlyForecast: [HourlyUVData] = []

    private let service = WeatherKit.WeatherService.shared

    @MainActor
    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil

        do {
            let weather = try await service.weather(for: location)
            uvIndex = Double(weather.currentWeather.uvIndex.value)
            cloudCover = mapCloudCover(weather.currentWeather.cloudCover)
            isDaylight = weather.currentWeather.isDaylight

            // Store hourly forecast
            hourlyForecast = weather.hourlyForecast.forecast.prefix(48).map { hour in
                HourlyUVData(
                    date: hour.date,
                    uvIndex: Double(hour.uvIndex.value),
                    cloudCover: hour.cloudCover,
                    isDaylight: hour.isDaylight
                )
            }

            isLoading = false
        } catch {
            errorMessage = "Unable to fetch weather data: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Look up data for a specific time from hourly forecast
    private func forecastEntry(at date: Date) -> HourlyUVData? {
        let closest = hourlyForecast.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
        guard let entry = closest,
              abs(entry.date.timeIntervalSince(date)) < 3600 else {
            return nil
        }
        return entry
    }

    /// Update displayed UV data for a selected time
    @MainActor
    func selectTime(_ date: Date?) {
        guard let date = date else {
            // Reset to current
            if let now = forecastEntry(at: Date()) {
                uvIndex = now.uvIndex
                cloudCover = mapCloudCover(now.cloudCover)
                isDaylight = now.isDaylight
            }
            return
        }
        if let entry = forecastEntry(at: date) {
            uvIndex = entry.uvIndex
            cloudCover = mapCloudCover(entry.cloudCover)
            isDaylight = entry.isDaylight
        }
    }

    private func mapCloudCover(_ fraction: Double) -> CloudCover {
        switch fraction {
        case 0..<0.25: return .clear
        case 0.25..<0.50: return .scattered
        case 0.50..<0.875: return .broken
        default: return .overcast
        }
    }
}
