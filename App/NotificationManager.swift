import Foundation
import UserNotifications
import BackgroundTasks
import WeatherKit
import CoreLocation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private static let bgTaskIdentifier = "com.sunscreenfyi.DoINeedSunscreen.refreshNotification"
    private static let notificationId = "sunscreen-daily"

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined

    private var preferencesObserver: NSObjectProtocol?
    private var debounceWorkItem: DispatchWorkItem?

    private init() {
        refreshPermissionStatus()
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("NotificationPreferencesChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.debouncedSchedule()
        }
    }

    deinit {
        if let observer = preferencesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func refreshPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
            }
        }
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            await MainActor.run {
                self.permissionStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            return false
        }
    }

    /// Debounce rapid preference changes (e.g., scrolling a time picker) to avoid
    /// firing dozens of WeatherKit requests. Waits 1 second of inactivity before scheduling.
    private func debouncedSchedule() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.scheduleNotifications()
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    func scheduleNotifications() {
        let preferences = UserPreferences()
        let center = UNUserNotificationCenter.current()

        // Remove any existing notification (repeating or legacy non-repeating)
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.notificationId,
            "sunscreen-daily-0",  // legacy identifiers from previous scheme
            "sunscreen-daily-1"
        ])

        guard preferences.notificationsEnabled else { return }

        // Always schedule a repeating notification first as a guaranteed fallback.
        // This fires every day even if the app never runs again.
        scheduleRepeatingFallback(preferences: preferences, center: center)

        // Then try to upgrade the content with fresh weather data.
        // If this succeeds, it replaces the fallback (same identifier).
        let defaults = UserDefaults(suiteName: "group.com.sunscreenfyi.shared")
        guard let lat = defaults?.object(forKey: "lastLatitude") as? Double,
              let lon = defaults?.object(forKey: "lastLongitude") as? Double else {
            return
        }

        let location = CLLocation(latitude: lat, longitude: lon)
        let weatherService = WeatherKit.WeatherService.shared

        Task {
            do {
                let weather = try await weatherService.weather(for: location)

                let forecast = weather.hourlyForecast.forecast.prefix(48).map { hour in
                    HourlyUV(
                        date: hour.date,
                        uvIndex: Double(hour.uvIndex.value),
                        cloudCover: Self.mapCloudCover(hour.cloudCover)
                    )
                }

                guard !forecast.isEmpty else { return }

                // Build the outdoor start time for tomorrow (the next notification firing)
                let calendar = Calendar.current
                let now = Date()
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
                var startComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                startComponents.hour = preferences.notificationStartHour
                startComponents.minute = preferences.notificationStartMinute
                startComponents.second = 0

                // Also check today's outdoor time if notification hasn't fired yet
                var todayStartComponents = calendar.dateComponents([.year, .month, .day], from: now)
                todayStartComponents.hour = preferences.notificationStartHour
                todayStartComponents.minute = preferences.notificationStartMinute
                todayStartComponents.second = 0

                var notifComponents = calendar.dateComponents([.year, .month, .day], from: now)
                notifComponents.hour = preferences.notificationHour
                notifComponents.minute = preferences.notificationMinute
                let todayNotifTime = calendar.date(from: notifComponents) ?? now

                // Use today's outdoor time if the notification hasn't fired yet today,
                // otherwise use tomorrow's
                let outdoorStartTime: Date
                if todayNotifTime > now, let todayStart = calendar.date(from: todayStartComponents) {
                    outdoorStartTime = todayStart
                } else if let tomorrowStart = calendar.date(from: startComponents) {
                    outdoorStartTime = tomorrowStart
                } else {
                    return
                }

                // Check forecast coverage
                let lastForecastDate = forecast.last?.date ?? now
                let forecastCoverageEnd = lastForecastDate.addingTimeInterval(3600)
                guard outdoorStartTime <= forecastCoverageEnd else { return }

                let outdoorEndTime = outdoorStartTime.addingTimeInterval(preferences.notificationDurationMinutes * 60)

                let needs = SunscreenAlgorithm.needsSunscreen(
                    hourlyForecast: Array(forecast),
                    startTime: outdoorStartTime,
                    skinType: preferences.skinType,
                    durationMinutes: min(preferences.notificationDurationMinutes,
                                         forecastCoverageEnd.timeIntervalSince(outdoorStartTime) / 60),
                    surface: preferences.surface,
                    elevationFeet: preferences.elevationFeet,
                    otherFactors: preferences.otherFactors
                )

                let uvAtTime = forecast
                    .min(by: { abs($0.date.timeIntervalSince(outdoorStartTime)) < abs($1.date.timeIntervalSince(outdoorStartTime)) })?
                    .uvIndex ?? 0

                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                let startTimeStr = formatter.string(from: outdoorStartTime)

                let content = UNMutableNotificationContent()
                content.title = needs ? "You need sunscreen today!" : "No sunscreen needed"
                if needs {
                    let partialCoverage = outdoorEndTime > forecastCoverageEnd
                    let suffix = partialCoverage ? " (forecast is partial)" : ""
                    content.body = "UV will be \(Int(uvAtTime)) at \(startTimeStr). Apply sunscreen before heading out.\(suffix)"
                } else {
                    content.body = "UV will be \(Int(uvAtTime)) at \(startTimeStr). You're good without sunscreen."
                }
                content.sound = .default

                // Replace the fallback with weather-specific content (same identifier)
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DateComponents(hour: preferences.notificationHour, minute: preferences.notificationMinute),
                    repeats: true
                )
                let request = UNNotificationRequest(identifier: Self.notificationId, content: content, trigger: trigger)
                try? await center.add(request)
            } catch {
                // Weather fetch failed — the repeating fallback notification is already scheduled
            }
        }
    }

    /// Schedule a repeating notification with generic content. This fires every day
    /// at the configured time, even if the app never runs again. It gets replaced
    /// with weather-specific content when a weather fetch succeeds.
    private func scheduleRepeatingFallback(preferences: UserPreferences, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "Sunscreen check"

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var startComponents = DateComponents()
        startComponents.hour = preferences.notificationStartHour
        startComponents.minute = preferences.notificationStartMinute
        let startTimeStr = Calendar.current.date(from: startComponents).map { formatter.string(from: $0) } ?? "later"
        content.body = "Couldn't fetch today's forecast. Open the app to check UV at \(startTimeStr)."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: preferences.notificationHour, minute: preferences.notificationMinute),
            repeats: true
        )
        let request = UNNotificationRequest(identifier: Self.notificationId, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            Self.notificationId,
            "sunscreen-daily-0",
            "sunscreen-daily-1"
        ])
    }

    // MARK: - Background Task

    func registerBGTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.bgTaskIdentifier,
            using: nil
        ) { task in
            self.handleBGTask(task as! BGAppRefreshTask)
        }
    }

    private func handleBGTask(_ task: BGAppRefreshTask) {
        let workTask = Task {
            scheduleNotifications()
        }

        scheduleBGRefresh()

        task.expirationHandler = {
            workTask.cancel()
            task.setTaskCompleted(success: false)
        }

        Task {
            _ = await workTask.result
            task.setTaskCompleted(success: true)
        }
    }

    func scheduleBGRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskIdentifier)
        // Schedule for around 2am
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 2
        components.minute = 0
        if let tomorrow2am = calendar.date(from: components) {
            let targetDate = tomorrow2am > Date() ? tomorrow2am : calendar.date(byAdding: .day, value: 1, to: tomorrow2am)!
            request.earliestBeginDate = targetDate
        }

        try? BGTaskScheduler.shared.submit(request)
    }

    private static func mapCloudCover(_ fraction: Double) -> CloudCover {
        switch fraction {
        case 0..<0.25: return .clear
        case 0.25..<0.50: return .scattered
        case 0.50..<0.875: return .broken
        default: return .overcast
        }
    }
}
