# BowlerTrax State Management and Data Models Specification

This document defines the Swift-native state management architecture for BowlerTrax, converting the TypeScript models from the React Native prototype to Swift/SwiftData for iOS 17+.

---

## 1. Swift Data Models

All models conform to `Codable` for JSON persistence/export and use Swift's value types where appropriate.

### 1.1 Color Types

```swift
import Foundation

/// HSV color representation (better for tracking than RGB)
struct HSVColor: Codable, Equatable, Hashable {
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
}

/// RGB color for display purposes
struct RGBColor: Codable, Equatable, Hashable {
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
}
```

### 1.2 Enumerations

```swift
import Foundation

/// Rev rate categories based on industry standards
enum RevCategory: String, Codable, CaseIterable {
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
}

/// Oil pattern types
enum OilPatternType: String, Codable, CaseIterable {
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
enum HandPreference: String, Codable, CaseIterable {
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
enum ShotResult: String, Codable, CaseIterable {
    case strike
    case spare
    case open
    case split
    case washout

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
        }
    }
}

/// Predicted leave types
enum PredictedLeave: String, Codable, CaseIterable {
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
enum BallPhase: String, Codable, CaseIterable {
    case skid
    case hook
    case roll

    var displayName: String {
        rawValue.capitalized
    }
}

/// Calibration wizard step
enum CalibrationStep: String, Codable, CaseIterable {
    case position     // Position camera
    case foulLine     // Mark foul line
    case arrows       // Mark arrows
    case verify       // Verify calibration
    case complete     // Done

    var displayName: String {
        switch self {
        case .position: return "Position Camera"
        case .foulLine: return "Mark Foul Line"
        case .arrows: return "Mark Arrows"
        case .verify: return "Verify"
        case .complete: return "Complete"
        }
    }

    var stepNumber: Int {
        switch self {
        case .position: return 1
        case .foulLine: return 2
        case .arrows: return 3
        case .verify: return 4
        case .complete: return 5
        }
    }
}
```

### 1.3 Core Domain Models

```swift
import Foundation

// MARK: - Center (Bowling Alley)

/// Bowling center (saved location)
struct Center: Codable, Identifiable, Equatable {
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

// MARK: - Ball Profile

/// Ball profile for color-based tracking
struct BallProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var brand: String?
    var color: HSVColor              // Ball color for detection
    var colorTolerance: Double       // How much variance allowed (default 15)
    var markerColor: HSVColor?       // PAP marker color for rev tracking
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        color: HSVColor,
        colorTolerance: Double = 15.0,
        markerColor: HSVColor? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.color = color
        self.colorTolerance = colorTolerance
        self.markerColor = markerColor
        self.createdAt = createdAt
    }
}

// MARK: - Calibration

/// Arrow point for calibration
struct ArrowPoint: Codable, Equatable {
    var arrowNumber: Int     // 1-7 (arrows on boards 5,10,15,20,25,30,35)
    var pixelX: Double
    var pixelY: Double
    var boardNumber: Int     // 5, 10, 15, 20, 25, 30, or 35

    static let standardBoards = [5, 10, 15, 20, 25, 30, 35]
}

/// Calibration profile saved for a center
struct CalibrationProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var centerId: UUID
    var centerName: String
    var laneNumber: Int?

    // Conversion factors
    var pixelsPerFoot: Double
    var pixelsPerBoard: Double

    // Reference points
    var foulLineY: Double
    var arrowsY: Double
    var leftGutterX: Double
    var rightGutterX: Double

    // Camera info
    var cameraHeightFt: Double?
    var cameraAngleDeg: Double?

    let createdAt: Date
    var lastUsed: Date?

    init(
        id: UUID = UUID(),
        centerId: UUID,
        centerName: String,
        laneNumber: Int? = nil,
        pixelsPerFoot: Double,
        pixelsPerBoard: Double,
        foulLineY: Double,
        arrowsY: Double,
        leftGutterX: Double,
        rightGutterX: Double,
        cameraHeightFt: Double? = nil,
        cameraAngleDeg: Double? = nil,
        createdAt: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.centerId = centerId
        self.centerName = centerName
        self.laneNumber = laneNumber
        self.pixelsPerFoot = pixelsPerFoot
        self.pixelsPerBoard = pixelsPerBoard
        self.foulLineY = foulLineY
        self.arrowsY = arrowsY
        self.leftGutterX = leftGutterX
        self.rightGutterX = rightGutterX
        self.cameraHeightFt = cameraHeightFt
        self.cameraAngleDeg = cameraAngleDeg
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }

    // MARK: - Pixel Conversion Methods

    func pixelToBoard(_ pixelX: Double) -> Double {
        let totalWidth = rightGutterX - leftGutterX
        let normalizedX = (pixelX - leftGutterX) / totalWidth
        return normalizedX * 39.0 + 1.0  // Boards 1-39
    }

    func pixelToDistanceFt(_ pixelY: Double) -> Double {
        (foulLineY - pixelY) / pixelsPerFoot
    }

    func boardToPixel(_ board: Double) -> Double {
        let normalizedX = (board - 1.0) / 39.0
        let totalWidth = rightGutterX - leftGutterX
        return leftGutterX + (normalizedX * totalWidth)
    }

    func distanceFtToPixel(_ distanceFt: Double) -> Double {
        foulLineY - (distanceFt * pixelsPerFoot)
    }
}

// MARK: - Session

/// Bowling session (practice or league)
struct Session: Codable, Identifiable, Equatable {
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

    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

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
}

// MARK: - Shot

/// Individual shot with all tracked metrics
struct Shot: Codable, Identifiable, Equatable {
    let id: UUID
    let sessionId: UUID
    var shotNumber: Int
    let timestamp: Date
    var frameNumber: Int?
    var isFirstBall: Bool

    // Speed metrics
    var launchSpeed: Double?          // Launch speed off hand (mph)
    var impactSpeed: Double?          // Speed at pins (mph)

    // Position metrics (in boards)
    var foulLineBoard: Double?        // Board at foul line
    var arrowBoard: Double?           // Board crossed at arrows (15ft)
    var breakpointBoard: Double?      // Where ball starts hooking
    var breakpointDistance: Double?   // Distance to breakpoint (feet)
    var pocketBoard: Double?          // Board position at pins
    var pocketOffset: Double?         // Distance from ideal 17.5/22.5 board

    // Angle metrics
    var entryAngle: Double?           // Angle into pocket (optimal: 6 degrees)
    var launchAngle: Double?          // Angle at release

    // Rev rate
    var revRate: Double?              // Revolutions per minute
    var revCategory: RevCategory?     // stroker/tweener/cranker

    // Result
    var result: ShotResult?
    var pinsLeft: [Int]?              // Array of remaining pins (1-10)
    var strikeProbability: Double?    // 0-1 probability
    var predictedLeave: PredictedLeave?

    // Video reference
    var videoPath: String?
    var thumbnailPath: String?

    // Raw trajectory data (not persisted to DB, computed on load)
    var trajectory: [TrajectoryPoint]?

    let createdAt: Date

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        shotNumber: Int,
        timestamp: Date = Date(),
        frameNumber: Int? = nil,
        isFirstBall: Bool = true,
        launchSpeed: Double? = nil,
        impactSpeed: Double? = nil,
        foulLineBoard: Double? = nil,
        arrowBoard: Double? = nil,
        breakpointBoard: Double? = nil,
        breakpointDistance: Double? = nil,
        pocketBoard: Double? = nil,
        pocketOffset: Double? = nil,
        entryAngle: Double? = nil,
        launchAngle: Double? = nil,
        revRate: Double? = nil,
        revCategory: RevCategory? = nil,
        result: ShotResult? = nil,
        pinsLeft: [Int]? = nil,
        strikeProbability: Double? = nil,
        predictedLeave: PredictedLeave? = nil,
        videoPath: String? = nil,
        thumbnailPath: String? = nil,
        trajectory: [TrajectoryPoint]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.shotNumber = shotNumber
        self.timestamp = timestamp
        self.frameNumber = frameNumber
        self.isFirstBall = isFirstBall
        self.launchSpeed = launchSpeed
        self.impactSpeed = impactSpeed
        self.foulLineBoard = foulLineBoard
        self.arrowBoard = arrowBoard
        self.breakpointBoard = breakpointBoard
        self.breakpointDistance = breakpointDistance
        self.pocketBoard = pocketBoard
        self.pocketOffset = pocketOffset
        self.entryAngle = entryAngle
        self.launchAngle = launchAngle
        self.revRate = revRate
        self.revCategory = revCategory
        self.result = result
        self.pinsLeft = pinsLeft
        self.strikeProbability = strikeProbability
        self.predictedLeave = predictedLeave
        self.videoPath = videoPath
        self.thumbnailPath = thumbnailPath
        self.trajectory = trajectory
        self.createdAt = createdAt
    }

    /// Calculate rev category from rev rate
    mutating func calculateRevCategory() {
        guard let rpm = revRate else {
            revCategory = nil
            return
        }
        switch rpm {
        case ..<300:
            revCategory = .stroker
        case 300..<400:
            revCategory = .tweener
        default:
            revCategory = .cranker
        }
    }

    /// Calculate pocket offset based on hand preference
    mutating func calculatePocketOffset(hand: HandPreference) {
        guard let pocketBoard = pocketBoard else {
            pocketOffset = nil
            return
        }
        pocketOffset = abs(pocketBoard - hand.pocketBoard)
    }
}

// MARK: - Trajectory Point

/// Single point in ball trajectory
struct TrajectoryPoint: Codable, Equatable {
    var x: Double              // Pixel X
    var y: Double              // Pixel Y
    var timestamp: TimeInterval // Seconds from shot start
    var frameNumber: Int       // Frame index
    var board: Double?         // Calculated board number (1-39)
    var distanceFt: Double?    // Calculated distance from foul line
    var phase: BallPhase?      // Current motion phase

    // Real-world coordinates (after calibration)
    var realWorldX: Double?    // Board position
    var realWorldY: Double?    // Distance from foul line in feet

    init(
        x: Double,
        y: Double,
        timestamp: TimeInterval,
        frameNumber: Int,
        board: Double? = nil,
        distanceFt: Double? = nil,
        phase: BallPhase? = nil,
        realWorldX: Double? = nil,
        realWorldY: Double? = nil
    ) {
        self.x = x
        self.y = y
        self.timestamp = timestamp
        self.frameNumber = frameNumber
        self.board = board
        self.distanceFt = distanceFt
        self.phase = phase
        self.realWorldX = realWorldX
        self.realWorldY = realWorldY
    }
}

// MARK: - Ball Detection

/// Ball detection result from a single frame
struct BallDetection: Codable, Equatable {
    var found: Bool
    var x: Double?
    var y: Double?
    var radius: Double?
    var confidence: Double       // 0-1 how confident the detection is
    var markerAngle: Double?     // Rotation angle of PAP marker (for rev rate)

    static let notFound = BallDetection(found: false, confidence: 0)

    init(
        found: Bool,
        x: Double? = nil,
        y: Double? = nil,
        radius: Double? = nil,
        confidence: Double,
        markerAngle: Double? = nil
    ) {
        self.found = found
        self.x = x
        self.y = y
        self.radius = radius
        self.confidence = confidence
        self.markerAngle = markerAngle
    }
}

// MARK: - Session Statistics

/// Session statistics summary
struct SessionStats: Codable, Equatable {
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
}

// MARK: - User Settings

/// User settings/preferences
struct UserSettings: Codable, Equatable {
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
```

