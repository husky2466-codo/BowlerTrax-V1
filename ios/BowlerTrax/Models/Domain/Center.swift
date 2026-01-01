//
//  Center.swift
//  BowlerTrax
//
//  Bowling center (saved location)
//

import Foundation

/// Bowling center (saved location)
struct Center: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var address: String?
    var laneCount: Int?
    var defaultOilPattern: OilPatternType?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        address: String? = nil,
        laneCount: Int? = nil,
        defaultOilPattern: OilPatternType? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.laneCount = laneCount
        self.defaultOilPattern = defaultOilPattern
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension Center {
    /// Display string for lane count
    var laneCountDisplay: String? {
        guard let count = laneCount else { return nil }
        return "\(count) lanes"
    }

    /// Full display string with address
    var fullDisplay: String {
        var parts = [name]
        if let address = address {
            parts.append(address)
        }
        return parts.joined(separator: "\n")
    }
}

// MARK: - Validation

extension Center {
    /// Check if center has minimum required data
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
