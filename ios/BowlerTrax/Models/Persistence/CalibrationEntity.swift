//
//  CalibrationEntity.swift
//  BowlerTrax
//
//  SwiftData entity for calibration profiles
//

import Foundation
import SwiftData
import CoreGraphics

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

    // Crop zone properties (stored as individual values since CGRect isn't supported)
    var cropX: Double?
    var cropY: Double?
    var cropWidth: Double?
    var cropHeight: Double?
    var cropEnabled: Bool

    var createdAt: Date
    var lastUsed: Date?

    var center: CenterEntity?

    /// Default initializer required by SwiftData
    init() {
        self.id = UUID()
        self.centerId = UUID()
        self.centerName = ""
        self.pixelsPerFoot = 50.0
        self.pixelsPerBoard = 10.0
        self.foulLineY = 0
        self.arrowsY = 100
        self.leftGutterX = 0
        self.rightGutterX = 400
        self.cropX = nil
        self.cropY = nil
        self.cropWidth = nil
        self.cropHeight = nil
        self.cropEnabled = false
        self.createdAt = Date()
    }

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

        self.createdAt = profile.createdAt
        self.lastUsed = profile.lastUsed
    }

    func toModel() -> CalibrationProfile {
        // Reconstruct CGRect from individual values if all are present
        var cropRect: CGRect? = nil
        if let x = cropX, let y = cropY, let width = cropWidth, let height = cropHeight {
            cropRect = CGRect(x: x, y: y, width: width, height: height)
        }

        return CalibrationProfile(
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
            cropRect: cropRect,
            cropEnabled: cropEnabled,
            createdAt: createdAt,
            lastUsed: lastUsed
        )
    }

    /// Update entity from domain model
    func update(from profile: CalibrationProfile) {
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

        self.lastUsed = profile.lastUsed
    }

    /// Mark calibration as recently used
    func markUsed() {
        self.lastUsed = Date()
    }

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
}
