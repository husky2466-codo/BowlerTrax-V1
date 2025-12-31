# BowlerTrax Development Progress

**Last Updated:** December 31, 2024

## Project Overview

BowlerTrax is a personal bowling analytics app inspired by LaneTrax and Kegel Specto. It uses computer vision to track bowling shots and provides real-time analytics.

## Completed Work

### Phase 0: Research & Planning

#### Video Analysis
Analyzed 3 YouTube review videos of LaneTrax app:
- **811 frames** extracted for UI/UX analysis
- **500 transcript segments** transcribed with Whisper
- Created comprehensive analysis document

**Key Findings from LaneTrax:**
- Auto-detects lane without manual calibration
- Auto-records shots (no manual trigger needed)
- Rev rate accuracy is "consistent but not absolute"
- Board tracking can be off by ~2 boards
- $10/month subscription model
- Uses teal/cyan color scheme with dark background

**Output Files:**
- `Analysis/LaneTrax-App-Analysis.md` - Complete feature analysis
- `Analysis/frames/` - 811 extracted video frames
- `Analysis/transcripts/` - Audio transcripts (txt + json)

#### Planning
- Created comprehensive implementation plan
- Incorporated USBC lane dimensions and bowling physics
- Defined 10-step implementation approach

**Output Files:**
- `BowlerTrax-Plan.md` - Full development plan
- `Bowling-Info-Ref.md` - Domain knowledge reference

---

### Phase 1: Foundation (COMPLETE)

#### 1. Project Setup
- Created Expo project with TypeScript (SDK 54)
- Configured for iOS-first development
- Set up file-based routing with Expo Router

#### 2. Dependencies Installed
```json
{
  "expo": "~54.0.30",
  "expo-camera": "~17.0.10",
  "expo-av": "~16.0.8",
  "expo-media-library": "~18.2.1",
  "expo-file-system": "~19.0.21",
  "expo-sqlite": "~16.0.10",
  "expo-secure-store": "~15.0.8",
  "expo-router": "~6.0.21",
  "react-native-reanimated": "~4.1.1",
  "@shopify/react-native-skia": "2.2.12",
  "expo-linear-gradient": "~15.0.8",
  "zustand": "^5.0.9",
  "nativewind": "^4.2.1"
}
```

#### 3. App Structure Created

```
mobile/
├── app/                          # Expo Router screens
│   ├── _layout.tsx               # Root layout with Stack navigator
│   ├── (tabs)/
│   │   ├── _layout.tsx           # Tab navigation (4 tabs)
│   │   ├── index.tsx             # Dashboard - stats overview
│   │   ├── record.tsx            # Camera recording screen
│   │   ├── sessions.tsx          # Past sessions list
│   │   └── settings.tsx          # User preferences
│   ├── calibrate.tsx             # Lane calibration wizard
│   ├── session/[id].tsx          # Session detail view
│   └── shot/[id].tsx             # Individual shot analysis
├── lib/
│   └── constants/
│       └── laneDimensions.ts     # USBC specs + physics formulas
├── stores/
│   ├── sessionStore.ts           # Active session state
│   ├── settingsStore.ts          # User preferences
│   ├── calibrationStore.ts       # Lane calibrations
│   └── index.ts                  # Re-exports
├── types/
│   ├── bowling.ts                # Core bowling types
│   ├── tracking.ts               # Ball detection types
│   ├── calibration.ts            # Calibration types
│   └── index.ts                  # Re-exports
├── app.json                      # Expo config + permissions
├── tailwind.config.js            # NativeWind theme
├── tsconfig.json                 # TypeScript config
├── CLAUDE.md                     # Project documentation
└── package.json
```

#### 4. Type Definitions Created

**bowling.ts:**
- `Session` - Practice/league session
- `Shot` - Individual shot with all metrics
- `Center` - Bowling center info
- `BallProfile` - Color tracking profile
- `HSVColor` / `RGBColor` - Color types
- `SessionStats` - Aggregated statistics
- `UserSettings` - App preferences

**tracking.ts:**
- `TrajectoryPoint` - Position + timestamp
- `BallPhase` - skid/hook/roll
- `BallDetection` - Frame detection result
- `CameraFrame` - Raw frame data
- `TrackingState` - Real-time tracking state
- `ColorMaskParams` - HSV filtering params
- `RevTrackingState` - Revolution counting

**calibration.ts:**
- `CalibrationStep` - Wizard steps
- `CalibrationWizardState` - Wizard state
- `ArrowPoint` - Calibration reference point
- `LaneDimensions` - USBC constants
- `CalibrationProfile` - Saved calibration

#### 5. Lane Dimensions & Physics

**laneDimensions.ts includes:**
- USBC standard lane measurements
- Arrow positions (boards 5, 10, 15, 20, 25, 30, 35)
- Pin positions for pocket calculation
- Optimal strike parameters (6° entry angle)
- Rev rate categories (stroker/tweener/cranker)
- Speed/rev ratio classifications
- Ball phase distances (skid/hook/roll)

**Helper Functions:**
- `boardToInches()` / `inchesToBoard()`
- `classifyRevRate(rpm)` → category
- `calculateStrikeProbability(angle, offset)` → 0-1
- `predictLeave(angle, offset, isRightHanded)` → predicted pins

#### 6. State Management (Zustand)

**sessionStore.ts:**
- `currentSession` - Active session
- `currentShots` - Shots in session
- `isRecording` - Recording state
- `startSession()`, `endSession()`, `addShot()`
- `getSessionStats()` - Calculate averages

**settingsStore.ts:**
- Hand preference (left/right)
- Default oil pattern
- Auto-save videos toggle
- Show previous shot toggle
- Haptic feedback toggle

