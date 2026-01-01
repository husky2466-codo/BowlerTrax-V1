//
//  Session.swift
//  BowlerTrax
//
//  Bowling session (practice or league)
//

import Foundation

/// Bowling session (practice or league)
struct Session: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var centerId: UUID?
    var centerName: String?
    var calibrationId: UUID?
    var ballProfileId: UUID?
    var name: String?
    var lane: Int?
    var oilPattern: OilPatternType
    var hand: HandPreference
    var isLeague: Bool
    let startTime: Date
    var endTime: Date?
    var notes: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        centerId: UUID? = nil,
        centerName: String? = nil,
        calibrationId: UUID? = nil,
        ballProfileId: UUID? = nil,
        name: String? = nil,
        lane: Int? = nil,
        oilPattern: OilPatternType = .house,
        hand: HandPreference = .right,
        isLeague: Bool = false,
        startTime: Date = Date(),
        endTime: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.centerId = centerId
        self.centerName = centerName
        self.calibrationId = calibrationId
        self.ballProfileId = ballProfileId
        self.name = name
        self.lane = lane
        self.oilPattern = oilPattern
        self.hand = hand
        self.isLeague = isLeague
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension Session {
    /// Session duration if ended
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    /// Formatted duration string
    var durationDisplay: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Display name for the session
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        if let centerName = centerName {
            return centerName
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "Session \(formatter.string(from: startTime))"
    }

    /// Check if session is currently active
    var isActive: Bool {
        endTime == nil
    }

    /// Lane display string
    var laneDisplay: String? {
        guard let lane = lane else { return nil }
        return "Lane \(lane)"
    }

    /// Full location display (center + lane)
    var locationDisplay: String {
        var parts: [String] = []
        if let centerName = centerName {
            parts.append(centerName)
        }
        if let laneDisplay = laneDisplay {
            parts.append(laneDisplay)
        }
        return parts.isEmpty ? "Unknown Location" : parts.joined(separator: " - ")
    }
}

// MARK: - Session Statistics

/// Session statistics summary
struct SessionStats: Codable, Equatable, Sendable {
    var totalShots: Int
    var strikes: Int
    var spares: Int
    var opens: Int
    var avgSpeedMph: Double
    var avgRevRateRpm: Double
    var avgEntryAngle: Double
    var consistencyScore: Double  // 0-100, how consistent the shots are

    var strikePercentage: Double {
        guard totalShots > 0 else { return 0 }
        return Double(strikes) / Double(totalShots) * 100
    }

    var sparePercentage: Double {
        let attempts = totalShots - strikes
        guard attempts > 0 else { return 0 }
        return Double(spares) / Double(attempts) * 100
    }

    static let empty = SessionStats(
        totalShots: 0,
        strikes: 0,
        spares: 0,
        opens: 0,
        avgSpeedMph: 0,
        avgRevRateRpm: 0,
        avgEntryAngle: 0,
        consistencyScore: 0
    )

    /// Formatted strike percentage string
    var strikePercentageDisplay: String {
        String(format: "%.0f%%", strikePercentage)
    }

    /// Formatted spare percentage string
    var sparePercentageDisplay: String {
        String(format: "%.0f%%", sparePercentage)
    }

    /// Formatted average speed string
    var avgSpeedDisplay: String {
        String(format: "%.1f mph", avgSpeedMph)
    }

    /// Formatted average rev rate string
    var avgRevRateDisplay: String {
        String(format: "%.0f RPM", avgRevRateRpm)
    }

    /// Formatted average entry angle string
    var avgEntryAngleDisplay: String {
        String(format: "%.1f°", avgEntryAngle)
    }

    /// Formatted consistency score string
    var consistencyDisplay: String {
        String(format: "%.0f", consistencyScore)
    }
}