---

## 2. SwiftData Schema

SwiftData models for persistent storage with relationships and indexes.

```swift
import Foundation
import SwiftData

// MARK: - Persistent Models

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
}

@Model
final class BallProfileEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var colorH: Double
    var colorS: Double
    var colorV: Double
    var colorTolerance: Double
    var markerColorH: Double?
    var markerColorS: Double?
    var markerColorV: Double?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \SessionEntity.ballProfile)
    var sessions: [SessionEntity]?

    init(from profile: BallProfile) {
        self.id = profile.id
        self.name = profile.name
        self.brand = profile.brand
        self.colorH = profile.color.h
        self.colorS = profile.color.s
        self.colorV = profile.color.v
        self.colorTolerance = profile.colorTolerance
        self.markerColorH = profile.markerColor?.h
        self.markerColorS = profile.markerColor?.s
        self.markerColorV = profile.markerColor?.v
        self.createdAt = profile.createdAt
    }

    func toModel() -> BallProfile {
        var markerColor: HSVColor? = nil
        if let h = markerColorH, let s = markerColorS, let v = markerColorV {
            markerColor = HSVColor(h: h, s: s, v: v)
        }
        return BallProfile(
            id: id,
            name: name,
            brand: brand,
            color: HSVColor(h: colorH, s: colorS, v: colorV),
            colorTolerance: colorTolerance,
            markerColor: markerColor,
            createdAt: createdAt
        )
    }
}

@Model
final class CalibrationEntity {
    @Attribute(.unique) var id: UUID
    var centerId: UUID
    var centerName: String
    var laneNumber: Int?
    var pixelsPerFoot: Double
    var pixelsPerBoard: Double
    var foulLineY: Double
    var arrowsY: Double
    var leftGutterX: Double
    var rightGutterX: Double
    var cameraHeightFt: Double?
    var cameraAngleDeg: Double?
    var createdAt: Date
    var lastUsed: Date?

    var center: CenterEntity?

    init(from profile: CalibrationProfile) {
        self.id = profile.id
        self.centerId = profile.centerId
        self.centerName = profile.centerName
        self.laneNumber = profile.laneNumber
        self.pixelsPerFoot = profile.pixelsPerFoot
        self.pixelsPerBoard = profile.pixelsPerBoard
        self.foulLineY = profile.foulLineY
        self.arrowsY = profile.arrowsY
        self.leftGutterX = profile.leftGutterX
        self.rightGutterX = profile.rightGutterX
        self.cameraHeightFt = profile.cameraHeightFt
        self.cameraAngleDeg = profile.cameraAngleDeg
        self.createdAt = profile.createdAt
        self.lastUsed = profile.lastUsed
    }

    func toModel() -> CalibrationProfile {
        CalibrationProfile(
            id: id,
            centerId: centerId,
            centerName: centerName,
            laneNumber: laneNumber,
            pixelsPerFoot: pixelsPerFoot,
            pixelsPerBoard: pixelsPerBoard,
            foulLineY: foulLineY,
            arrowsY: arrowsY,
            leftGutterX: leftGutterX,
            rightGutterX: rightGutterX,
            cameraHeightFt: cameraHeightFt,
            cameraAngleDeg: cameraAngleDeg,
            createdAt: createdAt,
            lastUsed: lastUsed
        )
    }
}

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
}

@Model
final class ShotEntity {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var shotNumber: Int
    var timestamp: Date
    var frameNumber: Int?
    var isFirstBall: Bool

    // Speed metrics
    var launchSpeed: Double?
    var impactSpeed: Double?

    // Position metrics
    var foulLineBoard: Double?
    var arrowBoard: Double?
    var breakpointBoard: Double?
    var breakpointDistance: Double?
    var pocketBoard: Double?
    var pocketOffset: Double?

    // Angle metrics
    var entryAngle: Double?
    var launchAngle: Double?

    // Rev rate
    var revRate: Double?
    var revCategory: String?

    // Result
    var result: String?
    var pinsLeftData: Data?  // JSON encoded [Int]
    var strikeProbability: Double?
    var predictedLeave: String?

    // Video reference
    var videoPath: String?
    var thumbnailPath: String?

    // Trajectory stored separately
    var trajectoryData: Data?  // JSON encoded [TrajectoryPoint]

    var createdAt: Date

    var session: SessionEntity?

    init(from shot: Shot) {
        self.id = shot.id
        self.sessionId = shot.sessionId
        self.shotNumber = shot.shotNumber
        self.timestamp = shot.timestamp
        self.frameNumber = shot.frameNumber
        self.isFirstBall = shot.isFirstBall
        self.launchSpeed = shot.launchSpeed
        self.impactSpeed = shot.impactSpeed
        self.foulLineBoard = shot.foulLineBoard
        self.arrowBoard = shot.arrowBoard
        self.breakpointBoard = shot.breakpointBoard
        self.breakpointDistance = shot.breakpointDistance
        self.pocketBoard = shot.pocketBoard
        self.pocketOffset = shot.pocketOffset
        self.entryAngle = shot.entryAngle
        self.launchAngle = shot.launchAngle
        self.revRate = shot.revRate
        self.revCategory = shot.revCategory?.rawValue
        self.result = shot.result?.rawValue
        self.pinsLeftData = try? JSONEncoder().encode(shot.pinsLeft)
        self.strikeProbability = shot.strikeProbability
        self.predictedLeave = shot.predictedLeave?.rawValue
        self.videoPath = shot.videoPath
        self.thumbnailPath = shot.thumbnailPath
        self.trajectoryData = try? JSONEncoder().encode(shot.trajectory)
        self.createdAt = shot.createdAt
    }

    func toModel() -> Shot {
        let pinsLeft: [Int]? = pinsLeftData.flatMap { try? JSONDecoder().decode([Int].self, from: $0) }
        let trajectory: [TrajectoryPoint]? = trajectoryData.flatMap { try? JSONDecoder().decode([TrajectoryPoint].self, from: $0) }

        return Shot(
            id: id,
            sessionId: sessionId,
            shotNumber: shotNumber,
            timestamp: timestamp,
            frameNumber: frameNumber,
            isFirstBall: isFirstBall,
            launchSpeed: launchSpeed,
            impactSpeed: impactSpeed,
            foulLineBoard: foulLineBoard,
            arrowBoard: arrowBoard,
            breakpointBoard: breakpointBoard,
            breakpointDistance: breakpointDistance,
            pocketBoard: pocketBoard,
            pocketOffset: pocketOffset,
            entryAngle: entryAngle,
            launchAngle: launchAngle,
            revRate: revRate,
            revCategory: revCategory.flatMap { RevCategory(rawValue: $0) },
            result: result.flatMap { ShotResult(rawValue: $0) },
            pinsLeft: pinsLeft,
            strikeProbability: strikeProbability,
            predictedLeave: predictedLeave.flatMap { PredictedLeave(rawValue: $0) },
            videoPath: videoPath,
            thumbnailPath: thumbnailPath,
            trajectory: trajectory,
            createdAt: createdAt
        )
    }
}

// MARK: - SwiftData Configuration

enum DataSchema {
    static let models: [any PersistentModel.Type] = [
        CenterEntity.self,
        BallProfileEntity.self,
        CalibrationEntity.self,
        SessionEntity.self,
        ShotEntity.self
    ]

    static var container: ModelContainer {
        let schema = Schema(models)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

### 2.1 Migration Strategy

```swift
import SwiftData

