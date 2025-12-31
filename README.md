# BowlerTrax

A personal bowling analytics app that uses computer vision to track bowling shots and provide real-time metrics including ball speed, trajectory, entry angle, rev rate, and strike probability.

## Features

- **Ball Tracking**: Color-based computer vision to track ball position down the lane
- **Speed Calculation**: Measure ball speed from release to pins (14-20 mph typical)
- **Rev Rate Analysis**: Track ball rotation using PAP marker (supports 120fps capture)
- **Entry Angle**: Calculate angle into pocket (optimal: 6°)
- **Strike Probability**: Predict strike likelihood based on entry angle and pocket offset
- **Session Management**: Track sessions by bowling center, lane, and oil pattern
- **Trend Analysis**: View historical performance trends

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
BowlerTrax/
├── mobile/                 # React Native Expo app
│   ├── app/                # Expo Router screens
│   │   ├── (tabs)/         # Tab navigation
│   │   │   ├── index.tsx   # Dashboard
│   │   │   ├── record.tsx  # Camera recording
│   │   │   ├── sessions.tsx# Past sessions
│   │   │   └── settings.tsx# App settings
│   │   ├── calibrate.tsx   # Lane calibration wizard
│   │   ├── session/[id].tsx# Session detail
│   │   └── shot/[id].tsx   # Shot analysis
│   ├── lib/                # Core logic
│   │   ├── constants/      # Lane dimensions
│   │   ├── cv/             # Computer vision
│   │   └── physics/        # Bowling calculations
│   ├── stores/             # Zustand state
│   └── types/              # TypeScript types
├── Analysis/               # Competitor analysis
└── docs/                   # Documentation & design
```

## Getting Started

### Prerequisites

- Node.js 18+
- iOS device or simulator (iPhone 11+ recommended for 120fps)
- Expo Go app (for development)

### Installation

```bash
# Clone the repository
git clone https://github.com/husky2466-codo/BowlerTrax-V1.git
cd BowlerTrax-V1/mobile

# Install dependencies
npm install

# Start development server
npm start

# Run on iOS
npm run ios

# Run on Android
npm run android
```

## How It Works

### Lane Calibration

The app uses USBC standard lane dimensions for calibration:
- Lane length: 60 feet (foul line to head pin)
- Lane width: 41.5 inches (39 boards)
- Arrows: 15 feet from foul line, 5 boards apart

Users calibrate by tapping on arrows and the foul line to establish pixel-to-real-world mapping.

### Ball Detection

Color-based tracking using HSV color space:
1. User taps on their ball to sample the color
2. App creates a color mask with tolerance
3. Finds circular contours matching the ball
4. Tracks ball centroid across video frames

### Rev Rate Tracking

For accurate rev rate measurement:
1. User marks ball with tape on PAP (Positive Axis Point)
2. App tracks marker rotation at 120fps
3. Counts full rotations from release to impact
4. Calculates RPM: (Rotations / Time) × 60

**Rev Rate Categories**:
- Stroker: 250-350 RPM
- Tweener: 300-400 RPM
- Cranker: 400+ RPM

### Strike Analysis

Strike probability is calculated based on:
- **Entry Angle**: Optimal 6° (< 4° = corner pins, > 7° = splits)
- **Pocket Offset**: Distance from ideal board 17.5 (right-handed)
- **Ball Speed**: Consistency matters for pin action
- **Rev Rate**: Higher = more pin carry potential

## Key Metrics

| Metric | Description | Optimal Range |
|--------|-------------|---------------|
| Ball Speed | Speed at pins | 14-20 mph |
| Rev Rate | Ball rotation | 300-400 RPM |
| Entry Angle | Angle into pocket | 4-7° (6° ideal) |
| Arrow Board | Board crossed at arrows | Target specific |
| Breakpoint | Where ball starts hooking | Lane dependent |

## Development Status

### Completed
- Project setup with Expo 54
- Tab navigation structure
- Type definitions
- Lane dimensions constants
- Zustand stores
- Basic camera integration
- Calibration wizard UI

### In Progress
- 120fps video capture
- Color-based ball detection
- Real-time tracking

### Planned
- Lane calibration calculations
- Trajectory visualization with Skia
- Physics calculations
- SQLite database
- Strike predictions
- Video replay with overlay

## Documentation

- `BowlerTrax-Plan.md` - Full implementation plan
- `Bowling-Info-Ref.md` - Bowling domain knowledge
- `Analysis/` - Competitor analysis (LaneTrax, Specto)

## License

MIT

## Acknowledgments

Inspired by:
- [LaneTrax](https://lanetrax.app) - Bowling analytics app
- [Kegel Specto](https://www.kfrspecto.com) - Professional lane tracking system
