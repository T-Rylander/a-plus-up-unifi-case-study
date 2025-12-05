#!/bin/bash
# Resale Tracker Update
# Updates the resale-tracker.csv with latest sales

set -euo pipefail

RESALE_CSV="$(dirname "$0")/../inventory/resale-tracker.csv"

if [ ! -f "$RESALE_CSV" ]; then
    echo "Error: $RESALE_CSV not found"
    exit 1
fi

echo "📊 Current Resale Status:"
echo ""
awk -F',' 'NR==1 {print; print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"} NR>1 {print}' "$RESALE_CSV"

echo ""
TOTAL=$(awk -F',' 'NR>1 && $4 != "" {sum += $4} END {print sum}' "$RESALE_CSV")
TARGET=2000
PCT=$((TOTAL * 100 / TARGET))

echo "Total Realized: \$${TOTAL}"
echo "Target: \$${TARGET}"
echo "Progress: ${PCT}%"

if [ "$TOTAL" -ge "$TARGET" ]; then
    echo "✅ TARGET EXCEEDED — BONUS GREEN"
elif [ "$TOTAL" -ge $((TARGET * 70 / 100)) ]; then
    echo "✅ ON TRACK"
else
    echo "⚠️  BELOW 70% THRESHOLD"
fi
