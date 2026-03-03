import SwiftUI
import WidgetKit

struct WidgetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(for: .widget) {
                Color(.systemBackground)
            }
        } else {
            content.background(Color(.systemBackground))
        }
    }
}

struct SunscreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: SunscreenEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .systemSmall:
            smallView
        default:
            smallView
        }
    }

    // MARK: - Circular Lock Screen Widget

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

    // MARK: - Rectangular Lock Screen Widget

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.needsSunscreen ? "sun.max.fill" : "sun.min")
                .font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.needsSunscreen ? "Sunscreen needed" : "No sunscreen needed")
                    .font(.system(size: 13, weight: .semibold))
                Text("UV \(Int(entry.uvIndex))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - System Small Widget

    private var smallView: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.needsSunscreen
                  ? "sun.max.trianglebadge.exclamationmark"
                  : "sun.min")
                .font(.system(size: 36))
                .foregroundColor(entry.needsSunscreen ? .orange : .green)

            Text(entry.needsSunscreen ? "Yes!" : "Nope")
                .font(.headline)

            Text("UV \(Int(entry.uvIndex))")
                .font(.caption)
                .foregroundColor(.secondary)

            if let safe = entry.safeExposureMinutes, !entry.needsSunscreen {
                Text("Safe: \(SunscreenAlgorithm.formatDuration(minutes: safe))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .modifier(WidgetBackgroundModifier())
    }
}
