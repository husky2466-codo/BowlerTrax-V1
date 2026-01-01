# BowlerTrax Development Guide

> **One-Shot Development Reference for Claude Code**
>
> This file contains everything needed to build BowlerTrax from scratch. Read this entirely before starting development.

---

## 1. PROJECT OVERVIEW

### What is BowlerTrax?
BowlerTrax is a personal bowling analytics app that uses **color-based computer vision** to track bowling shots and provide real-time metrics. The app runs entirely on-device with no cloud dependency.

### Core Features
- **Ball Tracking**: 120fps color detection using HSV masking
- **Shot Metrics**: Speed (mph), entry angle (degrees), rev rate (RPM), board position
- **Strike Probability**: Algorithm based on entry angle, pocket position, speed
- **Session Management**: Track practice sessions with full shot history
- **Lane Calibration**: Perspective correction for accurate measurements

### Tech Stack
| Component | Technology |
|-----------|------------|
| **Platform** | iOS 17+ / iPadOS 17+ |
| **Framework** | SwiftUI |
| **Computer Vision** | Apple Vision + Core Image + Metal |
| **Camera** | AVFoundation (120fps) |
| **Database** | SwiftData |
| **Graphics** | Core Animation / SwiftUI Canvas |
| **Target Device** | iPad optimized (works on iPhone) |

### Key Differentiators
- No special hardware required (just the device camera)
- All processing on-device (privacy first)
- 120fps capture for accurate rev rate detection
- Calibration-based perspective correction

---

## 2. PROJECT STRUCTURE

