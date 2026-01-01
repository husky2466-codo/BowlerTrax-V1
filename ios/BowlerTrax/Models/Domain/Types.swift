//
//  Types.swift
//  BowlerTrax
//
//  Supporting types for domain models
//

import Foundation
import UIKit

// MARK: - Color Types

/// HSV color representation (better for tracking than RGB)
struct HSVColor: Codable, Equatable, Hashable, Sendable {
    var h: Double  // Hue: 0-360
    var s: Double  // Saturation: 0-100
    var v: Double  // Value/Brightness: 0-100

    /// Convert to UIColor for display
    var uiColor: UIColor {
        UIColor(
            hue: CGFloat(h / 360.0),
            saturation: CGFloat(s / 100.0),
            brightness: CGFloat(v / 100.0),
            alpha: 1.0
        )
    }

    /// Create from UIColor
    static func from(_ color: UIColor) -> HSVColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        return HSVColor(h: Double(h * 360), s: Double(s * 100), v: Double(b * 100))
    }

    /// Create with validation
    init(h: Double, s: Double, v: Double) {
        self.h = max(0, min(360, h))
        self.s = max(0, min(100, s))
        self.v = max(0, min(100, v))
    }
}

/// RGB color for display purposes
struct RGBColor: Codable, Equatable, Hashable, Sendable {
    var r: Int  // 0-255
    var g: Int  // 0-255
    var b: Int  // 0-255

    var uiColor: UIColor {
        UIColor(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: 1.0
        )
    }

    /// Create with validation
    init(r: Int, g: Int, b: Int) {
        self.r = max(0, min(255, r))
        self.g = max(0, min(255, g))
        self.b = max(0, min(255, b))
    }

    /// Convert to HSV
    func toHSV() -> HSVColor {
        HSVColor.from(uiColor)
    }
}

// MARK: - Enumerations

/// Rev rate categories based on industry standards
enum RevCategory: String, Codable, CaseIterable, Sendable {
    case stroker   // 250-350 RPM
    case tweener   // 300-400 RPM
    case cranker   // 400+ RPM

    var rpmRange: ClosedRange<Int> {
        switch self {
        case .stroker: return 250...350
        case .tweener: return 300...400
        case .cranker: return 400...600
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    /// Determine category from RPM value
    static func from(rpm: Double) -> RevCategory {
        switch rpm {
        case ..<300:
            return .stroker
        case 300..<400:
            return .tweener
        default:
            return .cranker
        }
    }
}

/// Oil pattern types
enum OilPatternType: String, Codable, CaseIterable, Sendable {
    case house
    case sport
    case short
    case medium
    case long
    case custom

    var displayName: String {
        rawValue.capitalized
    }

    var typicalLength: ClosedRange<Int>? {
        switch self {
        case .short: return 32...37
        case .medium: return 38...42
        case .long: return 43...52
        case .house: return 38...42
        case .sport: return 38...45
        case .custom: return nil
        }
    }
}

/// Hand preference
enum HandPreference: String, Codable, CaseIterable, Sendable {
    case left
    case right

    var pocketBoard: Double {
        switch self {
        case .right: return 17.5
        case .left: return 22.5
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

/// Shot result types
enum ShotResult: String, Codable, CaseIterable, Sendable {
    case strike
    case spare
    case open
    case split
    case washout
    case gutter

    var displayName: String {
        rawValue.capitalized
    }

    var symbol: String {
        switch self {
        case .strike: return "X"
        case .spare: return "/"
        case .open: return "-"
        case .split: return "S"
        case .washout: return "W"
        case .gutter: return "G"
        }
    }
}

/// Predicted leave types
enum PredictedLeave: String, Codable, CaseIterable, Sendable {
    case clean
    case tenPin = "10-pin"
    case sevenPin = "7-pin"
    case split
    case bucket
    case washout
    case greekChurch = "greek-church"
    case other

    var displayName: String {
        switch self {
        case .tenPin: return "10 Pin"
        case .sevenPin: return "7 Pin"
        case .greekChurch: return "Greek Church"
        default: return rawValue.capitalized
        }
    }
}

/// Ball motion phases (Skid-Hook-Roll)
enum BallPhase: String, Codable, CaseIterable, Sendable {
    case skid
    case hook
    case roll

    var displayName: String {
        rawValue.capitalized
    }
}

/// Calibration wizard step
enum CalibrationStep: String, Codable, CaseIterable, Sendable {
    case position     // Position camera
    case foulLine     // Mark foul line
    case arrows       // Mark arrows
    case verify       // Verify calibration
    case cropZone     // Set crop zone (optional)
    case complete     // Done

    var displayName: String {
        switch self {
        case .position: return "Position Camera"
        case .foulLine: return "Mark Foul Line"
        case .arrows: return "Mark Arrows"
        case .verify: return "Verify"
        case .cropZone: return "Crop Zone"
        case .complete: return "Complete"
        }
    }

    var stepNumber: Int {
        switch self {
        case .position: return 1
        case .foulLine: return 2
        case .arrows: return 3
        case .verify: return 4
        case .cropZone: return 5
        case .complete: return 6
        }
    }

    /// Whether this step is optional (user can skip)
    var isOptional: Bool {
        switch self {
        case .cropZone: return true
        default: return false
        }
    }
}

// MARK: - Arrow Point

/// Arrow point for calibration
struct ArrowPoint: Codable, Equatable, Sendable {
    var arrowNumber: Int     // 1-7 (arrows on boards 5,10,15,20,25,30,35)
    var pixelX: Double
    var pixelY: Double
    var boardNumber: Int     // 5, 10, 15, 20, 25, 30, or 35

    static let standardBoards = [5, 10, 15, 20, 25, 30, 35]
}
