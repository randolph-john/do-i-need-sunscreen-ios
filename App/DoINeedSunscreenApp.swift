import SwiftUI
import FirebaseCore

@main
struct DoINeedSunscreenApp: App {
    init() {
        FirebaseApp.configure()
        NotificationManager.shared.registerBGTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
