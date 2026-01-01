# BowlerTrax Error Handling Matrix and Edge Cases

This document provides comprehensive error handling specifications for the BowlerTrax bowling analytics application. Each section includes error matrices, Swift error enum definitions, and recovery strategies.

---

## Table of Contents

1. [Camera Errors](#1-camera-errors)
2. [Ball Detection Errors](#2-ball-detection-errors)
3. [Calibration Errors](#3-calibration-errors)
4. [Tracking Errors](#4-tracking-errors)
5. [Data Persistence Errors](#5-data-persistence-errors)
6. [Network Errors](#6-network-errors)
7. [Edge Cases](#7-edge-cases)
8. [Graceful Degradation](#8-graceful-degradation)
9. [Swift Error Definitions](#9-swift-error-definitions)

---

## 1. Camera Errors

### Error Matrix

| Error | Cause | Detection | Recovery | User Message |
|-------|-------|-----------|----------|--------------|
| Permission Denied | User denied camera access or privacy settings | `AVCaptureDevice.authorizationStatus() == .denied` | Prompt user to Settings app | "Camera access is required to track your bowling shots. Please enable camera access in Settings." |
| Permission Restricted | Parental controls or MDM restrictions | `AVCaptureDevice.authorizationStatus() == .restricted` | Display informational message | "Camera access is restricted on this device. Please contact your administrator." |
| Camera Unavailable | No camera hardware or camera in use by another app | `AVCaptureDevice.default() == nil` or session start failure | Wait and retry, or prompt user | "Camera is currently unavailable. Please close other camera apps and try again." |
| Frame Capture Failure | Buffer allocation failure, memory pressure | `CMSampleBuffer` is nil or `CVPixelBuffer` extraction fails | Skip frame, continue capture | (Silent - no user message, log internally) |
| Low Light Conditions | Ambient light below threshold | Analyze frame histogram, average luminance < 40 | Enable flash/torch, warn user | "Low light detected. Move to a brighter area or enable the flash for better tracking." |
| Camera Obstructed | Finger over lens, case blocking | Frame variance near zero, all pixels similar | Prompt user to check camera | "Camera appears to be blocked. Please check that nothing is covering the lens." |
| Camera Disconnected | External camera unplugged (iPad) | `AVCaptureSession.wasInterrupted` notification | Switch to built-in camera | "External camera disconnected. Switching to built-in camera." |
| Thermal Throttling | Device overheating | `ProcessInfo.thermalState == .critical` | Reduce frame rate, pause if critical | "Device is too warm. Recording paused to cool down." |

### Detection Thresholds

```swift
struct CameraThresholds {
    static let minLuminance: Float = 40.0      // 0-255 scale
    static let maxLuminance: Float = 250.0     // Overexposure threshold
    static let minFrameVariance: Float = 100.0 // Below = obstructed
    static let frameDropThreshold: Int = 10    // Consecutive drops before warning
}
```

---

## 2. Ball Detection Errors

### Error Matrix

| Error | Cause | Detection | Recovery | User Message |
|-------|-------|-----------|----------|--------------|
| Ball Not Detected | Ball color not calibrated, ball out of frame | No contours match ball color profile in HSV range | Extend HSV range, prompt recalibration | "Ball not detected. Please ensure the ball is visible and consider recalibrating ball color." |
| Multiple Objects Detected | Other bowlers, equipment, similar colored objects | Multiple contours pass size/color threshold | Use motion prediction, select closest to expected position | (Silent - use best candidate, log for analytics) |
| Wrong Object Tracked | Bowler's shirt, lane marker, etc. | Object doesn't follow expected trajectory physics | Reset tracking, wait for new motion | "Tracking lost. Please wait for the next shot." |
| Ball Color Too Similar to Lane | Light-colored ball on synthetic lane | HSV overlap between ball and lane colors | Use shape detection + color, suggest different ball | "Ball color is difficult to distinguish. Try using a ball with more contrast to the lane." |
| Ball Exits Frame Unexpectedly | Camera angle wrong, ball in gutter | Position suddenly at frame edge with high velocity | Estimate exit point, complete trajectory | "Ball went out of frame early. Adjust camera angle to capture full lane." |
| Occlusion by Bowler | Bowler blocks ball at release | Ball disappears then reappears | Interpolate trajectory during occlusion | (Silent - interpolate gap, mark confidence lower) |
| Ball Reflection Detected | Glossy lane surface creating mirror image | Two similar objects, one below lane plane | Use Y-coordinate filtering, ignore below threshold | (Silent - filter reflection automatically) |
| Spin Blur | High rev rate causing motion blur | Circular contour becomes elliptical/streaked | Use centroid tracking over edge detection | (Silent - adjust algorithm, note in confidence) |

### Detection Parameters

```swift
struct BallDetectionParams {
    static let minContourArea: Int = 500       // Minimum pixels for valid ball
    static let maxContourArea: Int = 50000     // Maximum pixels (too close)
    static let circularityThreshold: Float = 0.7  // 1.0 = perfect circle
    static let hsvTolerance: Int = 15          // +/- from calibrated color
    static let maxOcclusionFrames: Int = 10    // Max frames to interpolate
    static let motionPredictionWeight: Float = 0.6  // Blend with detection
}
```

---

## 3. Calibration Errors

### Error Matrix

| Error | Cause | Detection | Recovery | User Message |
|-------|-------|-----------|----------|--------------|
| Wrong Arrow Tapped | User taps wrong arrow marker | Arrow position doesn't match expected sequence | Highlight correct arrow, allow retry | "That doesn't look like arrow [X]. Please tap the [X] arrow marker." |
| Foul Line Not Visible | Camera angle too high, foul line cropped | Calibration point at frame edge or not detected | Prompt camera adjustment | "Foul line not visible. Please adjust camera to show the foul line at bottom of frame." |
| Poor Lighting | Shadows obscuring markers, glare | Arrow contrast ratio < threshold | Suggest lighting adjustment | "Lane markers are hard to see. Please adjust lighting or position to reduce shadows." |
| Camera Moved During Calibration | Tripod bump, hand movement | Calibration points inconsistent with each other | Restart calibration | "Camera moved during calibration. Please keep camera steady and try again." |
| Invalid Pixel Measurements | Points create invalid geometry | Perspective transform matrix invalid or extreme | Reject and prompt retry | "Calibration measurements don't look right. Please try again from the start." |
| Arrows Not Detected | Auto-detection fails | Computer vision finds < 3 arrows | Fall back to manual tap | "Couldn't automatically detect arrows. Please tap each arrow manually." |
| Extreme Camera Angle | Camera too far to side or behind | Perspective ratio exceeds acceptable bounds | Guide to better position | "Camera angle is too extreme. Please position camera more directly behind the lane." |
| Partial Calibration | User abandons mid-calibration | Calibration state incomplete | Save partial, offer resume or restart | "Calibration incomplete. Would you like to resume or start over?" |

### Calibration Validation

```swift
struct CalibrationValidation {
    static let minArrowSpacing: CGFloat = 20.0    // Minimum pixels between arrows
    static let maxPerspectiveRatio: CGFloat = 3.0 // Max width ratio far/near
    static let minFoulLineWidth: CGFloat = 50.0   // Minimum detected width
    static let arrowSequenceOrder = [5, 10, 15, 20, 25, 30, 35]  // Board numbers
    static let maxCalibrationAttempts: Int = 3    // Before suggesting help
}
```

---

## 4. Tracking Errors

### Error Matrix

| Error | Cause | Detection | Recovery | User Message |
|-------|-------|-----------|----------|--------------|
| Lost Tracking Mid-Shot | Fast movement, occlusion, blur | Ball position undefined for > N frames | Interpolate if gap small, abort if large | "Lost track of the ball. Shot may be incomplete." |
| Trajectory Gaps | Dropped frames, momentary occlusion | Position jumps > physically possible | Spline interpolation for small gaps | (Silent - interpolate and mark confidence) |
| Impossible Speed (Too High) | Tracking error, misdetection | Speed > 35 mph sustained | Reject data point, use prediction | "Speed reading seems incorrect. Using estimated values." |
| Impossible Speed (Too Low) | Tracking stalled object | Speed < 5 mph without deceleration | Check if ball stopped (gutter/stuck) | "Ball appears to have stopped. Was this a gutter ball?" |
| Rev Rate Calculation Failed | Insufficient rotation data, no texture visible | Rotation detection confidence < threshold | Skip rev rate, show N/A | "Couldn't calculate rev rate for this shot." |
| Entry Angle Out of Range | Ball curved excessively or tracking error | Angle > 25 degrees or negative | Cap at reasonable bounds, flag | "Entry angle seems unusual. Please verify camera alignment." |
| Pin Detection Failed | Pins not in frame, already knocked down | No pin positions detected at impact | Skip pin count, use spare attempt data | "Couldn't detect pin results. Please enter manually if needed." |
| Frame Timestamp Errors | System clock issues, buffer delays | Timestamps non-monotonic or huge gaps | Use frame count with assumed FPS | (Silent - recalculate timing) |

### Tracking Thresholds

```swift
struct TrackingThresholds {
    static let maxBallSpeed: Float = 35.0       // mph - professional max ~27
    static let minBallSpeed: Float = 5.0        // mph - barely rolling
    static let maxEntryAngle: Float = 25.0      // degrees
    static let maxFrameGap: Int = 5             // frames before trajectory split
    static let minTrackingConfidence: Float = 0.6
    static let revRateMinRotation: Float = 45.0 // degrees to calculate
}
```

---

## 5. Data Persistence Errors

### Error Matrix

| Error | Cause | Detection | Recovery | User Message |
|-------|-------|-----------|----------|--------------|
| Database Write Failure | SQLite error, corruption | `sqlite3_step` returns error | Retry 3x, then queue for later | "Couldn't save shot data. Will retry automatically." |
| Storage Full | Device storage exhausted | `FileManager` reports < 50MB free | Delete old videos, warn user | "Storage is full. Please free up space to continue recording." |
| Video Save Failed | Encoding error, interrupted write | `AVAssetWriter.error` non-nil | Retry encode, save raw frames if needed | "Video couldn't be saved. Shot data preserved without video." |
| Corrupt Session Data | App crash during write, power loss | JSON/SQLite parse fails | Attempt recovery, mark session invalid | "Some session data may be incomplete. Recovered what was possible." |
| Migration Failed | Database schema update error | Migration version check fails | Keep old data, disable new features | "Database update needed. Some new features unavailable until update completes." |
| Export Failed | External storage error, permissions | Write to share location fails | Offer alternative export method | "Export failed. Try a different export option." |
| Backup Restore Failed | Corrupt backup, version mismatch | Backup file validation fails | Reject restore, keep current data | "Backup file couldn't be restored. Your current data is unchanged." |
| Concurrent Write Conflict | Multi-threaded access | SQLite busy error | Serial queue enforcement | (Silent - retry with queue) |

### Storage Thresholds

```swift
struct StorageThresholds {
    static let minFreeSpace: UInt64 = 50_000_000      // 50 MB minimum
    static let warningFreeSpace: UInt64 = 200_000_000 // 200 MB warning
    static let maxVideoSize: UInt64 = 500_000_000     // 500 MB per video
    static let maxRetryAttempts: Int = 3
    static let retryDelay: TimeInterval = 1.0
}
```

---

## 6. Network Errors

### Error Matrix

| Error | Cause | Detection | Recovery | User Message |
|-------|-------|-----------|----------|--------------|
| Sync Failed | Server unreachable, API error | HTTP status != 200, timeout | Queue for retry, use exponential backoff | "Sync failed. Your data is saved locally and will sync when connected." |
| Timeout | Slow connection, large payload | `URLSession` timeout fires | Reduce payload size, retry | "Connection timed out. Retrying with smaller data chunks." |
| Authentication Expired | Token expired, password changed | HTTP 401/403 | Prompt re-authentication | "Please sign in again to sync your data." |
| Rate Limited | Too many requests | HTTP 429 | Respect Retry-After header | "Sync paused briefly. Will resume automatically." |
| Offline Mode | No network connectivity | `NWPathMonitor` shows no path | Full offline operation | "You're offline. All features work locally, sync when connected." |
| Partial Sync | Connection lost mid-sync | Incomplete response | Resume from checkpoint | "Sync interrupted. Resuming from where it left off." |
| Server Error | Backend issues | HTTP 5xx | Retry with backoff | "Server is temporarily unavailable. Will retry automatically." |
| Data Conflict | Modified on multiple devices | Version mismatch detected | Offer conflict resolution UI | "This session was modified elsewhere. Choose which version to keep." |

### Network Configuration

```swift
struct NetworkConfig {
    static let timeoutInterval: TimeInterval = 30.0
    static let maxRetries: Int = 5
    static let baseBackoffDelay: TimeInterval = 1.0
    static let maxBackoffDelay: TimeInterval = 60.0
    static let offlineQueueLimit: Int = 1000  // Max queued operations
}
```

---

## 7. Edge Cases

### Recording Without Calibration

**Scenario:** User attempts to record without completing lane calibration.

**Handling:**
- Allow recording with warning
- Save raw video and pixel coordinates
- Prompt calibration after session
- Apply calibration retroactively if possible

```swift
struct UncalibratedRecording {
    let rawVideoURL: URL
    let pixelCoordinates: [TrackingPoint]  // Pixel space, not lane space
    let timestamp: Date
    var isCalibrationPending: Bool = true
}
```

**User Message:** "Lane not calibrated. Recording will continue, but metrics won't be available until you calibrate."

---

### Multiple Balls in Frame (League Bowling)

**Scenario:** Adjacent lane has bowler releasing simultaneously.

**Handling:**
- Use lane boundary detection
- Filter balls outside calibrated lane region
- Use motion prediction to maintain tracking
- Mark confidence if interference detected

**User Message:** (None if handled automatically, otherwise) "Another ball detected. Focusing on your lane."

---

### Very Fast Shots (>25 mph)

**Scenario:** Professional-level speed exceeding typical amateur range.

**Handling:**
- Increase frame processing priority
- Use motion blur analysis for position
- Accept readings up to 35 mph
- Flag for verification above 30 mph

```swift
struct SpeedValidation {
    static func validate(_ speed: Float) -> SpeedResult {
        switch speed {
        case ..<5: return .tooSlow
        case 5..<30: return .valid
        case 30..<35: return .valid(flagged: true)
        default: return .invalid
        }
    }
}
```

---

### Very Slow Shots (<10 mph)

**Scenario:** Beginner, child, or intentional slow roll.

**Handling:**
- Continue tracking even at low speeds
- Extend tracking window (may take longer to reach pins)
- Handle ball potentially stopping before pins
- Still calculate available metrics

**User Message:** (None - valid bowling, just slow)

---

### Gutter Balls

**Scenario:** Ball enters gutter before reaching pins.

**Handling:**
- Detect ball crossing gutter boundary
- Stop tracking at gutter entry point
- Record as gutter ball with partial trajectory
- Still calculate speed and initial angle
- Mark strike probability as 0%

```swift
enum ShotResult {
    case strike
    case spare(pins: Int)
    case open(pins: Int)
    case gutter(exitPoint: CGPoint)  // Where ball left lane
    case incomplete
}
```

---

### Ball Bounces Back from Pins

**Scenario:** Ball hits pins and returns toward bowler (rare).

**Handling:**
- Stop tracking at pin impact
- Ignore return trajectory
- Use impact point for entry angle calculation
- Handle gracefully in animation/replay

---

### Recording Interrupted

**Scenario:** Phone call, app backgrounded, or user switches apps.

**Handling:**
- Save tracking data immediately on interrupt
- Pause video recording gracefully
- Offer to resume or discard on return
- Keep partial data if useful

```swift
func handleInterruption(_ notification: Notification) {
    // Save current state immediately
    savePartialSession()

    // Pause camera capture
    captureSession.stopRunning()

    // Mark session as interrupted
    currentSession?.status = .interrupted
}
```

**User Message:** "Recording was interrupted. Would you like to resume or save what was recorded?"

---

### Low Battery During Recording

**Scenario:** Battery drops below 10% while recording.

**Handling:**
- Warn at 20% battery
- Force save at 10% battery
- Reduce frame rate at 15% to conserve
- Disable video recording, keep tracking at 10%

**User Messages:**
- 20%: "Battery low. Consider plugging in to continue recording."
- 10%: "Battery critical. Saving your session to prevent data loss."

---

### Camera Angle Changes Mid-Session

**Scenario:** Tripod bumped, phone moved.

**Handling:**
- Detect via sudden perspective shift
- Pause tracking
- Prompt quick recalibration or position reset
- Offer to split session at movement point

**User Message:** "Camera position changed. Quick calibration needed to continue accurate tracking."

---

### Network Transition During Sync

**Scenario:** WiFi to cellular or connection lost during upload.

**Handling:**
- Save sync checkpoint
- Resume from last successful chunk
- Handle reduced bandwidth gracefully
- Don't retry large uploads on cellular without permission

---

## 8. Graceful Degradation

### Features Without Calibration

| Feature | Without Calibration | Notes |
|---------|---------------------|-------|
| Video Recording | Full | Just recording, no overlay |
| Ball Detection | Full | Pixel coordinates only |
| Ball Color Calibration | Full | Independent of lane calibration |
| Speed Calculation | None | Requires distance reference |
| Entry Angle | None | Requires lane geometry |
| Rev Rate | Partial | Rotation detectable, RPM uncertain |
| Strike Probability | None | Requires position/angle |
| Trajectory Overlay | Pixel Only | No board numbers |
| Session History | Full | Stored with pending calibration flag |

### Minimum Viable Tracking

When rev rate cannot be calculated:

```swift
struct ShotMetrics {
    let speed: Float?           // mph, nil if uncalibrated
    let entryAngle: Float?      // degrees, nil if uncalibrated
    let entryBoard: Float?      // 1-39, nil if uncalibrated
    let revRate: Float?         // rpm, nil if detection failed
    let strikeProb: Float?      // 0-100%, nil if incomplete data
    let trajectory: [CGPoint]   // Always available (pixels or boards)
    let confidence: Float       // 0-1, overall tracking confidence
}
```

**Display Strategy:**
- Show available metrics prominently
- Use "---" or "N/A" for unavailable metrics
- Provide tooltip explaining why metric unavailable
- Offer suggestions to improve detection

### Fallback UI States

```swift
enum MetricDisplayState {
    case available(value: String)
    case calculating
    case unavailable(reason: String)
    case error(message: String)
}

// Example reasons
let unavailableReasons = [
    "speed": "Complete lane calibration to measure speed",
    "revRate": "Ball rotation couldn't be detected. Try a textured ball.",
    "entryAngle": "Ball exited frame before reaching pins",
    "strikeProb": "Incomplete trajectory data"
]
```

---

## 9. Swift Error Definitions

### Camera Errors

```swift
enum CameraError: LocalizedError {
    case permissionDenied
    case permissionRestricted
    case cameraUnavailable
    case frameCaptureFailed(underlying: Error?)
    case lowLightConditions(luminance: Float)
    case cameraObstructed
    case cameraDisconnected
    case thermalThrottling(state: ProcessInfo.ThermalState)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera access is required to track your bowling shots. Please enable camera access in Settings."
        case .permissionRestricted:
            return "Camera access is restricted on this device. Please contact your administrator."
        case .cameraUnavailable:
            return "Camera is currently unavailable. Please close other camera apps and try again."
        case .frameCaptureFailed:
            return "Failed to capture camera frame."
        case .lowLightConditions(let luminance):
            return "Low light detected (level: \(Int(luminance))). Move to a brighter area or enable the flash."
        case .cameraObstructed:
            return "Camera appears to be blocked. Please check that nothing is covering the lens."
        case .cameraDisconnected:
            return "External camera disconnected. Switching to built-in camera."
        case .thermalThrottling(let state):
            return "Device is too warm (\(state)). Recording paused to cool down."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Open Settings > BowlerTrax > Camera and enable access."
        case .lowLightConditions:
            return "Move closer to lane lighting or use the flash option."
        case .cameraObstructed:
            return "Remove any case or cover that may be blocking the camera."
        default:
            return nil
        }
    }
}
```

### Ball Detection Errors

```swift
enum BallDetectionError: LocalizedError {
    case ballNotDetected
    case multipleObjectsDetected(count: Int)
    case wrongObjectTracked
    case colorTooSimilarToLane
    case ballExitedFrameUnexpectedly(exitPoint: CGPoint)
    case occlusionDetected(duration: TimeInterval)
    case insufficientContrast
    case motionBlurExcessive

    var errorDescription: String? {
        switch self {
        case .ballNotDetected:
            return "Ball not detected. Please ensure the ball is visible and consider recalibrating ball color."
        case .multipleObjectsDetected(let count):
            return "Multiple objects detected (\(count)). Using best match."
        case .wrongObjectTracked:
            return "Tracking lost. Please wait for the next shot."
        case .colorTooSimilarToLane:
            return "Ball color is difficult to distinguish. Try using a ball with more contrast to the lane."
        case .ballExitedFrameUnexpectedly:
            return "Ball went out of frame early. Adjust camera angle to capture full lane."
        case .occlusionDetected(let duration):
            return "Ball was obscured for \(String(format: "%.1f", duration)) seconds."
        case .insufficientContrast:
            return "Ball doesn't have enough contrast with the lane. Consider a different colored ball."
        case .motionBlurExcessive:
            return "High spin causing motion blur. Tracking may be less accurate."
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .ballNotDetected, .colorTooSimilarToLane, .insufficientContrast:
            return false  // Requires user action
        case .multipleObjectsDetected, .occlusionDetected, .motionBlurExcessive:
            return true   // Can continue with reduced confidence
        case .wrongObjectTracked, .ballExitedFrameUnexpectedly:
            return false  // Shot is incomplete
        }
    }
}
```

### Calibration Errors

```swift
enum CalibrationError: LocalizedError {
    case wrongArrowTapped(expected: Int, tapped: Int)
    case foulLineNotVisible
    case poorLighting(contrast: Float)
    case cameraMoved(displacement: CGFloat)
    case invalidPixelMeasurements
    case arrowsNotDetected(found: Int, required: Int)
    case extremeCameraAngle(ratio: CGFloat)
    case calibrationIncomplete(step: Int, totalSteps: Int)
    case perspectiveInvalid

    var errorDescription: String? {
        switch self {
        case .wrongArrowTapped(let expected, _):
            return "That doesn't look like arrow \(expected). Please tap the correct arrow marker."
        case .foulLineNotVisible:
            return "Foul line not visible. Please adjust camera to show the foul line at bottom of frame."
        case .poorLighting:
            return "Lane markers are hard to see. Please adjust lighting or position to reduce shadows."
        case .cameraMoved:
            return "Camera moved during calibration. Please keep camera steady and try again."
        case .invalidPixelMeasurements:
            return "Calibration measurements don't look right. Please try again from the start."
        case .arrowsNotDetected(let found, let required):
            return "Only found \(found) of \(required) arrows. Please tap each arrow manually."
        case .extremeCameraAngle(let ratio):
            return "Camera angle is too extreme (ratio: \(String(format: "%.1f", ratio))). Please position camera more directly behind the lane."
        case .calibrationIncomplete(let step, let total):
            return "Calibration incomplete (\(step)/\(total)). Would you like to resume or start over?"
        case .perspectiveInvalid:
            return "Could not calculate lane perspective. Please recalibrate from a different position."
        }
    }
}
```

### Tracking Errors

```swift
enum TrackingError: LocalizedError {
    case lostTrackingMidShot(lastKnownPosition: CGPoint)
    case trajectoryGap(frames: Int)
    case impossibleSpeedHigh(speed: Float)
    case impossibleSpeedLow(speed: Float)
    case revRateCalculationFailed
    case entryAngleOutOfRange(angle: Float)
    case pinDetectionFailed
    case timestampError
    case insufficientDataPoints(count: Int, required: Int)

    var errorDescription: String? {
        switch self {
        case .lostTrackingMidShot:
            return "Lost track of the ball. Shot may be incomplete."
        case .trajectoryGap(let frames):
            return "Tracking gap of \(frames) frames. Using interpolation."
        case .impossibleSpeedHigh(let speed):
            return "Speed reading of \(String(format: "%.1f", speed)) mph seems incorrect. Using estimated values."
        case .impossibleSpeedLow(let speed):
            return "Ball appears to be moving very slowly (\(String(format: "%.1f", speed)) mph). Was this a gutter ball?"
        case .revRateCalculationFailed:
            return "Couldn't calculate rev rate for this shot."
        case .entryAngleOutOfRange(let angle):
            return "Entry angle of \(String(format: "%.1f", angle)) degrees seems unusual. Please verify camera alignment."
        case .pinDetectionFailed:
            return "Couldn't detect pin results. Please enter manually if needed."
        case .timestampError:
            return "Frame timing error detected. Speed calculation may be affected."
        case .insufficientDataPoints(let count, let required):
            return "Only captured \(count) of \(required) required tracking points."
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .lostTrackingMidShot, .insufficientDataPoints:
            return .high  // Shot data unusable
        case .impossibleSpeedHigh, .impossibleSpeedLow, .entryAngleOutOfRange:
            return .medium  // Data questionable
        case .trajectoryGap, .revRateCalculationFailed, .pinDetectionFailed, .timestampError:
            return .low  // Partial data available
        }
    }
}

enum ErrorSeverity {
    case low      // Minor issue, most data available
    case medium   // Some data questionable
    case high     // Shot data significantly compromised
    case critical // Cannot continue
}
```

### Data Persistence Errors

```swift
enum PersistenceError: LocalizedError {
    case databaseWriteFailed(underlying: Error)
    case storageFull(available: UInt64, required: UInt64)
    case videoSaveFailed(underlying: Error)
    case corruptSessionData(sessionId: String)
    case migrationFailed(fromVersion: Int, toVersion: Int)
    case exportFailed(destination: String, underlying: Error)
    case backupRestoreFailed(underlying: Error)
    case concurrentWriteConflict
    case fileNotFound(path: String)
    case encodingFailed(type: String)
    case decodingFailed(type: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .databaseWriteFailed:
            return "Couldn't save shot data. Will retry automatically."
        case .storageFull(let available, let required):
            return "Storage is full. Need \(formatBytes(required)) but only \(formatBytes(available)) available."
        case .videoSaveFailed:
            return "Video couldn't be saved. Shot data preserved without video."
        case .corruptSessionData(let id):
            return "Session \(id) data may be incomplete. Recovered what was possible."
        case .migrationFailed(let from, let to):
            return "Database update from v\(from) to v\(to) failed. Some new features unavailable."
        case .exportFailed(let dest, _):
            return "Export to \(dest) failed. Try a different export option."
        case .backupRestoreFailed:
            return "Backup file couldn't be restored. Your current data is unchanged."
        case .concurrentWriteConflict:
            return "Database busy. Retrying save operation."
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .encodingFailed(let type):
            return "Failed to encode \(type) data."
        case .decodingFailed(let type, _):
            return "Failed to decode \(type) data."
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
```

### Network Errors

```swift
enum NetworkError: LocalizedError {
    case syncFailed(underlying: Error)
    case timeout(duration: TimeInterval)
    case authenticationExpired
    case rateLimited(retryAfter: TimeInterval)
    case offline
    case partialSync(completed: Int, total: Int)
    case serverError(statusCode: Int)
    case dataConflict(localVersion: Int, remoteVersion: Int)
    case invalidResponse
    case sslError

    var errorDescription: String? {
        switch self {
        case .syncFailed:
            return "Sync failed. Your data is saved locally and will sync when connected."
        case .timeout(let duration):
            return "Connection timed out after \(Int(duration)) seconds. Retrying with smaller data chunks."
        case .authenticationExpired:
            return "Please sign in again to sync your data."
        case .rateLimited(let retryAfter):
            return "Sync paused. Will resume in \(Int(retryAfter)) seconds."
        case .offline:
            return "You're offline. All features work locally, sync when connected."
        case .partialSync(let completed, let total):
            return "Sync interrupted (\(completed)/\(total)). Resuming from where it left off."
        case .serverError(let code):
            return "Server error (\(code)). Will retry automatically."
        case .dataConflict:
            return "This session was modified elsewhere. Choose which version to keep."
        case .invalidResponse:
            return "Received invalid response from server."
        case .sslError:
            return "Secure connection failed. Please check your network."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .syncFailed, .timeout, .partialSync, .serverError:
            return true
        case .authenticationExpired, .dataConflict, .invalidResponse, .sslError:
            return false
        case .rateLimited, .offline:
            return true  // After delay
        }
    }
}
```

### Aggregate Error Type

```swift
enum BowlerTraxError: LocalizedError {
    case camera(CameraError)
    case ballDetection(BallDetectionError)
    case calibration(CalibrationError)
    case tracking(TrackingError)
    case persistence(PersistenceError)
    case network(NetworkError)
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .camera(let error): return error.errorDescription
        case .ballDetection(let error): return error.errorDescription
        case .calibration(let error): return error.errorDescription
        case .tracking(let error): return error.errorDescription
        case .persistence(let error): return error.errorDescription
        case .network(let error): return error.errorDescription
        case .unknown(let error): return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var category: String {
        switch self {
        case .camera: return "Camera"
        case .ballDetection: return "Detection"
        case .calibration: return "Calibration"
        case .tracking: return "Tracking"
        case .persistence: return "Storage"
        case .network: return "Network"
        case .unknown: return "Unknown"
        }
    }
}
```

---

## Error Logging

```swift
struct ErrorLog {
    let timestamp: Date
    let error: BowlerTraxError
    let context: [String: Any]
    let deviceState: DeviceState

    struct DeviceState {
        let batteryLevel: Float
        let thermalState: ProcessInfo.ThermalState
        let availableStorage: UInt64
        let networkStatus: String
        let appVersion: String
        let osVersion: String
    }
}

class ErrorLogger {
    static let shared = ErrorLogger()

    func log(_ error: BowlerTraxError, context: [String: Any] = [:]) {
        let log = ErrorLog(
            timestamp: Date(),
            error: error,
            context: context,
            deviceState: captureDeviceState()
        )

        // Save locally
        saveToLocalLog(log)

        // Queue for remote logging if enabled
        if UserDefaults.standard.bool(forKey: "analyticsEnabled") {
            queueForRemoteLogging(log)
        }
    }

    private func captureDeviceState() -> ErrorLog.DeviceState {
        // Implementation
    }
}
```

---

## Error Recovery Flows

### Automatic Recovery

```swift
class ErrorRecoveryManager {
    func attemptRecovery(for error: BowlerTraxError) async -> RecoveryResult {
        switch error {
        case .camera(.frameCaptureFailed):
            return await retryFrameCapture()

        case .ballDetection(.multipleObjectsDetected):
            return .continuedWithDegradedAccuracy

        case .tracking(.trajectoryGap(let frames)) where frames < 5:
            return .recoveredViaInterpolation

        case .persistence(.databaseWriteFailed):
            return await retryDatabaseWrite()

        case .network(.rateLimited(let retryAfter)):
            try? await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
            return await retrySync()

        default:
            return .requiresUserAction
        }
    }
}

enum RecoveryResult {
    case recovered
    case recoveredViaInterpolation
    case continuedWithDegradedAccuracy
    case requiresUserAction
    case unrecoverable
}
```

---

## Summary

This error handling specification ensures BowlerTrax gracefully handles all foreseeable failure modes while maintaining the best possible user experience. Key principles:

1. **Fail gracefully** - Always preserve user data even when features fail
2. **Be transparent** - Clear, actionable error messages
3. **Recover automatically** - Handle transient failures without user intervention
4. **Degrade gracefully** - Provide partial functionality when full features unavailable
5. **Log comprehensively** - Capture context for debugging and improvement
