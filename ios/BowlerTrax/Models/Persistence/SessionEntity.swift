//
//  SessionEntity.swift
//  BowlerTrax
//
//  SwiftData entity for bowling sessions
//

import Foundation
import SwiftData

@Model
final class SessionEntity {
    @Attribute(.unique) var id: UUID
    var centerId: UUID?
    var centerName: String?
    var calibrationId: UUID?
    var ballProfileId: UUID?
    var name: String?
    var lane: Int?
    var oilPattern: String
    var hand: String
    var isLeague: Bool
    var startTime: Date
    var endTime: Date?
    var notes: String?
    var createdAt: Date

    var center: CenterEntity?
    var ballProfile: BallProfileEntity?

    @Relationship(deleteRule: .cascade, inverse: \ShotEntity.session)
    var shots: [ShotEntity]?

    /// Default initializer required by SwiftData
    init() {
        self.id = UUID()
        self.oilPattern = OilPatternType.house.rawValue
        self.hand = HandPreference.right.rawValue
        self.isLeague = false
        self.startTime = Date()
        self.createdAt = Date()
    }

    init(from session: Session) {
        self.id = session.id
        self.centerId = session.centerId
        self.centerName = session.centerName
        self.calibrationId = session.calibrationId
        self.ballProfileId = session.ballProfileId
        self.name = session.name
        self.lane = session.lane
        self.oilPattern = session.oilPattern.rawValue
        self.hand = session.hand.rawValue
        self.isLeague = session.isLeague
        self.startTime = session.startTime
        self.endTime = session.endTime
        self.notes = session.notes
        self.createdAt = session.createdAt
    }

    func toModel() -> Session {
        Session(
            id: id,
            centerId: centerId,
            centerName: centerName,
            calibrationId: calibrationId,
            ballProfileId: ballProfileId,
            name: name,
            lane: lane,
            oilPattern: OilPatternType(rawValue: oilPattern) ?? .house,
            hand: HandPreference(rawValue: hand) ?? .right,
            isLeague: isLeague,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            createdAt: createdAt
        )
    }

    /// Update entity from domain model
    func update(from session: Session) {
        self.centerName = session.centerName
        self.calibrationId = session.calibrationId
        self.ballProfileId = session.ballProfileId
        self.name = session.name
        self.lane = session.lane
        self.oilPattern = session.oilPattern.rawValue
        self.hand = session.hand.rawValue
        self.isLeague = session.isLeague
        self.endTime = session.endTime
        self.notes = session.notes
    }

    /// End the session
    func endSession() {
        self.endTime = Date()
    }

    /// Get shot count
    var shotCount: Int {
        shots?.count ?? 0
    }
}