```
BowlerTrax-V1/
├── ios/                          # Main iOS/iPadOS app
│   └── BowlerTrax/
│       ├── App/
│       │   ├── BowlerTraxApp.swift        # App entry point
│       │   └── ContentView.swift          # Root navigation
│       │
│       ├── Features/                      # Feature modules
│       │   ├── Dashboard/
│       │   │   ├── DashboardView.swift
│       │   │   └── Components/
│       │   │
│       │   ├── Recording/
│       │   │   ├── RecordingView.swift
│       │   │   ├── CameraManager.swift
│       │   │   └── Components/
│       │   │       ├── CameraPreview.swift
│       │   │       └── MetricsOverlay.swift
│       │   │
│       │   ├── Sessions/
│       │   │   ├── SessionListView.swift
│       │   │   ├── SessionDetailView.swift
│       │   │   └── ShotDetailView.swift
│       │   │
│       │   ├── Calibration/
│       │   │   ├── CalibrationView.swift
│       │   │   ├── CalibrationWizard.swift
│       │   │   └── Components/
│       │   │
│       │   ├── Settings/
│       │   │   ├── SettingsView.swift
│       │   │   ├── BallProfileView.swift
│       │   │   └── CalibrationProfileView.swift
│       │   │
│       │   └── Onboarding/
│       │       ├── OnboardingView.swift
│       │       ├── WelcomeScreen.swift
│       │       ├── FeatureCarousel.swift
│       │       └── PermissionScreen.swift
│       │
│       ├── Core/                          # Core functionality
│       │   ├── CV/                        # Computer Vision
│       │   │   ├── BallDetector.swift
│       │   │   ├── ColorMaskGenerator.swift
│       │   │   ├── ContourDetector.swift
│       │   │   ├── TrajectoryTracker.swift
│       │   │   ├── RevRateCalculator.swift
│       │   │   └── KalmanFilter.swift
│       │   │
│       │   ├── Camera/
│       │   │   ├── CameraSessionManager.swift
│       │   │   ├── FrameProcessor.swift
│       │   │   └── VideoRecorder.swift
│       │   │
│       │   ├── Physics/
│       │   │   ├── SpeedCalculator.swift
│       │   │   ├── AngleCalculator.swift
│       │   │   └── StrikeProbability.swift
│       │   │
│       │   └── Calibration/
│       │       ├── CalibrationCalculator.swift
│       │       └── PerspectiveTransform.swift
│       │
│       ├── Models/                        # Data models
│       │   ├── Domain/                    # Plain Swift structs
│       │   │   ├── Shot.swift
│       │   │   ├── Session.swift
│       │   │   ├── BallProfile.swift
│       │   │   ├── CalibrationProfile.swift
│       │   │   ├── Center.swift
│       │   │   └── TrajectoryPoint.swift
│       │   │
│       │   └── Persistence/               # SwiftData entities
│       │       ├── ShotEntity.swift
│       │       ├── SessionEntity.swift
│       │       ├── BallProfileEntity.swift
│       │       └── CalibrationEntity.swift
│       │
│       ├── Services/                      # Business logic
│       │   ├── SessionService.swift
│       │   ├── CalibrationService.swift
│       │   ├── ExportService.swift
│       │   └── SettingsService.swift
│       │
│       ├── Stores/                        # State management
│       │   ├── SessionStore.swift
│       │   ├── CalibrationStore.swift
│       │   ├── RecordingStore.swift
│       │   └── SettingsStore.swift
│       │
│       ├── DesignSystem/                  # UI components
│       │   ├── Colors.swift
│       │   ├── Typography.swift
│       │   ├── Spacing.swift
│       │   ├── Animation.swift
│       │   └── Components/
│       │       ├── MetricCard.swift
│       │       ├── ActionButton.swift
│       │       ├── SessionCard.swift
│       │       ├── ShotCard.swift
│       │       ├── NavigationBar.swift
│       │       ├── TabBar.swift
│       │       ├── ProgressIndicator.swift
│       │       ├── CameraOverlay.swift
│       │       ├── TrajectoryPath.swift
│       │       └── StrikeProbabilityGauge.swift
│       │
│       ├── Utilities/
│       │   ├── Errors.swift
│       │   ├── Extensions/
│       │   └── Helpers/
│       │
│       └── Resources/
│           └── Assets.xcassets/
│
├── specs/                        # Specification documents
│   ├── UI-Wireframes.md
│   ├── Design-System.md
│   ├── CV-Pipeline.md
│   ├── State-Management.md
│   ├── Error-Handling.md
│   ├── Flow-Diagrams.md
│   └── Onboarding.md
│
├── BowlerTrax-Plan.md            # Original implementation plan
├── Bowling-Info-Ref.md           # Domain knowledge reference
├── PROGRESS.md                   # Development status
└── Analysis/
    └── LaneTrax-App-Analysis.md  # Competitor analysis
```

---

## 3. QUICK REFERENCE

### Lane Dimensions (USBC Standards)
```swift
struct LaneConstants {
    static let laneLength: Double = 60.0      // feet (foul line to head pin)
    static let laneWidth: Double = 41.5       // inches
    static let boardCount: Int = 39           // boards numbered 1-39
    static let boardWidth: Double = 1.0641    // inches per board

    static let arrowDistance: Double = 15.0   // feet from foul line
    static let arrowBoards = [5, 10, 15, 20, 25, 30, 35]  // board positions

    static let pocketBoardRight: Double = 17.5  // right-handed pocket
    static let pocketBoardLeft: Double = 22.5   // left-handed pocket

    static let optimalEntryAngle: Double = 6.0  // degrees for max strikes
}
```

### Color Palette (Dark Theme)
```swift
// Primary Brand (Teal)
static let btPrimary = Color(hex: "14B8A6")       // Teal-500
static let btPrimaryLight = Color(hex: "5EEAD4") // Teal-300
static let btPrimaryDark = Color(hex: "0D9488")  // Teal-600
static let btAccent = Color(hex: "22D3EE")       // Cyan-400

// Backgrounds
static let btBackground = Color(hex: "0F0F0F")   // Near black
static let btSurface = Color(hex: "1A1A1A")      // Card background
static let btSurfaceElevated = Color(hex: "252525")

// Text
static let btTextPrimary = Color(hex: "FFFFFF")
static let btTextSecondary = Color(hex: "A1A1AA")
static let btTextMuted = Color(hex: "71717A")

// Semantic
static let btSuccess = Color(hex: "22C55E")      // Green
static let btWarning = Color(hex: "F59E0B")      // Amber
static let btError = Color(hex: "EF4444")        // Red

// Metric Accents
static let btSpeed = Color(hex: "F97316")        // Orange
static let btRevRate = Color(hex: "A855F7")      // Purple
static let btAngle = Color(hex: "14B8A6")        // Teal
static let btStrike = Color(hex: "22C55E")       // Green
```

