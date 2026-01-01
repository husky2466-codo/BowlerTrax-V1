#!/bin/bash
# Pre-Bash Hook for Xcode safety
# Warns if about to build release configuration accidentally

# Get the command from environment (passed by Claude hooks)
COMMAND="${CLAUDE_TOOL_INPUT_COMMAND:-}"

# Exit early if no command
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Check if this is an xcodebuild command
if [[ ! "$COMMAND" == *xcodebuild* ]]; then
    exit 0
fi

# Check for release configuration warnings
if [[ "$COMMAND" == *"-configuration Release"* ]] || [[ "$COMMAND" == *"-configuration=Release"* ]]; then
    echo ""
    echo "=========================================="
    echo "[HOOK WARNING] Release Build Detected!"
    echo "=========================================="
    echo "You are about to run an xcodebuild with Release configuration."
    echo "This may take longer and produce optimized code without debug symbols."
    echo ""
    echo "Command: $COMMAND"
    echo ""
    echo "If this is intentional (e.g., for App Store), proceed."
    echo "For development, consider using Debug configuration."
    echo "=========================================="
    echo ""
fi

# Check for archive command (typically for distribution)
if [[ "$COMMAND" == *"archive"* ]]; then
    echo ""
    echo "=========================================="
    echo "[HOOK INFO] Archive Build Detected"
    echo "=========================================="
    echo "You are creating an archive, typically for App Store or TestFlight."
    echo "Ensure signing certificates and provisioning profiles are configured."
    echo "=========================================="
    echo ""
fi

# Check for clean build (can be slow)
if [[ "$COMMAND" == *"clean"* ]] && [[ "$COMMAND" == *"build"* ]]; then
    echo "[HOOK INFO] Clean build requested - this will take longer than incremental build"
fi

exit 0
