#!/bin/bash
# Post-Bash Hook for build notifications
# Plays sound or shows notification when xcodebuild completes

# Get the command and exit code from environment (passed by Claude hooks)
COMMAND="${CLAUDE_TOOL_INPUT_COMMAND:-}"
EXIT_CODE="${CLAUDE_TOOL_EXIT_CODE:-0}"

# Exit early if no command
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Check if this was an xcodebuild command
if [[ ! "$COMMAND" == *xcodebuild* ]]; then
    exit 0
fi

# Determine build result
if [[ "$EXIT_CODE" == "0" ]]; then
    STATUS="SUCCESS"
    SOUND="Glass"
    MESSAGE="Xcode build completed successfully!"
else
    STATUS="FAILED"
    SOUND="Basso"
    MESSAGE="Xcode build failed with exit code $EXIT_CODE"
fi

echo ""
echo "=========================================="
echo "[HOOK] Build $STATUS"
echo "=========================================="
echo "$MESSAGE"
echo "=========================================="
echo ""

# macOS notification (if osascript available)
if command -v osascript &> /dev/null; then
    # Play system sound
    osascript -e "do shell script \"afplay /System/Library/Sounds/${SOUND}.aiff &\"" 2>/dev/null

    # Show notification
    osascript -e "display notification \"$MESSAGE\" with title \"BowlerTrax Build\" sound name \"$SOUND\"" 2>/dev/null
fi

# Log build completion
LOG_DIR="/Volumes/DevDrive/Projects/BowlerTrax-V1/.claude/logs"
mkdir -p "$LOG_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build $STATUS - Exit code: $EXIT_CODE" >> "$LOG_DIR/build-history.log"

exit 0
