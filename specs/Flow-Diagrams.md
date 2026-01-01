# BowlerTrax Flow Diagrams

Comprehensive user flow, data flow, and process diagrams for the BowlerTrax bowling analytics application.

---

## 1. USER FLOW DIAGRAM

### 1.1 First Launch Flow

```
+------------------+
|   App Install    |
+--------+---------+
         |
         v
+------------------+
|   First Launch   |
+--------+---------+
         |
         v
+------------------+     +------------------+
|  Camera          |---->|  Permission      |
|  Permission      |     |  Denied          |
|  Request         |     +--------+---------+
+--------+---------+              |
         | Granted                v
         |               +------------------+
         v               |  Show Settings   |
+------------------+     |  Instructions    |
|  Microphone      |     +------------------+
|  Permission      |
|  Request         |
+--------+---------+
         | Granted
         v
+------------------+
|  Photo Library   |
|  Permission      |
|  Request         |
+--------+---------+
         | Granted
         v
+------------------+
|   Onboarding     |
|   Screen 1:      |
|   "Welcome"      |
+--------+---------+
         |
         v
+------------------+
|   Onboarding     |
|   Screen 2:      |
|   "How It Works" |
+--------+---------+
         |
         v
+------------------+
|   Onboarding     |
|   Screen 3:      |
|   "Camera Setup" |
+--------+---------+
         |
         v
+------------------+
|   Onboarding     |
|   Screen 4:      |
|   "Hand Select"  |
|   (Left/Right)   |
+--------+---------+
         |
         v
+------------------+
|   Dashboard      |
|   (Home Screen)  |
+------------------+
```

### 1.2 Main Navigation Flow

```
+==============================================================================+
|                              TAB NAVIGATION                                  |
+==============================================================================+
|                                                                              |
|  +----------------+  +----------------+  +----------------+  +------------+  |
|  |   DASHBOARD    |  |    RECORD      |  |   SESSIONS     |  |  SETTINGS  |  |
|  |   (Tab 1)      |  |    (Tab 2)     |  |   (Tab 3)      |  |  (Tab 4)   |  |
|  +-------+--------+  +-------+--------+  +-------+--------+  +-----+------+  |
|          |                   |                   |                 |         |
|          v                   v                   v                 v         |
|  +---------------+   +---------------+   +---------------+   +-----------+   |
|  | Recent Shots  |   | Camera View   |   | Session List  |   | Profile   |   |
|  | Session Stats |   | New Session   |   | Date Filter   |   | Ball Mgmt |   |
|  | Quick Actions |   | Quick Record  |   | Search        |   | Calibrate |   |
|  +---------------+   +---------------+   +---------------+   +-----------+   |
|                                                                              |
+==============================================================================+
```

### 1.3 Recording Session Flow

```
                    +------------------+
                    |    Dashboard     |
                    +--------+---------+
                             |
                             | Tap "New Session"
                             v
                    +------------------+
                    |  Session Setup   |
                    |  - Center Name   |
                    |  - Lane Number   |
                    |  - Oil Pattern   |
                    +--------+---------+
                             |
                             v
              +-----------------------------+
              |   Has Calibration for       |
              |   this Center/Lane?         |
              +------+----------------+-----+
                     |                |
                 YES |                | NO
                     |                |
                     v                v
              +-----------+    +--------------+
              |  Use      |    |  Calibration |
              |  Existing |    |  Wizard      |
              +-----------+    +------+-------+
                     |                |
                     +-------+--------+
                             |
                             v
                    +------------------+
                    |  Camera Preview  |
                    |  Position Guide  |
                    +--------+---------+
                             |
                             | Tap "Sample Ball Color"
                             v
                    +------------------+
                    |  Color Picker    |
                    |  (Tap on Ball)   |
                    +--------+---------+
                             |
                             | Color Selected
                             v
                    +------------------+
                    |  Ready to Record |
                    |  [Start Button]  |
                    +--------+---------+
                             |
                             | Tap Start
                             v
              +==============================+
              |      RECORDING ACTIVE        |
              |  +------------------------+  |
              |  |   Camera Feed          |  |
              |  |   Ball Tracking Dot    |  |
              |  |   Real-time Metrics    |  |
              |  +------------------------+  |
              |  [Shot 1] [Shot 2] [...]     |
              +==============+===============+
                             |
                             | Ball Released (Auto-detect)
                             v
                    +------------------+
                    |   Tracking...    |
                    |   Ball in Motion |
                    +--------+---------+
                             |
                             | Ball exits frame or hits pins
                             v
                    +------------------+
                    |   Shot Complete  |
                    |   Show Metrics   |
                    |   - Speed        |
                    |   - Entry Angle  |
                    |   - Board Cross  |
                    +--------+---------+
                             |
            +----------------+----------------+
            |                                 |
            v                                 v
    +---------------+                 +---------------+
    |  Record Next  |                 |  End Session  |
    |  Shot         |                 |               |
    +-------+-------+                 +-------+-------+
            |                                 |
            | (Loop)                          v
            +------------------->     +---------------+
                                      |  Session      |
                                      |  Summary      |
                                      |  Screen       |
                                      +-------+-------+
                                              |
                                              v
                                      +---------------+
                                      |  Save to      |
                                      |  SQLite DB    |
                                      +-------+-------+
                                              |
                                              v
                                      +---------------+
                                      |  Dashboard    |
                                      +---------------+
```

### 1.4 Session History Flow

