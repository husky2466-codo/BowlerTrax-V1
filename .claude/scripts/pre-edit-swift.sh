#!/bin/bash
# Pre-Edit Hook for Swift files
# Checks if file exists and creates backup before modifying existing files

# Get the file path from environment (passed by Claude hooks)
FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

# Exit early if no file path or not a Swift file
if [[ -z "$FILE_PATH" ]] || [[ ! "$FILE_PATH" == *.swift ]]; then
    exit 0
fi

# Define backup directory
BACKUP_DIR="/Volumes/DevDrive/Projects/BowlerTrax-V1/.claude/backups"
mkdir -p "$BACKUP_DIR"

# If file exists, create a backup before editing
if [[ -f "$FILE_PATH" ]]; then
    FILENAME=$(basename "$FILE_PATH")
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/${FILENAME%.swift}_${TIMESTAMP}.swift.bak"

    cp "$FILE_PATH" "$BACKUP_FILE"

    # Keep only last 5 backups per file
    ls -t "${BACKUP_DIR}/${FILENAME%.swift}_"*.swift.bak 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null

    echo "[HOOK] Backup created: $BACKUP_FILE"
fi

exit 0
