# BowlerTrax - Personal Bowling Analytics App

## Overview
An iOS-first React Native mobile app using color-based computer vision to track bowling shots and provide physics-based analytics including ball speed, trajectory, entry angle, rev rate, and strike probability.

**Target**: iOS (iPhone) for MVP, Android later
**Detection**: Color-based ball tracking (upgrade to ML later)
**Camera**: 120fps or 240fps for accurate rev rate calculation

## Domain Knowledge (from Bowling-Info-Ref.md)

### Critical Lane Dimensions
- **Lane Length**: 60 feet (foul line to head pin)
- **Lane Width**: 41.5 inches (39 boards + gutters)
- **Arrows**: Located 15 feet from foul line, 3 inches apart
- **Dots**: Located 12 feet and 15 feet from foul line
- **Pin Deck**: 2 feet 10-3/16 inches for pin triangle
- **Board Width**: ~1.06 inches each (39 boards total)

### Key Metrics & Formulas

**Rev Rate (RPM)**:
```
RPM = (Total Revolutions / Time in Seconds) × 60
```
- Categories: Stroker (250-350), Tweener (300-400), Cranker (400+)
- Requires tracking PAP (Positive Axis Point) marker on ball
- Need 120fps+ to count rotations accurately

**Ball Speed**:
```
Speed (mph) = (Distance in feet / Time in seconds) × 0.6818
```
- Typical range: 14-20 mph at pins

**Entry Angle** (optimal: 6°):
```
θ = arctan(Lateral Movement / Distance Traveled)
```
- Less than 4°: leaves corner pins
- More than 7°: causes splits
- Target: 17.5 board (pocket for righties)

**Strike Probability Factors**:
- Pocket offset (17.5 board ideal)
- Entry angle (6° optimal)
- Ball speed at impact
- Rev rate (higher = more pin action)

## Technology Stack

### Mobile Framework
- **React Native** with Expo SDK 52+ (managed workflow)
- **TypeScript** for type safety
- **Expo Router** for navigation

### Computer Vision (Color-Based MVP)
- **expo-camera** for 60fps video capture
- **expo-gl** + custom shaders for real-time color filtering
- **react-native-vision-camera** (alternative if expo-camera insufficient)
- HSV color space filtering for ball isolation

### Data & State
- **expo-sqlite** for local session/shot storage
- **Zustand** for state management
- **expo-secure-store** for settings

### UI
- **React Native Reanimated 3** for smooth animations
- **React Native Skia** for trajectory visualization overlays
- **NativeWind v4** (Tailwind for RN) for styling

## Core Features

### Phase 1: Foundation
1. Camera setup with positioning guide (behind bowler, elevated, capturing full lane)
2. 120fps video capture (iPhone 11+ supports this in slo-mo mode)
3. Color-based ball detection with tap-to-select
4. Session management (bowler name, center, lane number, oil pattern type)

### Phase 2: Lane Calibration
1. One-time calibration per bowling center/camera position
2. Use arrows (15ft from foul line) as reference points
3. Calculate pixels-per-board and pixels-per-foot ratios
4. Store calibration profiles per center

### Phase 3: Ball Tracking & Trajectory
1. Frame-by-frame ball centroid tracking
2. Trajectory path construction with timestamps
3. Skid-Hook-Roll phase detection (based on velocity changes)
4. Path visualization overlay with Skia

### Phase 4: Core Metrics
1. **Ball Speed**: Distance/time using calibrated lane (target: 14-20 mph)
2. **Arrow Crossing**: Which arrow (board) the ball crosses at 15ft
3. **Breakpoint**: Board number where ball starts hooking
4. **Entry Angle**: Angle into pocket (optimal: 6°, warn if <4° or >7°)
5. **Pocket Offset**: Distance from ideal 17.5 board at pins

### Phase 5: Rev Rate Calculation
1. User marks ball with tape/sticker on PAP (Positive Axis Point)
2. Track marker rotation through frames (120fps = 120 samples/sec)
3. Count full rotations from release to pins
4. Calculate: RPM = (Rotations / Time) × 60
5. Classify: Stroker, Tweener, or Cranker

### Phase 6: Strike Analysis
1. Calculate strike probability based on entry angle + pocket offset
2. Predict likely leave (corner pins if angle too low, splits if too high)
3. Suggest adjustments (move target, adjust speed)

## App Structure