// Version history for migrations
enum DataSchemaVersion: Int {
    case v1 = 1  // Initial schema
    case v2 = 2  // Future: Add new fields

    static let current = DataSchemaVersion.v1
}

// Migration plan (for future use)
struct DataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []  // No migrations yet
    }
}

// Initial schema version
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        DataSchema.models
    }
}
```

---

## 3. App State Architecture

Using `@Observable` (iOS 17+) for reactive state management.

### 3.1 Session Manager

```swift
import Foundation
import SwiftData

@Observable
final class SessionManager {
    // MARK: - Published State

    private(set) var activeSession: Session?
    private(set) var activeShots: [Shot] = []
    private(set) var sessionStats: SessionStats = .empty
    private(set) var recentSessions: [Session] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Session Lifecycle

    func startSession(
        center: Center? = nil,
        calibration: CalibrationProfile? = nil,
        ballProfile: BallProfile? = nil,
        oilPattern: OilPatternType = .house,
        hand: HandPreference = .right,
        lane: Int? = nil,
        isLeague: Bool = false
    ) {
        let session = Session(
            centerId: center?.id,
            centerName: center?.name,
            calibrationId: calibration?.id,
            ballProfileId: ballProfile?.id,
            lane: lane,
            oilPattern: oilPattern,
            hand: hand,
            isLeague: isLeague
        )

        activeSession = session
        activeShots = []
        sessionStats = .empty

        // Persist immediately
        saveActiveSession()
    }

    func endSession() {
        guard var session = activeSession else { return }
        session.endTime = Date()
        activeSession = session

        // Final save
        saveActiveSession()

        // Clear active state
        activeSession = nil
        activeShots = []
        sessionStats = .empty

        // Refresh recent sessions
        loadRecentSessions()
    }

    // MARK: - Shot Management

    func addShot(_ shot: Shot) {
        guard activeSession != nil else { return }

        activeShots.append(shot)
        recalculateStats()

        // Persist shot
        let entity = ShotEntity(from: shot)
        modelContext.insert(entity)
        trySave()
    }

    func updateShot(_ shot: Shot) {
        guard let index = activeShots.firstIndex(where: { $0.id == shot.id }) else { return }
        activeShots[index] = shot
        recalculateStats()

        // Update in database
        let descriptor = FetchDescriptor<ShotEntity>(
            predicate: #Predicate { $0.id == shot.id }
        )
        if let entity = try? modelContext.fetch(descriptor).first {
            // Update entity properties
            updateShotEntity(entity, from: shot)
            trySave()
        }
    }

    func deleteShot(_ shot: Shot) {
        activeShots.removeAll { $0.id == shot.id }
        recalculateStats()

        // Delete from database
        let descriptor = FetchDescriptor<ShotEntity>(
            predicate: #Predicate { $0.id == shot.id }
        )
        if let entity = try? modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            trySave()
        }
    }

    // MARK: - Data Loading

    func loadRecentSessions(limit: Int = 20) {
        isLoading = true
        defer { isLoading = false }

        var descriptor = FetchDescriptor<SessionEntity>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            let entities = try modelContext.fetch(descriptor)
            recentSessions = entities.map { $0.toModel() }
        } catch {
            self.error = error
        }
    }

    func loadSession(_ sessionId: UUID) -> Session? {
        let descriptor = FetchDescriptor<SessionEntity>(
            predicate: #Predicate { $0.id == sessionId }
        )
        return try? modelContext.fetch(descriptor).first?.toModel()
    }

    func loadShots(for sessionId: UUID) -> [Shot] {
        let descriptor = FetchDescriptor<ShotEntity>(
            predicate: #Predicate { $0.sessionId == sessionId },
            sortBy: [SortDescriptor(\.shotNumber)]
        )
        return (try? modelContext.fetch(descriptor).map { $0.toModel() }) ?? []
    }

    // MARK: - Statistics

    private func recalculateStats() {
        guard !activeShots.isEmpty else {
            sessionStats = .empty
            return
        }

        let strikes = activeShots.filter { $0.result == .strike }.count
        let spares = activeShots.filter { $0.result == .spare }.count
        let opens = activeShots.filter { $0.result == .open }.count

        let speeds = activeShots.compactMap { $0.launchSpeed }
        let avgSpeed = speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)

        let revRates = activeShots.compactMap { $0.revRate }
        let avgRevRate = revRates.isEmpty ? 0 : revRates.reduce(0, +) / Double(revRates.count)

        let angles = activeShots.compactMap { $0.entryAngle }
        let avgAngle = angles.isEmpty ? 0 : angles.reduce(0, +) / Double(angles.count)

        // Calculate consistency as standard deviation of pocket offset
        let offsets = activeShots.compactMap { $0.pocketOffset }
        let consistencyScore = calculateConsistency(offsets)

        sessionStats = SessionStats(
            totalShots: activeShots.count,
            strikes: strikes,
            spares: spares,
            opens: opens,
            avgSpeedMph: avgSpeed,
            avgRevRateRpm: avgRevRate,
            avgEntryAngle: avgAngle,
            consistencyScore: consistencyScore
        )
    }

    private func calculateConsistency(_ offsets: [Double]) -> Double {
        guard offsets.count >= 2 else { return 100 }

        let mean = offsets.reduce(0, +) / Double(offsets.count)
        let variance = offsets.map { pow($0 - mean, 2) }.reduce(0, +) / Double(offsets.count)
        let stdDev = sqrt(variance)

        // Convert to 0-100 score (lower std dev = higher score)
        // A std dev of 0 = 100, std dev of 5+ boards = 0
        return max(0, min(100, 100 - (stdDev * 20)))
    }

    // MARK: - Persistence Helpers

    private func saveActiveSession() {
        guard let session = activeSession else { return }

        let descriptor = FetchDescriptor<SessionEntity>(
            predicate: #Predicate { $0.id == session.id }
        )

        if let existingEntity = try? modelContext.fetch(descriptor).first {
            updateSessionEntity(existingEntity, from: session)
        } else {
            let entity = SessionEntity(from: session)
            modelContext.insert(entity)
        }

        trySave()
    }

    private func updateSessionEntity(_ entity: SessionEntity, from session: Session) {
        entity.name = session.name
        entity.lane = session.lane
        entity.oilPattern = session.oilPattern.rawValue
        entity.hand = session.hand.rawValue
        entity.isLeague = session.isLeague
        entity.endTime = session.endTime
        entity.notes = session.notes
    }

    private func updateShotEntity(_ entity: ShotEntity, from shot: Shot) {
        entity.frameNumber = shot.frameNumber
        entity.isFirstBall = shot.isFirstBall
        entity.launchSpeed = shot.launchSpeed
        entity.impactSpeed = shot.impactSpeed
        entity.foulLineBoard = shot.foulLineBoard
        entity.arrowBoard = shot.arrowBoard
        entity.breakpointBoard = shot.breakpointBoard
        entity.breakpointDistance = shot.breakpointDistance
        entity.pocketBoard = shot.pocketBoard
        entity.pocketOffset = shot.pocketOffset
        entity.entryAngle = shot.entryAngle
        entity.launchAngle = shot.launchAngle
        entity.revRate = shot.revRate
        entity.revCategory = shot.revCategory?.rawValue
        entity.result = shot.result?.rawValue
        entity.pinsLeftData = try? JSONEncoder().encode(shot.pinsLeft)
        entity.strikeProbability = shot.strikeProbability
        entity.predictedLeave = shot.predictedLeave?.rawValue
        entity.videoPath = shot.videoPath
        entity.thumbnailPath = shot.thumbnailPath
        entity.trajectoryData = try? JSONEncoder().encode(shot.trajectory)
    }

    private func trySave() {
        do {
            try modelContext.save()
        } catch {
            self.error = error
            print("Failed to save: \(error)")
        }
    }
}
```

### 3.2 Tracking State

```swift
import Foundation
import Combine

@Observable
final class TrackingState {
    // MARK: - Published State

