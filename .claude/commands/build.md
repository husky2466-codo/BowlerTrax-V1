# /build - Build iOS Project

Build the BowlerTrax iOS project using xcodebuild.

## Instructions

1. Navigate to the iOS project directory at `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/ios`

2. First, check if an Xcode workspace exists:
   - If `BowlerTrax.xcworkspace` exists, use it
   - Otherwise, use `BowlerTrax.xcodeproj`

3. Run the build command:
   ```bash
   xcodebuild -workspace BowlerTrax.xcworkspace -scheme BowlerTrax -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1
   ```

   Or if no workspace:
   ```bash
   xcodebuild -project BowlerTrax.xcodeproj -scheme BowlerTrax -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1
   ```

4. If this is an Expo/React Native project, use:
   ```bash
   cd /Volumes/DevDrive/Projects/BowlerTrax-V1/mobile && npx expo run:ios --no-install
   ```

5. Report results:
   - Show build duration
   - Report BUILD SUCCEEDED or BUILD FAILED
   - If failed, show relevant error messages
   - List any warnings if present

## Output Format

```
Building BowlerTrax...
Configuration: Debug
Target: iOS Simulator

[Build output summary]

Result: BUILD SUCCEEDED
Duration: X minutes Y seconds
```

## Notes

- For React Native/Expo projects, the iOS folder may need to be generated first with `npx expo prebuild`
- If pod install is needed, run `cd ios && pod install` first
