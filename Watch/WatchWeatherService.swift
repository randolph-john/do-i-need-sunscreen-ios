import WeatherKit
import CoreLocation

class WatchWeatherService: ObservableObject {
    @Published var uvIndex: Double = 0
    @Published var cloudCover: CloudCover = .clear
    @Published var cloudCoverPercent: Int = 0
    @Published var isLoading: Bool = false
    @Published var hourlyForecast: [HourlyUV] = []

    private let service = WeatherKit.WeatherService.shared

    @MainActor
    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        do {
            let weather = try await service.weather(for: location)
            uvIndex = Double(weather.currentWeather.uvIndex.value)
            cloudCover = mapCloudCover(weather.currentWeather.cloudCover)
            cloudCoverPercent = Int(round(weather.currentWeather.cloudCover * 100))

            hourlyForecast = weather.hourlyForecast.forecast.prefix(48).map { hour in
                HourlyUV(
                    date: hour.date,
                    uvIndex: Double(hour.uvIndex.value),
                    cloudCover: mapCloudCover(hour.cloudCover)
                )
            }

            isLoading = false
        } catch {
            isLoading = false
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
