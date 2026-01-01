//
//  BallProfile.swift
//  BowlerTrax
//
//  Ball profile for color-based tracking
//

import Foundation

/// Ball profile for color-based tracking
struct BallProfile: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var brand: String?
    var color: HSVColor              // Ball color for detection
    var colorTolerance: Double       // How much variance allowed (default 15)
    var markerColor: HSVColor?       // PAP marker color for rev tracking
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        color: HSVColor,
        colorTolerance: Double = 15.0,
        markerColor: HSVColor? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.color = color
        self.colorTolerance = colorTolerance
        self.markerColor = markerColor
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension BallProfile {
    /// Display name with optional brand
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) - \(name)"
        }
        return name
    }

    /// Check if marker tracking is configured
    var hasMarkerTracking: Bool {
        markerColor != nil
    }

    /// HSV range for ball detection (hue)
    var hueRange: ClosedRange<Double> {
        let tolerance = colorTolerance
        let minHue = (color.h - tolerance).truncatingRemainder(dividingBy: 360)
        let maxHue = (color.h + tolerance).truncatingRemainder(dividingBy: 360)

        // Handle wrap-around at 0/360
        if minHue < 0 {
            return (360 + minHue)...360
        }
        return min(minHue, maxHue)...max(minHue, maxHue)
    }

    /// HSV range for ball detection (saturation)
    var saturationRange: ClosedRange<Double> {
        let tolerance = 20.0  // Fixed saturation tolerance
        let minSat = max(0, color.s - tolerance)
        let maxSat = min(100, color.s + tolerance)
        return minSat...maxSat
    }

    /// HSV range for ball detection (value)
    var valueRange: ClosedRange<Double> {
        let tolerance = 30.0  // Fixed value tolerance (more forgiving for lighting)
        let minVal = max(0, color.v - tolerance)
        let maxVal = min(100, color.v + tolerance)
        return minVal...maxVal
    }
}

// MARK: - Factory Methods

extension BallProfile {
    /// Create a ball profile with common bowling ball colors
    static func preset(_ preset: BallColorPreset, name: String, brand: String? = nil) -> BallProfile {
        BallProfile(
            name: name,
            brand: brand,
            color: preset.hsvColor,
            colorTolerance: preset.recommendedTolerance
        )
    }
}

/// Common bowling ball color presets
enum BallColorPreset: String, CaseIterable, Sendable {
    case blue
    case red
    case purple
    case orange
    case green
    case pink
    case yellow
    case black

    var hsvColor: HSVColor {
        switch self {
        case .blue: return HSVColor(h: 210, s: 80, v: 70)
        case .red: return HSVColor(h: 0, s: 85, v: 75)
        case .purple: return HSVColor(h: 280, s: 70, v: 60)
        case .orange: return HSVColor(h: 30, s: 90, v: 85)
        case .green: return HSVColor(h: 120, s: 70, v: 60)
        case .pink: return HSVColor(h: 330, s: 60, v: 80)
        case .yellow: return HSVColor(h: 55, s: 85, v: 90)
        case .black: return HSVColor(h: 0, s: 0, v: 15)
        }
    }

    var recommendedTolerance: Double {
        switch self {
        case .black: return 10  // Narrow tolerance for black
        case .yellow, .orange: return 12  // Narrow for bright colors
        default: return 15  // Standard tolerance
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
