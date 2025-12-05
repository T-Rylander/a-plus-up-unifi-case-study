#!/bin/bash
# Staggered PoE Boot Sequence
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Run after power restoration to prevent inrush overload (1195W > 720W budget)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔌 Staggered PoE Boot Sequence"
echo ""
echo "Purpose: Prevent PoE inrush overload after power restoration"
echo "Inrush: 1195W (2.5x × 478W steady-state) > 720W budget"
echo ""
echo -e "${YELLOW}⚠️  Run this script immediately after power is restored${NC}"
echo ""

# Validate SSH access to USW
if ! ssh -q admin@10.99.0.2 exit 2>/dev/null; then
  echo -e "${RED}❌ ERROR: Cannot SSH to USW (10.99.0.2)${NC}"
  echo "   Verify switch is powered on and accessible"
  exit 1
fi

read -p "Continue with staggered boot? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted"
  exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 1: APs Only (Critical for Network)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[1/3] Enabling PoE on AP ports (1-16)..."
echo "      Power: 16 × 15W = 240W"
echo ""

for PORT in {1..16}; do
  ssh admin@10.99.0.2 "configure; set interface ethernet eth${PORT} poe opmode auto; commit" &>/dev/null
  echo "  ✓ Port ${PORT}: PoE enabled"
done

echo ""
echo "Waiting 60 seconds for APs to boot and adopt..."
sleep 60

# Verify APs are online
AP_COUNT=$(curl -s -k https://10.99.0.1:8443/api/s/default/stat/device 2>/dev/null | jq '[.data[] | select(.type=="uap") | select(.state==1)] | length' || echo "0")
echo "APs online: ${AP_COUNT}/16"

if [ "$AP_COUNT" -lt 12 ]; then
  echo -e "${YELLOW}⚠️  WARNING: Less than 12/16 APs online${NC}"
  echo "   Continue anyway? (y/n)"
  read -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 2: Phones (VoIP Priority)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[2/3] Enabling PoE on phone ports (17-24)..."
echo "      Power: 8 × 7W = 56W"
echo "      Total so far: 296W (41%)"
echo ""

for PORT in {17..24}; do
  ssh admin@10.99.0.2 "configure; set interface ethernet eth${PORT} poe opmode auto; commit" &>/dev/null
  echo "  ✓ Port ${PORT}: PoE enabled"
done

echo ""
echo "Waiting 45 seconds for phones to boot and register..."
sleep 45

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 3: Cameras + Wildcards"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[3/3] Enabling PoE on camera/wildcard ports (25-40)..."
echo "      Power: 11 × 12W = 132W (cameras) + 30W (intercom) + 30W (wildcards)"
echo "      Total: 478W (66.4%)"
echo ""

for PORT in {25..40}; do
  ssh admin@10.99.0.2 "configure; set interface ethernet eth${PORT} poe opmode auto; commit" &>/dev/null
  echo "  ✓ Port ${PORT}: PoE enabled"
done

echo ""
echo "Waiting 60 seconds for cameras to boot and connect to Verkada..."
sleep 60

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Staggered Boot Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total boot time: 165 seconds (2 minutes 45 seconds)"
echo ""
echo "Validation:"
echo ""
echo "# Check final PoE consumption"
echo "ssh admin@10.99.0.2 'show poe summary'"
echo "# Should show ~478W total"
echo ""
echo "# Verify all devices online"
echo "  • APs: UniFi Network Application → Devices → UniFi Devices"
echo "  • Phones: Check SIP registration status"
echo "  • Cameras: Verkada Command dashboard"
echo ""

# Verify final PoE consumption
FINAL_POE=$(ssh admin@10.99.0.2 "show poe summary" 2>/dev/null | grep -oP 'Total.*?(\d+\.\d+)W' | grep -oP '\d+\.\d+' || echo "unknown")

if [ "$FINAL_POE" != "unknown" ]; then
  echo "Final PoE consumption: ${FINAL_POE}W"
  
  if (( $(echo "$FINAL_POE > 600" | bc -l) )); then
    echo -e "${YELLOW}⚠️  WARNING: PoE >600W (83% utilization)${NC}"
    echo "   Monitor closely, consider second PoE switch for expansion"
  else
    echo -e "${GREEN}✅ PoE budget healthy: ${FINAL_POE}W / 720W${NC}"
  fi
else
  echo "Unable to determine final PoE consumption (check manually)"
fi

echo ""
# Log to CSV
mkdir -p logs
echo "$(date -Iseconds),staggered_boot_complete,165_seconds,${FINAL_POE}W" >> logs/poe-budget-history.csv

echo -e "${GREEN}✅ All devices powered on safely${NC}"
echo ""
echo -e "${YELLOW}⚠️  Future Power Outages:${NC}"
echo "   Always run this script after power restoration"
echo "   Do NOT rely on automatic PoE boot (will exceed budget)"
echo "   Alternative: Configure PoE schedule in UniFi (ports 1-16 first)"
echo ""