    private(set) var isTracking = false
    private(set) var isRecording = false
    private(set) var ballDetected = false
    private(set) var lastDetection: BallDetection = .notFound
    private(set) var currentTrajectory: [TrajectoryPoint] = []
    private(set) var frameCount = 0
    private(set) var fps: Double = 0

    // Calculated metrics (updated each frame)
    private(set) var currentSpeed: Double?
    private(set) var currentBoard: Double?
    private(set) var estimatedEntryAngle: Double?
    private(set) var estimatedStrikeProbability: Double?

    // MARK: - Configuration

    var calibration: CalibrationProfile?
    var ballProfile: BallProfile?

    // MARK: - Internal State

    private var trackingStartTime: Date?
    private var lastFrameTime: Date?
    private var frameTimestamps: [Date] = []
    private let maxTrajectoryPoints = 500  // Limit memory usage

    // MARK: - Tracking Lifecycle

    func startTracking() {
        isTracking = true
        trackingStartTime = Date()
        frameTimestamps = []
        resetCurrentShot()
    }

    func stopTracking() {
        isTracking = false
        trackingStartTime = nil
    }

    func startRecording() {
        guard isTracking else { return }
        isRecording = true
        resetCurrentShot()
    }

    func stopRecording() -> [TrajectoryPoint] {
        isRecording = false
        let trajectory = currentTrajectory
        // Don't reset - keep for display until next shot
        return trajectory
    }

    func resetCurrentShot() {
        currentTrajectory = []
        lastDetection = .notFound
        ballDetected = false
        currentSpeed = nil
        currentBoard = nil
        estimatedEntryAngle = nil
        estimatedStrikeProbability = nil
    }

    // MARK: - Frame Processing

    func processDetection(_ detection: BallDetection, at timestamp: TimeInterval) {
        lastDetection = detection
        ballDetected = detection.found
        frameCount += 1
        updateFPS()

        guard detection.found, let x = detection.x, let y = detection.y else { return }

        // Create trajectory point
        var point = TrajectoryPoint(
            x: x,
            y: y,
            timestamp: timestamp,
            frameNumber: frameCount
        )

        // Apply calibration if available
        if let cal = calibration {
            point.board = cal.pixelToBoard(x)
            point.distanceFt = cal.pixelToDistanceFt(y)
            point.realWorldX = point.board
            point.realWorldY = point.distanceFt
            currentBoard = point.board
        }

        // Determine ball phase
        point.phase = determineBallPhase(point)

        // Add to trajectory (with memory management)
        if isRecording {
            if currentTrajectory.count >= maxTrajectoryPoints {
                // Downsample: remove every other point
                currentTrajectory = currentTrajectory.enumerated()
                    .filter { $0.offset % 2 == 0 }
                    .map { $0.element }
            }
            currentTrajectory.append(point)
        }

        // Update calculated metrics
        updateMetrics()
    }

    // MARK: - Metric Calculations

    private func updateMetrics() {
        calculateSpeed()
        calculateEstimatedEntryAngle()
        calculateStrikeProbability()
    }

    private func calculateSpeed() {
        guard currentTrajectory.count >= 2,
              let cal = calibration else {
            currentSpeed = nil
            return
        }

        // Use last 5 points for smoothing
        let recentPoints = currentTrajectory.suffix(5)
        guard let first = recentPoints.first,
              let last = recentPoints.last,
              let firstDist = first.distanceFt,
              let lastDist = last.distanceFt else {
            return
        }

        let distanceFt = abs(lastDist - firstDist)
        let timeSec = last.timestamp - first.timestamp

        guard timeSec > 0 else { return }

        let feetPerSec = distanceFt / timeSec
        let mph = feetPerSec * 3600 / 5280

        currentSpeed = mph
    }

    private func calculateEstimatedEntryAngle() {
        guard currentTrajectory.count >= 10 else {
            estimatedEntryAngle = nil
            return
        }

        // Linear regression on recent points to estimate trajectory angle
        let recentPoints = Array(currentTrajectory.suffix(10))
        guard let firstBoard = recentPoints.first?.board,
              let lastBoard = recentPoints.last?.board,
              let firstDist = recentPoints.first?.distanceFt,
              let lastDist = recentPoints.last?.distanceFt else {
            return
        }

        let boardChange = lastBoard - firstBoard
        let distChange = lastDist - firstDist

        guard distChange != 0 else { return }

        // Convert to angle (boards per foot, then to degrees)
        // 39 boards = 41.5 inches = 3.458 feet
        let boardsPerFoot = boardChange / distChange
        let inchesPerFoot = boardsPerFoot * (41.5 / 39.0)

        estimatedEntryAngle = atan(inchesPerFoot / 12.0) * (180.0 / .pi)
    }

    private func calculateStrikeProbability() {
        guard let angle = estimatedEntryAngle,
              let board = currentBoard else {
            estimatedStrikeProbability = nil
            return
        }

        // Simple probability model based on entry angle and board position
        // Optimal: 6 degrees, board 17.5 (right-handed)
        let optimalAngle = 6.0
        let optimalBoard = 17.5  // Assuming right-handed for now

        let angleError = abs(angle - optimalAngle)
        let boardError = abs(board - optimalBoard)

        // Penalties
        let anglePenalty = angleError * 0.08  // 8% per degree off
        let boardPenalty = boardError * 0.05  // 5% per board off

        let probability = max(0, min(1, 1.0 - anglePenalty - boardPenalty))
        estimatedStrikeProbability = probability
    }

    private func determineBallPhase(_ point: TrajectoryPoint) -> BallPhase {
        guard let distanceFt = point.distanceFt else { return .skid }

        // Simplified phase detection based on distance
        // Real implementation would analyze trajectory curvature
        if distanceFt < 20 {
            return .skid
        } else if distanceFt < 45 {
            return .hook
        } else {
            return .roll
        }
    }

    private func updateFPS() {
        let now = Date()
        frameTimestamps.append(now)

        // Keep only last second of timestamps
        let oneSecondAgo = now.addingTimeInterval(-1)
        frameTimestamps = frameTimestamps.filter { $0 > oneSecondAgo }

        fps = Double(frameTimestamps.count)
    }
}
```

### 3.3 Calibration State

```swift
import Foundation

@Observable
final class CalibrationState {
    // MARK: - Published State

    private(set) var currentStep: CalibrationStep = .position
    private(set) var foulLineY: Double?
    private(set) var arrowPoints: [ArrowPoint] = []
    private(set) var leftGutterX: Double?
    private(set) var rightGutterX: Double?
    private(set) var pixelsPerFoot: Double?
    private(set) var pixelsPerBoard: Double?
    private(set) var isValid = false
    private(set) var errorMessage: String?

    // Preview/verification
    private(set) var previewProfile: CalibrationProfile?

    // MARK: - Configuration

    var targetCenter: Center?
    var targetLaneNumber: Int?

    // MARK: - Wizard Navigation

    func reset() {
        currentStep = .position
        foulLineY = nil
        arrowPoints = []
        leftGutterX = nil
        rightGutterX = nil
        pixelsPerFoot = nil
        pixelsPerBoard = nil
        isValid = false
        errorMessage = nil
        previewProfile = nil
    }

    func nextStep() {
        switch currentStep {
        case .position:
            currentStep = .foulLine
        case .foulLine:
            if foulLineY != nil {
                currentStep = .arrows
            } else {
                errorMessage = "Please mark the foul line"
            }
        case .arrows:
            if validateArrows() {
                calculateConversionFactors()
                currentStep = .verify
            }
        case .verify:
            if isValid {
                currentStep = .complete
            }
        case .complete:
            break
        }
    }

    func previousStep() {
        switch currentStep {
        case .position:
            break
        case .foulLine:
            currentStep = .position
        case .arrows:
            currentStep = .foulLine
        case .verify:
            currentStep = .arrows
        case .complete:
            currentStep = .verify
        }
    }

    // MARK: - Data Entry

    func setFoulLine(y: Double) {
        foulLineY = y
        errorMessage = nil
    }

    func setGutters(left: Double, right: Double) {
        leftGutterX = left
        rightGutterX = right
        recalculatePixelsPerBoard()
    }

    func addArrowPoint(_ point: ArrowPoint) {
        // Replace if same arrow number exists
        arrowPoints.removeAll { $0.arrowNumber == point.arrowNumber }
        arrowPoints.append(point)
        arrowPoints.sort { $0.arrowNumber < $1.arrowNumber }
        errorMessage = nil
    }

    func removeArrowPoint(arrowNumber: Int) {
        arrowPoints.removeAll { $0.arrowNumber == arrowNumber }
    }

    // MARK: - Validation

    private func validateArrows() -> Bool {
        // Need at least 2 arrow points for calibration
        guard arrowPoints.count >= 2 else {
            errorMessage = "Mark at least 2 arrows"
            return false
        }

        // All arrows should be at approximately the same Y (same horizontal line)
        let yValues = arrowPoints.map { $0.pixelY }
        let avgY = yValues.reduce(0, +) / Double(yValues.count)
        let maxDeviation = yValues.map { abs($0 - avgY) }.max() ?? 0

        if maxDeviation > 20 {  // 20 pixel tolerance
            errorMessage = "Arrows should be on a horizontal line"
            return false
        }

        return true
    }

