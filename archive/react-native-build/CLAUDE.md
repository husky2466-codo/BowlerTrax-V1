# CLAUDE.md - BowlerTrax Mobile App

This file provides guidance to Claude Code when working on the BowlerTrax project.

## Overview

BowlerTrax is a personal bowling analytics app inspired by LaneTrax and Kegel Specto. It uses computer vision to track bowling shots and provides real-time analytics including ball speed, trajectory, entry angle, rev rate, and strike probability.

## Tech Stack

- **Framework**: React Native with Expo SDK 54
- **Language**: TypeScript
- **Navigation**: Expo Router (file-based routing)
- **State Management**: Zustand
- **Styling**: NativeWind (Tailwind CSS for React Native)
- **Database**: expo-sqlite (local storage)
- **Camera**: expo-camera (120fps for rev rate tracking)
- **Graphics**: React Native Skia (trajectory visualization)

## Project Structure

```
mobile/
├── app/                    # Expo Router screens
│   ├── (tabs)/             # Tab navigation screens
│   │   ├── index.tsx       # Dashboard home
│   │   ├── record.tsx      # Camera recording
│   │   ├── sessions.tsx    # Past sessions list
│   │   └── settings.tsx    # App settings
│   ├── calibrate.tsx       # Lane calibration wizard
│   ├── session/[id].tsx    # Session detail
│   └── shot/[id].tsx       # Shot analysis
├── components/             # Reusable UI components
├── lib/                    # Core logic
│   ├── constants/          # Lane dimensions, etc.
│   ├── cv/                 # Computer vision (ball detection)
│   ├── physics/            # Bowling physics calculations
│   └── database/           # SQLite operations
├── stores/                 # Zustand state stores
├── types/                  # TypeScript type definitions
└── hooks/                  # Custom React hooks
```

## Key Domain Knowledge

### Lane Dimensions (USBC Standard)
- Lane length: 60 feet (foul line to head pin)
- Lane width: 41.5 inches (39 boards)
- Arrows: 15 feet from foul line
- Board width: ~1.0641 inches

### Key Metrics
- **Rev Rate (RPM)**: Ball rotation speed
  - Stroker: 250-350 RPM
  - Tweener: 300-400 RPM
  - Cranker: 400+ RPM
- **Entry Angle**: Optimal is 6° (< 4° = corner pins, > 7° = splits)
- **Pocket**: Board 17.5 for right-handed, 22.5 for left-handed

### Ball Detection Approach
Color-based tracking using HSV color space:
1. User taps ball to sample color
2. Convert RGB to HSV
3. Create color mask with tolerance
4. Find circular contours
5. Track centroid across frames

## Development Commands

```bash
# Start development server
npm start

# Run on iOS simulator
npm run ios

# Run on Android emulator
npm run android

# Run TypeScript checks
npx tsc --noEmit
```

## Key Files Reference

### Constants
- `lib/constants/laneDimensions.ts` - USBC lane specifications, rev rate categories, strike probability calculations

### Types
- `types/bowling.ts` - Session, Shot, Center, Calibration types
- `types/tracking.ts` - TrajectoryPoint, BallDetection types
- `types/calibration.ts` - CalibrationProfile, wizard state types

### Stores
- `stores/sessionStore.ts` - Active session and shots
- `stores/settingsStore.ts` - User preferences
- `stores/calibrationStore.ts` - Lane calibrations

## Implementation Status

### Completed (Phase 1 - Foundation)
- [x] Project setup with Expo 54
- [x] Tab navigation (Dashboard, Record, Sessions, Settings)
- [x] Type definitions for all entities
- [x] Lane dimensions constants
- [x] Zustand stores for state management
- [x] Basic camera integration with permissions
- [x] Calibration wizard UI scaffold
- [x] Session and shot detail screens

### In Progress (Phase 2 - Camera & Tracking)
- [ ] 120fps video capture
- [ ] Color-based ball detection (`lib/cv/colorTracker.ts`)
- [ ] HSV color utilities (`lib/cv/hsvUtils.ts`)
- [ ] Real-time ball position tracking

### Planned (Phase 3+)
- [ ] Lane calibration calculations
- [ ] Trajectory tracking and visualization
- [ ] Physics calculations (speed, angle, rev rate)
- [ ] SQLite database integration
- [ ] Strike analysis and predictions
- [ ] Video replay with overlay

## Notes for Development

1. **Camera Frame Rate**: iPhone 11+ supports 120fps in slow-mo mode. Use this for accurate rev rate calculation.

2. **Ball Detection**: Start with color-based tracking. User taps ball to sample color. HSV is more robust to lighting than RGB.

3. **Calibration**: Use arrows (15ft from foul line) as reference points. They're 5 boards apart.

4. **Rev Rate Tracking**: User marks ball with tape on PAP (Positive Axis Point). Track marker rotation through frames.

5. **Accuracy Priority**: Consistency > absolute accuracy. Relative changes shot-to-shot are most valuable.

## Related Files

- `../BowlerTrax-Plan.md` - Full implementation plan
- `../Bowling-Info-Ref.md` - Bowling domain knowledge reference
- `../Analysis/LaneTrax-App-Analysis.md` - Competitor analysis from video reviews