### Physics Formulas
```swift
// Speed (mph) from distance and time
func calculateSpeed(distanceFeet: Double, timeSeconds: Double) -> Double {
    let feetPerSecond = distanceFeet / timeSeconds
    return feetPerSecond * 0.6818  // fps to mph
}

// Entry angle from trajectory
func calculateEntryAngle(dx: Double, dy: Double) -> Double {
    return atan2(dx, dy) * (180.0 / .pi)  // radians to degrees
}

// Strike probability
func strikeProbability(entryAngle: Double, pocketOffset: Double, speed: Double) -> Double {
    // Optimal: 6 degrees, 0 offset, 16-18 mph
    let angleFactor = 1.0 - abs(entryAngle - 6.0) / 10.0
    let pocketFactor = 1.0 - abs(pocketOffset) / 3.0
    let speedFactor = 1.0 - abs(speed - 17.0) / 10.0

    return max(0, min(1, (angleFactor * 0.5) + (pocketFactor * 0.35) + (speedFactor * 0.15)))
}

// Rev rate (RPM) from rotation tracking
func calculateRevRate(rotationDegrees: Double, timeSeconds: Double) -> Double {
    let rotations = rotationDegrees / 360.0
    return (rotations / timeSeconds) * 60.0
}
```

### File Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| View | `<Name>View.swift` | `DashboardView.swift` |
| Component | `<Name>.swift` | `MetricCard.swift` |
| Service | `<Name>Service.swift` | `SessionService.swift` |
| Store | `<Name>Store.swift` | `RecordingStore.swift` |
| Entity | `<Name>Entity.swift` | `ShotEntity.swift` |
| Domain Model | `<Name>.swift` | `Shot.swift` |
| Error | `<Domain>Error.swift` | `CameraError.swift` |

---

## 4. DEVELOPMENT COMMANDS

### Xcode Build Commands
```bash
# Open project in Xcode
open ios/BowlerTrax.xcodeproj

# Build from command line
xcodebuild -project ios/BowlerTrax.xcodeproj -scheme BowlerTrax -configuration Debug build

# Run tests
xcodebuild -project ios/BowlerTrax.xcodeproj -scheme BowlerTrax test

# Build for device
xcodebuild -project ios/BowlerTrax.xcodeproj -scheme BowlerTrax -destination 'platform=iOS,name=<device-name>' build
```

### SwiftLint (if configured)
```bash
# Run linter
swiftlint

# Auto-fix issues
swiftlint --fix
```

### Device Deployment
```bash
# List available devices
xcrun xctrace list devices

# Install on device (after building)
ios-deploy --bundle ios/BowlerTrax/build/Debug-iphoneos/BowlerTrax.app
```

---

## 5. CODING STANDARDS

### Swift Style Guide

#### Naming
```swift
// Types: PascalCase
struct SessionStats { }
class BallDetector { }
enum ShotResult { }
protocol TrackingDelegate { }

// Properties/Methods: camelCase
var shotCount: Int
func calculateSpeed() -> Double

// Constants: camelCase
let maxFrameRate: Double = 120.0
static let defaultTolerance = 15.0

// Enums: camelCase cases
enum TrackingState {
    case searching
    case tracking
    case occluded(frames: Int)
    case lost
}
```

