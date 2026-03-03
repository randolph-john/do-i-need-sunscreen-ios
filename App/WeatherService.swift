import WeatherKit
import CoreLocation

class WeatherService: ObservableObject {
    @Published var uvIndex: Double = 0
    @Published var cloudCover: CloudCover = .clear
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let service = WeatherKit.WeatherService.shared

    @MainActor
    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil

        do {
            let weather = try await service.weather(for: location)
            uvIndex = Double(weather.currentWeather.uvIndex.value)
            cloudCover = mapCloudCover(weather.currentWeather.cloudCover)
            isLoading = false
        } catch {
            errorMessage = "Unable to fetch weather data: \(error.localizedDescription)"
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