**calibrationStore.ts:**
- Saved calibration profiles
- Active calibration
- Wizard state management
- Calibration calculation logic

#### 7. UI Screens Created

**Dashboard (index.tsx):**
- Quick action buttons (New Session, Calibrate)
- Stats overview cards (speed, rev rate, angle, strike %)
- Recent sessions list (empty state)

**Record (record.tsx):**
- Camera view with permission handling
- Lane guide overlays (foul line, arrows)
- Recording indicator and shot counter
- Real-time metrics display (placeholder)
- Calibration warning banner

**Sessions (sessions.tsx):**
- Session list with thumbnails
- Filter/sort capabilities (structure ready)
- Empty state with call-to-action

**Settings (settings.tsx):**
- Dominant hand toggle
- Lane calibration link
- Recording settings (auto-save, previous shot, haptics)
- Ball profiles section (placeholder)
- Data management (export, clear)
- About section

**Calibrate (calibrate.tsx):**
- Step progress indicator
- Camera view with tap-to-mark
- Foul line and arrow marking
- Verification step
- Save functionality (structure ready)

**Session Detail (session/[id].tsx):**
- Session header with metadata
- Stats summary row
- Shot list with metrics

**Shot Detail (shot/[id].tsx):**
- Shot result badge
- Trajectory visualization placeholder
- Strike probability display
- Speed & rev rate cards
- Board position details

#### 8. Configuration Files

**app.json:**
- Camera permissions configured
- Media library permissions
- iOS and Android settings
- Dark theme (backgroundColor: #1a1a1a)

**tailwind.config.js:**
- Primary colors (teal/cyan theme)
- Surface colors (dark grays)
- NativeWind preset

**tsconfig.json:**
- Path aliases (@/components, @/lib, etc.)
- Strict mode enabled

---

## Current Status

### What Works
- App scaffolding complete
- Tab navigation functional
- Camera permission flow
- Basic UI for all screens
- Type safety throughout
- State management ready

### What's Placeholder
- Ball detection (not implemented)
- Actual tracking (not implemented)
- SQLite database (not connected)
- Video recording (camera view only)
- Trajectory visualization (placeholder)
- Rev rate calculation (placeholder)

---

## Next Steps (Phase 2: Camera & Tracking)

### Immediate Tasks
1. **Color-based ball detection**
   - Create `lib/cv/hsvUtils.ts` - RGB↔HSV conversion
   - Create `lib/cv/colorTracker.ts` - Ball detection algorithm
   - Implement tap-to-select color picker

2. **Camera frame processing**
   - Access 120fps mode on iOS
   - Process frames for ball position
   - Track ball across frames

3. **Trajectory building**
   - Store position + timestamp
   - Calculate velocity/acceleration
   - Detect phase transitions

### Future Phases

**Phase 3: Lane Calibration**
- Implement pixel↔real-world conversion
- Use arrows as reference points
- Store calibration profiles

**Phase 4: Core Metrics**
- Speed calculation (distance/time)
- Entry angle calculation (arctan)
- Arrow crossing detection
- Breakpoint detection

**Phase 5: Rev Rate**
- PAP marker tracking
- Rotation counting
- RPM calculation

**Phase 6: Strike Analysis**
- Probability calculation
- Leave prediction
- Adjustment suggestions

**Phase 7: Database**
- SQLite schema implementation
- CRUD operations
- Data persistence

**Phase 8: Visualization**
- Skia trajectory overlay
- Video replay with graphics
- Charts and trends

---

## File Inventory

### Source Files Created
| File | Purpose | Lines |
|------|---------|-------|
| `app/_layout.tsx` | Root layout | ~45 |
| `app/(tabs)/_layout.tsx` | Tab navigation | ~55 |
| `app/(tabs)/index.tsx` | Dashboard | ~100 |
| `app/(tabs)/record.tsx` | Camera recording | ~230 |
| `app/(tabs)/sessions.tsx` | Sessions list | ~95 |
| `app/(tabs)/settings.tsx` | Settings | ~180 |
| `app/calibrate.tsx` | Calibration wizard | ~200 |
| `app/session/[id].tsx` | Session detail | ~130 |
| `app/shot/[id].tsx` | Shot analysis | ~180 |
| `lib/constants/laneDimensions.ts` | Lane specs | ~180 |
| `stores/sessionStore.ts` | Session state | ~95 |
| `stores/settingsStore.ts` | Settings state | ~40 |
| `stores/calibrationStore.ts` | Calibration state | ~115 |
| `types/bowling.ts` | Bowling types | ~115 |
| `types/tracking.ts` | Tracking types | ~85 |
| `types/calibration.ts` | Calibration types | ~80 |

### Configuration Files
| File | Purpose |
|------|---------|
| `app.json` | Expo configuration |
| `package.json` | Dependencies |
| `tsconfig.json` | TypeScript config |
| `tailwind.config.js` | NativeWind theme |
| `global.css` | Tailwind imports |
| `nativewind-env.d.ts` | NativeWind types |
| `CLAUDE.md` | Project documentation |

---

## Commands

```bash
# Navigate to project
cd D:\Projects\BowlerTrax\mobile

# Start development server
npm start

# Run on iOS simulator (macOS only)
npm run ios

# Run on Android emulator
npm run android

# Type check
npx tsc --noEmit

# Install new Expo package
npx expo install <package-name>
```

---

## Notes

- Using Expo SDK 54 (latest stable)
- React 19.1.0 with New Architecture enabled
- iOS-first development (120fps camera support)
- Color-based tracking MVP (ML upgrade later)
- Local-first data storage with SQLite
