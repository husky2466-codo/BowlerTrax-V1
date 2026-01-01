//
//  OilPatternService.swift
//  BowlerTrax
//
//  Service for loading and managing oil patterns
//

import Foundation

// MARK: - Oil Pattern Catalog

/// Container for oil pattern data from JSON
struct OilPatternCatalog: Codable {
    let patterns: [OilPatternData]
    let lastUpdated: String
    let version: String

    /// Get all patterns as domain models
    var patternModels: [OilPattern] {
        patterns.map { $0.toModel() }
    }

    /// Get patterns by category
    func patterns(forCategory category: OilPattern.PatternCategory) -> [OilPattern] {
        patternModels.filter { $0.category == category }
    }

    /// Get patterns by difficulty
    func patterns(forDifficulty difficulty: OilPattern.PatternDifficulty) -> [OilPattern] {
        patternModels.filter { $0.difficulty == difficulty }
    }
}

/// Raw pattern data from JSON
struct OilPatternData: Codable {
    let id: String
    let name: String
    let category: String
    let lengthFeet: Int
    let volumeML: Double?
    let ratio: Double?
    let difficulty: String
    let description: String?
    let isPreset: Bool

    func toModel() -> OilPattern {
        OilPattern(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            category: OilPattern.PatternCategory(rawValue: category) ?? .custom,
            lengthFeet: lengthFeet,
            volumeML: volumeML,
            ratio: ratio,
            difficulty: OilPattern.PatternDifficulty(rawValue: difficulty) ?? .medium,
            description: description,
            isPreset: isPreset
        )
    }
}

// MARK: - Oil Pattern Error

enum OilPatternError: LocalizedError {
    case fileNotFound
    case invalidData
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Oil pattern catalog file not found."
        case .invalidData:
            return "Oil pattern catalog data is invalid."
        case .decodingFailed(let error):
            return "Failed to decode oil pattern catalog: \(error.localizedDescription)"
        }
    }
}

// MARK: - Oil Pattern Service

/// Service for loading and querying oil patterns
@MainActor
final class OilPatternService: ObservableObject {
    // MARK: - Singleton

    static let shared = OilPatternService()

    // MARK: - Published Properties

    @Published private(set) var catalog: OilPatternCatalog?
    @Published private(set) var isLoading = false
    @Published private(set) var error: OilPatternError?

    // MARK: - Private Properties

    private var cachedPatterns: [OilPattern]?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Load the oil pattern catalog from the bundled JSON file
    func loadCatalog() async {
        guard catalog == nil else { return }  // Already loaded

        isLoading = true
        error = nil

        do {
            let loadedCatalog = try await loadFromBundle()
            catalog = loadedCatalog
            cachedPatterns = loadedCatalog.patternModels
        } catch let catalogError as OilPatternError {
            error = catalogError
        } catch {
            self.error = .decodingFailed(error)
        }

        isLoading = false
    }

    /// Get all patterns, loading if necessary
    var patterns: [OilPattern] {
        cachedPatterns ?? []
    }

    /// Get all preset patterns
    var presetPatterns: [OilPattern] {
        patterns.filter { $0.isPreset }
    }

    /// Get all categories with patterns
    var categories: [OilPattern.PatternCategory] {
        Array(Set(patterns.map { $0.category })).sorted { $0.rawValue < $1.rawValue }
    }

    /// Get patterns for a specific category
    func patterns(forCategory category: OilPattern.PatternCategory) -> [OilPattern] {
        patterns.filter { $0.category == category }.sorted()
    }

    /// Get patterns for a specific difficulty
    func patterns(forDifficulty difficulty: OilPattern.PatternDifficulty) -> [OilPattern] {
        patterns.filter { $0.difficulty == difficulty }.sorted()
    }

