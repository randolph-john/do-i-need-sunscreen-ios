import SwiftUI

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255.0
        g = Double((int >> 8) & 0xFF) / 255.0
        b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - UV Background Colors (from utils.js)

func uvBackgroundColor(uvIndex: Double, isDark: Bool) -> Color {
    if isDark { return Color(hex: "#0A0A0A") }
    let idx = Int(uvIndex)
    switch idx {
    case 0: return Color(hex: "#B0E0E6")
    case 1: return Color(hex: "#ADD8E6")
    case 2: return Color(hex: "#87CEFA")
    case 3: return Color(hex: "#FFF8DC")
    case 4: return Color(hex: "#FFEB3B")
    case 5: return Color(hex: "#FFD700")
    case 6: return Color(hex: "#FFA500")
    case 7: return Color(hex: "#FF8C00")
    case 8: return Color(hex: "#FF6347")
    case 9: return Color(hex: "#FF4500")
    case 10: return Color(hex: "#DC143C")
    default: return Color(hex: "#8B0000")
    }
}

func uvTextColor(uvIndex: Double, isDark: Bool) -> Color {
    if isDark { return .white }
    return uvIndex <= 5 ? .black : .white
}
