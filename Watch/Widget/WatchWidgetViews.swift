import SwiftUI
import WidgetKit

struct WatchWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: WatchWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCorner:
            cornerView
        default:
            circularView
        }
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: entry.needsSunscreen ? "sun.max.fill" : "sun.min")
                    .font(.system(size: 16))
                Text(entry.needsSunscreen ? "YES" : "NO")
                    .font(.system(size: 10, weight: .bold))
            }
        }
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.needsSunscreen ? "sun.max.fill" : "sun.min")
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.needsSunscreen ? "Sunscreen needed" : "No sunscreen needed")
                    .font(.system(size: 12, weight: .semibold))
                Text("UV \(Int(entry.uvIndex))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var cornerView: some View {
        Text(entry.needsSunscreen ? "YES" : "NO")
            .font(.system(size: 14, weight: .bold))
            .widgetLabel {
                Text("UV \(Int(entry.uvIndex))")
            }
    }
}