```
+------------------+
|   Sessions Tab   |
+--------+---------+
         |
         v
+------------------+     +------------------+
|  Session List    |     |  Filter Options  |
|  - Date grouped  |<--->|  - By Center     |
|  - Summary stats |     |  - By Date Range |
+--------+---------+     |  - By Hand       |
         |               +------------------+
         | Tap Session
         v
+------------------+
|  Session Detail  |
|  +-------------+ |
|  | Center Info | |
|  | Date/Time   | |
|  | Lane #      | |
|  | Shot Count  | |
|  +-------------+ |
|                  |
|  SHOTS LIST:     |
|  +-----------+   |
|  | Shot 1    |---|----+
|  | Shot 2    |   |    |
|  | Shot 3    |   |    | Tap Shot
|  | ...       |   |    |
|  +-----------+   |    |
|                  |    |
|  SESSION STATS:  |    |
|  - Avg Speed     |    |
|  - Avg Entry     |    |
|  - Strike %      |    |
+------------------+    |
                        v
               +------------------+
               |   Shot Detail    |
               |  +-------------+ |
               |  | Trajectory  | |
               |  | Replay      | |
               |  +-------------+ |
               |                  |
               |  METRICS:        |
               |  - Speed: 17 mph |
               |  - Entry: 5.8 deg|
               |  - Arrow: Bd 12  |
               |  - Break: Bd 8   |
               |  - Pocket: +0.5  |
               |  - Rev: 340 RPM  |
               |                  |
               |  ANALYSIS:       |
               |  - Strike Prob   |
               |  - Predicted Pin |
               |  - Suggestions   |
               |                  |
               |  [Play Video]    |
               |  [Share]         |
               |  [Delete]        |
               +------------------+
```

### 1.5 Settings Flow

```
+------------------+
|   Settings Tab   |
+--------+---------+
         |
         v
+------------------------------------------+
|              SETTINGS MENU               |
|  +------------------------------------+  |
|  |  PROFILE                           |  |
|  |  +------------------------------+  |  |
|  |  | Hand Preference  [Right >]   |--|--|----> Hand Selection
|  |  | Units            [Imperial>] |--|--|----> Units Toggle
|  |  +------------------------------+  |  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  |  BALL PROFILES                     |  |
|  |  +------------------------------+  |  |
|  |  | + Add New Ball               |--|--|----> Ball Profile
|  |  | Ball 1: Blue Storm           |--|--|      Creation
|  |  | Ball 2: Red Hammer           |  |  |
|  |  +------------------------------+  |  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  |  CALIBRATION PROFILES              |  |
|  |  +------------------------------+  |  |
|  |  | + New Calibration            |--|--|----> Calibration
|  |  | Sunset Lanes - Lane 12       |--|--|      Wizard
|  |  | Bowl America - Lane 5        |  |  |
|  |  +------------------------------+  |  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  |  DATA                              |  |
|  |  +------------------------------+  |  |
|  |  | Export Data (JSON/CSV)       |  |  |
|  |  | Clear All Data               |  |  |
|  |  +------------------------------+  |  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  |  ABOUT                             |  |
|  |  +------------------------------+  |  |
|  |  | Version 1.0.0                |  |  |
|  |  | Privacy Policy               |  |  |
|  |  | Terms of Service             |  |  |
|  |  +------------------------------+  |  |
|  +------------------------------------+  |
+------------------------------------------+
```

### 1.6 Ball Profile Management Flow

```
+------------------+
| Settings > Balls |
+--------+---------+
         |
         | Tap "Add New Ball"
         v
+------------------+
|  Ball Profile    |
|  Creation        |
+--------+---------+
         |
         v
+------------------+
|  Enter Ball Name |
|  [___________]   |
+--------+---------+
         |
         v
+------------------+
|  Camera Preview  |
|  "Tap on ball    |
|   to sample      |
|   color"         |
+--------+---------+
         |
         | Tap on ball in frame
         v
+------------------+
|  Color Sampled   |
|  [Preview Swatch]|
|                  |
|  HSV: H:220      |
|       S:85%      |
|       V:90%      |
|                  |
|  Tolerance: [15] |
+--------+---------+
         |
         v
+------------------------------+
|  Mark PAP for Rev Tracking?  |
+------+--------------+--------+
       |              |
      YES             NO
       |              |
       v              |
+------------------+  |
|  Tap on PAP      |  |
|  marker color    |  |
+--------+---------+  |
       |              |
       +-------+------+
               |
               v
       +------------------+
       |  Save Ball       |
       |  Profile         |
       +--------+---------+
                |
                v
       +------------------+
       |  Ball List       |
       |  (Updated)       |
       +------------------+
```

---

## 2. DATA FLOW DIAGRAM

### 2.1 High-Level System Data Flow

```
+==============================================================================+
|                           BOWLERTRAX DATA FLOW                               |
+==============================================================================+

  USER INPUT                    PROCESSING                    OUTPUT/STORAGE
  ==========                    ==========                    ==============

+-----------+              +------------------+
|  Camera   |------------->|  Frame Buffer    |
|  120 fps  |              |  (Circular)      |
+-----------+              +--------+---------+
                                    |
                                    v
+-----------+              +------------------+
|  Ball     |------------->|  Color Filter    |
|  Color    |              |  (HSV Masking)   |
|  Sample   |              +--------+---------+
+-----------+                       |
                                    v
                           +------------------+
                           |  Contour         |
                           |  Detection       |
                           +--------+---------+
                                    |
                                    v
                           +------------------+         +------------------+
                           |  Ball Position   |-------->|  Position        |
                           |  Extraction      |         |  History Array   |
                           +--------+---------+         +------------------+
                                    |                            |
                                    v                            v
+-----------+              +------------------+         +------------------+
|  Lane     |------------->|  Pixel to        |-------->|  Calibrated      |
|  Calibr.  |              |  Real-World      |         |  Trajectory      |
|  Profile  |              |  Transform       |         |  [{x,y,t,board}] |
+-----------+              +------------------+         +--------+---------+
                                                                 |
                           +-------------------------------------+
                           |
                           v
        +------------------+------------------+------------------+
        |                  |                  |                  |
        v                  v                  v                  v
+---------------+  +---------------+  +---------------+  +---------------+
|  Speed        |  |  Entry Angle  |  |  Breakpoint   |  |  Rev Rate     |
|  Calculator   |  |  Calculator   |  |  Detector     |  |  Calculator   |
|               |  |               |  |               |  |               |
|  d/t * 0.68   |  |  arctan(dx/dy)|  |  velocity     |  |  rotations/t  |
|  -> mph       |  |  -> degrees   |  |  delta        |  |  * 60 -> RPM  |
+-------+-------+  +-------+-------+  +-------+-------+  +-------+-------+
        |                  |                  |                  |
        +--------+---------+---------+--------+------------------+
                 |
                 v
         +---------------+
         |  Strike Prob  |
         |  Algorithm    |
         |               |
         |  f(angle,     |
         |    pocket,    |
         |    speed,     |
         |    revs)      |
         +-------+-------+
                 |
                 v
         +---------------+
         |  Shot Metrics |
         |  Complete     |
         +-------+-------+
                 |
        +--------+--------+
        |                 |
        v                 v
+---------------+  +---------------+
|  UI State     |  |  SQLite       |
|  (Zustand)    |  |  Database     |
+-------+-------+  +---------------+
        |
        v
+---------------+
|  Screen       |
|  Display      |
+---------------+
```

