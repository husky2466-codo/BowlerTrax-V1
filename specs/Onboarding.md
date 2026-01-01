# BowlerTrax Onboarding Flow and First-Use Experience Specification

## Overview

This document defines the complete first-use experience for BowlerTrax, ensuring new users can quickly understand the app's value, grant necessary permissions, and successfully track their first bowling shot.

---

## 1. FIRST LAUNCH SEQUENCE

### Flow Diagram

```
[App Launch] --> [Welcome Screen] --> [Feature Cards (3)] --> [Camera Permission]
                                                                      |
                                                            [Denied] / [Granted]
                                                               |           |
                                                               v           v
                                                    [Limited Mode]  [Hand Selection]
                                                                          |
                                                                          v
                                                                [Ball Profile Setup]
                                                                    (optional)
                                                                          |
                                                                          v
                                                                   [Dashboard]
```

### Step 1: Welcome Screen

```
+------------------------------------------+
|                                          |
|                                          |
|              [LOGO GRAPHIC]              |
|                                          |
|            B O W L E R T R A X           |
|                                          |
|       Track Every Shot. Improve         |
|            Every Game.                   |
|                                          |
|                                          |
|                                          |
|                                          |
|         +------------------------+       |
|         |     Get Started        |       |
|         +------------------------+       |
|                                          |
|                                          |
+------------------------------------------+
```

**Copy:**
- Headline: "BowlerTrax"
- Tagline: "Track Every Shot. Improve Every Game."
- Button: "Get Started"

**Behavior:**
- Logo fades in with subtle animation
- Tagline appears after 500ms delay
- Button pulses gently to draw attention
- Tap anywhere or button to proceed

---

### Step 2: Feature Highlights (Swipeable Cards)

**Card 1: Smart Ball Tracking**

```
+------------------------------------------+
|                                          |
|     +----------------------------+       |
|     |                            |       |
|     |    [Ball Tracking Icon]    |       |
|     |         .-""-.             |       |
|     |        /      \            |       |
|     |       |  (o)   |  ~~~>     |       |
|     |        \      /            |       |
|     |         '-..-'             |       |
|     +----------------------------+       |
|                                          |
|        Smart Ball Tracking               |
|                                          |
|   Your phone's camera tracks your        |
|   ball from release to pins using        |
|   color detection. No sensors or         |
|   special equipment needed.              |
|                                          |
|             o  .  .                      |
|                                          |
|                          [Next >]        |
+------------------------------------------+
```

**Copy:**
- Title: "Smart Ball Tracking"
- Description: "Your phone's camera tracks your ball from release to pins using color detection. No sensors or special equipment needed."

---

**Card 2: Real-Time Metrics**

```
+------------------------------------------+
|                                          |
|     +----------------------------+       |
|     |   Speed     Entry Angle    |       |
|     |   17.2      6.2 degrees    |       |
|     |   MPH                      |       |
|     |                            |       |
|     |   Rev Rate   Strike Prob   |       |
|     |   320 RPM    87%           |       |
|     +----------------------------+       |
|                                          |
|        Real-Time Metrics                 |
|                                          |
|   See ball speed, entry angle, rev       |
|   rate, and strike probability           |
|   instantly after every shot.            |
|                                          |
|             .  o  .                      |
|                                          |
|         [< Back]      [Next >]           |
+------------------------------------------+
```

**Copy:**
- Title: "Real-Time Metrics"
- Description: "See ball speed, entry angle, rev rate, and strike probability instantly after every shot."

---

**Card 3: Track Your Progress**

```
+------------------------------------------+
|                                          |
|     +----------------------------+       |
|     |                     /      |       |
|     |                   /        |       |
|     |               . /          |       |
|     |             . /            |       |
|     |           ./               |       |
|     |         ./                 |       |
|     |     __./___________________+       |
|     +----------------------------+       |
|                                          |
|        Track Your Progress               |
|                                          |
|   Review sessions, analyze trends,       |
|   and watch your consistency             |
|   improve over time.                     |
|                                          |
|             .  .  o                      |
|                                          |
|         [< Back]    [Continue >]         |
+------------------------------------------+
```

**Copy:**
- Title: "Track Your Progress"
- Description: "Review sessions, analyze trends, and watch your consistency improve over time."

**Behavior:**
- Horizontal swipe between cards
- Dots indicate current position
- "Continue" on final card proceeds to permissions
- Skip link available: "Skip intro" (small, bottom corner)

---

### Step 3: Camera Permission Request

