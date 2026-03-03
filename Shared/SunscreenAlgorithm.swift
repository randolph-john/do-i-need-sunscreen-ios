import Foundation

// MARK: - Minimal Erythemal Dose (MED) by Fitzpatrick skin type

enum SkinType: Int, CaseIterable, Codable {
    case typeI = 1
    case typeII = 2
    case typeIII = 3
    case typeIV = 4
    case typeV = 5
    case typeVI = 6

    var label: String {
        switch self {
        case .typeI: return "Type I - Very Fair"
        case .typeII: return "Type II - Fair"
        case .typeIII: return "Type III - Medium"
        case .typeIV: return "Type IV - Olive"
        case .typeV: return "Type V - Brown"
        case .typeVI: return "Type VI - Black"
        }
    }

    var description: String {
        switch self {
        case .typeI: return "Always burns, never tans"
        case .typeII: return "Usually burns, tans minimally"
        case .typeIII: return "Sometimes burns, tans gradually"
        case .typeIV: return "Rarely burns, always tans"
        case .typeV: return "Very rarely burns, tans deeply"
        case .typeVI: return "Never burns, deeply pigmented"
        }
    }

    var med: Double {
        switch self {
        case .typeI: return 2.0
        case .typeII: return 2.5
        case .typeIII: return 3.5
        case .typeIV: return 4.5
        case .typeV: return 7.0
        case .typeVI: return 11.5
        }
    }

    var swatchColorHex: String {
        switch self {
        case .typeI: return "#edd8c6"
        case .typeII: return "#e1b49f"
        case .typeIII: return "#daa78c"
        case .typeIV: return "#d6987c"
        case .typeV: return "#8e5f4b"
        case .typeVI: return "#482b1a"
        }
    }
}

// MARK: - Cloud Cover

enum CloudCover: String, CaseIterable, Codable {
    case clear
    case scattered
    case broken
    case overcast

    var factor: Double {
        switch self {
        case .clear: return 1.0
        case .scattered: return 0.9
        case .broken: return 0.73
        case .overcast: return 0.32
        }
    }

    var displayName: String {
        switch self {
        case .clear: return "Clear"
        case .scattered: return "Scattered"
        case .broken: return "Broken"
        case .overcast: return "Overcast"
        }
    }
}

// MARK: - Surface Type

enum SurfaceType: String, CaseIterable, Codable {
    case none
    case snow
    case sand
    case water
    case grass
    case concrete
    case asphalt
    case soil

    var factor: Double {
        switch self {
        case .none: return 1.0
        case .snow: return 1.85
        case .sand: return 1.35
        case .water: return 1.06
        case .grass: return 1.25
        case .concrete: return 1.3
        case .asphalt: return 1.08
        case .soil: return 1.17
        }
    }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .snow: return "Snow"
        case .sand: return "Sand"
        case .water: return "Water"
        case .grass: return "Grass"
        case .concrete: return "Concrete"
        case .asphalt: return "Asphalt"
        case .soil: return "Soil"
        }
    }
}

// MARK: - Other Risk Factors

enum OtherFactor: String, CaseIterable, Codable {
    case pregnant
    case breastfeeding
    case skinCancer
    case rosacea
    case eczema
    case photosensitizing
    case acne
    case antibiotics
    case retinoids
    case chemotherapy
    case immunosuppressants
    case diuretics
    case tattoos
    case recentProcedures

    var medReduction: Double {
        switch self {
        case .pregnant: return 0.20
        case .breastfeeding: return 0.10
        case .skinCancer: return 0.20
        case .rosacea: return 0.30
        case .eczema: return 0.25
        case .photosensitizing: return 0.40
        case .acne: return 0.05
        case .antibiotics: return 0.40
        case .retinoids: return 0.05
        case .chemotherapy: return 0.30
        case .immunosuppressants: return 0.35
        case .diuretics: return 0.25
        case .tattoos: return 0.50
        case .recentProcedures: return 0.50
        }
    }

    var displayName: String {
        switch self {
        case .pregnant: return "Pregnant"
        case .breastfeeding: return "Breastfeeding"
        case .skinCancer: return "History of skin cancer"
        case .rosacea: return "Rosacea"
        case .eczema: return "Eczema"
        case .photosensitizing: return "Photosensitizing condition"
        case .acne: return "Acne"
        case .antibiotics: return "Taking antibiotics"
        case .retinoids: return "Using retinoids"
        case .chemotherapy: return "Chemotherapy"
        case .immunosuppressants: return "Immunosuppressants"
        case .diuretics: return "Taking diuretics"
        case .tattoos: return "Recent tattoos"
        case .recentProcedures: return "Recent skin procedures"
        }
    }
}

