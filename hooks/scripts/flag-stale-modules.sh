#!/usr/bin/env bash
# PostToolUse hook: when a user edits a file that already appears in the
# architecture map, remind them to refresh the map.
#
# Input contract (per Claude Code hook spec): the hook payload arrives
# on STDIN as JSON. We read the file path via jq when available, or a
# conservative regex fallback when it isn't. No CLI arguments are used.

set -euo pipefail

# ── Read stdin payload (never block if no stdin is attached) ─────────
if [ -t 0 ]; then
  PAYLOAD=""
else
  PAYLOAD=$(cat 2>/dev/null || true)
fi

# No payload, nothing to do.
if [ -z "$PAYLOAD" ]; then
  exit 0
fi

# ── Extract the edited file path ─────────────────────────────────────
EDITED_FILE=""
if command -v jq >/dev/null 2>&1; then
  EDITED_FILE=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)
fi

# jq-less fallback: pull the first JSON "file_path" or "path" field.
# This is only used when jq is missing; it handles simple cases and
# silently no-ops on anything exotic (escaped quotes, nested objects).
if [ -z "$EDITED_FILE" ]; then
  EDITED_FILE=$(printf '%s' "$PAYLOAD" \
    | grep -oE '"(file_path|path)"[[:space:]]*:[[:space:]]*"[^"\\]*"' \
    | head -n1 \
    | sed -E 's/.*"(file_path|path)"[[:space:]]*:[[:space:]]*"([^"]*)".*/\2/' \
    || true)
fi

if [ -z "$EDITED_FILE" ]; then
  exit 0
fi

# ── Resolve the map path (honour .archmap.json output.html override) ─
MAP_FILE="docs/architecture.html"
if [ -f ".archmap.json" ] && command -v jq >/dev/null 2>&1; then
  CONFIG_MAP=$(jq -r '.output.html // empty' .archmap.json 2>/dev/null || true)
  if [ -n "$CONFIG_MAP" ]; then
    MAP_FILE="$CONFIG_MAP"
  fi
fi

if [ ! -f "$MAP_FILE" ]; then
  exit 0
fi

# Skip hook noise when the user is editing the map itself.
case "$EDITED_FILE" in
  *"$MAP_FILE"|"$MAP_FILE") exit 0 ;;
esac

# ── Normalize the edited path ────────────────────────────────────────
# Strip a repo-root absolute prefix if present, leading ./, and trailing /
case "$EDITED_FILE" in
  "$PWD"/*) EDITED_FILE="${EDITED_FILE#"$PWD"/}" ;;
esac
EDITED_FILE="${EDITED_FILE#./}"
EDITED_FILE="${EDITED_FILE%/}"

# Also keep the basename as a secondary search term — module maps often
# record a short path, not the full repo-relative one.
EDITED_BASE="${EDITED_FILE##*/}"

# ── Check the map's modules block for the file path ──────────────────
# Scope the search to the modules JSON array so we don't false-match
# paths appearing in comments, CSS, or theme definitions. The template
# writes modules between a stable anchor comment and the next anchor.
MODULES_BLOCK=$(awk '
  /── Project Data/ { in_block = 1 }
  in_block { print }
  in_block && /── Theme Engine/ { exit }
' "$MAP_FILE" 2>/dev/null || true)

if [ -z "$MODULES_BLOCK" ]; then
  # Fallback: search whole file if the anchor comment format changed.
  MODULES_BLOCK=$(cat "$MAP_FILE")
fi

# grep -F treats the needle as a literal string (no regex metachars).
# -- guards against paths starting with a dash.
if printf '%s' "$MODULES_BLOCK" | grep -Fq -- "$EDITED_FILE" \
|| { [ -n "$EDITED_BASE" ] && [ "$EDITED_BASE" != "$EDITED_FILE" ] \
     && printf '%s' "$MODULES_BLOCK" | grep -Fq -- "$EDITED_BASE"; }
then
  echo "Edited file may be part of a mapped architecture module. Run /archmap:focus or /archmap:repair to keep the map current."
fi

exit 0