### 2.2 Frame Processing Pipeline

```
+------------------------------------------------------------------------------+
|                        FRAME PROCESSING PIPELINE                             |
+------------------------------------------------------------------------------+

  Time: t=0ms        t=8.3ms         t=16.6ms        t=25ms         t=33.3ms
  (120fps = 8.3ms per frame)
       |               |                |              |               |
       v               v                v              v               v
  +---------+     +---------+      +---------+    +---------+     +---------+
  | Frame 1 |     | Frame 2 |      | Frame 3 |    | Frame 4 |     | Frame 5 |
  +---------+     +---------+      +---------+    +---------+     +---------+
       |               |                |              |               |
       +-------+-------+--------+-------+------+-------+-------+-------+
               |                        |                      |
               v                        v                      v
       +---------------+        +---------------+      +---------------+
       |  RGB -> HSV   |        |  RGB -> HSV   |      |  RGB -> HSV   |
       |  Conversion   |        |  Conversion   |      |  Conversion   |
       +-------+-------+        +-------+-------+      +-------+-------+
               |                        |                      |
               v                        v                      v
       +---------------+        +---------------+      +---------------+
       |  Color Mask   |        |  Color Mask   |      |  Color Mask   |
       |  (Ball Color) |        |  (Ball Color) |      |  (Ball Color) |
       +-------+-------+        +-------+-------+      +-------+-------+
               |                        |                      |
               v                        v                      v
       +---------------+        +---------------+      +---------------+
       | Morph Open/   |        | Morph Open/   |      | Morph Open/   |
       | Close (noise) |        | Close (noise) |      | Close (noise) |
       +-------+-------+        +-------+-------+      +-------+-------+
               |                        |                      |
               v                        v                      v
       +---------------+        +---------------+      +---------------+
       |  Find         |        |  Find         |      |  Find         |
       |  Contours     |        |  Contours     |      |  Contours     |
       +-------+-------+        +-------+-------+      +-------+-------+
               |                        |                      |
               v                        v                      v
       +---------------+        +---------------+      +---------------+
       |  Filter by    |        |  Filter by    |      |  Filter by    |
       |  Circularity  |        |  Circularity  |      |  Circularity  |
       |  (>0.7)       |        |  (>0.7)       |      |  (>0.7)       |
       +-------+-------+        +-------+-------+      +-------+-------+
               |                        |                      |
               v                        v                      v
       +---------------+        +---------------+      +---------------+
       |  Centroid     |        |  Centroid     |      |  Centroid     |
       |  (x1, y1)     |        |  (x2, y2)     |      |  (x3, y3)     |
       +-------+-------+        +-------+-------+      +-------+-------+
               |                        |                      |
               +------------------------+-----------------------+
                                        |
                                        v
                               +------------------+
                               |  Position Buffer |
                               |  +-------------+ |
                               |  | t=0   (x,y) | |
                               |  | t=8   (x,y) | |
                               |  | t=16  (x,y) | |
                               |  | t=25  (x,y) | |
                               |  | t=33  (x,y) | |
                               |  | ...         | |
                               |  +-------------+ |
                               +------------------+
```

### 2.3 Calibration Data Flow

```
+------------------------------------------------------------------------------+
|                         CALIBRATION DATA FLOW                                |
+------------------------------------------------------------------------------+

  USER INPUTS                                   CALCULATED VALUES
  ===========                                   =================

+-------------------+
|  Camera Frame     |
|  (Lane View)      |
+---------+---------+
          |
          v
+-------------------+                          +-------------------+
|  User taps        |                          |                   |
|  Arrow 1 (Left)   |------------------------->|  Arrow1 Pixel     |
|  (Board 10)       |                          |  (x1, y1)         |
+-------------------+                          +---------+---------+
                                                         |
+-------------------+                                    |
|  User taps        |                                    |
|  Arrow 2 (Right)  |------------------------->+---------+---------+
|  (Board 25)       |                          |  Arrow2 Pixel     |
+-------------------+                          |  (x2, y2)         |
                                               +---------+---------+
                                                         |
                          +------------------------------+
                          |
                          v
               +-------------------+
               |  CALCULATE:       |
               |                   |
               |  pixel_distance   |
               |  = sqrt((x2-x1)^2 |
               |    + (y2-y1)^2)   |
               |                   |
               |  board_distance   |
               |  = 25 - 10 = 15   |
               |                   |
               |  PIXELS_PER_BOARD |
               |  = pixel_distance |
               |    / 15           |
               +-------------------+
                          |
                          v
+-------------------+    +-------------------+
|  User taps        |    |  pixelsPerBoard   |
|  Foul Line        |--->|  pixelsPerFoot    |------+
|                   |    |  foulLineY        |      |
+-------------------+    +-------------------+      |
                                                    v
+-------------------+                      +-------------------+
|  User taps        |                      |  CALIBRATION      |
|  Arrows Line      |----------------------|  PROFILE          |
|                   |                      |                   |
+-------------------+                      |  {                |
                                           |    centerId,      |
                                           |    laneNumber,    |
                                           |    pixelsPerBoard,|
                                           |    pixelsPerFoot, |
                                           |    foulLineY,     |
                                           |    arrowsY,       |
                                           |    refPoints      |
                                           |  }                |
                                           +---------+---------+
                                                     |
                                                     v
                                           +-------------------+
                                           |  SQLite Storage   |
                                           |  (calibrations    |
                                           |   table)          |
                                           +-------------------+
```