```
BowlerTrax/
├── app/                          # Expo Router screens
│   ├── (tabs)/
│   │   ├── index.tsx             # Dashboard (recent sessions, trends)
│   │   ├── record.tsx            # Live recording screen
│   │   ├── sessions.tsx          # Past sessions list
│   │   └── settings.tsx          # App settings, hand preference
│   ├── session/[id].tsx          # Session detail with all shots
│   ├── shot/[id].tsx             # Individual shot analysis
│   ├── calibrate.tsx             # Lane calibration wizard
│   └── center/[id].tsx           # Center profile (saved calibrations)
├── components/
│   ├── Camera/
│   │   ├── BowlingCamera.tsx     # 120fps camera component
│   │   ├── PositionGuide.tsx     # Camera positioning overlay
│   │   └── ColorPicker.tsx       # Tap-to-select ball color
│   ├── Tracking/
│   │   ├── TrajectoryOverlay.tsx # Skia path visualization
│   │   ├── MetricsDisplay.tsx    # Real-time metrics HUD
│   │   └── RevMarkerTracker.tsx  # PAP marker rotation tracking
│   ├── Analysis/
│   │   ├── StrikeAnalysis.tsx    # Entry angle & pocket analysis
│   │   ├── SpeedGauge.tsx        # Ball speed visualization
│   │   └── RevRateDisplay.tsx    # RPM with category badge
│   └── Charts/
│       ├── TrajectoryChart.tsx   # Shot path visualization
│       ├── TrendChart.tsx        # Historical trends
│       └── BoardChart.tsx        # Arrow/breakpoint visualization
├── lib/
│   ├── cv/                       # Computer Vision
│   │   ├── colorTracker.ts       # HSV color-based ball detection
│   │   ├── hsvUtils.ts           # RGB↔HSV conversion
│   │   ├── contourDetection.ts   # Find ball contours
│   │   └── markerTracker.ts      # PAP marker rotation detection
│   ├── physics/                  # Bowling Physics Calculations
│   │   ├── speedCalculator.ts    # Distance/time → mph
│   │   ├── entryAngle.ts         # arctan(lateral/distance) → degrees
│   │   ├── revRate.ts            # Rotations/time → RPM
│   │   ├── breakpoint.ts         # Detect hook initiation board
│   │   └── strikeProb.ts         # Strike probability algorithm
│   ├── calibration/
│   │   ├── laneCalibration.ts    # Pixels ↔ feet/boards conversion
│   │   └── arrowDetection.ts     # Auto-detect arrows for calibration
│   ├── constants/
│   │   └── laneDimensions.ts     # 60ft, 39 boards, arrow positions
│   └── database/
│       ├── schema.ts             # SQLite schema
│       ├── queries.ts            # CRUD operations
│       └── migrations.ts         # Schema migrations
├── hooks/
│   ├── useCamera.ts              # Camera controls, 120fps
│   ├── useBallTracking.ts        # Real-time ball position
│   ├── useRevTracking.ts         # Marker rotation tracking
│   ├── useSession.ts             # Current session state
│   └── useCalibration.ts         # Lane calibration state
├── stores/
│   ├── sessionStore.ts           # Active session
│   ├── settingsStore.ts          # User preferences
│   └── calibrationStore.ts       # Saved calibrations
└── types/
    ├── bowling.ts                # Shot, Session, Metrics types
    ├── calibration.ts            # Calibration types
    └── tracking.ts               # TrackingPoint, Trajectory types
```

## Lane Calibration Approach

