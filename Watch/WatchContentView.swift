import SwiftUI
import CoreLocation

struct WatchContentView: View {
    @StateObject private var locationManager = WatchLocationManager()
    @StateObject private var weatherService = WatchWeatherService()
    @State private var preferences = UserPreferences()
    @State private var locationFailed = false

    private var isDark: Bool {
        guard let location = locationManager.location else {
            return weatherService.uvIndex == 0
        }
        return !SolarCalculator.isDaylight(at: Date(), latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    private var bgColor: Color {
        uvBackgroundColor(uvIndex: weatherService.uvIndex, isDark: isDark)
    }

    private var textColor: Color {
        uvTextColor(uvIndex: weatherService.uvIndex, isDark: isDark)
    }

    private var result: SunscreenResult {
        let forecast = weatherService.hourlyForecast

        let needs: Bool
        let safeTime: Int?

        if !forecast.isEmpty {
            needs = SunscreenAlgorithm.needsSunscreen(
                hourlyForecast: forecast,
                startTime: Date(),
                skinType: preferences.skinType,
                durationMinutes: preferences.durationMinutes,
                surface: preferences.surface,
                elevationFeet: preferences.elevationFeet,
                otherFactors: preferences.otherFactors
            )
            safeTime = SunscreenAlgorithm.safeExposureTime(
                hourlyForecast: forecast,
                startTime: Date(),
                skinType: preferences.skinType,
                surface: preferences.surface,
                elevationFeet: preferences.elevationFeet,
                otherFactors: preferences.otherFactors
            )
        } else {
            needs = SunscreenAlgorithm.needsSunscreen(
                uvIndex: weatherService.uvIndex,
                skinType: preferences.skinType,
                durationMinutes: preferences.durationMinutes,
                cloudCover: weatherService.cloudCover,
                surface: preferences.surface,
                elevationFeet: preferences.elevationFeet,
                otherFactors: preferences.otherFactors
            )
            safeTime = SunscreenAlgorithm.safeExposureTime(
                uvIndex: weatherService.uvIndex,
                skinType: preferences.skinType,
                cloudCover: weatherService.cloudCover,
                surface: preferences.surface,
                elevationFeet: preferences.elevationFeet,
                otherFactors: preferences.otherFactors
            )
        }

        let reapply = SunscreenAlgorithm.reapplicationTime(
            uvIndex: weatherService.uvIndex,
            skinType: preferences.skinType,
            durationMinutes: preferences.durationMinutes
        )
        return SunscreenResult(
            needsSunscreen: needs,
            uvIndex: weatherService.uvIndex,
            safeExposureMinutes: safeTime,
            reapplicationMinutes: reapply
        )
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if weatherService.isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(textColor)
                    Text("Getting UV data...")
                        .font(.system(size: 12))
                        .foregroundColor(textColor.opacity(0.7))
                }
            } else if locationFailed && locationManager.location == nil {
                VStack(spacing: 8) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 24))
                        .foregroundColor(textColor.opacity(0.7))
                    Text("No location")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                    Text("Open the iPhone app first")
                        .font(.system(size: 11))
                        .foregroundColor(textColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 6) {
                    Text(result.needsSunscreen ? "YES" : "NO")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(textColor)

                    Text("UV \(Int(weatherService.uvIndex))")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(textColor.opacity(0.9))

                    if result.needsSunscreen, let safeMin = result.safeExposureMinutes, safeMin > 0 {
                        Text("Apply in \(SunscreenAlgorithm.formatDuration(minutes: safeMin))")
                            .font(.system(size: 13))
                            .foregroundColor(textColor.opacity(0.8))
                    }

                    if let name = locationManager.locationName {
                        Text(name)
                            .font(.system(size: 12))
                            .foregroundColor(textColor.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.location) {
            guard let location = locationManager.location else { return }
            Task {
                await weatherService.fetchWeather(for: location)
            }
        }
        .onChange(of: locationManager.didFail) {
            if locationManager.didFail && locationManager.location == nil {
                locationFailed = true
            }
        }
    }
}
