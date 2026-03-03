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
        StaticConfiguration(kind: kind, provider: SunscreenWidgetProvider()) { entry in
            SunscreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sunscreen Check")
        .description("See if you need sunscreen right now.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}