### Known Reference Points (USBC Standard)
All bowling lanes share these exact dimensions:
- **Foul Line to Arrows**: 15 feet
- **Foul Line to Head Pin**: 60 feet
- **Lane Width**: 41.5 inches (39 boards × 1.0641" each)
- **Arrow Spacing**: 5 boards apart (arrows on boards 5, 10, 15, 20, 25, 30, 35)
- **Gutter Width**: ~1.25 inches each side

### Calibration Wizard Steps
1. **Position Camera**: Guide user to place phone behind bowler, elevated 5-6 feet, centered on lane
2. **Identify Arrows**: User taps on 2 arrows in camera view (known to be 15 boards apart)
3. **Identify Foul Line**: User marks foul line (0 feet reference)
4. **Calculate Ratios**:
   ```
   pixelsPerBoard = distance(arrow1, arrow2) / 15
   pixelsPerFoot = distance(foulLine, arrows) / 15
   ```
5. **Store Profile**: Save with center name for reuse

## Ball Detection Strategy (Color-Based MVP)

### How It Works
1. **Color Selection**: User taps on their ball in camera preview to sample the color
2. **HSV Conversion**: Convert RGB to HSV color space (more robust to lighting changes)
3. **Color Masking**: Create binary mask of pixels matching ball color (with tolerance)
4. **Contour Detection**: Find largest circular contour = ball position
5. **Centroid Tracking**: Track ball center across frames

### Color Tracking Algorithm
```typescript
// Pseudocode for ball detection
function detectBall(frame: ImageData, targetHSV: HSVColor): Point | null {
  // 1. Convert frame to HSV
  const hsvFrame = rgbToHsv(frame);

  // 2. Create mask for target color (with tolerance)
  const mask = createColorMask(hsvFrame, targetHSV, tolerance: 15);

  // 3. Apply morphological operations (remove noise)
  const cleaned = morphClose(morphOpen(mask));

  // 4. Find contours and filter by circularity
  const contours = findContours(cleaned);
  const circles = contours.filter(c => circularity(c) > 0.7);

  // 5. Return center of largest circle
  return circles.length > 0 ? centroid(largest(circles)) : null;
}
```

### Handling Challenges
- **Similar colors in background**: Use motion detection to filter static objects
- **Ball partially hidden**: Interpolate position during occlusion
- **Lighting changes**: Auto-adjust HSV tolerance based on detection confidence

## Implementation Order

### Step 1: Project Setup
- Create Expo project with TypeScript
- Configure NativeWind, Zustand, Expo Router
- Set up folder structure and types
- Create tab navigation (Dashboard, Record, Sessions, Settings)
- Add `lib/constants/laneDimensions.ts` with USBC standards

### Step 2: Camera Integration (120fps)
- Implement camera view with 120fps slo-mo capture
- Add camera positioning guide overlay (show where to place tripod)
- Test frame extraction at high fps
- Build `useCamera` hook with recording controls

### Step 3: Color Picker & Ball Detection
- Build color sampling UI (tap on ball to select color)
- Implement `lib/cv/hsvUtils.ts` for RGB↔HSV conversion
- Implement `lib/cv/colorTracker.ts` for ball detection
- Add real-time ball position indicator on camera view
- Create ball profile saving (for different balls)

### Step 4: Lane Calibration Wizard
- Create `app/calibrate.tsx` wizard screen
- Guide user to tap on arrows and foul line
- Calculate `pixelsPerBoard` and `pixelsPerFoot`
- Implement `lib/calibration/laneCalibration.ts`
- Store calibration profiles per center in SQLite

### Step 5: Trajectory Tracking
- Record ball positions with timestamps across frames
- Build trajectory data structure `{x, y, t, board, feet}[]`
- Implement Skia overlay for path visualization
- Detect Skid-Hook-Roll phases based on velocity changes

### Step 6: Core Metrics
- `lib/physics/speedCalculator.ts`: Distance/time → mph
- `lib/physics/entryAngle.ts`: arctan calculation → degrees
- `lib/physics/breakpoint.ts`: Detect hook initiation board
- Arrow crossing: Which board at 15ft mark
- Pocket offset: Distance from ideal 17.5 board

### Step 7: Rev Rate Tracking
- User marks ball with tape on PAP
- `lib/cv/markerTracker.ts`: Track marker color separately
- Count full rotations from release to impact
- `lib/physics/revRate.ts`: RPM = (rotations / time) × 60
- Classify: Stroker, Tweener, Cranker

### Step 8: Strike Analysis
- `lib/physics/strikeProb.ts`: Calculate probability
- Predict likely leave based on entry angle + pocket offset
- Show suggestions (move target, adjust speed)
- Display results with visual feedback

### Step 9: Session Management
- SQLite database setup with full schema
- Save/load sessions, shots, centers, calibrations
- Session list view with summary stats
- Individual shot detail view with video playback

### Step 10: Polish & Testing
- Historical trend charts (speed, rev rate over time)
- Export session data (JSON/CSV)
- Real-world testing at bowling alley
- Performance optimization for real-time tracking

## Key Technical Challenges

1. **Frame Rate**: Need 120fps for accurate rev rate (ball travels ~25mph, rotates 300-500 RPM)
   - Solution: Use iPhone slo-mo mode (120fps on iPhone 11+, 240fps on Pro models)

2. **Lighting**: Bowling alleys have variable lighting, colored lane lights
   - Solution: HSV color space is more robust than RGB; auto-adjust tolerance

3. **Occlusion**: Ball hidden by bowler during release
   - Solution: Start tracking after ball crosses foul line; interpolate gaps

4. **Perspective Distortion**: Camera angle causes foreshortening down lane
   - Solution: Calibration maps pixel positions to real-world coordinates

5. **Rev Rate Accuracy**: Counting rotations at high speed is challenging
   - Solution: High-contrast tape marker on PAP; 120fps gives 120 samples/sec

6. **Real-time Processing**: Must process frames fast enough to display live
   - Solution: Process subset of frames for live preview; full analysis post-shot

## Getting Started Commands

```bash
# Create new Expo project with latest SDK
npx create-expo-app@latest BowlerTrax -t expo-template-blank-typescript

cd BowlerTrax

# Install camera and media
npx expo install expo-camera expo-av expo-media-library expo-file-system

# Install database
npx expo install expo-sqlite expo-secure-store

# Install UI/animation libraries
npx expo install react-native-reanimated
npx expo install @shopify/react-native-skia
npx expo install expo-linear-gradient

# Install Expo Router for navigation
npx expo install expo-router expo-linking expo-constants

# Install state management
npm install zustand

# Install NativeWind (Tailwind CSS)
npm install nativewind tailwindcss
npx tailwindcss init

# Install dev dependencies
npm install -D @types/react

# Create iOS build (when ready to test on device)
npx expo prebuild --platform ios
```

## Initial Files to Create

After project setup, these are the first files we'll create:

1. `app/_layout.tsx` - Root layout with tab navigation
2. `app/(tabs)/index.tsx` - Dashboard home screen
3. `app/(tabs)/record.tsx` - Camera recording screen
4. `app/(tabs)/sessions.tsx` - Past sessions list
5. `app/(tabs)/settings.tsx` - App settings
6. `lib/cv/colorTracker.ts` - Color-based ball detection
7. `lib/cv/hsvUtils.ts` - HSV color space utilities
8. `stores/sessionStore.ts` - Zustand store for session state
9. `components/Camera/BowlingCamera.tsx` - Main camera component
10. `tailwind.config.js` - NativeWind configuration

## Database Schema

```sql
CREATE TABLE centers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE calibrations (
  id TEXT PRIMARY KEY,
  center_id TEXT NOT NULL,
  lane_number INTEGER,
  pixels_per_foot REAL NOT NULL,
  pixels_per_board REAL NOT NULL,
  foul_line_y INTEGER,           -- Y pixel of foul line
  arrows_y INTEGER,              -- Y pixel of arrows
  camera_height_ft REAL,
  reference_points_json TEXT,    -- JSON of calibration tap points
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (center_id) REFERENCES centers(id)
);

CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  center_id TEXT,
  lane_number INTEGER,
  oil_pattern TEXT,              -- 'house', 'sport', 'short', 'long'
  hand TEXT DEFAULT 'right',     -- 'left' or 'right'
  date TEXT NOT NULL,
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (center_id) REFERENCES centers(id)
);

CREATE TABLE shots (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  shot_number INTEGER NOT NULL,
  frame_number INTEGER,
  is_first_ball INTEGER DEFAULT 1,

  -- Metrics
  speed_mph REAL,
  rev_rate_rpm REAL,
  rev_category TEXT,             -- 'stroker', 'tweener', 'cranker'
  entry_angle_deg REAL,
  pocket_offset_boards REAL,     -- Distance from ideal 17.5 board
  arrow_board REAL,              -- Board crossed at arrows
  breakpoint_board REAL,
  breakpoint_distance_ft REAL,

  -- Strike Analysis
  strike_probability REAL,
  predicted_leave TEXT,          -- '10-pin', 'split', 'clean', etc.
  actual_result TEXT,            -- 'strike', 'spare', 'open', pins left

  -- Raw Data
  trajectory_json TEXT,          -- [{x, y, t, board, feet}, ...]
  video_uri TEXT,
  thumbnail_uri TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);

CREATE TABLE ball_profiles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color_hsv_json TEXT,           -- {h, s, v, tolerance}
  marker_color_hsv_json TEXT,    -- PAP marker color for rev tracking
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```
