import SwiftUI

struct NotificationSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var preferences: UserPreferences
    @ObservedObject var notificationManager: NotificationManager

    @State private var showSettingsAlert = false
    @State private var notificationTime: Date
    @State private var outdoorStartTime: Date

    init(isPresented: Binding<Bool>, preferences: UserPreferences, notificationManager: NotificationManager) {
        self._isPresented = isPresented
        self.preferences = preferences
        self.notificationManager = notificationManager

        var notifComponents = DateComponents()
        notifComponents.hour = preferences.notificationHour
        notifComponents.minute = preferences.notificationMinute
        let notifDate = Calendar.current.date(from: notifComponents) ?? Date()
        self._notificationTime = State(initialValue: notifDate)

        var startComponents = DateComponents()
        startComponents.hour = preferences.notificationStartHour
        startComponents.minute = preferences.notificationStartMinute
        let startDate = Calendar.current.date(from: startComponents) ?? Date()
        self._outdoorStartTime = State(initialValue: startDate)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Daily Notifications", isOn: Binding(
                        get: { preferences.notificationsEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let granted = await notificationManager.requestPermission()
                                    await MainActor.run {
                                        if granted {
                                            preferences.notificationsEnabled = true
                                        } else {
                                            preferences.notificationsEnabled = false
                                            showSettingsAlert = true
                                        }
                                    }
                                }
                            } else {
                                preferences.notificationsEnabled = false
                                notificationManager.cancelAllNotifications()
                            }
                        }
                    ))
                    .tint(Color(hex: "#FFD700"))
                }

                if preferences.notificationsEnabled {
                    Section {
                        DatePicker("Notify me at", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .onChange(of: notificationTime) { newTime in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                preferences.notificationHour = components.hour ?? 8
                                preferences.notificationMinute = components.minute ?? 0
                            }

                        DatePicker("I'll be outside at", selection: $outdoorStartTime, displayedComponents: .hourAndMinute)
                            .onChange(of: outdoorStartTime) { newTime in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                preferences.notificationStartHour = components.hour ?? 12
                                preferences.notificationStartMinute = components.minute ?? 0
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time outdoors: \(formatDuration(minutes: Int(preferences.notificationDurationMinutes)))")

                            Slider(
                                value: $preferences.notificationDurationMinutes,
                                in: 15...480,
                                step: 15
                            )
                            .tint(Color(hex: "#FFD700"))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Notifications Disabled", isPresented: $showSettingsAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive daily sunscreen reminders.")
            }
        }
    }

    private func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours) hr \(mins) min"
        } else if hours > 0 {
            return "\(hours) hr"
        } else {
            return "\(mins) min"
        }
    }
}
