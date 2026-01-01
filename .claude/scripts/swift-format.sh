#!/bin/bash
# Post-Edit Hook for Swift formatting
# Runs swiftformat on edited Swift files if installed

# Get the file path from environment (passed by Claude hooks)
FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

# Exit early if no file path or not a Swift file
if [[ -z "$FILE_PATH" ]] || [[ ! "$FILE_PATH" == *.swift ]]; then
    exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Check if swiftformat is installed
if command -v swiftformat &> /dev/null; then
    echo "[HOOK] Running swiftformat on: $(basename "$FILE_PATH")"
    swiftformat "$FILE_PATH" --quiet

    if [[ $? -eq 0 ]]; then
        echo "[HOOK] Swift formatting complete"
    else
        echo "[HOOK] Warning: swiftformat encountered issues"
    fi
else
    # Try homebrew path on macOS
    if [[ -x "/opt/homebrew/bin/swiftformat" ]]; then
        /opt/homebrew/bin/swiftformat "$FILE_PATH" --quiet
        echo "[HOOK] Swift formatting complete (homebrew)"
    elif [[ -x "/usr/local/bin/swiftformat" ]]; then
        /usr/local/bin/swiftformat "$FILE_PATH" --quiet
        echo "[HOOK] Swift formatting complete (usr/local)"
    else
        echo "[HOOK] Note: swiftformat not installed - skipping auto-format"
        echo "[HOOK] Install with: brew install swiftformat"
    fi
fi

exit 0
