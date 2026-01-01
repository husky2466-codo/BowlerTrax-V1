//
//  CalibrationProfile.swift
//  BowlerTrax
//
//  Calibration profile for lane perspective correction.
//  Supports comprehensive multi-point calibration for accurate
//  ball tracking and metric calculation.
//

import Foundation
import CoreGraphics

/// Calibration profile saved for a center
struct CalibrationProfile: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var centerId: UUID
    var centerName: String
    var laneNumber: Int?

    // MARK: - Primary Reference Points (Required)

    /// Foul line Y position in pixels (0 ft from approach)
    var foulLineY: Double

    /// Pin deck / pinsetter entrance Y position in pixels (60 ft from foul line)
    var pinDeckY: Double?

    /// Left gutter edge X position in pixels (board 1)
    var leftGutterX: Double

    /// Right gutter edge X position in pixels (board 39)
    var rightGutterX: Double

    // MARK: - Arrow Reference Points

    /// Arrows row Y position in pixels (15 ft from foul line)
    var arrowsY: Double

    /// Individual arrow X positions (boards 5, 10, 15, 20, 25, 30, 35)
    /// Array of 7 values corresponding to each arrow position
    var arrowPositions: [Double]?

    // MARK: - Derived Measurements (Calculated)

    /// Pixels per foot (calculated from foulLine to arrows or pinDeck)
    var pixelsPerFoot: Double

    /// Pixels per board (calculated from left to right gutter)
    var pixelsPerBoard: Double

    /// Total lane width in pixels (rightGutterX - leftGutterX)
    var laneWidthPixels: Double {
        rightGutterX - leftGutterX
    }

    /// Total lane length in pixels (pinDeckY to foulLineY)
    var laneLengthPixels: Double? {
        guard let pinDeck = pinDeckY else { return nil }
        return abs(foulLineY - pinDeck)
    }

    // MARK: - Breakpoint Zone (Optional)

    /// Breakpoint zone start Y position (~35 ft from foul line)
    var breakpointStartY: Double?

    /// Breakpoint zone end Y position (~45 ft from foul line)
    var breakpointEndY: Double?

    // MARK: - Ball Return (Optional)

    /// Left ball return edge X position
    var ballReturnLeftX: Double?

    /// Right ball return edge X position
    var ballReturnRightX: Double?

    // MARK: - Camera Info

    /// Camera height in feet (optional)
    var cameraHeightFt: Double?

    /// Camera angle in degrees (optional)
    var cameraAngleDeg: Double?

    // MARK: - Crop Zone

    /// Crop zone rectangle (normalized 0-1 coordinates)
    var cropRect: CGRect?

    /// Whether crop zone is enabled
    var cropEnabled: Bool

    // MARK: - Calibration Quality

    /// Overall calibration confidence (0-1)
    var calibrationConfidence: Double?

    /// Which calibration points were auto-detected vs manually set
    var autoDetectedPoints: CalibrationPointFlags?

    // MARK: - Metadata

    let createdAt: Date
    var lastUsed: Date?

    /// Calibration version for migration support
    var version: Int = 2

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        centerId: UUID,
        centerName: String,
        laneNumber: Int? = nil,
        foulLineY: Double,
        pinDeckY: Double? = nil,
        leftGutterX: Double,
        rightGutterX: Double,
        arrowsY: Double,
        arrowPositions: [Double]? = nil,
        pixelsPerFoot: Double,
        pixelsPerBoard: Double,
        breakpointStartY: Double? = nil,
        breakpointEndY: Double? = nil,
        ballReturnLeftX: Double? = nil,
        ballReturnRightX: Double? = nil,
        cameraHeightFt: Double? = nil,
        cameraAngleDeg: Double? = nil,
        cropRect: CGRect? = nil,
        cropEnabled: Bool = false,
        calibrationConfidence: Double? = nil,
        autoDetectedPoints: CalibrationPointFlags? = nil,
        createdAt: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.centerId = centerId
        self.centerName = centerName
        self.laneNumber = laneNumber
        self.foulLineY = foulLineY
        self.pinDeckY = pinDeckY
        self.leftGutterX = leftGutterX
        self.rightGutterX = rightGutterX
        self.arrowsY = arrowsY
        self.arrowPositions = arrowPositions
        self.pixelsPerFoot = pixelsPerFoot
        self.pixelsPerBoard = pixelsPerBoard
        self.breakpointStartY = breakpointStartY
        self.breakpointEndY = breakpointEndY
        self.ballReturnLeftX = ballReturnLeftX
        self.ballReturnRightX = ballReturnRightX
        self.cameraHeightFt = cameraHeightFt
        self.cameraAngleDeg = cameraAngleDeg
        self.cropRect = cropRect
        self.cropEnabled = cropEnabled
        self.calibrationConfidence = calibrationConfidence
        self.autoDetectedPoints = autoDetectedPoints
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }

    /// Convenience initializer for backward compatibility with v1 calibrations
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
        self.foulLineY = foulLineY
        self.pinDeckY = nil
        self.leftGutterX = leftGutterX
        self.rightGutterX = rightGutterX
        self.arrowsY = arrowsY
        self.arrowPositions = nil
        self.pixelsPerFoot = pixelsPerFoot
        self.pixelsPerBoard = pixelsPerBoard
        self.breakpointStartY = nil
        self.breakpointEndY = nil
        self.ballReturnLeftX = nil
        self.ballReturnRightX = nil
        self.cameraHeightFt = cameraHeightFt
        self.cameraAngleDeg = cameraAngleDeg
        self.cropRect = cropRect
        self.cropEnabled = cropEnabled
        self.calibrationConfidence = nil
        self.autoDetectedPoints = nil
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.version = 1
    }
}

