//
//  CalibrationEntity.swift
//  BowlerTrax
//
//  SwiftData entity for calibration profiles.
//  Supports comprehensive multi-point lane calibration.
//

import Foundation
import SwiftData
import CoreGraphics

@Model
final class CalibrationEntity {
    // MARK: - Primary Identifiers

    @Attribute(.unique) var id: UUID
    var centerId: UUID
    var centerName: String
    var laneNumber: Int?

    // MARK: - Primary Reference Points

    /// Foul line Y position in pixels
    var foulLineY: Double

    /// Pin deck Y position in pixels (60 ft from foul line)
    var pinDeckY: Double?

    /// Left gutter edge X position in pixels
    var leftGutterX: Double

    /// Right gutter edge X position in pixels
    var rightGutterX: Double

    /// Arrows row Y position in pixels
    var arrowsY: Double

    /// Individual arrow X positions (stored as comma-separated string for SwiftData)
    var arrowPositionsData: String?

    // MARK: - Derived Measurements

    var pixelsPerFoot: Double
    var pixelsPerBoard: Double

    // MARK: - Breakpoint Zone

    var breakpointStartY: Double?
    var breakpointEndY: Double?

    // MARK: - Ball Return

    var ballReturnLeftX: Double?
    var ballReturnRightX: Double?

    // MARK: - Camera Info

    var cameraHeightFt: Double?
    var cameraAngleDeg: Double?

    // MARK: - Crop Zone (stored as individual values since CGRect isn't supported)

    var cropX: Double?
    var cropY: Double?
    var cropWidth: Double?
    var cropHeight: Double?
    var cropEnabled: Bool

    // MARK: - Calibration Quality

    var calibrationConfidence: Double?

    /// Auto-detected points flags (stored as bitmask)
    var autoDetectedFlags: Int?

    // MARK: - Metadata

    var createdAt: Date
    var lastUsed: Date?
    var version: Int

    // MARK: - Relationships

    var center: CenterEntity?

    // MARK: - Initialization

    /// Default initializer required by SwiftData
    init() {
        self.id = UUID()
        self.centerId = UUID()
        self.centerName = ""
        self.foulLineY = 0
        self.pinDeckY = nil
        self.leftGutterX = 0
        self.rightGutterX = 400
        self.arrowsY = 100
        self.arrowPositionsData = nil
        self.pixelsPerFoot = 50.0
        self.pixelsPerBoard = 10.0
        self.breakpointStartY = nil
        self.breakpointEndY = nil
        self.ballReturnLeftX = nil
        self.ballReturnRightX = nil
        self.cameraHeightFt = nil
        self.cameraAngleDeg = nil
        self.cropX = nil
        self.cropY = nil
        self.cropWidth = nil
        self.cropHeight = nil
        self.cropEnabled = false
        self.calibrationConfidence = nil
        self.autoDetectedFlags = nil
        self.createdAt = Date()
        self.lastUsed = nil
        self.version = 2
    }

    init(from profile: CalibrationProfile) {
        self.id = profile.id
        self.centerId = profile.centerId
        self.centerName = profile.centerName
        self.laneNumber = profile.laneNumber
        self.foulLineY = profile.foulLineY
        self.pinDeckY = profile.pinDeckY
        self.leftGutterX = profile.leftGutterX
        self.rightGutterX = profile.rightGutterX
        self.arrowsY = profile.arrowsY

        // Convert arrow positions array to comma-separated string
        if let positions = profile.arrowPositions {
            self.arrowPositionsData = positions.map { String($0) }.joined(separator: ",")
        } else {
            self.arrowPositionsData = nil
        }

        self.pixelsPerFoot = profile.pixelsPerFoot
        self.pixelsPerBoard = profile.pixelsPerBoard
        self.breakpointStartY = profile.breakpointStartY
        self.breakpointEndY = profile.breakpointEndY
        self.ballReturnLeftX = profile.ballReturnLeftX
        self.ballReturnRightX = profile.ballReturnRightX
        self.cameraHeightFt = profile.cameraHeightFt
        self.cameraAngleDeg = profile.cameraAngleDeg

        // Convert CGRect to individual values for persistence
        if let cropRect = profile.cropRect {
            self.cropX = cropRect.origin.x
            self.cropY = cropRect.origin.y
            self.cropWidth = cropRect.width
            self.cropHeight = cropRect.height
        } else {
            self.cropX = nil
            self.cropY = nil
            self.cropWidth = nil
            self.cropHeight = nil
        }
        self.cropEnabled = profile.cropEnabled

        self.calibrationConfidence = profile.calibrationConfidence

        // Convert auto-detected flags to bitmask
        if let flags = profile.autoDetectedPoints {
            self.autoDetectedFlags = Self.flagsToBitmask(flags)
        } else {
            self.autoDetectedFlags = nil
        }

        self.createdAt = profile.createdAt
        self.lastUsed = profile.lastUsed
        self.version = profile.version
    }

