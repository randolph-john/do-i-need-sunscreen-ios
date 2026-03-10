import AppIntents
import WidgetKit

enum WidgetMode: String, AppEnum {
    case now = "now"
    case scheduled = "scheduled"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Widget Mode"
    }

    static var caseDisplayRepresentations: [WidgetMode: DisplayRepresentation] {
        [
            .now: "Current sunscreen need",
            .scheduled: "At your outdoor time"
        ]
    }
}

struct SunscreenWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Sunscreen Check"
    static var description = IntentDescription("Check if you need sunscreen.")

    @Parameter(title: "Mode", default: .now)
    var mode: WidgetMode
}
