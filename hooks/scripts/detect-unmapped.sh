#!/bin/bash
# SessionStart hook: detect unmapped or stale architecture maps

MAP_FILE="docs/architecture.html"

if [ ! -f "$MAP_FILE" ]; then
  echo "No architecture map found. Run /archmap to generate an interactive codebase visualization."
  exit 0
fi

# Check if map is stale (older than any source file)
MAP_MTIME=$(stat -c %Y "$MAP_FILE" 2>/dev/null || stat -f %m "$MAP_FILE" 2>/dev/null)

if [ -z "$MAP_MTIME" ]; then
  exit 0
fi

# Find the most recently modified source file (common extensions)
NEWEST_SOURCE=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.rs" -o -name "*.go" -o -name "*.java" -o -name "*.rb" -o -name "*.cs" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" -o -name "*.swift" -o -name "*.kt" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/vendor/*" -newer "$MAP_FILE" -print -quit 2>/dev/null)

if [ -n "$NEWEST_SOURCE" ]; then
  echo "Architecture map may be stale — source files have been modified since it was generated. Run /archmap:repair to update it."
fi

exit 0
