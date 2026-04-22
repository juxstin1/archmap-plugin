#!/usr/bin/env bash
# tests/run.sh — discover and execute archmap regression tests.
#
# Each test is an executable bash script in tests/ (not this file).
# A test prints human-readable output and exits 0 on pass, non-zero
# on fail. This runner aggregates exit codes and surfaces a summary.
#
# CI invokes this directly. Run locally with:   bash tests/run.sh
set -euo pipefail

cd "$(dirname "$0")/.."

FAIL=0
TOTAL=0
for t in tests/*.sh; do
  [ "$(basename "$t")" = "run.sh" ] && continue
  TOTAL=$((TOTAL + 1))
  echo "==> $t"
  if bash "$t"; then
    echo "    PASS"
  else
    echo "    FAIL"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
if [ "$FAIL" -ne 0 ]; then
  echo "archmap tests: $FAIL of $TOTAL failed"
  exit 1
fi

echo "archmap tests: $TOTAL/$TOTAL passed"
