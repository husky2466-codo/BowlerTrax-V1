# LaneTrax App Analysis

Based on analysis of 3 YouTube review videos (811 frames, 500 transcript segments)

## What LaneTrax Does

LaneTrax is an AI-powered mobile app (iOS) that acts as a portable Specto system. It uses computer vision to track bowling shots and provides analytics similar to what PBA broadcasters show on TV.

### Core Metrics Tracked
1. **Rev Rate (RPM)** - Ball rotation speed
2. **Launch Speed** - Ball speed off the hand
3. **Impact Speed** - Ball speed at the pins
4. **Entry Board** - Which board the ball hits at the pins
5. **Break Point Board** - Where the ball starts hooking
6. **Break Point Distance** - How far down the lane the ball breaks
7. **Launch Angle** - Angle at release
8. **Impact Angle** - Angle entering the pocket
9. **Arrow Position** - Which board at the arrows (15ft)
10. **Foul Line Position** - Starting position

## App Setup & Usage

### Physical Setup
1. **Tripod**: Phone mounted on tripod, elevated behind the bowler
2. **Position**: Parallel to right gutter (NOT directly behind target)
   - If positioned behind 10 board, bowler will block camera
3. **Zoom**: Fill viewfinder with lane, keep all 4 corners and pins visible
4. **Auto-detect**: App automatically detects the lane when properly positioned

### Recording Flow
1. Tap "Detect Lane" - app confirms lane detection
2. Bowl normally - app auto-records each shot
3. After each shot, view replay and stats
4. Tap X to dismiss replay, or save to photos
5. "Quit and Save" to end session (NOT "Quit and Delete")

### Modes
- **Classic Mode**: Practice sessions, tracks all shots
- **League Mode**: Toggle tracking on/off per shot
  - Tap lane to turn tracking OFF (turns red)
  - Tap again to turn ON before your shot
  - Useful when bowling with teammates

## Key Features

### Video Recording
- Automatically records every shot without manual press
- Replay shows trajectory overlay on lane
- Save individual shots to camera roll
- All sessions stored in cloud (not local storage)

### Historical Data
- Sessions saved with date/location
- Can browse past sessions weeks/months back
- Filter by: All shots, Strikes only, Misses
- Compare current session to past "good" sessions
- Track trends over time

### Analytics Display
Shows PBA-style trajectory overlay with:
- Ball path from foul line to pins
- Board position at arrows
- Break point location
- Entry angle visualization

## Known Limitations & Accuracy

### Rev Rate
- **Not 100% accurate** but **consistent**
- Relative changes are meaningful (higher/lower between shots)
- Using colorful balls helps detection
- Don't trust exact number (e.g., "400 RPM")

### Board Tracking
- Can be off by ~2 boards, typically to the right
- If targeting 15 board, app may read 13
- Developers actively working on fix

### Speed Readings
- Launch speed is more accurate than house sensor
- House sensors measure at pins (after friction slowdown)
- Spare shots appear 1-2 mph faster than strikes at house sensors

## Pricing (as of late 2024)

- **Free Trial**: 20-30 shots free
- **Subscription**: $10/month
- **Holiday Promos**: 100-150 free shots, 50% off first month

## Use Cases Identified

### For Individual Bowlers
1. Determine if hitting intended target (eye dominance issues)
2. Track rev rate and speed consistency
3. Identify why leaving specific pins (10-pin = low revs/speed)
4. Video review for form analysis
5. Compare sessions when in a "funk"

### For Coaches
1. Show students their stats objectively
2. Track consistency/inconsistency patterns
3. Cheaper than traveling to Specto lanes
4. Multiple sessions of data for each player

### Comparison to Kegel Specto
| Feature | Specto | LaneTrax |
|---------|--------|----------|
| Cost | Very expensive (lane + per game) | $10/month |
| Availability | Rare (40+ miles for some) | Any bowling center |
| Hardware | Installed cameras | Just iPhone + tripod |
| Accuracy | Professional-grade | Close, with some variance |
| Video | Yes | Yes (recent update) |
| History | Yes | Yes (cloud stored) |

