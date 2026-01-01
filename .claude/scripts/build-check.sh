#!/bin/bash
# Post-Edit Hook for Swift build validation
# Runs quick syntax check with swiftc -parse on Swift files in ios/ directory

# Get the file path from environment (passed by Claude hooks)
FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

# Exit early if no file path or not a Swift file
if [[ -z "$FILE_PATH" ]] || [[ ! "$FILE_PATH" == *.swift ]]; then
    exit 0
fi

# Check if file is in ios/ directory
if [[ ! "$FILE_PATH" == */ios/* ]]; then
    exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Define project root
PROJECT_ROOT="/Volumes/DevDrive/Projects/BowlerTrax-V1"
IOS_DIR="${PROJECT_ROOT}/ios"

# Check if swiftc is available
if ! command -v swiftc &> /dev/null; then
    # Try Xcode toolchain
    SWIFTC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
    if [[ ! -x "$SWIFTC" ]]; then
        echo "[HOOK] Note: swiftc not found - skipping syntax check"
        exit 0
    fi
else
    SWIFTC="swiftc"
fi

echo "[HOOK] Running Swift syntax check on: $(basename "$FILE_PATH")"

# Run syntax parse (no code generation, just parsing)
OUTPUT=$($SWIFTC -parse "$FILE_PATH" 2>&1)
RESULT=$?

if [[ $RESULT -eq 0 ]]; then
    echo "[HOOK] Syntax check passed"
else
    echo "[HOOK] Syntax errors detected:"
    echo "$OUTPUT"
    echo ""
    echo "[HOOK] Please fix the syntax errors before continuing"
fi

exit 0
