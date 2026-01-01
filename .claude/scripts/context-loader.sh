#!/bin/bash
# Session Start Hook - Context Loader
# Loads project context and checks Xcode/simulator status on session start

PROJECT_ROOT="/Volumes/DevDrive/Projects/BowlerTrax-V1"
IOS_DIR="${PROJECT_ROOT}/ios"

echo ""
echo "========================================================"
echo "  BowlerTrax iOS Development - Session Initialized"
echo "========================================================"
echo ""

# Check Xcode installation
echo "[Context] Checking Xcode..."
if [[ -d "/Applications/Xcode.app" ]]; then
    XCODE_VERSION=$(/usr/bin/xcodebuild -version 2>/dev/null | head -1)
    echo "  Xcode: $XCODE_VERSION"
else
    echo "  WARNING: Xcode not found at /Applications/Xcode.app"
fi

# Check iOS Simulator status
echo ""
echo "[Context] Checking iOS Simulators..."
if command -v xcrun &> /dev/null; then
    BOOTED_SIM=$(xcrun simctl list devices | grep "(Booted)" | head -1)
    if [[ -n "$BOOTED_SIM" ]]; then
        echo "  Active Simulator: $BOOTED_SIM"
    else
        echo "  No simulator currently running"
        echo "  Tip: Open Simulator from Xcode > Open Developer Tool > Simulator"
    fi

    # List available iPhone simulators
    echo ""
    echo "[Context] Available iPhone Simulators:"
    xcrun simctl list devices available | grep "iPhone" | head -5 | while read line; do
        echo "  $line"
    done
else
    echo "  WARNING: xcrun not available"
fi

# Check for iOS project structure
echo ""
echo "[Context] Project Structure..."
if [[ -d "$IOS_DIR" ]]; then
    echo "  iOS directory found: $IOS_DIR"

    # Check for Xcode project or workspace
    XCWORKSPACE=$(find "$IOS_DIR" -maxdepth 2 -name "*.xcworkspace" | head -1)
    XCODEPROJ=$(find "$IOS_DIR" -maxdepth 2 -name "*.xcodeproj" | head -1)

    if [[ -n "$XCWORKSPACE" ]]; then
        echo "  Workspace: $(basename "$XCWORKSPACE")"
    fi
    if [[ -n "$XCODEPROJ" ]]; then
        echo "  Project: $(basename "$XCODEPROJ")"
    fi

    # Count Swift files
    SWIFT_COUNT=$(find "$IOS_DIR" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Swift files: $SWIFT_COUNT"
else
    echo "  iOS directory not yet created at: $IOS_DIR"
    echo "  This is a React Native/Expo project - iOS code is in mobile/ios/"
fi

# Check mobile/ios for Expo/React Native iOS
MOBILE_IOS="${PROJECT_ROOT}/mobile/ios"
if [[ -d "$MOBILE_IOS" ]]; then
    echo ""
    echo "[Context] Expo iOS Directory:"
    echo "  Found at: $MOBILE_IOS"
    MOBILE_SWIFT=$(find "$MOBILE_IOS" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Swift files: $MOBILE_SWIFT"
fi

# Load key project files into context
echo ""
echo "[Context] Key Project Documents:"

if [[ -f "${PROJECT_ROOT}/CLAUDE.md" ]]; then
    echo "  - CLAUDE.md (project instructions)"
fi
if [[ -f "${PROJECT_ROOT}/BowlerTrax-Plan.md" ]]; then
    echo "  - BowlerTrax-Plan.md (implementation plan)"
fi
if [[ -f "${PROJECT_ROOT}/PROGRESS.md" ]]; then
    echo "  - PROGRESS.md (development status)"
fi
if [[ -f "${PROJECT_ROOT}/mobile/CLAUDE.md" ]]; then
    echo "  - mobile/CLAUDE.md (mobile-specific guidance)"
fi

# Check swiftformat availability
echo ""
echo "[Context] Development Tools:"
if command -v swiftformat &> /dev/null; then
    echo "  swiftformat: installed"
else
    echo "  swiftformat: not installed (brew install swiftformat)"
fi

if command -v swiftlint &> /dev/null; then
    echo "  swiftlint: installed"
else
    echo "  swiftlint: not installed (brew install swiftlint)"
fi

echo ""
echo "========================================================"
echo "  Ready for iOS Development!"
echo "========================================================"
echo ""

exit 0
