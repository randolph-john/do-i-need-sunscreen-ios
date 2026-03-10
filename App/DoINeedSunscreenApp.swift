import SwiftUI

@main
struct DoINeedSunscreenApp: App {
    init() {
        NotificationManager.shared.registerBGTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