    /// Search patterns by query
    func search(query: String) -> [OilPattern] {
        guard !query.isEmpty else { return patterns }

        let lowercasedQuery = query.lowercased()
        return patterns.filter { pattern in
            pattern.name.lowercased().contains(lowercasedQuery) ||
            pattern.category.rawValue.lowercased().contains(lowercasedQuery) ||
            (pattern.description?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }

    /// Get a pattern by name
    func pattern(named name: String) -> OilPattern? {
        patterns.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Get patterns grouped by category
    var patternsByCategory: [(category: OilPattern.PatternCategory, patterns: [OilPattern])] {
        categories.map { category in
            (category: category, patterns: patterns(forCategory: category))
        }
    }

    /// Get patterns grouped by difficulty
    var patternsByDifficulty: [(difficulty: OilPattern.PatternDifficulty, patterns: [OilPattern])] {
        OilPattern.PatternDifficulty.allCases.map { difficulty in
            (difficulty: difficulty, patterns: patterns(forDifficulty: difficulty))
        }
    }

    /// Reload the catalog (for refresh purposes)
    func reload() async {
        catalog = nil
        cachedPatterns = nil
        await loadCatalog()
    }

    // MARK: - Private Methods

    private func loadFromBundle() async throws -> OilPatternCatalog {
        guard let url = Bundle.main.url(forResource: "OilPatterns", withExtension: "json") else {
            throw OilPatternError.fileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw OilPatternError.invalidData
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(OilPatternCatalog.self, from: data)
        } catch {
            throw OilPatternError.decodingFailed(error)
        }
    }
}

// MARK: - Preview Helper

extension OilPatternService {
    /// Create a service with sample data for previews
    static func preview() -> OilPatternService {
        let service = OilPatternService()
        service.catalog = OilPatternCatalog.sampleCatalog
        service.cachedPatterns = OilPatternCatalog.sampleCatalog.patternModels
        return service
    }
}

// MARK: - Sample Data

extension OilPatternCatalog {
    /// Sample catalog for previews and testing
    static var sampleCatalog: OilPatternCatalog {
        OilPatternCatalog(
            patterns: [
                OilPatternData(
                    id: UUID().uuidString,
                    name: "Cheetah",
                    category: "PBA Animal",
                    lengthFeet: 33,
                    volumeML: 22.0,
                    ratio: 4.0,
                    difficulty: "Short",
                    description: "A short, fast-playing pattern that demands accuracy.",
                    isPreset: true
                ),
                OilPatternData(
                    id: UUID().uuidString,
                    name: "Bear",
                    category: "PBA Animal",
                    lengthFeet: 41,
                    volumeML: 25.0,
                    ratio: 5.5,
                    difficulty: "Medium",
                    description: "A powerful medium pattern that rewards strength and rev rate.",
                    isPreset: true
                ),
                OilPatternData(
                    id: UUID().uuidString,
                    name: "Shark",
                    category: "PBA Animal",
                    lengthFeet: 48,
                    volumeML: 29.0,
                    ratio: 8.0,
                    difficulty: "Long",
                    description: "The longest PBA Animal pattern.",
                    isPreset: true
                ),
                OilPatternData(
                    id: UUID().uuidString,
                    name: "Typical House Shot",
                    category: "House Shot",
                    lengthFeet: 40,
                    volumeML: 20.0,
                    ratio: 10.0,
                    difficulty: "Medium",
                    description: "Standard recreational center pattern.",
                    isPreset: true
                )
            ],
            lastUpdated: "2025-01-01",
            version: "1.0.0"
        )
    }
}

// MARK: - Static Preset Loader

extension OilPattern {
    /// Load all preset patterns from the bundled JSON
    /// Use this when you need patterns synchronously (e.g., in initializers)
    static func loadPresets() -> [OilPattern] {
        guard let url = Bundle.main.url(forResource: "OilPatterns", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(OilPatternCatalog.self, from: data) else {
            return []
        }
        return catalog.patternModels
    }

    /// Get a preset pattern by name
    static func preset(named name: String) -> OilPattern? {
        loadPresets().first { $0.name.lowercased() == name.lowercased() }
    }

    /// All PBA Animal patterns
    static var pbaAnimalPatterns: [OilPattern] {
        loadPresets().filter { $0.category == .pbaAnimal }.sorted()
    }

    /// All PBA Hall of Fame patterns
    static var pbaHallOfFamePatterns: [OilPattern] {
        loadPresets().filter { $0.category == .pbaHallOfFame }.sorted()
    }

    /// All House patterns
    static var housePatterns: [OilPattern] {
        loadPresets().filter { $0.category == .house }.sorted()
    }
}
