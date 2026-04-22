#!/usr/bin/env bash
# tests/fixtures-schema.sh — validate every .archmap.json fixture
# against schemas/archmap.schema.json.
#
# Each fixture exercises a different combination of optional fields,
# enum alternatives, or default-override shapes that the single
# examples/.archmap.json doesn't cover. A schema regression that
# breaks, say, "history.enabled: false with no other history fields"
# would slip past the examples check but fail one of these.
#
# Skips gracefully when ajv-cli isn't on PATH (local dev without the
# global npm install). CI installs ajv-cli in an earlier step.
set -euo pipefail

SCHEMA="schemas/archmap.schema.json"
FIXTURE_ROOT="tests/fixtures"

[ -f "$SCHEMA" ] || { echo "FAIL: $SCHEMA missing" >&2; exit 1; }
[ -d "$FIXTURE_ROOT" ] || { echo "FAIL: $FIXTURE_ROOT missing" >&2; exit 1; }

if ! command -v ajv >/dev/null 2>&1; then
  echo "fixtures-schema: ajv-cli not found (local dev) — skipping; CI validates"
  exit 0
fi

mapfile -t FIXTURES < <(find "$FIXTURE_ROOT" -name '.archmap.json' -type f | sort)
if [ "${#FIXTURES[@]}" -eq 0 ]; then
  echo "FAIL: no fixtures found under $FIXTURE_ROOT" >&2
  exit 1
fi

for f in "${FIXTURES[@]}"; do
  if ! ajv validate -s "$SCHEMA" -d "$f" --spec=draft2020 -c ajv-formats >/dev/null 2>&1; then
    echo "FAIL: $f does not validate against $SCHEMA" >&2
    ajv validate -s "$SCHEMA" -d "$f" --spec=draft2020 -c ajv-formats >&2 || true
    exit 1
  fi
done

echo "fixtures-schema: ${#FIXTURES[@]} fixtures validated"
