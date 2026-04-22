#!/usr/bin/env bash
# tests/template-render.sh — verify templates/archmap-template.html
# renders cleanly when every placeholder is substituted.
#
# The existing CI only checks placeholder *names* exist. This test
# substitutes known-good stub values into every {{...}}, then:
#   1. confirms no residual {{...}} markers remain
#   2. extracts each baked JSON variable and validates the blob parses
#
# Catches regressions where the template surrounding a placeholder
# drifts into a shape the generator can't fill without breaking the
# embedded JS (e.g., a stray comma or bracket near an assignment).
set -euo pipefail

TEMPLATE="templates/archmap-template.html"
[ -f "$TEMPLATE" ] || { echo "FAIL: $TEMPLATE missing" >&2; exit 1; }

RENDERED="$(mktemp)"
trap 'rm -f "$RENDERED"' EXIT

sed \
  -e 's|{{PROJECT_NAME}}|test-project|g' \
  -e 's|{{STATS_HTML}}|<span class="stat">test</span>|g' \
  -e 's|{{MODULES_JSON}}|[]|g' \
  -e 's|{{EDGES_JSON}}|[]|g' \
  -e 's|{{TIER_LABELS_JSON}}|[]|g' \
  -e 's|{{PIPELINE_JSON}}|[]|g' \
  -e 's|{{LEGEND_JSON}}|[]|g' \
  -e 's|{{LAYOUT_JSON}}|{}|g' \
  -e 's|{{HISTORY_JSON}}|[]|g' \
  "$TEMPLATE" > "$RENDERED"

if grep -qE '\{\{[A-Z_]+\}\}' "$RENDERED"; then
  echo "FAIL: residual placeholder(s) in rendered template:" >&2
  grep -nE '\{\{[A-Z_]+\}\}' "$RENDERED" | head -5 >&2
  exit 1
fi

# Each of these 7 top-level assignments gets a baked JSON blob at
# generation time. Match `let` or `const` — the timeline scrubber
# rebinds the first six, so newer template versions use `let`.
VARS=(modules edges tierLabels pipelineSteps legendItems layoutOverrides history)
for v in "${VARS[@]}"; do
  value=$(grep -E "^[[:space:]]*(let|const) $v = " "$RENDERED" \
          | head -1 \
          | sed -E "s/^[[:space:]]*(let|const) $v = (.*);[[:space:]]*$/\2/")
  if [ -z "$value" ]; then
    echo "FAIL: could not extract value for '$v' from rendered template" >&2
    exit 1
  fi
  if ! echo "$value" | jq empty 2>/dev/null; then
    echo "FAIL: baked JSON for '$v' does not parse:" >&2
    echo "       $value" >&2
    exit 1
  fi
done

echo "template-render: all ${#VARS[@]} baked JSON vars parse; no residual placeholders"