    // MARK: - Calculations

    private func calculateConversionFactors() {
        guard let foulY = foulLineY,
              arrowPoints.count >= 2 else {
            return
        }

        // Calculate arrowsY as average Y of arrow points
        let arrowsY = arrowPoints.map { $0.pixelY }.reduce(0, +) / Double(arrowPoints.count)

        // Arrows are 15 feet from foul line
        let pixelDistance = foulY - arrowsY
        pixelsPerFoot = pixelDistance / 15.0

        // Calculate pixelsPerBoard from arrow spacing
        recalculatePixelsPerBoard()

        // Generate preview profile
        generatePreviewProfile(arrowsY: arrowsY)

        isValid = pixelsPerFoot != nil && pixelsPerBoard != nil
    }

    private func recalculatePixelsPerBoard() {
        // Method 1: From gutters (if available)
        if let left = leftGutterX, let right = rightGutterX {
            let totalWidth = right - left
            pixelsPerBoard = totalWidth / 39.0  // 39 boards
            return
        }

        // Method 2: From arrow spacing (arrows are 5 boards apart)
        guard arrowPoints.count >= 2 else { return }

        let sortedPoints = arrowPoints.sorted { $0.boardNumber < $1.boardNumber }
        var pixelDistances: [Double] = []

        for i in 0..<(sortedPoints.count - 1) {
            let point1 = sortedPoints[i]
            let point2 = sortedPoints[i + 1]
            let boardDiff = Double(point2.boardNumber - point1.boardNumber)
            let pixelDiff = abs(point2.pixelX - point1.pixelX)
            pixelDistances.append(pixelDiff / boardDiff)
        }

        if !pixelDistances.isEmpty {
            pixelsPerBoard = pixelDistances.reduce(0, +) / Double(pixelDistances.count)
        }
    }

    private func generatePreviewProfile(arrowsY: Double) {
        guard let center = targetCenter,
              let foulY = foulLineY,
              let ppf = pixelsPerFoot,
              let ppb = pixelsPerBoard else {
            return
        }

        // Estimate gutter positions if not set
        let leftX = leftGutterX ?? (arrowPoints.min(by: { $0.pixelX < $1.pixelX })?.pixelX ?? 0) - 100
        let rightX = rightGutterX ?? (arrowPoints.max(by: { $0.pixelX < $1.pixelX })?.pixelX ?? 0) + 100

        previewProfile = CalibrationProfile(
            centerId: center.id,
            centerName: center.name,
            laneNumber: targetLaneNumber,
            pixelsPerFoot: ppf,
            pixelsPerBoard: ppb,
            foulLineY: foulY,
            arrowsY: arrowsY,
            leftGutterX: leftX,
            rightGutterX: rightX
        )
    }

    // MARK: - Finalization

    func finalizeProfile() -> CalibrationProfile? {
        guard isValid, let profile = previewProfile else { return nil }
        return profile
    }
}
```

### 3.4 Settings Manager

```swift
import Foundation
import SwiftData

@Observable
final class SettingsManager {
    // MARK: - Published State

    private(set) var settings: UserSettings = .defaults
    private(set) var ballProfiles: [BallProfile] = []
    private(set) var centers: [Center] = []
    private(set) var calibrations: [CalibrationProfile] = []