### 2.4 Metrics Calculation Data Flow

```
+------------------------------------------------------------------------------+
|                        METRICS CALCULATION DATA FLOW                         |
+------------------------------------------------------------------------------+

  INPUT: Calibrated Trajectory Array
  [{x, y, t, boardNum, distanceFt}, ...]

                              TRAJECTORY
                                  |
        +------------+------------+------------+------------+
        |            |            |            |            |
        v            v            v            v            v

  +-----------+  +-----------+  +-----------+  +-----------+  +-----------+
  |  SPEED    |  |  ENTRY    |  |  ARROW    |  |  BREAK    |  |  REV RATE |
  |  CALC     |  |  ANGLE    |  |  CROSSING |  |  POINT    |  |  CALC     |
  +-----------+  +-----------+  +-----------+  +-----------+  +-----------+
       |              |              |              |              |
       v              v              v              v              v

  +----------+   +----------+   +----------+   +----------+   +----------+
  | Get last |   | Get last |   | Find pt  |   | Analyze  |   | Track    |
  | 10ft of  |   | 5ft of   |   | where    |   | velocity |   | marker   |
  | trajectory   | trajectory   | dist=15ft|   | changes  |   | rotation |
  +----+-----+   +----+-----+   +----+-----+   +----+-----+   +----+-----+
       |              |              |              |              |
       v              v              v              v              v

  +----------+   +----------+   +----------+   +----------+   +----------+
  | distance |   | dx = end |   | Return   |   | Find pt  |   | Count    |
  | = p2.ft  |   |   - start|   | boardNum |   | where    |   | full     |
  |   - p1.ft|   |   board  |   | at that  |   | velocity |   | rotations|
  +----+-----+   |          |   | point    |   | vector   |   +----+-----+
       |         | dy = end |   +----+-----+   | changes  |        |
       v         |   - start|        |         | direction|        v
  +----------+   |   feet   |        v         +----+-----+   +----------+
  | time =   |   +----+-----+   +----------+        |         | time =   |
  | p2.t     |        |         |  Arrow   |        v         | last.t - |
  |   - p1.t |        v         |  Board   |   +----------+   | first.t  |
  +----+-----+   +----------+   | (eg: 12) |   | Breakpt  |   +----+-----+
       |         | angle =  |   +----------+   | Board #  |        |
       v         | arctan   |                  | (eg: 8)  |        v
  +----------+   | (dx/dy)  |                  +----------+   +----------+
  | speed =  |   +----+-----+                                 | RPM =    |
  | (dist/   |        |                                       | (rots /  |
  |  time)   |        v                                       |  time)   |
  | * 0.6818 |   +----------+                                 | * 60     |
  +----+-----+   | Entry    |                                 +----+-----+
       |         | Angle    |                                      |
       v         | (eg: 5.2)|                                      v
  +----------+   +----+-----+                                 +----------+
  |  Speed   |        |                                       | Rev Rate |
  |  17.2 mph|        v                                       | 342 RPM  |
  +----+-----+   +----------+                                 +----+-----+
       |         | Optimal  |                                      |
       |         | Check:   |                                      v
       |         | 4-7 deg  |                                 +----------+
       |         +----------+                                 | Category:|
       |                                                      | Tweener  |
       +-------------+----------------------------------------+----+-----+
                     |                                             |
                     v                                             |
            +------------------+                                   |
            |  STRIKE          |<----------------------------------+
            |  PROBABILITY     |
            |  ALGORITHM       |
            +--------+---------+
                     |
                     v
            +------------------+
            |  Inputs:         |
            |  - entry_angle   |
            |  - pocket_offset |
            |  - speed         |
            |  - rev_rate      |
            +--------+---------+
                     |
                     v
            +------------------+
            |  Calculate:      |
            |                  |
            |  angle_score =   |
            |   1 - |6-angle|/3|
            |                  |
            |  pocket_score =  |
            |   1 - |offset|/2 |
            |                  |
            |  strike_prob =   |
            |   avg(scores)    |
            +--------+---------+
                     |
                     v
            +------------------+
            |  Strike Prob:    |
            |  78%             |
            |                  |
            |  Predicted Leave:|
            |  "Clean/Strike"  |
            +------------------+
```

---

## 3. RECORDING SESSION FLOW (Detailed)

### 3.1 Step-by-Step Recording Process

