import WidgetKit
import SwiftUI

@main
struct SunscreenWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        SunscreenWatchWidget()
    }
}

struct SunscreenWatchWidget: Widget {
    let kind: String = "SunscreenWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            WatchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sunscreen")
        .description("See if you need sunscreen now.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner])
    }
}