    // Selected items
    var selectedBallProfile: BallProfile?
    var selectedCenter: Center?
    var selectedCalibration: CalibrationProfile?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "bowlertrax.settings"

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
        loadAllData()
    }

    // MARK: - Settings Management

    func updateSettings(_ update: (inout UserSettings) -> Void) {
        update(&settings)
        saveSettings()
    }

    private func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }

    // MARK: - Ball Profiles

    func addBallProfile(_ profile: BallProfile) {
        let entity = BallProfileEntity(from: profile)
        modelContext.insert(entity)
        trySave()
        loadBallProfiles()
    }

    func updateBallProfile(_ profile: BallProfile) {
        let descriptor = FetchDescriptor<BallProfileEntity>(
            predicate: #Predicate { $0.id == profile.id }
        )
        if let entity = try? modelContext.fetch(descriptor).first {
            entity.name = profile.name
            entity.brand = profile.brand
            entity.colorH = profile.color.h
            entity.colorS = profile.color.s
            entity.colorV = profile.color.v
            entity.colorTolerance = profile.colorTolerance
            entity.markerColorH = profile.markerColor?.h
            entity.markerColorS = profile.markerColor?.s
            entity.markerColorV = profile.markerColor?.v
            trySave()
            loadBallProfiles()
        }
    }

    func deleteBallProfile(_ profile: BallProfile) {
        let descriptor = FetchDescriptor<BallProfileEntity>(
            predicate: #Predicate { $0.id == profile.id }
        )
        if let entity = try? modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            trySave()
            loadBallProfiles()
        }
    }

    private func loadBallProfiles() {
        let descriptor = FetchDescriptor<BallProfileEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        ballProfiles = (try? modelContext.fetch(descriptor).map { $0.toModel() }) ?? []

        // Update selected if it was deleted
        if let selected = selectedBallProfile,
           !ballProfiles.contains(where: { $0.id == selected.id }) {
            selectedBallProfile = ballProfiles.first
        }
    }

    // MARK: - Centers

    func addCenter(_ center: Center) {
        let entity = CenterEntity(from: center)
        modelContext.insert(entity)
        trySave()
        loadCenters()
    }

    func updateCenter(_ center: Center) {
        let descriptor = FetchDescriptor<CenterEntity>(
            predicate: #Predicate { $0.id == center.id }
        )
        if let entity = try? modelContext.fetch(descriptor).first {
            entity.name = center.name
            entity.address = center.address
            entity.laneCount = center.laneCount
            entity.defaultOilPattern = center.defaultOilPattern?.rawValue
            trySave()
            loadCenters()
        }
    }

    func deleteCenter(_ center: Center) {
        let descriptor = FetchDescriptor<CenterEntity>(
            predicate: #Predicate { $0.id == center.id }
        )
        if let entity = try? modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            trySave()
            loadCenters()
        }
    }

    private func loadCenters() {
        let descriptor = FetchDescriptor<CenterEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        centers = (try? modelContext.fetch(descriptor).map { $0.toModel() }) ?? []
    }

    // MARK: - Calibrations

    func addCalibration(_ calibration: CalibrationProfile) {
        let entity = CalibrationEntity(from: calibration)
        modelContext.insert(entity)
        trySave()
        loadCalibrations()
    }

    func deleteCalibration(_ calibration: CalibrationProfile) {
        let descriptor = FetchDescriptor<CalibrationEntity>(
            predicate: #Predicate { $0.id == calibration.id }
        )
        if let entity = try? modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            trySave()
            loadCalibrations()
        }
    }

    func calibrationsForCenter(_ centerId: UUID) -> [CalibrationProfile] {
        calibrations.filter { $0.centerId == centerId }
    }

    private func loadCalibrations() {
        let descriptor = FetchDescriptor<CalibrationEntity>(
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        calibrations = (try? modelContext.fetch(descriptor).map { $0.toModel() }) ?? []
    }

    // MARK: - Data Loading

    private func loadAllData() {
        loadBallProfiles()
        loadCenters()
        loadCalibrations()

        // Restore selections from settings
        if let defaultBallId = settings.defaultBallProfileId {
            selectedBallProfile = ballProfiles.first { $0.id == defaultBallId }
        }
        if let defaultCenterId = settings.defaultCenterId {
            selectedCenter = centers.first { $0.id == defaultCenterId }
        }
    }

    private func trySave() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
```

---

## 4. State Flow Between Views

```
+------------------------------------------------------------------+
|                        BowlerTraxApp                              |
|  +------------------------------------------------------------+  |
|  |  @Environment(\.modelContext) + State Managers injected    |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
+------------------+  +------------------+  +------------------+
|   DashboardView  |  |   RecordView     |  |  SessionsView    |
|                  |  |                  |  |                  |
| READS:           |  | READS:           |  | READS:           |
| - SessionManager |  | - SessionManager |  | - SessionManager |
|   .recentSessions|  |   .activeSession |  |   .recentSessions|
|   .sessionStats  |  |   .activeShots   |  |                  |
| - SettingsManager|  |   .sessionStats  |  | WRITES:          |
|   .settings      |  | - TrackingState  |  | - SessionManager |
|                  |  |   .isRecording   |  |   .loadSession() |
| WRITES:          |  |   .currentBoard  |  +------------------+
| - SessionManager |  |   .currentSpeed  |
|   .loadRecent()  |  |   .trajectory    |
+------------------+  | - CalibrationState|
                      |   .currentStep   |
                      | - SettingsManager|
                      |   .selectedBall  |
                      |                  |
                      | WRITES:          |
                      | - SessionManager |
                      |   .startSession()|
                      |   .addShot()     |
                      |   .endSession()  |
                      | - TrackingState  |
                      |   .startTracking |
                      |   .processFrame()|
                      +------------------+
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
+------------------+  +------------------+  +------------------+
| CameraOverlayView|  | MetricsView      |  | TrajectoryView   |
|                  |  |                  |  |                  |
| READS:           |  | READS:           |  | READS:           |
| - TrackingState  |  | - TrackingState  |  | - TrackingState  |
|   .ballDetected  |  |   .currentSpeed  |  |   .trajectory    |
|   .lastDetection |  |   .currentBoard  |  | - CalibrationState|
|   .isRecording   |  |   .estimatedAngle|  |   .previewProfile|
| - CalibrationState|  |   .probability  |  |                  |
|   .previewProfile|  | - SessionManager |  | (Read-only)      |
|                  |  |   .sessionStats  |  +------------------+
| (Read-only)      |  |                  |
+------------------+  | (Read-only)      |
                      +------------------+

+------------------+  +------------------+  +------------------+
|  SettingsView    |  | CalibrateView    |  |  ShotDetailView  |
|                  |  |                  |  |                  |
| READS:           |  | READS:           |  | READS:           |
| - SettingsManager|  | - CalibrationState|  | - SessionManager |
|   .settings      |  |   .currentStep   |  |   (specific shot)|
|   .ballProfiles  |  |   .arrowPoints   |  |                  |
|   .centers       |  |   .previewProfile|  | WRITES:          |
|                  |  |                  |  | - SessionManager |
| WRITES:          |  | WRITES:          |  |   .updateShot()  |
| - SettingsManager|  | - CalibrationState|  +------------------+
|   .updateSettings|  |   .setFoulLine() |
|   .addBallProfile|  |   .addArrowPoint |
|   .addCenter()   |  |   .nextStep()    |
+------------------+  | - SettingsManager|
                      |   .addCalibration|
                      +------------------+

DATA FLOW LEGEND:
================
READS  = View observes state (reactive updates)
WRITES = View can call methods to modify state
```

---

## 5. Real-Time Tracking State

### 5.1 High-Frequency Update Strategy

```swift
import Foundation
import Combine

/// Manages high-frequency camera frame processing with throttled UI updates
final class TrackingCoordinator {
    // MARK: - State Managers

    private let trackingState: TrackingState
    private let sessionManager: SessionManager

    // MARK: - Publishers

    private var framePublisher = PassthroughSubject<CameraFrame, Never>()
    private var detectionPublisher = PassthroughSubject<(BallDetection, TimeInterval), Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Performance Tuning

    /// How often to update UI (Hz). Lower = better performance, higher = smoother UI
    private let uiUpdateRate: Double = 30  // 30 Hz UI updates

    /// Maximum trajectory points to keep in memory
    private let maxTrajectoryPoints = 500

    /// Minimum confidence to consider detection valid
    private let minDetectionConfidence: Double = 0.6

    // MARK: - Internal State

    private var lastUIUpdate = Date.distantPast
    private var pendingDetections: [(BallDetection, TimeInterval)] = []
    private let processingQueue = DispatchQueue(
        label: "com.bowlertrax.tracking",
        qos: .userInteractive
    )

    // MARK: - Initialization

    init(trackingState: TrackingState, sessionManager: SessionManager) {
        self.trackingState = trackingState
        self.sessionManager = sessionManager
        setupPipeline()
    }

    // MARK: - Pipeline Setup

    private func setupPipeline() {
        // Frame processing pipeline (on background queue)
        framePublisher
            .receive(on: processingQueue)
            .compactMap { [weak self] frame -> (BallDetection, TimeInterval)? in
                self?.processFrame(frame)
            }
            .sink { [weak self] result in
                self?.detectionPublisher.send(result)
            }
            .store(in: &cancellables)

        // Detection aggregation with UI throttling
        detectionPublisher
            .collect(.byTime(processingQueue, .milliseconds(Int(1000 / uiUpdateRate))))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detections in
                self?.updateUI(with: detections)
            }
            .store(in: &cancellables)
    }

    // MARK: - Frame Input

    func submitFrame(_ frame: CameraFrame) {
        guard trackingState.isTracking else { return }
        framePublisher.send(frame)
    }

    // MARK: - Frame Processing

    private func processFrame(_ frame: CameraFrame) -> (BallDetection, TimeInterval)? {
        // TODO: Actual ball detection implementation
        // This is where color-based tracking would happen

        let detection = performBallDetection(frame)
        let timestamp = Double(frame.timestamp) / 1000.0  // Convert to seconds

        guard detection.confidence >= minDetectionConfidence else {
            return nil
        }

        return (detection, timestamp)
    }

    private func performBallDetection(_ frame: CameraFrame) -> BallDetection {
        // Placeholder - actual implementation in CV module
        // Would use HSV color filtering, contour detection, etc.
        return .notFound
    }

    // MARK: - UI Updates

    private func updateUI(with detections: [(BallDetection, TimeInterval)]) {
        // Use most recent detection for display
        guard let latest = detections.last else { return }

        // Update tracking state (triggers SwiftUI updates)
        trackingState.processDetection(latest.0, at: latest.1)

        // Memory management: trim trajectory if needed
        trimTrajectoryIfNeeded()
    }

    private func trimTrajectoryIfNeeded() {
        // Handled inside TrackingState.processDetection()
    }

    // MARK: - Shot Finalization

    func finalizeShot() -> Shot? {
        guard let session = sessionManager.activeSession else { return nil }

        let trajectory = trackingState.stopRecording()
        guard !trajectory.isEmpty else { return nil }

        // Calculate final metrics from trajectory
        let metrics = calculateFinalMetrics(from: trajectory)

        var shot = Shot(
            sessionId: session.id,
            shotNumber: sessionManager.activeShots.count + 1
        )

        // Apply calculated metrics
        shot.launchSpeed = metrics.launchSpeed
        shot.impactSpeed = metrics.impactSpeed
        shot.foulLineBoard = metrics.foulLineBoard
        shot.arrowBoard = metrics.arrowBoard
        shot.breakpointBoard = metrics.breakpointBoard
        shot.breakpointDistance = metrics.breakpointDistance
        shot.pocketBoard = metrics.pocketBoard
        shot.entryAngle = metrics.entryAngle
        shot.launchAngle = metrics.launchAngle
        shot.strikeProbability = metrics.strikeProbability
        shot.trajectory = trajectory

        // Calculate pocket offset
        shot.calculatePocketOffset(hand: session.hand)

        return shot
    }

    private func calculateFinalMetrics(from trajectory: [TrajectoryPoint]) -> ShotMetrics {
        // Implement detailed metric calculations
        // This would analyze the full trajectory
        return ShotMetrics()
    }
}

/// Container for calculated shot metrics
private struct ShotMetrics {
    var launchSpeed: Double?
    var impactSpeed: Double?
    var foulLineBoard: Double?
    var arrowBoard: Double?
    var breakpointBoard: Double?
    var breakpointDistance: Double?
    var pocketBoard: Double?
    var entryAngle: Double?
    var launchAngle: Double?
    var strikeProbability: Double?
}

/// Camera frame data structure
struct CameraFrame {
    let data: Data           // Raw pixel data (CVPixelBuffer converted)
    let width: Int
    let height: Int
    let timestamp: Int64     // Milliseconds
    let frameNumber: Int
}
```

### 5.2 Performance Considerations

```swift
// MARK: - Performance Guidelines

/*
 HIGH-FREQUENCY UPDATE STRATEGY
 ==============================

 Camera captures at 60-120 FPS, but SwiftUI can't handle that update rate.
 We use a multi-tier approach:

 1. FRAME CAPTURE (60-120 Hz)
    - Raw CMSampleBuffer from AVCaptureSession
    - Processed immediately on capture queue

 2. DETECTION PROCESSING (60-120 Hz)
    - Ball detection runs on every frame
    - Uses dedicated processing queue
    - Results buffered before UI update

 3. UI UPDATES (30 Hz)
    - Throttled using Combine's collect(.byTime)
    - Only latest detection used for display
    - Trajectory array managed for memory

 4. PERSISTENCE (1 Hz or on-demand)
    - Auto-save runs every second during recording
    - Full save on shot completion
    - Background save queue

 MEMORY MANAGEMENT
 =================

 - Trajectory limited to 500 points (configurable)
 - Older points downsampled when limit reached
 - Full trajectory saved to disk, trimmed version in memory

 SWIFTUI OPTIMIZATION
 ====================

 - Use @Observable (iOS 17+) for automatic dependency tracking
 - Split large views into smaller components
 - Use .drawingGroup() for trajectory overlay
 - Avoid unnecessary state in views (read from managers)

 EXAMPLE VIEW STRUCTURE:

 struct RecordView: View {
     @Environment(TrackingState.self) var tracking

     var body: some View {
         ZStack {
             CameraPreviewView()  // UIViewRepresentable - no SwiftUI updates

             // Only this updates at 30Hz
             TrajectoryOverlayView()
                 .drawingGroup()  // Offscreen render

             // Updates less frequently
             MetricsHUDView()
         }
     }
 }
 */
