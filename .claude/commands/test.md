# /test - Run Test Suite

Run the XCTest suite for BowlerTrax and display results.

## Instructions

1. For Expo/React Native projects, check for Jest tests:
   ```bash
   cd /Volumes/DevDrive/Projects/BowlerTrax-V1/mobile

   # Check if Jest is configured
   if [ -f "jest.config.js" ] || grep -q '"jest"' package.json; then
     npm test
   fi
   ```

2. For native iOS projects with XCTest:
   ```bash
   xcodebuild test \
     -workspace BowlerTrax.xcworkspace \
     -scheme BowlerTrax \
     -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
     -resultBundlePath TestResults.xcresult \
     2>&1
   ```

3. Parse and summarize results:
   - Total tests run
   - Tests passed
   - Tests failed
   - Tests skipped
   - Duration

4. For failures, show:
   - Test name
   - Failure reason
   - File and line number
   - Relevant assertion message

5. Check for test files:
   ```bash
   find /Volumes/DevDrive/Projects/BowlerTrax-V1 -name "*Test*.swift" -o -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" 2>/dev/null
   ```

## Output Format

```
Running BowlerTrax Tests...

Test Suite: BowlerTraxTests
---------------------------
[OK] testBallDetection - 0.15s
[OK] testTrajectoryCalculation - 0.08s
[FAIL] testEntryAngleComputation - 0.12s
[OK] testSpeedCalculation - 0.05s

FAILURES:
---------
testEntryAngleComputation (BallPhysicsTests.swift:45)
  Expected: 6.0
  Actual: 5.8
  Message: Entry angle calculation off by 0.2 degrees

SUMMARY:
--------
Total: 4 tests
Passed: 3
Failed: 1
Skipped: 0
Duration: 0.40s

Result: TESTS FAILED
```

## Arguments

- `--filter <pattern>`: Run only tests matching pattern
- `--verbose` or `-v`: Show all test output
- `--coverage`: Generate code coverage report
