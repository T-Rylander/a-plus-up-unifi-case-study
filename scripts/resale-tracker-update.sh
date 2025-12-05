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
# Print header and data rows (skip metadata rows)
awk -F',' 'NR==1 {print; print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"} NR>1 && NF==6 {print}' "$RESALE_CSV"

echo ""
# Calculate total from Sold_Price column (column 4), only count numeric values
TOTAL=0
while IFS=',' read -r item _ _ sold _ _; do
    # Skip header and empty lines
    if [ "$item" = "Item" ] || [ -z "$item" ]; then
        continue
    fi
    # Only count if sold_price is not empty and is numeric
    if [ -n "${sold:-}" ] && [ "${sold}" -eq "${sold}" ] 2>/dev/null; then
        TOTAL=$((TOTAL + sold))
    fi
done < "$RESALE_CSV"

TARGET=2000
if [ "$TARGET" -gt 0 ]; then
    PCT=$((TOTAL * 100 / TARGET))
else
    PCT=0
fi

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