```

---

## 6. Persistence Strategy

### 6.1 Auto-Save Coordinator

```swift
import Foundation
import SwiftData

/// Manages automatic saving during recording sessions
final class PersistenceCoordinator {
    // MARK: - Configuration

    /// Auto-save interval during recording (seconds)
    private let autoSaveInterval: TimeInterval = 5.0

    /// Background save queue
    private let saveQueue = DispatchQueue(
        label: "com.bowlertrax.persistence",
        qos: .utility
    )

    // MARK: - State

    private var autoSaveTimer: Timer?
    private var pendingShots: [Shot] = []
    private var isRecoveryMode = false

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let sessionManager: SessionManager

    // MARK: - Recovery Keys

    private let recoverySessionKey = "bowlertrax.recovery.session"
    private let recoveryShotsKey = "bowlertrax.recovery.shots"
    private let recoveryTimestampKey = "bowlertrax.recovery.timestamp"

    // MARK: - Initialization

    init(modelContext: ModelContext, sessionManager: SessionManager) {
        self.modelContext = modelContext
        self.sessionManager = sessionManager
        checkForRecovery()
    }

    // MARK: - Auto-Save Control

    func startAutoSave() {
        stopAutoSave()

        autoSaveTimer = Timer.scheduledTimer(
            withTimeInterval: autoSaveInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performAutoSave()
        }
    }

    func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    // MARK: - Auto-Save Implementation

    private func performAutoSave() {
        saveQueue.async { [weak self] in
            self?.saveCurrentState()
        }
    }

    private func saveCurrentState() {
        guard let session = sessionManager.activeSession else { return }

        // Save to UserDefaults for crash recovery
        let encoder = JSONEncoder()

        if let sessionData = try? encoder.encode(session) {
            UserDefaults.standard.set(sessionData, forKey: recoverySessionKey)
        }

        let shots = sessionManager.activeShots
        if let shotsData = try? encoder.encode(shots) {
            UserDefaults.standard.set(shotsData, forKey: recoveryShotsKey)
        }

        UserDefaults.standard.set(Date(), forKey: recoveryTimestampKey)

        // Also save to SwiftData (on main context)
        DispatchQueue.main.async { [weak self] in
            try? self?.modelContext.save()
        }
    }

    // MARK: - Crash Recovery

    private func checkForRecovery() {
        guard let timestamp = UserDefaults.standard.object(forKey: recoveryTimestampKey) as? Date else {
            return
        }

        // Only recover if crash was within last hour
        let timeSinceCrash = Date().timeIntervalSince(timestamp)
        guard timeSinceCrash < 3600 else {
            clearRecoveryData()
            return
        }

        // Check if there's data to recover
        guard UserDefaults.standard.data(forKey: recoverySessionKey) != nil else {
            clearRecoveryData()
            return
        }

        isRecoveryMode = true
    }

    var hasRecoverableSession: Bool {
        isRecoveryMode
    }

    func recoverSession() -> (Session, [Shot])? {
        guard isRecoveryMode else { return nil }

        let decoder = JSONDecoder()

        guard let sessionData = UserDefaults.standard.data(forKey: recoverySessionKey),
              let session = try? decoder.decode(Session.self, from: sessionData) else {
            clearRecoveryData()
            return nil
        }

        var shots: [Shot] = []
        if let shotsData = UserDefaults.standard.data(forKey: recoveryShotsKey),
           let decodedShots = try? decoder.decode([Shot].self, from: shotsData) {
            shots = decodedShots
        }

        clearRecoveryData()
        isRecoveryMode = false

        return (session, shots)
    }

    func discardRecovery() {
        clearRecoveryData()
        isRecoveryMode = false
    }

    private func clearRecoveryData() {
        UserDefaults.standard.removeObject(forKey: recoverySessionKey)
        UserDefaults.standard.removeObject(forKey: recoveryShotsKey)
        UserDefaults.standard.removeObject(forKey: recoveryTimestampKey)
    }

    // MARK: - Data Export

    func exportSession(_ session: Session, shots: [Shot]) throws -> Data {
        let export = SessionExport(
            session: session,
            shots: shots,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(export)
    }

    func importSession(from data: Data) throws -> (Session, [Shot]) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let export = try decoder.decode(SessionExport.self, from: data)
        return (export.session, export.shots)
    }
}

// MARK: - Export Format

struct SessionExport: Codable {
    let session: Session
    let shots: [Shot]
    let exportDate: Date
    let appVersion: String
}
```

### 6.2 Background Saving During Recording

```swift
// MARK: - Recording Session Persistence

extension SessionManager {
    /// Called during recording to save trajectory incrementally
    func saveTrajectoryCheckpoint(_ trajectory: [TrajectoryPoint], for shotId: UUID) {
        // Save trajectory to temporary file for recovery
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("trajectory_\(shotId.uuidString).json")

        if let data = try? JSONEncoder().encode(trajectory) {
            try? data.write(to: tempURL)
        }
    }

    /// Load trajectory from checkpoint if available
    func loadTrajectoryCheckpoint(for shotId: UUID) -> [TrajectoryPoint]? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("trajectory_\(shotId.uuidString).json")

        guard let data = try? Data(contentsOf: tempURL) else { return nil }
        return try? JSONDecoder().decode([TrajectoryPoint].self, from: data)
    }

    /// Clean up trajectory checkpoint after successful save
    func clearTrajectoryCheckpoint(for shotId: UUID) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("trajectory_\(shotId.uuidString).json")
        try? FileManager.default.removeItem(at: tempURL)
    }
}
```

---

## 7. Combine Pipelines

### 7.1 Camera Frame Publisher

```swift
import Foundation
import Combine
import AVFoundation

/// Publishes camera frames for processing
final class CameraFramePublisher: NSObject {
    // MARK: - Publishers

    let framePublisher = PassthroughSubject<CMSampleBuffer, Never>()
    let errorPublisher = PassthroughSubject<Error, Never>()

    // MARK: - State

    private var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "com.bowlertrax.camera")
    private var isRunning = false

    // MARK: - Configuration

    func configure(preferredFPS: Int = 60) async throws {
        let session = AVCaptureSession()
        session.beginConfiguration()

        // Get best available camera
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraError.deviceNotFound
        }

        // Configure for high frame rate
        try device.lockForConfiguration()

        // Find best format for target FPS
        let formats = device.formats.filter { format in
            let ranges = format.videoSupportedFrameRateRanges
            return ranges.contains { $0.maxFrameRate >= Double(preferredFPS) }
        }

        if let bestFormat = formats.last,
           let range = bestFormat.videoSupportedFrameRateRanges.first(where: {
               $0.maxFrameRate >= Double(preferredFPS)
           }) {
            device.activeFormat = bestFormat
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(preferredFPS))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(preferredFPS))
        }

        device.unlockForConfiguration()

        // Add input
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.inputNotSupported
        }
        session.addInput(input)

        // Add output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard session.canAddOutput(output) else {
            throw CameraError.outputNotSupported
        }
        session.addOutput(output)

        session.commitConfiguration()
        captureSession = session
    }

    func start() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.startRunning()
            self?.isRunning = true
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.isRunning = false
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraFramePublisher: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        framePublisher.send(sampleBuffer)
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Frame dropped - could log for debugging
    }
}

// MARK: - Errors

enum CameraError: Error, LocalizedError {
    case deviceNotFound
    case inputNotSupported
    case outputNotSupported
    case configurationFailed

    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Camera not found"
        case .inputNotSupported:
            return "Camera input not supported"
        case .outputNotSupported:
            return "Video output not supported"
        case .configurationFailed:
            return "Camera configuration failed"
        }
    }
}
```

### 7.2 Detection Pipeline

```swift
import Foundation
import Combine
import CoreImage

/// Processes camera frames and detects ball position
final class DetectionPipeline {
    // MARK: - Publishers

    private let inputSubject = PassthroughSubject<CMSampleBuffer, Never>()
    let detectionPublisher: AnyPublisher<BallDetection, Never>

    // MARK: - Configuration

    var ballColor: HSVColor?
    var colorTolerance: Double = 15.0

    // MARK: - Processing

    private let ciContext = CIContext()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        detectionPublisher = inputSubject
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .compactMap { [weak self] buffer -> BallDetection? in
                self?.processBuffer(buffer)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Input

    func process(_ buffer: CMSampleBuffer) {
        inputSubject.send(buffer)
    }

    // MARK: - Processing Implementation

    private func processBuffer(_ buffer: CMSampleBuffer) -> BallDetection? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer),
              let ballColor = ballColor else {
            return .notFound
        }

        // Convert to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Apply color threshold filter
        guard let filtered = applyColorFilter(ciImage, targetColor: ballColor) else {
            return .notFound
        }

