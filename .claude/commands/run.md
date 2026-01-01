# /run - Build and Run on Device/Simulator

Build and launch BowlerTrax on an iPad simulator or connected device.

## Instructions

1. First, list available simulators and connected devices:
   ```bash
   xcrun simctl list devices available | head -50
   ```

2. Check for connected physical devices:
   ```bash
   xcrun xctrace list devices 2>/dev/null | grep -i ipad || echo "No physical iPads connected"
   ```

3. Select target (in priority order):
   - Connected physical iPad (if available)
   - iPad Pro 13-inch (M4) simulator
   - Any available iPad simulator
   - iPhone simulator as fallback

4. For Expo/React Native projects:
   ```bash
   cd /Volumes/DevDrive/Projects/BowlerTrax-V1/mobile && npx expo run:ios --device
   ```

   Or for simulator:
   ```bash
   cd /Volumes/DevDrive/Projects/BowlerTrax-V1/mobile && npx expo run:ios
   ```

5. For native Swift projects, build and run:
   ```bash
   xcodebuild -workspace BowlerTrax.xcworkspace -scheme BowlerTrax -configuration Debug -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build

   # Boot simulator if needed
   xcrun simctl boot "iPad Pro 13-inch (M4)" 2>/dev/null || true

   # Install and launch
   xcrun simctl install "iPad Pro 13-inch (M4)" /path/to/build/Products/Debug-iphonesimulator/BowlerTrax.app
   xcrun simctl launch "iPad Pro 13-inch (M4)" com.bowlertrax.app
   ```

6. Open Simulator app to view:
   ```bash
   open -a Simulator
   ```

## Output Format

```
Detecting available targets...

Available Simulators:
- iPad Pro 13-inch (M4) (Booted)
- iPad Air (5th generation)
- iPhone 16 Pro

Connected Devices:
- [None detected]

Selected Target: iPad Pro 13-inch (M4) (Simulator)

Building and launching BowlerTrax...
[Build output]

App launched successfully on iPad Pro 13-inch (M4)
```

## Arguments

- `--device` or `-d`: Force physical device
- `--simulator` or `-s`: Force simulator
- Simulator name: Use specific simulator (e.g., `/run iPad Air`)
