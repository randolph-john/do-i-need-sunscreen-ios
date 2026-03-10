import WidgetKit
import SwiftUI

@main
struct SunscreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        SunscreenWidget()
    }
}

struct SunscreenWidget: Widget {
    let kind: String = "SunscreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SunscreenWidgetIntent.self, provider: SunscreenConfigurableProvider()) { entry in
            SunscreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sunscreen Check")
        .description("See if you need sunscreen now or at a scheduled time.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}