```
+==============================================================================+
|                    DETAILED RECORDING SESSION FLOW                           |
+==============================================================================+

STEP 1: SESSION INITIATION
==========================
+------------------+
|  User on         |
|  Dashboard       |
+--------+---------+
         |
         | Tap "New Session" or "+" button
         v
+------------------+
|  SESSION SETUP   |
|  MODAL           |
|  +-------------+ |
|  | Center:     | |
|  | [Dropdown]  | |
|  |             | |
|  | Lane #:     | |
|  | [1-60]      | |
|  |             | |
|  | Pattern:    | |
|  | [House/Sport| |
|  |  /Short/Long| |
|  +-------------+ |
|                  |
|  [Cancel] [Next] |
+--------+---------+
         |
         v

STEP 2: CALIBRATION CHECK
=========================
+----------------------------------+
|   Check: Calibration exists for  |
|   selected Center + Lane?        |
+--------+----------------+--------+
         |                |
       FOUND          NOT FOUND
         |                |
         v                v
+---------------+  +---------------+
| Load existing |  | Start         |
| calibration   |  | Calibration   |
| profile       |  | Wizard        |
+-------+-------+  | (See Flow 4)  |
        |          +-------+-------+
        |                  |
        +--------+---------+
                 |
                 v

STEP 3: CAMERA INITIALIZATION
=============================
+----------------------------------+
|     CAMERA INITIALIZING...       |
|  +----------------------------+  |
|  |                            |  |
|  |     [Spinner]              |  |
|  |                            |  |
|  |  Initializing 120fps       |  |
|  |  camera...                 |  |
|  |                            |  |
|  +----------------------------+  |
+--------+------------------------++
         |
         | Camera Ready
         v
+----------------------------------+
|      CAMERA POSITION GUIDE       |
|  +----------------------------+  |
|  |  [Live Camera Feed]        |  |
|  |                            |  |
|  |    +--+       Foul Line    |  |
|  |    |  | <-- Camera here    |  |
|  |    +--+     (elevated,     |  |
|  |     /\       behind bowler)|  |
|  |    /  \                    |  |
|  |   /    \                   |  |
|  |  [Lane Preview Overlay]    |  |
|  +----------------------------+  |
|                                  |
|  Instructions:                   |
|  - Place camera behind approach  |
|  - Elevate 5-6 feet high         |
|  - Center on lane                |
|  - Ensure full lane visible      |
|                                  |
|  [Position Looks Good]           |
+--------+-------------------------+
         |
         v

STEP 4: BALL COLOR SAMPLING
===========================
+----------------------------------+
|       BALL COLOR SELECTION       |
|  +----------------------------+  |
|  |  [Live Camera Feed]        |  |
|  |                            |  |
|  |      Tap on your           |  |
|  |      bowling ball          |  |
|  |      to sample color       |  |
|  |                            |  |
|  |          [O] <-- Ball      |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  Selected Ball: [None]           |
|  Color Preview: [ ]              |
|                                  |
|  [Use Saved Ball Profile v]      |
+--------+-------------------------+
         |
         | User taps on ball in frame
         v
+----------------------------------+
|       COLOR CONFIRMED            |
|  +----------------------------+  |
|  |                            |  |
|  |  Color Sampled!            |  |
|  |                            |  |
|  |  [Blue Preview Swatch]     |  |
|  |                            |  |
|  |  HSV: H:220 S:85% V:90%    |  |
|  |  Tolerance: 15             |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  [Resample] [Ready to Record]    |
+--------+-------------------------+
         |
         v

STEP 5: READY STATE
===================
+----------------------------------+
|          READY TO RECORD         |
|  +----------------------------+  |
|  |  [Live Camera Feed]        |  |
|  |                            |  |
|  |  [Ball Tracking Indicator] |  |
|  |     ^                      |  |
|  |     |                      |  |
|  |  Shows detected ball       |  |
|  |  position in real-time     |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  Session: Sunset Lanes, Lane 12  |
|  Ball Color: [Blue Swatch]       |
|  Shots: 0                        |
|                                  |
|  +----------------------------+  |
|  |      [START RECORDING]     |  |
|  +----------------------------+  |
+--------+-------------------------+
         |
         | Tap Start
         v

STEP 6: ACTIVE RECORDING
========================
+==================================+
|        RECORDING ACTIVE          |
|  +----------------------------+  |
|  |  [Live Camera Feed]        |  |
|  |                            |  |
|  |     [Ball Tracking Dot]    |  |
|  |           *                |  |
|  |                            |  |
|  |  +-----------------------+ |  |
|  |  | Speed: --             | |  |
|  |  | Board: --             | |  |
|  |  +-----------------------+ |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  WAITING FOR RELEASE...          |
|  (Ball motion detection active)  |
|                                  |
|  [End Session]                   |
+--------+-------------------------+
         |
         | Ball released (velocity detected)
         v

STEP 7: SHOT TRACKING
=====================
+==================================+
|        TRACKING SHOT #1          |
|  +----------------------------+  |
|  |  [Camera Feed + Overlay]   |  |
|  |                            |  |
|  |     *---*                  |  |
|  |          \                 |  |
|  |           *---*            |  |
|  |                \           |  |
|  |  [Live Trajectory Path]    |  |
|  |                            |  |
|  |  +-----------------------+ |  |
|  |  | Speed: 16.8 mph       | |  |
|  |  | Board: 12.5           | |  |
|  |  +-----------------------+ |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  Tracking ball...                |
+--------+-------------------------+
         |
         | Ball exits frame OR detected pin impact
         v

STEP 8: SHOT COMPLETE
=====================
+----------------------------------+
|         SHOT #1 COMPLETE         |
|  +----------------------------+  |
|  |  [Final Frame / Thumbnail] |  |
|  |                            |  |
|  |  +----------------------+  |  |
|  |  | TRAJECTORY OVERLAY   |  |  |
|  |  | *---*                 |  |  |
|  |  |      \                |  |  |
|  |  |       *---*           |  |  |
|  |  |            \          |  |  |
|  |  |             *-->[Pins]|  |  |
|  |  +----------------------+  |  |
|  +----------------------------+  |
|                                  |
|  METRICS:                        |
|  +----------------------------+  |
|  | Speed:      17.2 mph       |  |
|  | Entry Angle: 5.8 deg   [OK]|  |
|  | Arrow Cross: Board 12      |  |
|  | Breakpoint:  Board 8       |  |
|  | Pocket:      +0.3 boards   |  |
|  | Rev Rate:    342 RPM       |  |
|  | Category:    Tweener       |  |
|  +----------------------------+  |
|                                  |
|  ANALYSIS:                       |
|  +----------------------------+  |
|  | Strike Probability: 82%    |  |
|  | Predicted: Clean strike    |  |
|  +----------------------------+  |
|                                  |
|  [Record Next Shot] [End Session]|
+--------+----------------+--------+
         |                |
         |                |
 "Record Next"       "End Session"
         |                |
         v                v
   (Return to         (Go to Step 9)
    Step 6)
```

### 3.2 Session End Flow