```
+------------------------------------------+
|                                          |
|                                          |
|           +----------------+             |
|           |                |             |
|           |   [Camera      |             |
|           |    Icon]       |             |
|           |      O         |             |
|           |     /|\        |             |
|           |     / \        |             |
|           +----------------+             |
|                                          |
|          Camera Access Required          |
|                                          |
|   BowlerTrax needs camera access to      |
|   track your bowling ball down the       |
|   lane and calculate your shot           |
|   metrics in real-time.                  |
|                                          |
|   Your video stays on your device        |
|   and is never uploaded.                 |
|                                          |
|         +------------------------+       |
|         |   Enable Camera        |       |
|         +------------------------+       |
|                                          |
|            Why is this needed?           |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Camera Access Required"
- Description: "BowlerTrax needs camera access to track your bowling ball down the lane and calculate your shot metrics in real-time."
- Privacy note: "Your video stays on your device and is never uploaded."
- Button: "Enable Camera"
- Link: "Why is this needed?" (expandable)

**Expanded "Why is this needed?" section:**
```
+------------------------------------------+
|   BowlerTrax uses your camera to:        |
|                                          |
|   [Check] Detect your ball by color      |
|   [Check] Track the ball's path          |
|   [Check] Calculate speed and angle      |
|   [Check] Record shots for playback      |
|                                          |
|   No data leaves your phone. All         |
|   processing happens locally.            |
+------------------------------------------+
```

**Behavior:**
- Tapping "Enable Camera" triggers iOS permission dialog
- If granted: proceed to hand selection
- If denied: show limited mode screen

---

### Step 3a: Permission Denied Handling

```
+------------------------------------------+
|                                          |
|              [Warning Icon]              |
|                  /!\                     |
|                                          |
|          Camera Access Denied            |
|                                          |
|   Without camera access, BowlerTrax      |
|   cannot track your shots. You can       |
|   still manually log your games.         |
|                                          |
|                                          |
|   +----------------------------------+   |
|   | Open Settings to Enable Camera   |   |
|   +----------------------------------+   |
|                                          |
|            Continue Without Camera       |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Camera Access Denied"
- Description: "Without camera access, BowlerTrax cannot track your shots. You can still manually log your games."
- Primary Button: "Open Settings to Enable Camera"
- Secondary Link: "Continue Without Camera"

**Behavior:**
- "Open Settings" deep-links to app settings in iOS Settings
- "Continue Without Camera" proceeds to hand selection but marks tracking as unavailable
- App periodically prompts to enable camera (see Section 7)

---

### Step 4: Hand Preference Selection

```
+------------------------------------------+
|                                          |
|           Which hand do you              |
|              bowl with?                  |
|                                          |
|    +---------------+  +---------------+  |
|    |               |  |               |  |
|    |    [LEFT]     |  |    [RIGHT]    |  |
|    |               |  |               |  |
|    |      / |      |  |      | \      |  |
|    |     /__|      |  |      |__\     |  |
|    |               |  |               |  |
|    +---------------+  +---------------+  |
|                                          |
|   This helps us show you the correct     |
|   lane perspective and pocket position.  |
|                                          |
|                                          |
|                                          |
+------------------------------------------+
```

**Copy:**
- Question: "Which hand do you bowl with?"
- Options: "Left" | "Right"
- Explanation: "This helps us show you the correct lane perspective and pocket position."

**Behavior:**
- Tapping either option highlights it with accent color
- Selection auto-advances after 300ms delay
- Stored in settings store
- Can be changed later in Settings

---

### Step 5: First Ball Profile Setup (Optional)

