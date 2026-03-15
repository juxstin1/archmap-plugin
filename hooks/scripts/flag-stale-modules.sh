#!/bin/bash
# PostToolUse hook: flag when edited files are part of a mapped architecture
# Receives the tool input file path as $1

MAP_FILE="docs/architecture.html"
TOOL_INPUT="$1"

# Only proceed if a map exists
if [ ! -f "$MAP_FILE" ]; then
  exit 0
fi

# Only proceed if we got a file path argument
if [ -z "$TOOL_INPUT" ]; then
  exit 0
fi

# Extract the file path from the tool input (handles Write and Edit tools)
EDITED_FILE=$(grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' "$TOOL_INPUT" 2>/dev/null | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')

if [ -z "$EDITED_FILE" ]; then
  exit 0
fi

# Normalize path — strip leading ./ and make relative
EDITED_FILE=$(echo "$EDITED_FILE" | sed 's|^\./||')

# Check if this file path appears in the architecture map
if grep -q "$EDITED_FILE" "$MAP_FILE" 2>/dev/null; then
  echo "Edited file may be part of a mapped architecture module. Run /archmap:focus or /archmap:repair to keep the map current."
fi

exit 0