#### Structure Organization
```swift
struct Shot: Codable, Identifiable {
    // MARK: - Properties
    let id: UUID
    var speed: Double?
    var entryAngle: Double?

    // MARK: - Initialization
    init(id: UUID = UUID()) {
        self.id = id
    }

    // MARK: - Computed Properties
    var isComplete: Bool {
        speed != nil && entryAngle != nil
    }

    // MARK: - Methods
    func strikeProbability() -> Double { }

    // MARK: - Private Methods
    private func validate() -> Bool { }
}
```

#### SwiftUI View Pattern
```swift
struct MetricCard: View {
    // MARK: - Properties
    let title: String
    let value: String
    let accentColor: Color

    // MARK: - State
    @State private var isAnimating = false

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            titleView
            valueView
        }
        .padding(BTLayout.cardPadding)
        .background(cardBackground)
    }

    // MARK: - Subviews
    private var titleView: some View {
        Text(title)
            .font(BTFont.metricLabel())
            .foregroundColor(.btMetricLabel)
    }

    private var valueView: some View {
        Text(value)
            .font(BTFont.metricValue())
            .foregroundColor(.btMetricValue)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.btSurface)
    }
}
```

#### Error Handling Pattern
```swift
enum CameraError: LocalizedError {
    case permissionDenied
    case deviceNotFound
    case captureSessionFailed(underlying: Error?)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera access is required to track shots."
        case .deviceNotFound:
            return "Camera is unavailable."
        case .captureSessionFailed(let error):
            return "Camera failed: \(error?.localizedDescription ?? "Unknown")"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Enable camera access in Settings > BowlerTrax."
        default:
            return nil
        }
    }
}
```

#### Async/Await Pattern
```swift
class BallDetector {
    func detectBall(in frame: CVPixelBuffer) async throws -> BallDetection? {
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    let result = self.processFrame(frame)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

---

## 6. SPEC FILE REFERENCES

| Topic | File | Key Content |
|-------|------|-------------|
| **UI Screens** | `specs/UI-Wireframes.md` | All screen wireframes, component layouts |
| **Design Tokens** | `specs/Design-System.md` | Colors, typography, spacing, component specs |
| **CV Algorithm** | `specs/CV-Pipeline.md` | Ball detection, tracking, rev rate calculation |
| **State Management** | `specs/State-Management.md` | Swift models, SwiftData schema, state flow |
| **Error Handling** | `specs/Error-Handling.md` | Error matrices, Swift error enums, recovery |
| **User Flows** | `specs/Flow-Diagrams.md` | Navigation flows, data flow diagrams |
| **First Use** | `specs/Onboarding.md` | Onboarding screens, permission requests |
| **Domain Knowledge** | `Bowling-Info-Ref.md` | Bowling physics, rev rate categories |
| **Competitor** | `Analysis/LaneTrax-App-Analysis.md` | Feature comparison, UI inspiration |

### Quick Links to Critical Sections

**UI Wireframes (specs/UI-Wireframes.md)**
- Recording screen layout
- Shot analysis screen
- Calibration wizard steps

**Design System (specs/Design-System.md)**
- MetricCard component (lines 400-480)
- ActionButton component (lines 490-600)
- TrajectoryPath component (lines 1140-1250)
- StrikeProbabilityGauge (lines 1255-1345)
- Animation specifications (lines 1430-1630)

**CV Pipeline (specs/CV-Pipeline.md)**
- Camera setup for 120fps (lines 25-85)
- HSV color masking (lines 270-360)
- Contour detection (lines 450-480)
- Trajectory tracking (lines 750-910)
- Rev rate detection (lines 1120-1390)

**State Management (specs/State-Management.md)**
- Shot model (lines 435-560)
- Session model (lines 365-435)
- SwiftData entities (lines 700-900)
- Calibration profile (lines 275-365)

**Error Handling (specs/Error-Handling.md)**
- Camera errors (lines 440-485)
- Ball detection errors (lines 490-530)
- Tracking errors (lines 575-620)
- Graceful degradation (lines 380-430)

---

## 7. COMMON TASKS

### Adding a New Screen

1. **Create View File**
```swift
// Features/<Feature>/<Name>View.swift
import SwiftUI

