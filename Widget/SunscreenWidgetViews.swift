import SwiftUI
import WidgetKit

struct WidgetBackgroundModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content.containerBackground(for: .widget) {
            color
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

    private var smallWidgetBgColor: Color {
        let uv = Int(entry.uvIndex)
        switch uv {
        case 0: return Color(red: 0.2, green: 0.2, blue: 0.3)
        case 1: return Color(red: 0.3, green: 0.7, blue: 0.3)
        case 2: return Color(red: 0.3, green: 0.7, blue: 0.3)
        case 3: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 4: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 5: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 6: return Color(red: 1.0, green: 0.65, blue: 0.0)
        case 7: return Color(red: 1.0, green: 0.55, blue: 0.0)
        case 8: return Color(red: 1.0, green: 0.39, blue: 0.28)
        case 9: return Color(red: 1.0, green: 0.27, blue: 0.0)
        case 10: return Color(red: 0.86, green: 0.08, blue: 0.24)
        default: return Color(red: 0.55, green: 0.0, blue: 0.0)
        }
    }

    private var smallWidgetTextColor: Color {
        entry.uvIndex <= 5 ? .black : .white
    }

    private var modeLabel: String {
        if let label = entry.scheduledTimeLabel {
            return label
        }
        return "Now"
    }

    private var smallView: some View {
        VStack(spacing: 6) {
            Image(systemName: entry.needsSunscreen
                  ? "sun.max.trianglebadge.exclamationmark"
                  : "sun.min")
                .font(.system(size: 32))
                .foregroundColor(smallWidgetTextColor)

            Text(entry.needsSunscreen ? "YES" : "NO")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(smallWidgetTextColor)

            Text("UV \(Int(entry.uvIndex))")
                .font(.system(size: 13))
                .foregroundColor(smallWidgetTextColor.opacity(0.8))

            if entry.needsSunscreen, let safe = entry.safeExposureMinutes, safe > 0 {
                Text("Apply in \(SunscreenAlgorithm.formatDuration(minutes: safe))")
                    .font(.system(size: 11))
                    .foregroundColor(smallWidgetTextColor.opacity(0.8))
            }

            Text(modeLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(smallWidgetTextColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(WidgetBackgroundModifier(color: smallWidgetBgColor))
    }
}