```
STEP 9: SESSION SUMMARY
=======================
+----------------------------------+
|        SESSION COMPLETE          |
+----------------------------------+
|                                  |
|  Sunset Lanes - Lane 12          |
|  December 31, 2025               |
|  Pattern: House                  |
|                                  |
+----------------------------------+
|  SESSION STATISTICS              |
|  +----------------------------+  |
|  | Total Shots:      24       |  |
|  | Avg Speed:        16.8 mph |  |
|  | Avg Entry Angle:  5.4 deg  |  |
|  | Avg Rev Rate:     338 RPM  |  |
|  | Strike Prob Avg:  71%      |  |
|  +----------------------------+  |
|                                  |
|  SHOTS BREAKDOWN:                |
|  +----------------------------+  |
|  | Shot | Speed | Angle | Prob|  |
|  |------|-------|-------|-----|  |
|  |   1  | 17.2  |  5.8  | 82% |  |
|  |   2  | 16.5  |  5.2  | 75% |  |
|  |   3  | 16.9  |  6.1  | 79% |  |
|  |  ... | ...   |  ...  | ... |  |
|  +----------------------------+  |
|                                  |
|  TRENDS:                         |
|  [Speed Trend Chart]             |
|  [Entry Angle Chart]             |
|                                  |
|  [Save & Exit]    [Add Notes]    |
+--------+-------------------------+
         |
         | Tap "Save & Exit"
         v
+----------------------------------+
|  SAVING TO DATABASE...           |
|  +----------------------------+  |
|  | Saving session...          |  |
|  | Saving 24 shots...         |  |
|  | Generating thumbnails...   |  |
|  +----------------------------+  |
+--------+-------------------------+
         |
         v
+----------------------------------+
|        SESSION SAVED             |
|                                  |
|  Your session has been saved.    |
|                                  |
|  [View Session]  [Back to Home]  |
+----------------------------------+
```

---

## 4. CALIBRATION FLOW (Detailed)

### 4.1 Calibration Wizard Step-by-Step

```
+==============================================================================+
|                    LANE CALIBRATION WIZARD                                   |
+==============================================================================+

STEP 1: INTRODUCTION
====================
+----------------------------------+
|      LANE CALIBRATION            |
|                                  |
|  +----------------------------+  |
|  |  [Lane Diagram]            |  |
|  |                            |  |
|  |  60 ft ----------------+   |  |
|  |     |                  |   |  |
|  |  Arrows (15ft)     Pins    |  |
|  |     |      ^           ^   |  |
|  |     v      |           |   |  |
|  |  Foul Line              |  |  |
|  |     |                      |  |
|  |  Camera                    |  |
|  +----------------------------+  |
|                                  |
|  This wizard will calibrate      |
|  the camera view to real-world   |
|  lane dimensions.                |
|                                  |
|  You will need:                  |
|  - Clear view of arrows          |
|  - Visible foul line             |
|                                  |
|  [Cancel]            [Start]     |
+--------+-------------------------+
         |
         v

STEP 2: CAMERA POSITIONING
==========================
+----------------------------------+
|    STEP 1/4: POSITION CAMERA     |
|  +----------------------------+  |
|  |  [Live Camera Feed]        |  |
|  |                            |  |
|  |  +--------------------+    |  |
|  |  |                    |    |  |
|  |  |   POSITION GUIDE   |    |  |
|  |  |                    |    |  |
|  |  |    +--+            |    |  |
|  |  |    |OK|            |    |  |
|  |  |    +--+            |    |  |
|  |  +--------------------+    |  |
|  +----------------------------+  |
|                                  |
|  Position Requirements:          |
|  [X] Foul line visible           |
|  [X] Arrows visible              |
|  [ ] Lane centered               |
|  [ ] Camera stable               |
|                                  |
|  [Back]        [Position Good]   |
+--------+-------------------------+
         |
         | All checks pass
         v

STEP 3: MARK ARROW 1 (LEFT)
===========================
+----------------------------------+
|   STEP 2/4: TAP LEFT ARROW       |
|  +----------------------------+  |
|  |  [Live Camera Feed]        |  |
|  |                            |  |
|  |       Arrows Row           |  |
|  |       v                    |  |
|  |    [<] * * * * * * * [>]   |  |
|  |     ^                      |  |
|  |     |                      |  |
|  |   Tap here (Board 10)      |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  Instructions:                   |
|  Tap on the SECOND arrow from    |
|  the LEFT gutter (Board 10).     |
|                                  |
|  This arrow is 10 boards from    |
|  the right edge (for righties).  |
|                                  |
|  [Back]                          |
+--------+-------------------------+
         |
         | User taps arrow
         v
+----------------------------------+
|   ARROW 1 MARKED                 |
|  +----------------------------+  |
|  |  [Camera Feed]             |  |
|  |                            |  |
|  |       [X] <-- Marked       |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  Arrow 1 Position:               |
|  Pixel: (245, 380)               |
|  Board: 10                       |
|                                  |
|  [Redo]              [Next]      |
+--------+-------------------------+
         |
         v

STEP 4: MARK ARROW 2 (RIGHT)
============================
+----------------------------------+
|   STEP 3/4: TAP RIGHT ARROW      |
|  +----------------------------+  |
|  |  [Camera Feed]             |  |
|  |                            |  |
|  |    [X]       [?]           |  |
|  |     ^         ^            |  |
|  |     |         |            |  |
|  |  Arrow 1   Tap here        |  |
|  |  (done)    (Board 25)      |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  Instructions:                   |
|  Tap on the THIRD arrow from     |
|  the RIGHT gutter (Board 25).    |
|                                  |
|  This gives us 15 boards of      |
|  reference distance.             |
|                                  |
|  [Back]                          |
+--------+-------------------------+
         |
         | User taps arrow
         v
+----------------------------------+
|   BOTH ARROWS MARKED             |
|  +----------------------------+  |
|  |  [Camera Feed]             |  |
|  |                            |  |
|  |    [X]<---->[X]            |  |
|  |         15 boards          |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  Arrow 1: (245, 380) - Board 10  |
|  Arrow 2: (495, 375) - Board 25  |
|                                  |
|  Calculated:                     |
|  Pixel Distance: 250.5 px        |
|  Board Distance: 15 boards       |
|  >> PIXELS PER BOARD: 16.7 px    |
|                                  |
|  [Redo]              [Next]      |
+--------+-------------------------+
         |
         v

STEP 5: MARK FOUL LINE
======================
+----------------------------------+
|   STEP 4/4: TAP FOUL LINE        |
|  +----------------------------+  |
|  |  [Camera Feed]             |  |
|  |                            |  |
|  |    [X]       [X] Arrows    |  |
|  |                            |  |
|  |                            |  |
|  |                            |  |
|  |  =====================     |  |
|  |  ^                         |  |
|  |  Tap anywhere on foul line |  |
|  +----------------------------+  |
|                                  |
|  Instructions:                   |
|  Tap anywhere along the          |
|  FOUL LINE (the black line       |
|  at the start of the lane).      |
|                                  |
|  [Back]                          |
+--------+-------------------------+
         |
         | User taps foul line
         v

STEP 6: VALIDATION & CALCULATION
================================
+----------------------------------+
|   CALCULATING CALIBRATION...     |
|  +----------------------------+  |
|  |                            |  |
|  |    [X]       [X] Arrows    |  |
|  |         (y=375)            |  |
|  |                            |  |
|  |    15 ft distance          |  |
|  |         |                  |  |
|  |         v                  |  |
|  |  [========] Foul Line      |  |
|  |    (y=620)                 |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  CALCULATING...                  |
|                                  |
|  Arrow Y:      375 px            |
|  Foul Line Y:  620 px            |
|  Y Distance:   245 px            |
|  Real Distance: 15 ft            |
|                                  |
|  >> PIXELS PER FOOT: 16.3 px     |
|  >> PIXELS PER BOARD: 16.7 px    |
|                                  |
+--------+-------------------------+
         |
         v

STEP 7: VALIDATION
==================
+----------------------------------+
|   CALIBRATION VALIDATION         |
|  +----------------------------+  |
|  |  [Camera Feed with Grid]   |  |
|  |                            |  |
|  |  |  |  |  |  |  |  |  |    |  |
|  |  5 10 15 20 25 30 35       |  |
|  |  Boards                    |  |
|  |  ________________________  |  |
|  |  |  |  |  |  |  |         |  |
|  |  15 30 45 60              |  |
|  |  Feet                      |  |
|  +----------------------------+  |
|                                  |
|  VALIDATION:                     |
|  [X] Lane width matches (39 bd)  |
|  [X] Distance looks accurate     |
|  [X] Grid aligns with arrows     |
|                                  |
|  Does this grid look correct?    |
|                                  |
|  [Redo Calibration]  [Confirm]   |
+--------+-------------------------+
         |
         v

STEP 8: SAVE PROFILE
====================
+----------------------------------+
|   SAVE CALIBRATION PROFILE       |
|                                  |
|  Center Name:                    |
|  [Sunset Lanes_____________]     |
|                                  |
|  Lane Number:                    |
|  [12________________________]    |
|                                  |
|  Camera Height (optional):       |
|  [6 feet____________________]    |
|                                  |
|  CALIBRATION VALUES:             |
|  +----------------------------+  |
|  | Pixels per Board:   16.7   |  |
|  | Pixels per Foot:    16.3   |  |
|  | Foul Line Y:        620    |  |
|  | Arrows Y:           375    |  |
|  +----------------------------+  |
|                                  |
|  [Cancel]            [Save]      |
+--------+-------------------------+
         |
         | User taps Save
         v
+----------------------------------+
|   CALIBRATION SAVED!             |
|                                  |
|  Profile "Sunset Lanes - Lane 12"|
|  has been saved successfully.    |
|                                  |
|  This calibration will be        |
|  automatically loaded when you   |
|  record on this lane.            |
|                                  |
|  [Done]                          |
+----------------------------------+
```