struct NewFeatureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewFeatureViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                // Content
            }
            .background(Color.btBackground)
            .navigationTitle("Title")
        }
    }
}
```

2. **Add to Navigation**
```swift
// In parent view or TabBar
NavigationLink(destination: NewFeatureView()) {
    Text("New Feature")
}
```

### Adding a New Model

1. **Create Domain Model**
```swift
// Models/Domain/<Name>.swift
struct NewModel: Codable, Identifiable, Equatable {
    let id: UUID
    var property: String
    let createdAt: Date

    init(id: UUID = UUID(), property: String, createdAt: Date = Date()) {
        self.id = id
        self.property = property
        self.createdAt = createdAt
    }
}
```

2. **Create SwiftData Entity**
```swift
// Models/Persistence/<Name>Entity.swift
import SwiftData

@Model
final class NewModelEntity {
    @Attribute(.unique) var id: UUID
    var property: String
    var createdAt: Date

    init(from model: NewModel) {
        self.id = model.id
        self.property = model.property
        self.createdAt = model.createdAt
    }

    func toModel() -> NewModel {
        NewModel(id: id, property: property, createdAt: createdAt)
    }
}
```

### Modifying CV Pipeline

1. **Ball Detection Changes**: `Core/CV/BallDetector.swift`
   - Adjust HSV tolerance in `ColorMaskGenerator`
   - Modify circularity threshold in `filterCircularContours()`

2. **Add New Metric**:
   - Add property to `Shot` model
   - Create calculator in `Core/Physics/`
   - Update `TrajectoryTracker` to call calculator
   - Add UI in `ShotDetailView`

3. **Change Frame Rate**:
   - Modify `CameraSessionManager.configureSession()`
   - Update buffer sizes accordingly
   - Adjust timing calculations in physics

### Adding Error Handling

1. **Define Error Type**
```swift
// Utilities/Errors.swift
enum NewFeatureError: LocalizedError {
    case specificError(details: String)

    var errorDescription: String? {
        switch self {
        case .specificError(let details):
            return "Error occurred: \(details)"
        }
    }
}
```

2. **Handle in View**
```swift
struct SomeView: View {
    @State private var error: Error?
    @State private var showError = false

    var body: some View {
        VStack { }
            .alert("Error", isPresented: $showError, presenting: error) { _ in
                Button("OK") { }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}
```

---

## 8. TESTING ON DEVICE

### iPad Device Deployment
```bash
# Get device UDID
xcrun xctrace list devices

# Example output:
# Myers's iPad Pro (00008112-000XXXXXXXXXXXXX)
```

### Simulator Options
```bash
# List simulators
xcrun simctl list devices

# Recommended simulators:
# - iPad Pro (12.9-inch) - Primary target
# - iPad (10th generation) - Standard iPad
# - iPhone 15 Pro - Phone testing
```

### Camera Testing Notes

1. **Simulator Limitations**:
   - No real camera access
   - Use mock video frames for testing CV pipeline
   - Create `MockCameraManager` that plays pre-recorded bowling videos

2. **Device Testing Requirements**:
   - Physical iPad/iPhone required for camera
   - 120fps only available on recent devices (A12+ chip)
   - Test in actual bowling alley lighting conditions

3. **Test Video Setup**:
   - Record test videos at bowling alley
   - Include various ball colors (blue, red, purple, orange)
   - Capture different lighting conditions
   - Include gutter balls and strikes for edge cases

### Performance Testing
```swift
// Add to FrameProcessor for benchmarking
func processFrame(_ buffer: CVPixelBuffer) {
    let start = CACurrentMediaTime()

    // Processing code...

    let elapsed = CACurrentMediaTime() - start
    if elapsed > 0.0083 { // 8.33ms = 120fps budget
        print("Frame exceeded budget: \(elapsed * 1000)ms")
    }
}
```

---

## 9. KEY IMPLEMENTATION NOTES

### Camera Configuration for 120fps
```swift
// Must find format supporting 120fps at 1080p
for format in device.formats {
    for range in format.videoSupportedFrameRateRanges {
        if range.maxFrameRate >= 120.0 {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if dimensions.height == 1080 {
                // Use this format
            }
        }
    }
}

// Set frame duration
device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 120)
device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 120)
```

### HSV Color Masking
```swift
// Ball color detection uses HSV because:
// - Hue is invariant to lighting changes
// - Saturation filters out white/gray objects
// - Value threshold handles shadows