// MARK: - Calibration Point Flags

/// Flags indicating which calibration points were auto-detected
struct CalibrationPointFlags: Codable, Equatable, Sendable {
    var foulLine: Bool = false
    var pinDeck: Bool = false
    var leftGutter: Bool = false
    var rightGutter: Bool = false
    var arrows: Bool = false
    var breakpoint: Bool = false
    var ballReturn: Bool = false

    /// Number of points that were auto-detected
    var autoDetectedCount: Int {
        [foulLine, pinDeck, leftGutter, rightGutter, arrows, breakpoint, ballReturn]
            .filter { $0 }.count
    }

    /// Total number of detectable points
    static let totalPoints = 7
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

    /// Check if this is a comprehensive (v2) calibration with all points
    var isComprehensive: Bool {
        pinDeckY != nil && version >= 2
    }

    /// Estimated breakpoint Y position (35 ft from foul line)
    var estimatedBreakpointY: Double? {
        guard pixelsPerFoot > 0 else { return nil }
        let breakpointY = foulLineY - (35.0 * pixelsPerFoot)
        return breakpointY > 0 ? breakpointY : nil
    }

    /// Estimated pin deck Y position (60 ft from foul line)
    var estimatedPinDeckY: Double {
        pinDeckY ?? (foulLineY - (60.0 * pixelsPerFoot))
    }

    /// Get arrow X position for a specific arrow number (1-7)
    func arrowXPosition(arrowNumber: Int) -> Double? {
        guard arrowNumber >= 1 && arrowNumber <= 7 else { return nil }

        // If we have stored arrow positions, use them
        if let positions = arrowPositions, positions.count >= arrowNumber {
            return positions[arrowNumber - 1]
        }

        // Otherwise calculate from board positions
        let arrowBoards = [5, 10, 15, 20, 25, 30, 35]
        let boardNumber = arrowBoards[arrowNumber - 1]
        return boardToPixel(Double(boardNumber))
    }

    /// Get all arrow X positions (calculated if not stored)
    var allArrowXPositions: [Double] {
        if let positions = arrowPositions, positions.count == 7 {
            return positions
        }
        return (1...7).compactMap { arrowXPosition(arrowNumber: $0) }
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
