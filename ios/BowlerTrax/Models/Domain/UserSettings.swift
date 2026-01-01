//
//  UserSettings.swift
//  BowlerTrax
//
//  User settings and preferences
//

import Foundation

/// User settings/preferences
struct UserSettings: Codable, Equatable, Sendable {
    var hand: HandPreference
    var defaultOilPattern: OilPatternType
    var showPreviousShot: Bool
    var autoSaveVideos: Bool
    var hapticFeedback: Bool
    var defaultBallProfileId: UUID?
    var defaultCenterId: UUID?

    static let defaults = UserSettings(
        hand: .right,
        defaultOilPattern: .house,
        showPreviousShot: true,
        autoSaveVideos: true,
        hapticFeedback: true,
        defaultBallProfileId: nil,
        defaultCenterId: nil
    )
}

// MARK: - UserDefaults Keys

extension UserSettings {
    private enum Keys {
        static let hand = "settings.hand"
        static let defaultOilPattern = "settings.defaultOilPattern"
        static let showPreviousShot = "settings.showPreviousShot"
        static let autoSaveVideos = "settings.autoSaveVideos"
        static let hapticFeedback = "settings.hapticFeedback"
        static let defaultBallProfileId = "settings.defaultBallProfileId"
        static let defaultCenterId = "settings.defaultCenterId"
    }

    /// Save settings to UserDefaults
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(hand.rawValue, forKey: Keys.hand)
        defaults.set(defaultOilPattern.rawValue, forKey: Keys.defaultOilPattern)
        defaults.set(showPreviousShot, forKey: Keys.showPreviousShot)
        defaults.set(autoSaveVideos, forKey: Keys.autoSaveVideos)
        defaults.set(hapticFeedback, forKey: Keys.hapticFeedback)
        defaults.set(defaultBallProfileId?.uuidString, forKey: Keys.defaultBallProfileId)
        defaults.set(defaultCenterId?.uuidString, forKey: Keys.defaultCenterId)
    }

    /// Load settings from UserDefaults
    static func load() -> UserSettings {
        let defaults = UserDefaults.standard

        let hand = defaults.string(forKey: Keys.hand)
            .flatMap { HandPreference(rawValue: $0) } ?? .right

        let oilPattern = defaults.string(forKey: Keys.defaultOilPattern)
            .flatMap { OilPatternType(rawValue: $0) } ?? .house

        let showPreviousShot = defaults.object(forKey: Keys.showPreviousShot) as? Bool ?? true
        let autoSaveVideos = defaults.object(forKey: Keys.autoSaveVideos) as? Bool ?? true
        let hapticFeedback = defaults.object(forKey: Keys.hapticFeedback) as? Bool ?? true

        let ballProfileId = defaults.string(forKey: Keys.defaultBallProfileId)
            .flatMap { UUID(uuidString: $0) }

        let centerId = defaults.string(forKey: Keys.defaultCenterId)
            .flatMap { UUID(uuidString: $0) }

        return UserSettings(
            hand: hand,
            defaultOilPattern: oilPattern,
            showPreviousShot: showPreviousShot,
            autoSaveVideos: autoSaveVideos,
            hapticFeedback: hapticFeedback,
            defaultBallProfileId: ballProfileId,
            defaultCenterId: centerId
        )
    }
}
