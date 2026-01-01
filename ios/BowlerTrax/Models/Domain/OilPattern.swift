//
//  OilPattern.swift
//  BowlerTrax
//
//  Oil pattern model for lane conditioning data
//

import Foundation

/// Oil pattern configuration for lane conditioning
struct OilPattern: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var category: PatternCategory
    var lengthFeet: Int               // 32-52 feet
    var volumeML: Double?             // Total oil volume in milliliters
    var ratio: Double?                // Inside/outside ratio (e.g., 10:1 = 10.0)
    var difficulty: PatternDifficulty
    var description: String?
    var isPreset: Bool

    // MARK: - Nested Types

    enum PatternCategory: String, Codable, CaseIterable, Sendable {
        case pbaAnimal = "PBA Animal"
        case pbaHallOfFame = "PBA Hall of Fame"
        case usOpen = "U.S. Open"
        case house = "House Shot"
        case sport = "Sport"
        case custom = "Custom"

        var displayName: String {
            rawValue
        }
    }

    enum PatternDifficulty: String, Codable, CaseIterable, Sendable {
        case short = "Short"      // < 36ft
        case medium = "Medium"    // 37-42ft
        case long = "Long"        // > 43ft

        var displayName: String {
            rawValue
        }

        var lengthRange: ClosedRange<Int> {
            switch self {
            case .short: return 32...36
            case .medium: return 37...42
            case .long: return 43...52
            }
        }

        /// Determine difficulty from pattern length
        static func from(lengthFeet: Int) -> PatternDifficulty {
            switch lengthFeet {
            case ...36:
                return .short
            case 37...42:
                return .medium
            default:
                return .long
            }
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        category: PatternCategory,
        lengthFeet: Int,
        volumeML: Double? = nil,
        ratio: Double? = nil,
        difficulty: PatternDifficulty,
        description: String? = nil,
        isPreset: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.lengthFeet = max(32, min(52, lengthFeet))  // Clamp to valid range
        self.volumeML = volumeML
        self.ratio = ratio
        self.difficulty = difficulty
        self.description = description
        self.isPreset = isPreset
    }
}

// MARK: - Rule of 31

extension OilPattern {
    /// Target board based on the Rule of 31
    /// The Rule of 31 states: subtract pattern length from 31 to get target board at arrows
    var targetBoard: Int {
        lengthFeet - 31
    }

    /// Formatted target board display
    var targetBoardDisplay: String {
        let board = targetBoard
        if board <= 0 {
            return "Outside"
        }
        return "Board \(board)"
    }

    /// Target arrow (1-7) based on Rule of 31
    /// Arrows are on boards 5, 10, 15, 20, 25, 30, 35
    var targetArrow: Int? {
        let board = targetBoard
        guard board > 0 else { return nil }

        // Find closest arrow
        let arrowBoards = [5, 10, 15, 20, 25, 30, 35]
        var closestArrow = 1
        var minDistance = abs(board - arrowBoards[0])

        for (index, arrowBoard) in arrowBoards.enumerated() {
            let distance = abs(board - arrowBoard)
            if distance < minDistance {
                minDistance = distance
                closestArrow = index + 1
            }
        }

        return closestArrow
    }
}

// MARK: - Computed Properties

extension OilPattern {
    /// Display string for pattern length
    var lengthDisplay: String {
        "\(lengthFeet) ft"
    }

    /// Display string for oil volume
    var volumeDisplay: String? {
        guard let volume = volumeML else { return nil }
        return String(format: "%.1f mL", volume)
    }

    /// Display string for oil ratio
    var ratioDisplay: String? {
        guard let ratio = ratio else { return nil }
        return String(format: "%.0f:1", ratio)
    }

    /// Full display name including length
    var fullDisplayName: String {
        "\(name) (\(lengthFeet)ft)"
    }

    /// Description for the pattern with key details
    var summaryDescription: String {
        var parts: [String] = []
        parts.append(lengthDisplay)
        parts.append(difficulty.displayName)

        if let ratioDisplay = ratioDisplay {
            parts.append(ratioDisplay)
        }

        return parts.joined(separator: " | ")
    }
}

// MARK: - Validation

extension OilPattern {
    /// Check if pattern length is within valid range
    var isValidLength: Bool {
        lengthFeet >= 32 && lengthFeet <= 52
    }

    /// Check if volume is reasonable (typical range 15-35 mL)
    var isReasonableVolume: Bool {
        guard let volume = volumeML else { return true }
        return volume >= 10.0 && volume <= 50.0
    }

    /// Check if ratio is within typical range (2:1 to 20:1)
    var isReasonableRatio: Bool {
        guard let ratio = ratio else { return true }
        return ratio >= 2.0 && ratio <= 20.0
    }
}

// MARK: - Comparable

extension OilPattern: Comparable {
    static func < (lhs: OilPattern, rhs: OilPattern) -> Bool {
        if lhs.category.rawValue != rhs.category.rawValue {
            return lhs.category.rawValue < rhs.category.rawValue
        }
        return lhs.lengthFeet < rhs.lengthFeet
    }
}

// MARK: - Sample Data

extension OilPattern {
    /// Sample pattern for previews
    static let sample = OilPattern(
        name: "Cheetah",
        category: .pbaAnimal,
        lengthFeet: 33,
        volumeML: 22.0,
        ratio: 4.0,
        difficulty: .short,
        description: "Short PBA Animal pattern, requires precision and ball control.",
        isPreset: true
    )

    /// Typical house shot for testing
    static let houseShot = OilPattern(
        name: "Typical House Shot",
        category: .house,
        lengthFeet: 40,
        volumeML: 20.0,
        ratio: 10.0,
        difficulty: .medium,
        description: "Standard recreational center pattern with high ratio for easier scoring.",
        isPreset: true
    )
}
