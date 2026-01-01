//
//  BallCatalog.swift
//  BowlerTrax
//
//  Bowling ball catalog data models for pre-populated ball selection
//

import Foundation

// MARK: - Core Type

/// Ball core symmetry type
enum CoreType: String, Codable, CaseIterable, Sendable {
    case symmetric
    case asymmetric

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .symmetric:
            return "Predictable, smooth arc motion"
        case .asymmetric:
            return "Stronger backend reaction"
        }
    }
}

// MARK: - Catalog Ball

/// A bowling ball from the catalog database
struct CatalogBall: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let brand: String
    let coverstock: String
    let coreName: String
    let coreType: CoreType
    let rg: Double                    // Radius of gyration (typically 2.46-2.60)
    let differential: Double          // Differential (typically 0.010-0.060)
    let massBiasDiff: Double?         // Mass bias differential (asymmetric only)
    let releaseDate: String?          // Format: "YYYY-MM" or "YYYY"
    let colors: [String]              // Primary color names like ["purple", "blue"]

    // MARK: - Computed Properties

    /// Display name combining brand and ball name
    var displayName: String {
        "\(brand) \(name)"
    }

    /// Primary color for HSV matching (first in list)
    var primaryColor: String {
        colors.first ?? "unknown"
    }

    /// Secondary color if available
    var secondaryColor: String? {
        colors.count > 1 ? colors[1] : nil
    }

    /// Formatted RG value
    var formattedRG: String {
        String(format: "%.2f", rg)
    }

    /// Formatted differential value
    var formattedDiff: String {
        String(format: "%.3f", differential)
    }

    /// Brief specs string for list display
    var specsString: String {
        "RG: \(formattedRG) | Diff: \(formattedDiff)"
    }

    /// Full specs for detail view
    var fullSpecsString: String {
        var specs = "RG: \(formattedRG), Diff: \(formattedDiff)"
        if let massBias = massBiasDiff {
            specs += ", MB: \(String(format: "%.3f", massBias))"
        }
        return specs
    }

    // MARK: - HSV Color Mapping

    /// Suggested HSV color based on the ball's primary color
    var suggestedHSVColor: HSVColor {
        colorNameToHSV(primaryColor)
    }

    /// Convert color name to HSV values
    private func colorNameToHSV(_ colorName: String) -> HSVColor {
        switch colorName.lowercased() {
        case "blue", "navy", "cobalt":
            return HSVColor(h: 210, s: 80, v: 70)
        case "red", "crimson", "scarlet":
            return HSVColor(h: 0, s: 85, v: 75)
        case "purple", "violet", "plum":
            return HSVColor(h: 280, s: 70, v: 60)
        case "orange", "tangerine":
            return HSVColor(h: 30, s: 90, v: 85)
        case "green", "emerald", "lime":
            return HSVColor(h: 120, s: 70, v: 60)
        case "pink", "magenta", "fuchsia":
            return HSVColor(h: 330, s: 60, v: 80)
        case "yellow", "gold":
            return HSVColor(h: 55, s: 85, v: 90)
        case "black", "onyx", "carbon":
            return HSVColor(h: 0, s: 0, v: 15)
        case "white", "pearl":
            return HSVColor(h: 0, s: 0, v: 95)
        case "silver", "gray", "grey":
            return HSVColor(h: 0, s: 0, v: 60)
        case "teal", "cyan", "aqua":
            return HSVColor(h: 180, s: 70, v: 70)
        case "bronze", "copper", "brown":
            return HSVColor(h: 30, s: 60, v: 50)
        case "burgundy", "maroon":
            return HSVColor(h: 345, s: 70, v: 50)
        default:
            // Default to a medium gray for unknown colors
            return HSVColor(h: 0, s: 0, v: 50)
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CatalogBall, rhs: CatalogBall) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Ball Catalog

/// Container for the full ball catalog
struct BallCatalog: Codable, Sendable {
    let balls: [CatalogBall]
    let lastUpdated: String           // ISO 8601 date string

    // MARK: - Computed Properties

    /// All unique brands in the catalog, sorted alphabetically
    var brands: [String] {
        Array(Set(balls.map { $0.brand })).sorted()
    }

    /// Total number of balls in the catalog
    var count: Int {
        balls.count
    }

    /// Last updated as Date
    var lastUpdatedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: lastUpdated)
    }

    // MARK: - Filtering

    /// Filter balls by brand
    func balls(forBrand brand: String) -> [CatalogBall] {
        balls.filter { $0.brand.lowercased() == brand.lowercased() }
    }

    /// Filter balls by primary color
    func balls(withColor color: String) -> [CatalogBall] {
        balls.filter { ball in
            ball.colors.contains { $0.lowercased() == color.lowercased() }
        }
    }

    /// Filter balls by core type
    func balls(withCoreType coreType: CoreType) -> [CatalogBall] {
        balls.filter { $0.coreType == coreType }
    }

    /// Search balls by name (case-insensitive)
    func search(query: String) -> [CatalogBall] {
        guard !query.isEmpty else { return balls }
        let lowercasedQuery = query.lowercased()
        return balls.filter { ball in
            ball.name.lowercased().contains(lowercasedQuery) ||
            ball.brand.lowercased().contains(lowercasedQuery) ||
            ball.coverstock.lowercased().contains(lowercasedQuery)
        }
    }

    /// Get ball by ID
    func ball(withId id: String) -> CatalogBall? {
        balls.first { $0.id == id }
    }

    // MARK: - Grouping

    /// Balls grouped by brand
    var ballsByBrand: [String: [CatalogBall]] {
        Dictionary(grouping: balls) { $0.brand }
    }

    /// Balls grouped by primary color
    var ballsByColor: [String: [CatalogBall]] {
        Dictionary(grouping: balls) { $0.primaryColor }
    }
}