// MARK: - Sunscreen Algorithm

struct SunscreenAlgorithm {
    static let absorptionFactor: Double = 0.9

    /// Calculate adjusted MED threshold after applying other risk factor reductions.
    /// Reductions stack additively but MED won't drop below 10% of the base value.
    static func adjustedMED(baseMED: Double, otherFactors: Set<OtherFactor>) -> Double {
        guard !otherFactors.isEmpty else { return baseMED }

        var totalReduction = 0.0
        for factor in otherFactors {
            totalReduction += factor.medReduction
        }

        let adjustmentFactor = max(0.1, 1.0 - totalReduction)
        return baseMED * adjustmentFactor
    }

    /// Calculate UV dose for a given UV index and duration
    static func calculateUVDose(uvIndex: Double, durationMinutes: Double) -> Double {
        return (uvIndex * durationMinutes) / 60.0
    }

    /// Determine whether sunscreen is needed
    static func needsSunscreen(
        uvIndex: Double,
        skinType: SkinType,
        durationMinutes: Double,
        cloudCover: CloudCover = .clear,
        surface: SurfaceType = .none,
        elevationFeet: Double = 0,
        otherFactors: Set<OtherFactor> = []
    ) -> Bool {
        var uvDose = calculateUVDose(uvIndex: uvIndex, durationMinutes: durationMinutes)

        if uvDose == 0 { return false }

        // Apply absorption factor
        uvDose *= absorptionFactor

        // Apply cloud cover factor
        uvDose *= cloudCover.factor

        // Apply surface reflection factor
        uvDose *= surface.factor

        // Apply altitude factor (convert feet to kilometers)
        let altitudeKm = elevationFeet * 0.0003048
        let altitudeFactor = 1.0 + (altitudeKm * 0.06)
        uvDose *= altitudeFactor

        // Get MED threshold for skin type, adjusted for other risk factors
        let medThreshold = adjustedMED(baseMED: skinType.med, otherFactors: otherFactors)

        return uvDose > medThreshold
    }

    /// Get safe exposure time without sunscreen in minutes
    static func safeExposureTime(
        uvIndex: Double,
        skinType: SkinType,
        cloudCover: CloudCover = .clear,
        surface: SurfaceType = .none,
        elevationFeet: Double = 0,
        otherFactors: Set<OtherFactor> = []
    ) -> Int? {
        guard uvIndex > 0 else { return nil }

        let medThreshold = adjustedMED(baseMED: skinType.med, otherFactors: otherFactors)
        let altitudeKm = elevationFeet * 0.0003048
        let altitudeFactor = 1.0 + (altitudeKm * 0.06)

        let safeTime = (medThreshold * 60.0) / (uvIndex * absorptionFactor * cloudCover.factor * surface.factor * altitudeFactor)

        return Int(safeTime.rounded())
    }

    /// Calculate sunscreen reapplication time in minutes
    static func reapplicationTime(uvIndex: Double, skinType: SkinType, durationMinutes: Double) -> Int? {
        guard needsSunscreen(uvIndex: uvIndex, skinType: skinType, durationMinutes: durationMinutes) else {
            return nil
        }

        var baseTime = 120 // 2 hours
        if uvIndex > 7 { baseTime = 90 }
        if uvIndex > 10 { baseTime = 60 }

        return min(baseTime, Int(durationMinutes))
    }

    /// Format duration in minutes to a readable string
    static func formatDuration(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)min"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainingMinutes)min"
    }
}

// MARK: - Sunscreen Result

struct SunscreenResult {
    let needsSunscreen: Bool
    let uvIndex: Double
    let safeExposureMinutes: Int?
    let reapplicationMinutes: Int?

    var recommendation: String {
        if uvIndex == 0 {
            return "No UV exposure detected"
        }
        if needsSunscreen {
            return "Yes, wear sunscreen!"
        }
        if let safe = safeExposureMinutes {
            return "Not needed for \(SunscreenAlgorithm.formatDuration(minutes: safe))"
        }
        return "No sunscreen needed"
    }

    var emoji: String {
        if uvIndex == 0 { return "moon" }
        return needsSunscreen ? "sun.max.trianglebadge.exclamationmark" : "sun.min"
    }
}
