//
//  CenterEntity.swift
//  BowlerTrax
//
//  SwiftData entity for bowling centers
//

import Foundation
import SwiftData

@Model
final class CenterEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String?
    var laneCount: Int?
    var defaultOilPattern: String?  // Store as raw value
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SessionEntity.center)
    var sessions: [SessionEntity]?

    @Relationship(deleteRule: .cascade, inverse: \CalibrationEntity.center)
    var calibrations: [CalibrationEntity]?

    /// Default initializer required by SwiftData
    init() {
        self.id = UUID()
        self.name = ""
        self.createdAt = Date()
    }

    init(from center: Center) {
        self.id = center.id
        self.name = center.name
        self.address = center.address
        self.laneCount = center.laneCount
        self.defaultOilPattern = center.defaultOilPattern?.rawValue
        self.createdAt = center.createdAt
    }

    func toModel() -> Center {
        Center(
            id: id,
            name: name,
            address: address,
            laneCount: laneCount,
            defaultOilPattern: defaultOilPattern.flatMap { OilPatternType(rawValue: $0) },
            createdAt: createdAt
        )
    }

    /// Update entity from domain model
    func update(from center: Center) {
        self.name = center.name
        self.address = center.address
        self.laneCount = center.laneCount
        self.defaultOilPattern = center.defaultOilPattern?.rawValue
    }
}