### 4.2 Calibration Decision Flow

```
+------------------------------------------------------------------------------+
|                    CALIBRATION DECISION TREE                                 |
+------------------------------------------------------------------------------+

                    +------------------+
                    |  Start Recording |
                    |  Session         |
                    +--------+---------+
                             |
                             v
                    +------------------+
                    |  User selects    |
                    |  Center + Lane   |
                    +--------+---------+
                             |
                             v
              +-----------------------------+
              |  Query SQLite:              |
              |  SELECT * FROM calibrations |
              |  WHERE center_id = ?        |
              |  AND lane_number = ?        |
              +------+----------------+-----+
                     |                |
                Found (1+ rows)   Not Found (0 rows)
                     |                |
                     v                v
              +-----------+    +--------------+
              |  Multiple |    |  Show        |
              |  matches? |    |  Calibration |
              +--+-----+--+    |  Required    |
                 |     |       |  Modal       |
              NO |     | YES   +------+-------+
                 |     |              |
                 v     v              v
         +--------+ +--------+  +-------------+
         |  Use   | |  Show  |  | "No calib   |
         |  only  | |  picker|  |  found for  |
         |  match | |  modal |  |  this lane" |
         +---+----+ +---+----+  +------+------+
             |          |              |
             |          v              v
             |    +-----------+   +-------------+
             |    | User picks|   | [Calibrate] |
             |    | profile   |   | [Skip]      |
             |    +-----------+   +------+------+
             |          |              |     |
             +-----+----+       "Calibrate"  "Skip"
                   |                   |       |
                   v                   v       v
           +---------------+    +----------+ +----------+
           | Load          |    | Launch   | | Use      |
           | Calibration   |    | Wizard   | | Default  |
           | Profile       |    | (Flow 4) | | Estimate |
           +-------+-------+    +----+-----+ +----+-----+
                   |                 |            |
                   +-----------------+------------+
                             |
                             v
                    +------------------+
                    | Calibration      |
                    | Applied          |
                    +--------+---------+
                             |
                             v
                    +------------------+
                    | Continue to      |
                    | Camera Setup     |
                    +------------------+
```

---