    func toModel() -> CalibrationProfile {
        // Reconstruct CGRect from individual values if all are present
        var cropRect: CGRect? = nil
        if let x = cropX, let y = cropY, let width = cropWidth, let height = cropHeight {
            cropRect = CGRect(x: x, y: y, width: width, height: height)
        }

        // Parse arrow positions from comma-separated string
        var arrowPositions: [Double]? = nil
        if let data = arrowPositionsData, !data.isEmpty {
            arrowPositions = data.split(separator: ",").compactMap { Double($0) }
        }

        // Convert bitmask to flags
        var autoDetectedPoints: CalibrationPointFlags? = nil
        if let flags = autoDetectedFlags {
            autoDetectedPoints = Self.bitmaskToFlags(flags)
        }

        return CalibrationProfile(
            id: id,
            centerId: centerId,
            centerName: centerName,
            laneNumber: laneNumber,
            foulLineY: foulLineY,
            pinDeckY: pinDeckY,
            leftGutterX: leftGutterX,
            rightGutterX: rightGutterX,
            arrowsY: arrowsY,
            arrowPositions: arrowPositions,
            pixelsPerFoot: pixelsPerFoot,
            pixelsPerBoard: pixelsPerBoard,
            breakpointStartY: breakpointStartY,
            breakpointEndY: breakpointEndY,
            ballReturnLeftX: ballReturnLeftX,
            ballReturnRightX: ballReturnRightX,
            cameraHeightFt: cameraHeightFt,
            cameraAngleDeg: cameraAngleDeg,
            cropRect: cropRect,
            cropEnabled: cropEnabled,
            calibrationConfidence: calibrationConfidence,
            autoDetectedPoints: autoDetectedPoints,
            createdAt: createdAt,
            lastUsed: lastUsed
        )
    }

    /// Update entity from domain model
    func update(from profile: CalibrationProfile) {
        self.centerName = profile.centerName
        self.laneNumber = profile.laneNumber
        self.foulLineY = profile.foulLineY
        self.pinDeckY = profile.pinDeckY
        self.leftGutterX = profile.leftGutterX
        self.rightGutterX = profile.rightGutterX
        self.arrowsY = profile.arrowsY

        // Update arrow positions
        if let positions = profile.arrowPositions {
            self.arrowPositionsData = positions.map { String($0) }.joined(separator: ",")
        } else {
            self.arrowPositionsData = nil
        }

        self.pixelsPerFoot = profile.pixelsPerFoot
        self.pixelsPerBoard = profile.pixelsPerBoard
        self.breakpointStartY = profile.breakpointStartY
        self.breakpointEndY = profile.breakpointEndY
        self.ballReturnLeftX = profile.ballReturnLeftX
        self.ballReturnRightX = profile.ballReturnRightX
        self.cameraHeightFt = profile.cameraHeightFt
        self.cameraAngleDeg = profile.cameraAngleDeg

        // Update crop zone properties
        if let cropRect = profile.cropRect {
            self.cropX = cropRect.origin.x
            self.cropY = cropRect.origin.y
            self.cropWidth = cropRect.width
            self.cropHeight = cropRect.height
        } else {
            self.cropX = nil
            self.cropY = nil
            self.cropWidth = nil
            self.cropHeight = nil
        }
        self.cropEnabled = profile.cropEnabled

        self.calibrationConfidence = profile.calibrationConfidence

        if let flags = profile.autoDetectedPoints {
            self.autoDetectedFlags = Self.flagsToBitmask(flags)
        } else {
            self.autoDetectedFlags = nil
        }

        self.lastUsed = profile.lastUsed
        self.version = profile.version
    }

    /// Mark calibration as recently used
    func markUsed() {
        self.lastUsed = Date()
    }

    // MARK: - Computed Properties

    /// Check if crop zone is configured and enabled
    var hasCropZone: Bool {
        cropEnabled && cropX != nil && cropY != nil && cropWidth != nil && cropHeight != nil
    }

    /// Get the crop rect if available
    var cropRect: CGRect? {
        guard let x = cropX, let y = cropY, let width = cropWidth, let height = cropHeight else {
            return nil
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// Check if this is a comprehensive calibration
    var isComprehensive: Bool {
        pinDeckY != nil && version >= 2
    }

    /// Get arrow positions as array
    var arrowPositions: [Double]? {
        guard let data = arrowPositionsData, !data.isEmpty else { return nil }
        return data.split(separator: ",").compactMap { Double($0) }
    }

    // MARK: - Flag Conversion Helpers

    private static func flagsToBitmask(_ flags: CalibrationPointFlags) -> Int {
        var mask = 0
        if flags.foulLine { mask |= 1 << 0 }
        if flags.pinDeck { mask |= 1 << 1 }
        if flags.leftGutter { mask |= 1 << 2 }
        if flags.rightGutter { mask |= 1 << 3 }
        if flags.arrows { mask |= 1 << 4 }
        if flags.breakpoint { mask |= 1 << 5 }
        if flags.ballReturn { mask |= 1 << 6 }
        return mask
    }

    private static func bitmaskToFlags(_ mask: Int) -> CalibrationPointFlags {
        CalibrationPointFlags(
            foulLine: (mask & (1 << 0)) != 0,
            pinDeck: (mask & (1 << 1)) != 0,
            leftGutter: (mask & (1 << 2)) != 0,
            rightGutter: (mask & (1 << 3)) != 0,
            arrows: (mask & (1 << 4)) != 0,
            breakpoint: (mask & (1 << 5)) != 0,
            ballReturn: (mask & (1 << 6)) != 0
        )
    }
}
