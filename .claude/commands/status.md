# /status - Project Status Overview

Show comprehensive status of the BowlerTrax project including build status, devices, and recent changes.

## Instructions

1. **Check Git Status**
   ```bash
   cd /Volumes/DevDrive/Projects/BowlerTrax-V1
   git status --short
   git log --oneline -5
   ```

2. **Check Project Build Status**

   For React Native/Expo:
   ```bash
   cd /Volumes/DevDrive/Projects/BowlerTrax-V1/mobile

   # Check if node_modules exists
   [ -d "node_modules" ] && echo "Dependencies: Installed" || echo "Dependencies: Not installed (run npm install)"

   # Check TypeScript
   npx tsc --noEmit 2>&1 | tail -20
   ```

   For Native iOS:
   ```bash
   # Check for build artifacts
   ls -la /Volumes/DevDrive/Projects/BowlerTrax-V1/ios/build/ 2>/dev/null || echo "No build artifacts found"
   ```

3. **List Available Simulators**
   ```bash
   xcrun simctl list devices available | grep -E "(iPad|iPhone)" | head -15
   ```

4. **Check Connected Devices**
   ```bash
   xcrun xctrace list devices 2>/dev/null | grep -v "^==" | head -10
   ```

5. **Check Running Processes**
   ```bash
   # Check if Metro bundler is running
   pgrep -f "metro" > /dev/null && echo "Metro: Running" || echo "Metro: Not running"

   # Check if Simulator is open
   pgrep -f "Simulator" > /dev/null && echo "Simulator: Open" || echo "Simulator: Closed"
   ```

6. **Check Project Health**
   - Verify key files exist
   - Check for common issues (outdated deps, missing configs)
   - Verify iOS provisioning (if applicable)

## Output Format

```
=== BowlerTrax Project Status ===

Git Status:
-----------
Branch: main
Clean: Yes/No
Uncommitted changes:
  M  app/(tabs)/index.tsx
  ?? stores/newStore.ts

Recent Commits:
  abc1234 Add ball tracking algorithm
  def5678 Fix calibration UI
  ghi9012 Update lane dimensions

Build Status:
-------------
Dependencies: Installed
TypeScript: No errors / X errors found
Last Build: [timestamp or "Never"]

Devices:
--------
Simulators (Available):
  - iPad Pro 13-inch (M4) [Booted]
  - iPad Air (5th generation)
  - iPhone 16 Pro

Physical Devices:
  - [None connected]

Services:
---------
Metro Bundler: Running on port 8081 / Not running
iOS Simulator: Open / Closed

Project Health:
---------------
[OK] package.json exists
[OK] node_modules installed
[OK] TypeScript configured
[WARN] No tests found
[OK] Expo config valid
```

## Arguments

- `--git`: Show only git status
- `--build`: Show only build status
- `--devices`: Show only device info
- `--health`: Run health checks only
- `--verbose` or `-v`: Show detailed output

## Usage

```
/status           # Full status report
/status --git     # Git status only
/status --devices # Available devices only
/status --health  # Project health checks
```

## Health Checks

The following are verified:
- [ ] package.json exists and is valid
- [ ] node_modules directory exists
- [ ] TypeScript compiles without errors
- [ ] Required Expo packages installed
- [ ] iOS directory exists (if native)
- [ ] Pods installed (if native iOS)
- [ ] Environment variables set (.env)
- [ ] Xcode command line tools installed

## Notes

- Run this command to get quick overview before starting work
- Helps identify issues before attempting to build or run
- Use `--verbose` for debugging build issues