// Typical ball color tolerances:
// Hue: +/- 15 degrees
// Saturation: +/- 0.2
// Value: +/- 0.3
```

### Calibration Math
```swift
// Convert pixel to board number:
// 1. Get normalized X position (0-1) across lane width
// 2. Apply perspective correction
// 3. Map to boards 1-39

func pixelToBoard(_ pixelX: Double) -> Double {
    let normalizedX = (pixelX - leftGutterX) / (rightGutterX - leftGutterX)
    return normalizedX * 39.0 + 1.0
}

// Convert pixel to distance:
// Use arrow position (known to be 15ft from foul line) as reference
```

### SwiftData Container Setup
```swift
@main
struct BowlerTraxApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            SessionEntity.self,
            ShotEntity.self,
            BallProfileEntity.self,
            CalibrationEntity.self,
            CenterEntity.self
        ])

        let config = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

---

## 10. COMMON PITFALLS TO AVOID

1. **Camera Frame Dropping**: Always use `alwaysDiscardsLateVideoFrames = true` to prevent buffer buildup

2. **Memory Pressure**: Release CVPixelBuffer references immediately after processing

3. **Main Thread Blocking**: All CV processing must happen on background queue

4. **Calibration Validation**: Always validate perspective transform produces reasonable values

5. **Rev Rate at 30fps**: At 30fps, 400 RPM ball moves 80 degrees/frame - too fast to track reliably. Must use 120fps.

6. **Color Similarity**: Ball colors similar to lane color (tan/brown) will fail. Encourage users to use colored balls.

7. **Lighting Variance**: HSV hue is stable but value changes drastically. Normalize brightness before color matching.

8. **iPad Orientation**: Lock to landscape for consistent camera view and UI layout.

---

## 11. CHECKLIST FOR IMPLEMENTATION

### Phase 1: Foundation
- [ ] Create Xcode project with SwiftUI lifecycle
- [ ] Set up folder structure per Section 2
- [ ] Implement Design System (Colors, Typography, Spacing)
- [ ] Create base components (MetricCard, ActionButton, etc.)
- [ ] Set up SwiftData container and entities

### Phase 2: Camera & CV
- [ ] Implement CameraSessionManager (120fps)
- [ ] Create BallDetector with HSV masking
- [ ] Build TrajectoryTracker
- [ ] Add physics calculators (speed, angle)
- [ ] Implement frame processing pipeline

### Phase 3: Calibration
- [ ] Build CalibrationWizard UI
- [ ] Implement arrow detection/tap handling
- [ ] Create perspective transform calculator
- [ ] Add calibration persistence

### Phase 4: Recording Flow
- [ ] Create RecordingView with camera preview
- [ ] Add real-time metrics overlay
- [ ] Implement shot detection (start/end)
- [ ] Build session management

### Phase 5: History & Analytics
- [ ] SessionListView with filtering
- [ ] SessionDetailView with stats
- [ ] ShotDetailView with trajectory replay
- [ ] Export functionality

### Phase 6: Polish
- [ ] Onboarding flow
- [ ] Error handling throughout
- [ ] Animations and transitions
- [ ] Performance optimization
- [ ] iPad-specific layouts

---

*This document should enable one-shot development of BowlerTrax. When in doubt, reference the spec files listed in Section 6.*
