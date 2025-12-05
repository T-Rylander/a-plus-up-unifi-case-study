#!/bin/bash
# Calculate PoE Budget with Inrush Current
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Must account for 2.5x inrush multiplier during simultaneous boot

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "⚡ PoE Budget Calculation (with Inrush)"
echo ""

# Device inventory (steady-state power consumption)
AP_COUNT=16
AP_WATTS=15

PHONE_COUNT=8
PHONE_WATTS=7

CAMERA_COUNT=11
CAMERA_WATTS=12

WILDCARD_PC_COUNT=2
WILDCARD_PC_WATTS=15

INTERCOM_WATTS=30

# Calculate steady-state total
STEADY_STATE=$(( (AP_COUNT * AP_WATTS) + (PHONE_COUNT * PHONE_WATTS) + (CAMERA_COUNT * CAMERA_WATTS) + (WILDCARD_PC_COUNT * WILDCARD_PC_WATTS) + INTERCOM_WATTS ))

# Calculate inrush (2.5x multiplier for simultaneous boot after power outage)
INRUSH_MULTIPLIER=2.5
INRUSH_TOTAL=$(echo "$STEADY_STATE * $INRUSH_MULTIPLIER" | bc | cut -d. -f1)

# USW-Pro-Max-48-PoE budget
POE_BUDGET=720

# Calculate utilization percentages
STEADY_PERCENT=$(echo "scale=1; $STEADY_STATE * 100 / $POE_BUDGET" | bc)
INRUSH_PERCENT=$(echo "scale=1; $INRUSH_TOTAL * 100 / $POE_BUDGET" | bc)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PoE Budget Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Device Breakdown (Steady-State):"
echo "  - ${AP_COUNT}× APs @ ${AP_WATTS}W each = $((AP_COUNT * AP_WATTS))W"
echo "  - ${PHONE_COUNT}× Phones @ ${PHONE_WATTS}W each = $((PHONE_COUNT * PHONE_WATTS))W"
echo "  - ${CAMERA_COUNT}× Cameras @ ${CAMERA_WATTS}W each = $((CAMERA_COUNT * CAMERA_WATTS))W"
echo "  - ${WILDCARD_PC_COUNT}× PCs @ ${WILDCARD_PC_WATTS}W each = $((WILDCARD_PC_COUNT * WILDCARD_PC_WATTS))W"
echo "  - Intercom @ ${INTERCOM_WATTS}W"
echo ""
echo "Steady-State Total: ${STEADY_STATE}W (${STEADY_PERCENT}% of ${POE_BUDGET}W)"
echo "Inrush (${INRUSH_MULTIPLIER}x): ${INRUSH_TOTAL}W (${INRUSH_PERCENT}% of ${POE_BUDGET}W)"
echo ""

# Alert thresholds
YELLOW_THRESHOLD=600
RED_THRESHOLD=680

# Check if inrush exceeds budget
if (( $(echo "$INRUSH_TOTAL > $POE_BUDGET" | bc -l) )); then
  echo -e "${RED}❌ BREACH: Inrush exceeds PoE budget!${NC}"
  echo ""
  echo "Risk: Power outage → all devices boot simultaneously → PoE shutdown"
  echo ""
  echo "Mitigation Options:"
  echo "  1. ✅ Implement staggered boot script (scripts/staggered-poe-boot.sh)"
  echo "     - Boot APs first (critical for network)"
  echo "     - Then phones (165 seconds total)"
  echo "     - Finally cameras + wildcards"
  echo ""
  echo "  2. Reduce device count to ~400W steady-state (55% utilization)"
  echo "     - Remove 5 cameras OR 3 APs OR 10 phones"
  echo ""
  echo "  3. Add second PoE switch (distribute load)"
  echo "     - USW-16-PoE (95W) for phones only"
  echo "     - Keeps main switch under 500W"
  echo ""
  exit 1

elif (( $(echo "$STEADY_STATE > $RED_THRESHOLD" | bc -l) )); then
  echo -e "${RED}🔴 RED ALERT: Steady-state >${RED_THRESHOLD}W (${STEADY_PERCENT}%)${NC}"
  echo ""
  echo "Risk: Minimal headroom for expansion"
  echo "Recommendation: Freeze PoE device additions, plan second switch"
  echo ""

elif (( $(echo "$STEADY_STATE > $YELLOW_THRESHOLD" | bc -l) )); then
  echo -e "${YELLOW}🟡 YELLOW ALERT: Steady-state >${YELLOW_THRESHOLD}W (${STEADY_PERCENT}%)${NC}"
  echo ""
  echo "Warning: Limited headroom for expansion"
  echo "Recommendation: Monitor closely, no more than 2-3 additional devices"
  echo ""

else
  echo -e "${GREEN}✅ PoE Budget: ETERNAL GREEN${NC}"
  echo ""
  echo "Headroom: $((POE_BUDGET - STEADY_STATE))W ($(echo "scale=1; 100 - $STEADY_PERCENT" | bc)%)"
  echo "Room for expansion: ~$((($POE_BUDGET - $STEADY_STATE) / 12)) additional cameras OR"
  echo "                    ~$((($POE_BUDGET - $STEADY_STATE) / 15)) additional APs"
  echo ""
fi

# Log to CSV for tracking
mkdir -p logs
echo "$(date -Iseconds),$STEADY_STATE,$INRUSH_TOTAL,$STEADY_PERCENT,$INRUSH_PERCENT" >> logs/poe-budget-history.csv

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Monitoring & Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "# Check current PoE utilization"
echo "ssh admin@10.99.0.2 'show poe summary'"
echo ""
echo "# Monitor per-port PoE consumption"
echo "ssh admin@10.99.0.2 'show poe ports'"
echo ""
echo "# Alert thresholds (configure in UniFi):"
echo "  Yellow: ${YELLOW_THRESHOLD}W ($(echo "scale=1; $YELLOW_THRESHOLD * 100 / $POE_BUDGET" | bc)%)"
echo "  Red: ${RED_THRESHOLD}W ($(echo "scale=1; $RED_THRESHOLD * 100 / $POE_BUDGET" | bc)%)"
echo ""
echo "# Historical tracking"
echo "cat logs/poe-budget-history.csv | tail -30"
echo ""
echo "Maintenance Schedule:"
echo "  Monthly: Review PoE utilization, update device count"
echo "  Quarterly: Run this script, validate against actual consumption"
echo "  Annually: Test staggered boot after UPS maintenance"
echo ""