```
+------------------------------------------+
|                                          |
|           Set Up Your First Ball         |
|                                          |
|     +----------------------------+       |
|     |                            |       |
|     |        [Ball Icon]         |       |
|     |          .---.             |       |
|     |         /     \            |       |
|     |        |  oo   |           |       |
|     |         \  o  /            |       |
|     |          '---'             |       |
|     +----------------------------+       |
|                                          |
|   Ball Name                              |
|   +----------------------------------+   |
|   | Storm Hyroad Pearl               |   |
|   +----------------------------------+   |
|                                          |
|   Ball Color (for tracking)              |
|   +----------------------------------+   |
|   | [Purple] [Blue] [Red] [Custom]   |   |
|   +----------------------------------+   |
|                                          |
|         +------------------------+       |
|         |      Save Ball         |       |
|         +------------------------+       |
|                                          |
|               Skip for now               |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Set Up Your First Ball"
- Fields:
  - "Ball Name" (text input, placeholder: "e.g., Storm Hyroad Pearl")
  - "Ball Color (for tracking)" (color picker)
- Button: "Save Ball"
- Link: "Skip for now"

**Color Options:**
- Pre-defined: Purple, Blue, Red, Orange, Green, Black
- Custom: Opens color picker or "Tap ball during calibration"

**Behavior:**
- "Skip for now" proceeds to dashboard
- "Save Ball" validates input, creates ball profile, proceeds to dashboard
- Ball can be added/edited later in Settings > Ball Profiles

---

### Step 6: Dashboard (Ready to Use)

```
+------------------------------------------+
|  BowlerTrax              [Profile Icon]  |
|------------------------------------------|
|                                          |
|     Welcome! You're ready to bowl.       |
|                                          |
|  +------------------------------------+  |
|  |                                    |  |
|  |   [Start New Session Button]       |  |
|  |                                    |  |
|  |   Tap to begin tracking shots      |  |
|  |                                    |  |
|  +------------------------------------+  |
|                                          |
|  Quick Stats        (no data yet)        |
|  +------------------------------------+  |
|  |  Sessions: 0  |  Shots: 0          |  |
|  |  Avg Speed: -- | Strike %: --      |  |
|  +------------------------------------+  |
|                                          |
|                                          |
|------------------------------------------|
| [Home]   [Record]   [History]   [More]   |
+------------------------------------------+
```

**Copy:**
- Welcome message: "Welcome! You're ready to bowl."
- CTA: "Start New Session" with subtext "Tap to begin tracking shots"
- Empty state: "No data yet" for quick stats

**Behavior:**
- First time only: Show first-session tutorial overlay (Section 4)
- Tapping "Start New Session" begins first calibration flow (Section 3)

---

## 2. PERMISSION REQUEST SCREENS

### Camera Permission (Required)

**When requested:** Step 3 of onboarding
**iOS Dialog Copy:**
```
"BowlerTrax" Would Like to Access the Camera
This app uses your camera to track your bowling ball and calculate shot metrics.
[Don't Allow]  [Allow]
```

**Custom pre-permission screen:** (see Step 3 above)

**If denied:**
- Show explanation screen (Step 3a)
- Offer deep-link to Settings
- Allow limited mode (manual logging only)
- Badge/prompt on Record tab when camera unavailable

---

### Photo Library Permission (Optional)

**When requested:** First time user taps "Save Video"
**Purpose:** Save recorded shot videos to Camera Roll

```
+------------------------------------------+
|                                          |
|           +----------------+             |
|           |   [Gallery     |             |
|           |    Icon]       |             |
|           +----------------+             |
|                                          |
|           Save Videos to Photos          |
|                                          |
|   To save your shot recordings to your   |
|   photo library, BowlerTrax needs        |
|   permission to access your photos.      |
|                                          |
|   Videos are only saved when you         |
|   tap "Save to Photos."                  |
|                                          |
|         +------------------------+       |
|         |    Allow Access        |       |
|         +------------------------+       |
|                                          |
|               Not Now                    |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Save Videos to Photos"
- Description: "To save your shot recordings to your photo library, BowlerTrax needs permission to access your photos."
- Privacy note: "Videos are only saved when you tap 'Save to Photos.'"
- Primary: "Allow Access"
- Secondary: "Not Now"

**iOS Dialog Copy:**
```
"BowlerTrax" Would Like to Add to Your Photos
This will allow you to save bowling shot recordings.
[Don't Allow]  [Allow]
```

**If denied:**
- Toast: "Photo access required to save videos. Enable in Settings."
- "Save to Photos" button shows lock icon
- Offer Settings deep-link when tapped

---

### Permission Summary Table

| Permission | Required | When Requested | Denial Behavior |
|------------|----------|----------------|-----------------|
| Camera | Yes | Onboarding Step 3 | Limited mode (manual logging only) |
| Photo Library | No | First "Save Video" tap | Cannot save to Camera Roll |
| Notifications | No | After first session complete | No reminders/tips |

---

## 3. FIRST CALIBRATION EXPERIENCE

### Overview

Calibration creates a coordinate mapping from camera pixels to lane position. This is required before tracking can work accurately.

### Calibration Flow

```
[Record Tab Tap] --> [Calibration Check] --> [Already Calibrated?]
                                                    |
                                            [No]  /   \  [Yes]
                                             |           |
                                             v           v
                                    [Start Calibration]  [Recording Mode]
```

### Step 1: Camera Positioning Guide

```
+------------------------------------------+
|                                          |
|   LIVE CAMERA PREVIEW (dimmed)           |
|   +----------------------------------+   |
|   |                                  |   |
|   |                                  |   |
|   |                                  |   |
|   |                                  |   |
|   |                                  |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|  +------------------------------------+  |
|  |  [1]  Camera Positioning           |  |
|  |                                    |  |
|  |  Position your camera:             |  |
|  |                                    |  |
|  |  [Check] Behind the approach       |  |
|  |  [Check] Elevated (shoulder height)|  |
|  |  [Check] Centered on your lane     |  |
|  |  [Check] Stable (use tripod/stand) |  |
|  |                                    |  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  |          Position is Good          |  |
|  +------------------------------------+  |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Camera Positioning"
- Instructions:
  - "Behind the approach" - Camera sees down the lane
  - "Elevated (shoulder height)" - Better angle to see ball path
  - "Centered on your lane" - Arrows should be visible
  - "Stable (use tripod/stand)" - Movement ruins tracking
- Button: "Position is Good"

**Behavior:**
- Camera preview is active but dimmed
- Checklist items highlight as user reads
- Tapping button proceeds to arrow identification

---

### Step 2: Arrow Identification

```
+------------------------------------------+
|                                          |
|   LIVE CAMERA PREVIEW                    |
|   +----------------------------------+   |
|   |                                  |   |
|   |         [Arrow Overlay]          |   |
|   |           ^   ^   ^              |   |
|   |          /|\ /|\ /|\             |   |
|   |                                  |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|  +------------------------------------+  |
|  |  [2]  Identify the Arrows          |  |
|  |                                    |  |
|  |  Tap the CENTER arrow on the       |  |
|  |  lane (arrow on board 20).         |  |
|  |                                    |  |
|  |  +------------------------------+  |  |
|  |  |  (Visual: arrow diagram)     |  |  |
|  |  |    5  10  15 [20] 25  30  35 |  |  |
|  |  +------------------------------+  |  |
|  |                                    |  |
|  +------------------------------------+  |
|                                          |
|               [Help: Can't see arrows?]  |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Identify the Arrows"
- Instruction: "Tap the CENTER arrow on the lane (arrow on board 20)."
- Help link: "Can't see arrows?"

**Help Expanded:**
```
+------------------------------------------+
|  Arrows are located 15 feet down the     |
|  lane. They're typically darker marks    |
|  in the shape of triangles or chevrons.  |
|                                          |
|  If you can't see them:                  |
|  - Move camera higher                    |
|  - Adjust camera angle downward          |
|  - Ensure lane is well-lit               |
+------------------------------------------+
```

**Behavior:**
- User taps on center arrow in camera view
- App places marker at tap location
- Validates tap is in reasonable screen region
- Proceeds to next arrow if valid

---

### Step 3: Additional Reference Points

```
+------------------------------------------+
|                                          |
|   LIVE CAMERA PREVIEW                    |
|   +----------------------------------+   |
|   |                            [X]   |   |
|   |         [Arrow Overlay]          |   |
|   |           ^   ^   ^              |   |
|   |          /|\ /|\ /|\             |   |
|   |              ^                   |   |
|   |             (marked)             |   |
|   +----------------------------------+   |
|                                          |
|  +------------------------------------+  |
|  |  [3]  Mark the Foul Line           |  |
|  |                                    |  |
|  |  Tap where the foul line meets     |  |
|  |  the right gutter.                 |  |
|  |                                    |  |
|  |  +------------------------------+  |  |
|  |  |  (Visual: lane diagram)      |  |  |
|  |  |  [Foul line] ----------[X]   |  |  |
|  |  +------------------------------+  |  |
|  |                                    |  |
|  +------------------------------------+  |
|                                          |
+------------------------------------------+
```

**Calibration Points Required:**
1. Center arrow (board 20)
2. Foul line right edge
3. Foul line left edge
4. Pin deck center (optional, improves accuracy)

**Copy for each step:**
- Step 2: "Tap the CENTER arrow on the lane (arrow on board 20)."
- Step 3: "Tap where the foul line meets the right gutter."
- Step 4: "Tap where the foul line meets the left gutter."
- Step 5: "Tap the head pin position (optional)."

---

### Step 4: Validation Feedback

**Success:**
```
+------------------------------------------+
|                                          |
|   CAMERA PREVIEW WITH OVERLAY            |
|   +----------------------------------+   |
|   |                                  |   |
|   |    [Lane grid overlay showing    |   |
|   |     calibration is accurate]     |   |
|   |                                  |   |
|   |       |   |   |   |   |          |   |
|   |       5  10  15  20  25          |   |
|   +----------------------------------+   |
|                                          |
|  +------------------------------------+  |
|  |  [Checkmark]  Calibration Complete |  |
|  |                                    |  |
|  |  Lane grid looks accurate!         |  |
|  |                                    |  |
|  |  +------------------------------+  |  |
|  |  |       Start Recording        |  |  |
|  |  +------------------------------+  |  |
|  |                                    |  |
|  |         Redo Calibration          |  |  |
|  +------------------------------------+  |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Calibration Complete"
- Message: "Lane grid looks accurate!"
- Primary: "Start Recording"
- Secondary: "Redo Calibration"

**Retry (if validation fails):**
```
+------------------------------------------+
|                                          |
|  +------------------------------------+  |
|  |  [Warning]  Let's Try Again        |  |
|  |                                    |  |
|  |  The calibration doesn't look      |  |
|  |  quite right. This can happen if:  |  |
|  |                                    |  |
|  |  - Camera moved between taps       |  |
|  |  - Tap was off-target              |  |
|  |  - Glare is affecting visibility   |  |
|  |                                    |  |
|  |  +------------------------------+  |  |
|  |  |        Try Again             |  |  |
|  |  +------------------------------+  |  |
|  +------------------------------------+  |
|                                          |
+------------------------------------------+
```

---

### Step 5: Save Calibration

```
+------------------------------------------+
|                                          |
|           Save This Calibration?         |
|                                          |
|   Save this calibration for quick        |
|   setup next time at this location.      |
|                                          |
|   Bowling Center Name (optional)         |
|   +----------------------------------+   |
|   | AMF Bowling Center               |   |
|   +----------------------------------+   |
|                                          |
|   Lane Number(s)                         |
|   +----------------------------------+   |
|   | Lanes 15-16                      |   |
|   +----------------------------------+   |
|                                          |
|         +------------------------+       |
|         |   Save Calibration     |       |
|         +------------------------+       |
|                                          |
|            Use Without Saving            |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Save This Calibration?"
- Description: "Save this calibration for quick setup next time at this location."
- Fields:
  - "Bowling Center Name (optional)"
  - "Lane Number(s)"
- Primary: "Save Calibration"
- Secondary: "Use Without Saving"

**Behavior:**
- Saved calibrations appear in Settings > Saved Calibrations
- Can load saved calibration for faster setup
- Calibrations include camera position hash for validation

---

## 4. FIRST SHOT TUTORIAL

### Interactive Overlay During First Recording

When user enters recording mode for the first time, show step-by-step overlays.

### Overlay 1: Color Selection

```
+------------------------------------------+
|  [X]                                     |
|   LIVE CAMERA PREVIEW                    |
|   +----------------------------------+   |
|   |                                  |   |
|   |       .---.                      |   |
|   |      /     \  <-- Tap here       |   |
|   |     |  oo   |     to set color   |   |
|   |      \  o  /                     |   |
|   |       '---'                      |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|  +------------------------------------+  |
|  |        Tap Your Ball               |  |
|  |                                    |  |
|  |  Tap on your bowling ball to       |  |
|  |  set the tracking color.           |  |
|  |                                    |  |
|  |  Tip: Tap the brightest, most      |  |
|  |  unique color on your ball.        |  |
|  +------------------------------------+  |
|                                          |
|                 [Got it]                 |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Tap Your Ball"
- Instruction: "Tap on your bowling ball to set the tracking color."
- Tip: "Tip: Tap the brightest, most unique color on your ball."
- Button: "Got it"

**Behavior:**
- Overlay dismisses on button tap
- User taps ball in camera view
- Color sample appears with confirmation

---

### Overlay 2: Camera Position Check

```
+------------------------------------------+
|  [X]                                     |
|   LIVE CAMERA PREVIEW                    |
|   +----------------------------------+   |
|   |  [Foul line area]                |   |
|   |                                  |   |
|   |  [Arrows visible]                |   |
|   |                                  |   |
|   |  [Pin deck visible]              |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|  +------------------------------------+  |
|  |        Check Your View             |  |
|  |                                    |  |
|  |  Make sure you can see:            |  |
|  |                                    |  |
|  |  [Check] Foul line area            |  |
|  |  [Check] Lane arrows               |  |
|  |  [Check] Pins (at least partially) |  |
|  |                                    |  |
|  +------------------------------------+  |
|                                          |
|              [Looks Good]                |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Check Your View"
- Checklist:
  - "Foul line area"
  - "Lane arrows"
  - "Pins (at least partially)"
- Button: "Looks Good"

---

### Overlay 3: Recording Instructions

```
+------------------------------------------+
|  [X]                                     |
|   LIVE CAMERA PREVIEW                    |
|   +----------------------------------+   |
|   |                                  |   |
|   |   (waiting for ball detection)   |   |
|   |                                  |   |
|   |         READY TO TRACK           |   |
|   |                                  |   |
|   |                                  |   |
|   +----------------------------------+   |
|                                          |
|  +------------------------------------+  |
|  |        Ready to Bowl               |  |
|  |                                    |  |
|  |  Recording starts automatically    |  |
|  |  when your ball is detected.       |  |
|  |                                    |  |
|  |  Recording stops when the ball     |  |
|  |  reaches the pins.                 |  |
|  |                                    |  |
|  |  Just bowl normally!               |  |
|  +------------------------------------+  |
|                                          |
|              [Start Tracking]            |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "Ready to Bowl"
- Instructions:
  - "Recording starts automatically when your ball is detected."
  - "Recording stops when the ball reaches the pins."
  - "Just bowl normally!"
- Button: "Start Tracking"

---

### Post-Shot: Success Celebration

After first successfully tracked shot:

```
+------------------------------------------+
|                                          |
|                                          |
|              [Celebration Icon]          |
|                   * * *                  |
|                  * * * *                 |
|                   * * *                  |
|                                          |
|             First Shot Tracked!          |
|                                          |
|   +----------------------------------+   |
|   |  Speed:        17.2 MPH          |   |
|   |  Entry Angle:  5.8 degrees       |   |
|   |  Rev Rate:     ~320 RPM          |   |
|   +----------------------------------+   |
|                                          |
|   Great start! Keep bowling to          |
|   build up your session data.            |
|                                          |
|         +------------------------+       |
|         |    Continue Session    |       |
|         +------------------------+       |
|                                          |
|              View Shot Details           |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "First Shot Tracked!"
- Message: "Great start! Keep bowling to build up your session data."
- Primary: "Continue Session"
- Secondary: "View Shot Details"

---

## 5. CONTEXTUAL HELP

### Metric Tooltips

Tooltips appear when user taps the info icon (i) next to any metric.

**Ball Speed:**
```
+--------------------------------------+
|  Ball Speed                          |
|                                      |
|  How fast your ball travels down     |
|  the lane, measured in MPH.          |
|                                      |
|  Typical range: 14-20 MPH            |
|  Pros average: 17-19 MPH             |
|                                      |
|  Faster isn't always better!         |
|  Find the speed that gives you       |
|  the best pin action.                |
+--------------------------------------+
```

**Entry Angle:**
```
+--------------------------------------+
|  Entry Angle                         |
|                                      |
|  The angle your ball enters the      |
|  pocket, measured in degrees.        |
|                                      |
|  Optimal: 4-6 degrees                |
|  Ideal for strikes: ~6 degrees       |
|                                      |
|  Higher angle = more pin action      |
|  but harder to control.              |
+--------------------------------------+
```

**Rev Rate:**
```
+--------------------------------------+
|  Rev Rate                            |
|                                      |
|  How many times your ball spins      |
|  per minute (RPM).                   |
|                                      |
|  Low: Under 200 RPM                  |
|  Medium: 200-350 RPM                 |
|  High: 350-450 RPM                   |
|  Very High: 450+ RPM                 |
|                                      |
|  Higher revs = more hook potential   |
|  but requires more control.          |
+--------------------------------------+
```

**Strike Probability:**
```
+--------------------------------------+
|  Strike Probability                  |
|                                      |
|  Estimated chance of striking        |
|  based on entry angle and pocket     |
|  position.                           |
|                                      |
|  90%+: Excellent entry               |
|  70-90%: Good entry                  |
|  50-70%: Marginal entry              |
|  Under 50%: Off-pocket               |
|                                      |
|  Factors: angle, speed, position     |
+--------------------------------------+
```

---

### Trajectory Visualization Help

```
+------------------------------------------+
|  Understanding Your Shot Path            |
|                                          |
|  +----------------------------------+    |
|  |        [Lane diagram]            |    |
|  |                                  |    |
|  |   -----.                         |    |
|  |         \                        |    |
|  |          \                       |    |
|  |           `.                     |    |
|  |             \                    |    |
|  |              [Pin]               |    |
|  +----------------------------------+    |
|                                          |
|  RELEASE POINT (start of line)           |
|  Where you released the ball.            |
|                                          |
|  BREAKPOINT (curve inflection)           |
|  Where the ball starts hooking.          |
|                                          |
|  ENTRY POINT (at pins)                   |
|  Where the ball hits the pocket.         |
|                                          |
|  [Close]                                 |
+------------------------------------------+
```

---

### Improvement Tips (Contextual)

Shown after shots with specific characteristics:

**Low Entry Angle (<4 degrees):**
```
+--------------------------------------+
|  Tip: Increase Your Entry Angle      |
|                                      |
|  Your ball is entering the pocket    |
|  too straight. Try:                  |
|                                      |
|  - Moving your target left (RH)      |
|  - Increasing ball speed slightly    |
|  - Adjusting your release            |
|                                      |
|  Goal: 4-6 degree entry angle        |
+--------------------------------------+
```

**High Entry Angle (>8 degrees):**
```
+--------------------------------------+
|  Tip: Reduce Your Entry Angle        |
|                                      |
|  Your ball is hooking too much.      |
|  This can cause inconsistent         |
|  pin carry. Try:                     |
|                                      |
|  - Moving your target right (RH)     |
|  - Decreasing ball speed             |
|  - Using a weaker ball               |
|                                      |
|  Goal: 4-6 degree entry angle        |
+--------------------------------------+
```

**Brooklyn Hit (wrong pocket):**
```
+--------------------------------------+
|  Brooklyn!                           |
|                                      |
|  Your ball crossed to the opposite   |
|  pocket. This usually means:         |
|                                      |
|  - Ball hooked more than expected    |
|  - Lane conditions changed           |
|  - Target was too far inside         |
|                                      |
|  Adjust: Move your feet/target       |
|  slightly right (for RH bowlers).    |
+--------------------------------------+
```

---

## 6. SKIP/LATER OPTIONS

### Skippable Steps

| Step | Can Skip? | Consequence | Reminder |
|------|-----------|-------------|----------|
| Feature highlights | Yes | None | None |
| Camera permission | No* | Limited mode | Persistent badge |
| Hand preference | No | Cannot proceed | N/A |
| Ball profile setup | Yes | Use default color | Prompt on first record |
| Calibration | Yes** | Cannot track | Required before recording |
| First shot tutorial | Yes | May struggle | Show once per session |

*Camera can be denied but user enters limited mode
**Can skip to dashboard but must calibrate before first recording

### Reminder Prompts

**Ball Profile Reminder (if skipped):**
Shown when user first enters Record tab:
```
+--------------------------------------+
|  Set Up Your Ball?                   |
|                                      |
|  Setting your ball color helps       |
|  tracking accuracy.                  |
|                                      |
|  [Set Up Now]     [Maybe Later]      |
+--------------------------------------+
```
- Shows maximum 3 times
- "Maybe Later" delays reminder 24 hours
- Dismissed permanently after 3 declines

**Camera Permission Reminder (if denied):**
Badge appears on Record tab. When tapped:
```
+--------------------------------------+
|  Camera Required                     |
|                                      |
|  To track shots, enable camera       |
|  access in Settings.                 |
|                                      |
|  [Open Settings]    [Not Now]        |
+--------------------------------------+
```
- Shows every time Record tab tapped
- Clears when permission granted

---

## 7. RETURNING USER EXPERIENCE

### Onboarding Completion Tracking

Store in AsyncStorage/settings:

```typescript
interface OnboardingState {
  completed: boolean;
  completedAt: string | null;
  skippedSteps: string[];
  featureHighlightsSeen: boolean;
  firstCalibrationDone: boolean;
  firstShotTracked: boolean;
  tutorialOverlaysDismissed: string[];
  lastVersionSeen: string;
}
```

### "What's New" Screen

Shown after app update if user completed onboarding:

```
+------------------------------------------+
|  [X]                                     |
|                                          |
|           What's New in v1.1             |
|                                          |
|  +------------------------------------+  |
|  |  [Icon] Session Comparison         |  |
|  |                                    |  |
|  |  Compare two sessions side-by-     |  |
|  |  side to see your improvement.     |  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  |  [Icon] Export to CSV              |  |
|  |                                    |  |
|  |  Export your shot data for         |  |
|  |  analysis in spreadsheets.         |  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  |  [Icon] Bug Fixes                  |  |
|  |                                    |  |
|  |  Improved tracking accuracy and    |  |
|  |  fixed battery drain issue.        |  |
|  +------------------------------------+  |
|                                          |
|              [Got It]                    |
|                                          |
+------------------------------------------+
```

**Copy:**
- Title: "What's New in v[X.X]"
- List new features with icons
- Button: "Got It"

**Behavior:**
- Only shows once per version
- Can be dismissed with X or button
- Accessible later via Settings > What's New

---

### Quick Recalibration Prompts

**Scenario 1: Different bowling center detected**
Based on location services (if enabled):
```
+--------------------------------------+
|  New Location Detected               |
|                                      |
|  It looks like you're at a new       |
|  bowling center. Would you like to:  |
|                                      |
|  [New Calibration]                   |
|  [Load Saved Calibration]            |
|  [Use Current (may be inaccurate)]   |
+--------------------------------------+
```

**Scenario 2: Camera position seems different**
Based on calibration validation:
```
+--------------------------------------+
|  Calibration Check                   |
|                                      |
|  Your camera position looks          |
|  different from your saved           |
|  calibration.                        |
|                                      |
|  [Recalibrate]   [Continue Anyway]   |
+--------------------------------------+
```

**Scenario 3: Extended time since last session**
If >30 days since last session:
```
+--------------------------------------+
|  Welcome Back!                       |
|                                      |
|  It's been a while. Before you       |
|  start, you may want to:             |
|                                      |
|  - Check your calibration            |
|  - Update your ball profiles         |
|  - Review the tracking tips          |
|                                      |
|  [Quick Setup]       [Start Now]     |
+--------------------------------------+
```

---

## 8. IMPLEMENTATION NOTES

### File Structure

```
app/
  onboarding/
    index.tsx           # Onboarding flow controller
    welcome.tsx         # Welcome screen
    features.tsx        # Feature highlights carousel
    permissions.tsx     # Permission request screens
    hand-selection.tsx  # Hand preference
    ball-setup.tsx      # Optional ball profile

components/
  onboarding/
    FeatureCard.tsx
    PermissionExplainer.tsx
    HandSelector.tsx
    CalibrationOverlay.tsx
    TutorialOverlay.tsx
    MetricTooltip.tsx
    WhatsNewModal.tsx

stores/
  onboardingStore.ts    # Onboarding state (Zustand)

lib/
  constants/
    onboardingCopy.ts   # All copy/text centralized
```

### Key Dependencies

- `expo-camera` - Camera permissions and preview
- `expo-media-library` - Photo library permissions
- `expo-location` - Optional: bowling center detection
- `@react-native-async-storage/async-storage` - Persist onboarding state
- `react-native-reanimated` - Animations for overlays

### Accessibility Considerations

- All images have alt text
- Focus order follows visual order
- Color is not the only indicator (use icons + text)
- Minimum touch target: 44x44pt
- Screen reader announcements for state changes
- Reduce motion option respects system setting

### Analytics Events

Track these events to improve onboarding:
- `onboarding_started`
- `onboarding_step_completed` (with step name)
- `onboarding_step_skipped` (with step name)
- `onboarding_completed`
- `onboarding_abandoned` (with last step)
- `permission_requested` (with type)
- `permission_granted` (with type)
- `permission_denied` (with type)
- `first_calibration_completed`
- `first_shot_tracked`
- `tutorial_overlay_dismissed` (with overlay name)

---

## 9. COPY REFERENCE

### All Button Labels

| Context | Primary | Secondary |
|---------|---------|-----------|
| Welcome | Get Started | - |
| Features | Next / Continue | Skip intro |
| Camera Permission | Enable Camera | Why is this needed? |
| Permission Denied | Open Settings | Continue Without Camera |
| Hand Selection | (auto-advance) | - |
| Ball Setup | Save Ball | Skip for now |
| Calibration Position | Position is Good | - |
| Calibration Complete | Start Recording | Redo Calibration |
| Save Calibration | Save Calibration | Use Without Saving |
| Tutorial Overlay | Got it / Looks Good / Start Tracking | - |
| First Shot Success | Continue Session | View Shot Details |
| What's New | Got It | - |

### Error Messages

| Scenario | Message |
|----------|---------|
| Camera permission denied | "Camera access is required to track your shots. Enable in Settings." |
| Photo library denied | "Photo access required to save videos. Enable in Settings." |
| Calibration failed | "Calibration doesn't look right. Let's try again." |
| Ball not detected | "Can't detect your ball. Make sure it's visible and well-lit." |
| Tracking lost | "Lost track of the ball. Try adjusting camera position." |

### Encouragement Messages (rotate randomly)

After successful shots:
- "Nice shot!"
- "Looking good!"
- "Solid roll!"
- "Great form!"
- "On target!"

After strikes:
- "Strike!"
- "X marks the spot!"
- "Crushed it!"
- "Perfect entry!"

---

## 10. SUMMARY

The BowlerTrax onboarding flow is designed to:

1. **Educate** users on the app's value proposition quickly
2. **Obtain** necessary permissions with clear explanations
3. **Guide** users through calibration step-by-step
4. **Celebrate** first successful shot to build engagement
5. **Support** users with contextual help throughout
6. **Respect** users' time with skip options
7. **Welcome back** returning users appropriately

The flow should take approximately 2-3 minutes for a new user who completes all steps, or under 1 minute for users who skip optional steps.
