//
//  CalibrationProfile.swift
//  BowlerTrax
//
//  Calibration profile for lane perspective correction
//

import Foundation
import CoreGraphics

/// Calibration profile saved for a center
struct CalibrationProfile: Codable, Identifiable, Equatable, Sendable {
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

    // Crop zone (normalized 0-1 coordinates)
    var cropRect: CGRect?
    var cropEnabled: Bool

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
        cropRect: CGRect? = nil,
        cropEnabled: Bool = false,
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
        self.cropRect = cropRect
        self.cropEnabled = cropEnabled
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }
}

// MARK: - Pixel Conversion Methods

extension CalibrationProfile {
    /// Convert pixel X coordinate to board number (1-39)
    func pixelToBoard(_ pixelX: Double) -> Double {
        let totalWidth = rightGutterX - leftGutterX
        let normalizedX = (pixelX - leftGutterX) / totalWidth
        return normalizedX * 39.0 + 1.0  // Boards 1-39
    }

    /// Convert pixel Y coordinate to distance from foul line (feet)
    func pixelToDistanceFt(_ pixelY: Double) -> Double {
        (foulLineY - pixelY) / pixelsPerFoot
    }

    /// Convert board number to pixel X coordinate
    func boardToPixel(_ board: Double) -> Double {
        let normalizedX = (board - 1.0) / 39.0
        let totalWidth = rightGutterX - leftGutterX
        return leftGutterX + (normalizedX * totalWidth)
    }

    /// Convert distance (feet) to pixel Y coordinate
    func distanceFtToPixel(_ distanceFt: Double) -> Double {
        foulLineY - (distanceFt * pixelsPerFoot)
    }

    /// Convert pixel point to real-world coordinates
    func pixelToRealWorld(_ point: CGPoint) -> (board: Double, distanceFt: Double) {
        let board = pixelToBoard(Double(point.x))
        let distance = pixelToDistanceFt(Double(point.y))
        return (board, distance)
    }

    /// Convert real-world coordinates to pixel point
    func realWorldToPixel(board: Double, distanceFt: Double) -> CGPoint {
        let x = boardToPixel(board)
        let y = distanceFtToPixel(distanceFt)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Computed Properties

extension CalibrationProfile {
    /// Total lane width in pixels
    var laneWidthPixels: Double {
        rightGutterX - leftGutterX
    }

    /// Distance from foul line to arrows in pixels
    var foulToArrowsPixels: Double {
        foulLineY - arrowsY
    }

    /// Display name for the calibration
    var displayName: String {
        if let lane = laneNumber {
            return "\(centerName) - Lane \(lane)"
        }
        return centerName
    }

    /// Check if calibration is recent (used within last 7 days)
    var isRecent: Bool {
        guard let lastUsed = lastUsed else { return false }
        return Date().timeIntervalSince(lastUsed) < 7 * 24 * 60 * 60
    }

    /// Check if crop zone is configured and enabled
    var hasCropZone: Bool {
        cropEnabled && cropRect != nil
    }
}

// MARK: - Crop Zone

extension CalibrationProfile {
    /// Apply crop rect to a pixel coordinate (transforms from full frame to cropped frame)
    func applyCrop(to point: CGPoint, frameSize: CGSize) -> CGPoint? {
        guard let crop = cropRect, cropEnabled else {
            return point  // No crop, return original
        }

        // Convert normalized crop rect to pixel coordinates
        let cropPixelRect = CGRect(
            x: crop.origin.x * frameSize.width,
            y: crop.origin.y * frameSize.height,
            width: crop.width * frameSize.width,
            height: crop.height * frameSize.height
        )

        // Check if point is within crop area
        guard cropPixelRect.contains(point) else {
            return nil  // Point outside crop area
        }

        // Transform to cropped coordinate space
        return CGPoint(
            x: point.x - cropPixelRect.origin.x,
            y: point.y - cropPixelRect.origin.y
        )
    }

    /// Reverse crop transform (from cropped frame coordinates to full frame)
    func reverseCrop(from point: CGPoint, frameSize: CGSize) -> CGPoint {
        guard let crop = cropRect, cropEnabled else {
            return point  // No crop, return original
        }

        // Convert normalized crop rect to pixel coordinates
        let cropPixelRect = CGRect(
            x: crop.origin.x * frameSize.width,
            y: crop.origin.y * frameSize.height,
            width: crop.width * frameSize.width,
            height: crop.height * frameSize.height
        )

        // Transform back to full frame coordinate space
        return CGPoint(
            x: point.x + cropPixelRect.origin.x,
            y: point.y + cropPixelRect.origin.y
        )
    }

    /// Get the cropped frame size given the original frame size
    func croppedFrameSize(from originalSize: CGSize) -> CGSize {
        guard let crop = cropRect, cropEnabled else {
            return originalSize  // No crop, return original
        }

        return CGSize(
            width: crop.width * originalSize.width,
            height: crop.height * originalSize.height
        )
    }
}

// MARK: - Validation

extension CalibrationProfile {
    /// Validate calibration values are reasonable
    /// Note: Uses relaxed validation - only checks essential constraints
    var isValid: Bool {
        // Check all values are positive
        guard pixelsPerFoot > 0,
              pixelsPerBoard > 0,
              foulLineY > 0,
              arrowsY > 0,
              leftGutterX >= 0,
              rightGutterX > leftGutterX else {
            return false
        }

        // Check arrows are above foul line in image (Y decreases upward)
        // Note: In screen coordinates, lower Y means higher on screen
        guard arrowsY < foulLineY else {
            return false
        }

        // Removed strict aspect ratio validation - different camera angles and
        // positions can result in valid calibrations outside the "ideal" range.
        // The user verifies visually in Step 4 (Verify) that the overlay looks correct.

        return true
    }

    /// Get validation error message if invalid
    var validationError: String? {
        if pixelsPerFoot <= 0 { return "Invalid pixels per foot" }
        if pixelsPerBoard <= 0 { return "Invalid pixels per board" }
        if foulLineY <= 0 { return "Invalid foul line position" }
        if arrowsY <= 0 { return "Invalid arrows position" }
        if leftGutterX < 0 { return "Invalid left gutter position" }
        if rightGutterX <= leftGutterX { return "Invalid right gutter position" }
        if arrowsY >= foulLineY { return "Arrows must be above foul line" }
        return nil
    }
}