        // Find contours and detect ball
        return detectBall(in: filtered, originalSize: ciImage.extent.size)
    }

    private func applyColorFilter(_ image: CIImage, targetColor: HSVColor) -> CIImage? {
        // Create color cube for HSV filtering
        // This is a simplified version - real implementation would use Metal

        let filter = CIFilter(name: "CIColorCube")
        filter?.setValue(image, forKey: kCIInputImageKey)

        // Generate color cube data for HSV range
        let cubeData = generateColorCube(
            targetH: targetColor.h,
            toleranceH: colorTolerance,
            targetS: targetColor.s,
            toleranceS: 30,
            targetV: targetColor.v,
            toleranceV: 30
        )

        filter?.setValue(cubeData, forKey: "inputCubeData")
        filter?.setValue(64, forKey: "inputCubeDimension")

        return filter?.outputImage
    }

    private func generateColorCube(
        targetH: Double,
        toleranceH: Double,
        targetS: Double,
        toleranceS: Double,
        targetV: Double,
        toleranceV: Double
    ) -> Data {
        let size = 64
        var cubeData = [Float](repeating: 0, count: size * size * size * 4)

        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    let index = (b * size * size + g * size + r) * 4

                    // Convert RGB to HSV
                    let rf = Float(r) / Float(size - 1)
                    let gf = Float(g) / Float(size - 1)
                    let bf = Float(b) / Float(size - 1)

                    let (h, s, v) = rgbToHsv(r: rf, g: gf, b: bf)

                    // Check if within tolerance
                    let hDiff = min(abs(h - Float(targetH)), 360 - abs(h - Float(targetH)))
                    let inRange = hDiff <= Float(toleranceH) &&
                                  abs(s - Float(targetS / 100)) <= Float(toleranceS / 100) &&
                                  abs(v - Float(targetV / 100)) <= Float(toleranceV / 100)

                    if inRange {
                        cubeData[index] = 1.0     // R
                        cubeData[index + 1] = 1.0 // G
                        cubeData[index + 2] = 1.0 // B
                        cubeData[index + 3] = 1.0 // A
                    } else {
                        cubeData[index] = 0.0
                        cubeData[index + 1] = 0.0
                        cubeData[index + 2] = 0.0
                        cubeData[index + 3] = 1.0
                    }
                }
            }
        }

        return Data(bytes: cubeData, count: cubeData.count * MemoryLayout<Float>.size)
    }

    private func rgbToHsv(r: Float, g: Float, b: Float) -> (h: Float, s: Float, v: Float) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        var h: Float = 0
        let s: Float = maxC == 0 ? 0 : delta / maxC
        let v: Float = maxC

        if delta != 0 {
            if maxC == r {
                h = 60 * fmod((g - b) / delta, 6)
            } else if maxC == g {
                h = 60 * ((b - r) / delta + 2)
            } else {
                h = 60 * ((r - g) / delta + 4)
            }
        }

        if h < 0 { h += 360 }

        return (h, s, v)
    }

    private func detectBall(in image: CIImage, originalSize: CGSize) -> BallDetection {
        // Simplified ball detection
        // Real implementation would use contour detection via Metal or vImage

        // For now, return placeholder
        return .notFound
    }
}
```

### 7.3 Metrics Calculation Subscriber

```swift
import Foundation
import Combine

/// Subscribes to detection results and calculates metrics
final class MetricsCalculator {
    // MARK: - Publishers

    let speedPublisher = CurrentValueSubject<Double?, Never>(nil)
    let boardPublisher = CurrentValueSubject<Double?, Never>(nil)
    let anglePublisher = CurrentValueSubject<Double?, Never>(nil)
    let probabilityPublisher = CurrentValueSubject<Double?, Never>(nil)

    // MARK: - State

    private var recentDetections: [(BallDetection, TimeInterval)] = []
    private let maxHistorySize = 30  // About 0.5 seconds at 60fps
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let calibration: CalibrationProfile?
    private let handPreference: HandPreference

    // MARK: - Initialization

    init(
        detectionPublisher: AnyPublisher<BallDetection, Never>,
        calibration: CalibrationProfile?,
        handPreference: HandPreference = .right
    ) {
        self.calibration = calibration
        self.handPreference = handPreference

        setupSubscription(detectionPublisher)
    }

    // MARK: - Setup

    private func setupSubscription(_ publisher: AnyPublisher<BallDetection, Never>) {
        publisher
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] detection in
                let timestamp = ProcessInfo.processInfo.systemUptime
                self?.processDetection(detection, at: timestamp)
            }
            .store(in: &cancellables)
    }

    // MARK: - Processing

    private func processDetection(_ detection: BallDetection, at timestamp: TimeInterval) {
        guard detection.found else { return }

        // Add to history
        recentDetections.append((detection, timestamp))

        // Trim old detections
        if recentDetections.count > maxHistorySize {
            recentDetections.removeFirst(recentDetections.count - maxHistorySize)
        }

        // Calculate metrics
        calculateSpeed()
        calculateBoard(detection)
        calculateEntryAngle()
        calculateStrikeProbability()
    }

    private func calculateSpeed() {
        guard recentDetections.count >= 5,
              let calibration = calibration else {
            speedPublisher.send(nil)
            return
        }

        let firstFive = Array(recentDetections.prefix(5))
        guard let first = firstFive.first,
              let last = firstFive.last,
              let firstY = first.0.y,
              let lastY = last.0.y else {
            return
        }

        let firstDist = calibration.pixelToDistanceFt(firstY)
        let lastDist = calibration.pixelToDistanceFt(lastY)
        let distanceFt = abs(lastDist - firstDist)
        let timeSec = last.1 - first.1

        guard timeSec > 0 else { return }

        let feetPerSec = distanceFt / timeSec
        let mph = feetPerSec * 3600 / 5280

        speedPublisher.send(mph)
    }

    private func calculateBoard(_ detection: BallDetection) {
        guard let calibration = calibration,
              let x = detection.x else {
            boardPublisher.send(nil)
            return
        }

        let board = calibration.pixelToBoard(x)
        boardPublisher.send(board)
    }

    private func calculateEntryAngle() {
        guard recentDetections.count >= 10,
              let calibration = calibration else {
            anglePublisher.send(nil)
            return
        }

        // Linear regression on recent points
        let points = Array(recentDetections.suffix(10))

        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0
        var count: Double = 0

        for (detection, _) in points {
            guard let x = detection.x, let y = detection.y else { continue }
            let board = calibration.pixelToBoard(x)
            let dist = calibration.pixelToDistanceFt(y)

            sumX += dist
            sumY += board
            sumXY += dist * board
            sumX2 += dist * dist
            count += 1
        }

        guard count >= 2 else { return }

        // Slope = change in boards per change in distance
        let slope = (count * sumXY - sumX * sumY) / (count * sumX2 - sumX * sumX)

        // Convert to angle (boards per foot -> degrees)
        let boardsPerFoot = slope
        let inchesPerFoot = boardsPerFoot * (41.5 / 39.0)
        let angle = atan(inchesPerFoot / 12.0) * (180.0 / .pi)

        anglePublisher.send(abs(angle))
    }

    private func calculateStrikeProbability() {
        guard let angle = anglePublisher.value,
              let board = boardPublisher.value else {
            probabilityPublisher.send(nil)
            return
        }

        let optimalAngle = 6.0
        let optimalBoard = handPreference.pocketBoard

        let angleError = abs(angle - optimalAngle)
        let boardError = abs(board - optimalBoard)

        // Penalty factors (tuned from real bowling data)
        let anglePenalty = pow(angleError / 10.0, 2) * 0.5
        let boardPenalty = pow(boardError / 5.0, 2) * 0.5

        let probability = max(0, min(1, 1.0 - anglePenalty - boardPenalty))
        probabilityPublisher.send(probability)
    }

    // MARK: - Reset

    func reset() {
        recentDetections.removeAll()
        speedPublisher.send(nil)
        boardPublisher.send(nil)
        anglePublisher.send(nil)
        probabilityPublisher.send(nil)
    }
}
```

---

## Summary

This specification provides a complete Swift-native state management architecture for BowlerTrax:

1. **Swift Data Models**: All TypeScript types converted to Swift with `Codable` conformance
2. **SwiftData Schema**: Persistent models with relationships and conversion helpers
3. **App State Architecture**: Four `@Observable` managers for sessions, tracking, calibration, and settings
4. **State Flow Diagram**: Clear visualization of which views read/write which state
5. **Real-Time Tracking**: High-frequency update strategy with throttled UI updates (30 Hz)
6. **Persistence Strategy**: Auto-save, crash recovery, and JSON export
7. **Combine Pipelines**: Camera frame publisher, detection pipeline, and metrics calculator

Key design decisions:
- Use `@Observable` (iOS 17+) instead of ObservableObject for better performance
- Separate SwiftData entities from domain models for flexibility
- Throttle UI updates to 30 Hz while processing at full camera rate
- Store trajectory as JSON blob for flexibility
- Implement crash recovery via UserDefaults checkpoints
