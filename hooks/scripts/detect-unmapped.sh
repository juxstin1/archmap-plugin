#!/usr/bin/env bash
# SessionStart hook: detect missing or stale architecture maps.
#
# - If no map exists, nudge the user to run /archmap:generate.
# - If the map is older than the newest source file, nudge /archmap:repair.
# - Silently skip if the user has opted out via .archmap.json.
#
# Designed to finish well under the 10s hook budget even on large repos:
# uses `git ls-files` when available (respects .gitignore for free) and
# falls back to a depth-capped `find`. Exits 0 on every failure path so
# a broken hook can never block a session.

set -euo pipefail

# ── Config: honour .archmap.json ──────────────────────────────────────
MAP_FILE="docs/architecture.html"
SESSION_START_ENABLED="true"

if [ -f ".archmap.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    CFG_MAP=$(jq -r '.output.html // empty' .archmap.json 2>/dev/null || true)
    [ -n "$CFG_MAP" ] && MAP_FILE="$CFG_MAP"

    # Opt-out path: { "hooks": { "sessionStart": false } }
    # Note: do NOT use `// empty` here — jq's // operator treats false
    # as missing, which would make the opt-out unreachable.
    CFG_SS=$(jq -r '.hooks.sessionStart' .archmap.json 2>/dev/null || true)
    if [ "$CFG_SS" = "false" ]; then
      SESSION_START_ENABLED="false"
    fi
  else
    # jq-less fallback for the opt-out flag only — good enough to let
    # users silence the nag without installing jq.
    if grep -qE '"sessionStart"[[:space:]]*:[[:space:]]*false' .archmap.json 2>/dev/null; then
      SESSION_START_ENABLED="false"
    fi
  fi
fi

if [ "$SESSION_START_ENABLED" = "false" ]; then
  exit 0
fi

# ── No map yet: nudge generation ──────────────────────────────────────
if [ ! -f "$MAP_FILE" ]; then
  echo "No architecture map found. Run /archmap:generate to generate an interactive codebase visualization."
  exit 0
fi

# ── Map mtime ─────────────────────────────────────────────────────────
# GNU stat uses -c, BSD/macOS stat uses -f. Probe once.
map_mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo ""
}

MAP_MTIME=$(map_mtime "$MAP_FILE")
if [ -z "$MAP_MTIME" ]; then
  # Couldn't read the map's mtime — treat as not-stale and exit quietly.
  exit 0
fi

# ── Newest-source check (bounded, never exceeds 10s hook budget) ──────
NEWEST_SOURCE=""

# Preferred path: use git to enumerate tracked files. This skips
# node_modules, .git, build/, dist/, vendor/ for free via .gitignore.
IN_GIT_REPO="false"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IN_GIT_REPO="true"
  # Walk up to 2000 tracked files, bail on the first newer one. Using
  # `git ls-files` is fast, respects .gitignore, and skips vendored
  # directories like node_modules for free.
  check_git_staleness() {
    git ls-files 2>/dev/null \
      | grep -E '\.(ts|tsx|js|jsx|mjs|cjs|py|rs|go|java|kt|swift|rb|cs|cpp|cc|c|h|hpp|php|scala|clj|ex|exs|elm|dart|lua|zig|nim|ml|hs|fs|vue|svelte)$' \
      | head -n 2000 \
      | while IFS= read -r f; do
          [ -f "$f" ] || continue
          m=$(map_mtime "$f")
          if [ -n "$m" ] && [ "$m" -gt "$MAP_MTIME" ]; then
            printf '%s\n' "$f"
            return 0
          fi
        done
  }
  NEWEST_SOURCE=$(check_git_staleness 2>/dev/null || true)
fi

# Fallback: depth-capped find for non-git repos.
if [ -z "$NEWEST_SOURCE" ] && [ "$IN_GIT_REPO" = "false" ]; then
  NEWEST_SOURCE=$(find . -maxdepth 6 -type f \
    \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
    -o -name "*.mjs" -o -name "*.cjs" -o -name "*.py" -o -name "*.rs" \
    -o -name "*.go" -o -name "*.java" -o -name "*.kt" -o -name "*.swift" \
    -o -name "*.rb" -o -name "*.cs" -o -name "*.cpp" -o -name "*.cc" \
    -o -name "*.c" -o -name "*.h" -o -name "*.hpp" -o -name "*.php" \
    -o -name "*.vue" -o -name "*.svelte" \) \
    -not -path "*/node_modules/*" -not -path "*/.git/*" \
    -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/vendor/*" \
    -not -path "*/target/*" -not -path "*/.next/*" -not -path "*/.venv/*" \
    -newer "$MAP_FILE" -print -quit 2>/dev/null || true)
fi

if [ -n "$NEWEST_SOURCE" ]; then
  echo "Architecture map may be stale — source files have been modified since it was generated. Run /archmap:repair to update it."
fi

exit 0