## Technical Observations

### What's Working Well
1. Auto lane detection
2. Automatic shot recording (no manual trigger)
3. Cloud storage for sessions
4. Video overlay similar to PBA broadcasts
5. League mode toggle for team bowling
6. Session history and browsing

### Areas for Improvement
1. Rev rate precision
2. Board tracking accuracy (2-board offset)
3. Android support (was iOS only in beta)
4. Spare mode (mentioned as "coming soon")

## Key Quotes from Reviewers

> "Specto on the go at a very affordable price"

> "If you're in high school or college, you gotta get lane tracks"

> "It's essentially an extra eye for me"

> "The reverates are always a little bit iffy... using a more colorful ball generally helps"

> "Everything seemed very, very accurate... the numbers were consistent"

## UI Design Analysis (from video frames)

### Main Stats Screen Layout
```
┌─────────────────────────────────────┐
│ [History] [●○○] [□] [≡]  │ ← Top nav icons
├─────────────┬───────────────────────┤
│             │ Foul Line │  Arrows   │
│  Lane View  │   29.6    │   20.1    │
│  with       │ Prev:28.1 │ Prev:19.4 │
│  Trajectory ├───────────┼───────────┤
│  Overlay    │Entry Board│ Rev Rate  │
│  (cyan      │   12.5    │   394rpm  │
│   line)     │ Prev:10.5 │ Prev: 362 │
│             ├───────────┼───────────┤
│             │Breakpoint │ Breakpoint│
│             │  Board    │ Distance  │
│             │   5.4     │  46.4ft   │
│             │ Prev: 4.6 │ Prev:48.4 │
│             ├───────────┼───────────┤
│             │Launch     │ Impact    │
│             │ Angle     │  Angle    │
│             │   3.3°    │   6.0°    │
│             │ Prev: 3.0 │ Prev: 6.0 │
│             ├───────────┼───────────┤
│             │Launch     │ Impact    │
│             │ Speed     │  Speed    │
│             │ 19.5mph   │ 18.2mph   │
│             │Prev: 19.5 │Prev: 18.2 │
├─────────────┴───────────┴───────────┤
│ [⟳] │ < 3 9 10 > │ [X]              │ ← Nav bar
└─────────────────────────────────────┘
```

### Key UI Features Observed
1. **2-column grid** for stats tiles
2. **"Prev:" comparison values** shown below each metric
3. **Cyan trajectory line** overlaid on lane view
4. **Shot counter** (e.g., "3 9 10") with arrow navigation
5. **Teal/mint color scheme** for tile backgrounds
6. **White text** on colored backgrounds
7. **Units displayed** inline (mph, ft, °, rpm)
8. **Video thumbnail** integrated with stats view

### Library/History Screen
- List view with video thumbnails
- Filterable by: All shots, Strikes, Misses
- Grouped by session date
- Expandable shot details

### Color Palette
- Primary: Teal/Cyan (`#4DB6AC` approximately)
- Background: Dark (`#1a1a1a`)
- Text: White
- Trajectory line: Cyan/Light blue

## Implications for BowlerTrax Development

Based on this analysis, our BowlerTrax app should:

1. **Prioritize consistency over absolute accuracy** for rev rate
2. **Use colorful ball markers** to improve tracking (as LaneTrax recommends)
3. **Auto-detect lane** rather than manual calibration if possible
4. **Position camera parallel to gutter**, not behind bowler's target
5. **Auto-record shots** without manual trigger
6. **Store sessions locally** with cloud sync option
7. **Include league mode** toggle for team bowling
8. **Show PBA-style trajectory overlay** on video
9. **Track historical data** for trend analysis
10. **Focus on relative metrics** (shot-to-shot changes) not absolute values
