//
//  OilPatternEntity.swift
//  BowlerTrax
//
//  SwiftData entity for oil patterns
//

import Foundation
import SwiftData

@Model
final class OilPatternEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var lengthFeet: Int
    var volumeML: Double?
    var ratio: Double?
    var difficulty: String
    var patternDescription: String?
    var isPreset: Bool
    var createdAt: Date

    /// Default initializer required by SwiftData
    init() {
        self.id = UUID()
        self.name = ""
        self.category = OilPattern.PatternCategory.custom.rawValue
        self.lengthFeet = 40
        self.difficulty = OilPattern.PatternDifficulty.medium.rawValue
        self.isPreset = false
        self.createdAt = Date()
    }

    /// Initialize from domain model
    init(from pattern: OilPattern) {
        self.id = pattern.id
        self.name = pattern.name
        self.category = pattern.category.rawValue
        self.lengthFeet = pattern.lengthFeet
        self.volumeML = pattern.volumeML
        self.ratio = pattern.ratio
        self.difficulty = pattern.difficulty.rawValue
        self.patternDescription = pattern.description
        self.isPreset = pattern.isPreset
        self.createdAt = Date()
    }

    /// Convert to domain model
    func toModel() -> OilPattern {
        OilPattern(
            id: id,
            name: name,
            category: OilPattern.PatternCategory(rawValue: category) ?? .custom,
            lengthFeet: lengthFeet,
            volumeML: volumeML,
            ratio: ratio,
            difficulty: OilPattern.PatternDifficulty(rawValue: difficulty) ?? .medium,
            description: patternDescription,
            isPreset: isPreset
        )
    }

    /// Update entity from domain model
    func update(from pattern: OilPattern) {
        self.name = pattern.name
        self.category = pattern.category.rawValue
        self.lengthFeet = pattern.lengthFeet
        self.volumeML = pattern.volumeML
        self.ratio = pattern.ratio
        self.difficulty = pattern.difficulty.rawValue
        self.patternDescription = pattern.description
        self.isPreset = pattern.isPreset
    }
}

// MARK: - Queries

extension OilPatternEntity {
    /// Fetch descriptor for all patterns sorted by category and length
    static var allPatternsSorted: FetchDescriptor<OilPatternEntity> {
        let descriptor = FetchDescriptor<OilPatternEntity>(
            sortBy: [
                SortDescriptor(\.category),
                SortDescriptor(\.lengthFeet)
            ]
        )
        return descriptor
    }

    /// Fetch descriptor for preset patterns only
    static var presetsOnly: FetchDescriptor<OilPatternEntity> {
        let descriptor = FetchDescriptor<OilPatternEntity>(
            predicate: #Predicate { $0.isPreset },
            sortBy: [
                SortDescriptor(\.category),
                SortDescriptor(\.lengthFeet)
            ]
        )
        return descriptor
    }

    /// Fetch descriptor for custom patterns only
    static var customOnly: FetchDescriptor<OilPatternEntity> {
        let descriptor = FetchDescriptor<OilPatternEntity>(
            predicate: #Predicate { !$0.isPreset },
            sortBy: [
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        return descriptor
    }

    /// Fetch descriptor for patterns by category
    static func byCategory(_ category: OilPattern.PatternCategory) -> FetchDescriptor<OilPatternEntity> {
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<OilPatternEntity>(
            predicate: #Predicate { $0.category == categoryRaw },
            sortBy: [SortDescriptor(\.lengthFeet)]
        )
        return descriptor
    }

    /// Fetch descriptor for patterns by difficulty
    static func byDifficulty(_ difficulty: OilPattern.PatternDifficulty) -> FetchDescriptor<OilPatternEntity> {
        let difficultyRaw = difficulty.rawValue
        let descriptor = FetchDescriptor<OilPatternEntity>(
            predicate: #Predicate { $0.difficulty == difficultyRaw },
            sortBy: [SortDescriptor(\.lengthFeet)]
        )
        return descriptor
    }
}