## 5. STATE MANAGEMENT FLOW

### 5.1 Zustand Store Architecture

```
+==============================================================================+
|                         ZUSTAND STATE ARCHITECTURE                           |
+==============================================================================+

+----------------------+    +----------------------+    +----------------------+
|   SESSION STORE      |    |   SETTINGS STORE     |    |  CALIBRATION STORE   |
+----------------------+    +----------------------+    +----------------------+
|                      |    |                      |    |                      |
| State:               |    | State:               |    | State:               |
| - activeSession      |    | - handPreference     |    | - calibrations[]     |
| - currentShot        |    | - units              |    | - activeCalibration  |
| - shots[]            |    | - ballProfiles[]     |    | - isCalibrating      |
| - isRecording        |    | - lastCenterId       |    |                      |
| - trackingState      |    |                      |    |                      |
|                      |    |                      |    |                      |
| Actions:             |    | Actions:             |    | Actions:             |
| - startSession()     |    | - setHand()          |    | - loadCalibrations() |
| - endSession()       |    | - setUnits()         |    | - saveCalibration()  |
| - addShot()          |    | - addBallProfile()   |    | - deleteCalibration()|
| - updateMetrics()    |    | - updateBallProfile()|    | - setActive()        |
| - setRecording()     |    | - deleteBallProfile()|    |                      |
+----------+-----------+    +----------+-----------+    +----------+-----------+
           |                           |                           |
           +-----------+---------------+-----------+---------------+
                       |                           |
                       v                           v
              +------------------+        +------------------+
              |  React Components|        |  SQLite Database |
              |  (Subscribers)   |        |  (Persistence)   |
              +------------------+        +------------------+


DATA FLOW:

  User Action                Store Update               UI Update
  ===========                ============               =========

+-------------+           +---------------+           +-------------+
| Tap "Start" |---------->| setRecording  |---------->| Camera View |
| Recording   |           | (true)        |           | Shows HUD   |
+-------------+           +---------------+           +-------------+

+-------------+           +---------------+           +-------------+
| Ball        |---------->| updateMetrics |---------->| Metrics     |
| Detected    |           | ({speed: 17}) |           | Display     |
+-------------+           +---------------+           +-------------+

+-------------+           +---------------+           +-------------+
| Shot        |---------->| addShot(data) |---------->| Shot List   |
| Complete    |           |               |           | Updates     |
+-------------+           +----+----------+           +-------------+
                               |
                               v
                          +---------------+
                          | SQLite INSERT |
                          | (async)       |
                          +---------------+
```

---

## 6. ERROR HANDLING FLOWS

### 6.1 Camera Permission Denied

```
+------------------+
|  Permission      |
|  Denied          |
+--------+---------+
         |
         v
+----------------------------------+
|      CAMERA ACCESS REQUIRED      |
|                                  |
|  BowlerTrax needs camera access  |
|  to track your bowling shots.    |
|                                  |
|  Please enable camera access     |
|  in your device settings:        |
|                                  |
|  Settings > BowlerTrax > Camera  |
|                                  |
|  [Open Settings]  [Try Again]    |
+----------------------------------+
```

### 6.2 Ball Detection Failed

```
+----------------------------------+
|  DETECTION WARNING               |
|                                  |
|  Having trouble detecting your   |
|  ball. Try these steps:          |
|                                  |
|  1. Ensure good lighting         |
|  2. Use a brightly colored ball  |
|  3. Resample the ball color      |
|  4. Avoid similar colored        |
|     backgrounds                  |
|                                  |
|  [Resample Color] [Continue]     |
+----------------------------------+
```

### 6.3 Calibration Mismatch

```
+----------------------------------+
|  CALIBRATION WARNING             |
|                                  |
|  The current camera position     |
|  doesn't match the saved         |
|  calibration profile.            |
|                                  |
|  Expected foul line at y=620     |
|  Current detection at y=580      |
|                                  |
|  [Recalibrate] [Use Anyway]      |
+----------------------------------+
```

---

## 7. DATA PERSISTENCE FLOW

### 7.1 SQLite Write Operations

```
+------------------------------------------------------------------------------+
|                         DATABASE WRITE FLOW                                  |
+------------------------------------------------------------------------------+

  SHOT COMPLETION
        |
        v
+------------------+
|  Shot Metrics    |
|  Calculated      |
+--------+---------+
         |
         v
+------------------+
|  Create Shot     |
|  Object          |
|  {               |
|    id: uuid(),   |
|    session_id,   |
|    speed_mph,    |
|    entry_angle,  |
|    trajectory,   |
|    ...           |
|  }               |
+--------+---------+
         |
         v
+------------------+     +------------------+
|  Zustand Store   |---->|  UI Updates      |
|  addShot()       |     |  (Immediate)     |
+--------+---------+     +------------------+
         |
         | (async, non-blocking)
         v
+------------------+
|  SQLite          |
|  INSERT INTO     |
|  shots (...)     |
|  VALUES (...)    |
+--------+---------+
         |
         +---> Success: Log confirmation
         |
         +---> Error: Queue for retry, show toast
```

### 7.2 Session Resume Flow

```
+------------------+
|  App Launched    |
+--------+---------+
         |
         v
+------------------+
|  Check for       |
|  Incomplete      |
|  Session         |
+--------+---------+
         |
         v
+-----------------------------+
|  SELECT * FROM sessions     |
|  WHERE completed = false    |
|  AND date = today           |
+------+----------------+-----+
       |                |
    FOUND           NOT FOUND
       |                |
       v                v
+---------------+  +---------------+
|  RESUME       |  |  Normal       |
|  SESSION?     |  |  Dashboard    |
|  Modal        |  +---------------+
+-------+-------+
        |
   +----+----+
   |         |
  YES        NO
   |         |
   v         v
+------+ +------+
|Resume| |Delete|
|Flow  | |& New |
+------+ +------+
```

---

This document provides comprehensive flow diagrams for all major user interactions, data processing pipelines, and state management in the BowlerTrax application.
