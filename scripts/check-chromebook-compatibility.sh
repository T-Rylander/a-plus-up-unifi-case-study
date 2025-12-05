#!/bin/bash
# Check Chromebook 802.11r Compatibility
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Pre-2020 Chromebooks (AUE <2026) may not support 802.11r

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "💻 Checking Chromebook 802.11r Compatibility"
echo ""

# Check if inventory file exists
if [ ! -f inventory/chromebook-inventory.json ]; then
  echo -e "${RED}❌ ERROR: inventory/chromebook-inventory.json not found${NC}"
  echo ""
  echo "Create inventory file with format:"
  cat << 'EOF'
{
  "chromebooks": [
    {
      "model": "Acer Chromebook 11 C732",
      "aue_date": "2024-06-01",
      "count": 25
    },
    {
      "model": "HP Chromebook 14 G5",
      "aue_date": "2026-06-01",
      "count": 75
    }
  ]
}
EOF
  exit 1
fi

# Parse inventory for Chromebook models + AUE dates
CHROMEBOOK_MODELS=$(jq -r '.chromebooks[] | "\(.model),\(.aue_date),\(.count)"' inventory/chromebook-inventory.json)

INCOMPATIBLE_COUNT=0
INCOMPATIBLE_DEVICES=0
TOTAL_DEVICES=0

echo "Analyzing Chromebook inventory..."
echo ""
echo "Model                              | AUE Date   | Count | Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

while IFS=',' read -r MODEL AUE_DATE COUNT; do
  AUE_YEAR=$(date -d "$AUE_DATE" +%Y 2>/dev/null || echo "unknown")
  TOTAL_DEVICES=$((TOTAL_DEVICES + COUNT))
  
  # Chromebooks with AUE before 2026 likely pre-2020 models
  # May not support 802.11r (causes disconnects/roaming issues)
  if [ "$AUE_YEAR" != "unknown" ] && [ "$AUE_YEAR" -lt 2026 ]; then
    echo -e "${MODEL:0:35} | ${AUE_DATE} | ${COUNT:3} | ${RED}⚠️  May not support 802.11r${NC}"
    ((INCOMPATIBLE_COUNT++))
    INCOMPATIBLE_DEVICES=$((INCOMPATIBLE_DEVICES + COUNT))
  else
    echo -e "${MODEL:0:35} | ${AUE_DATE} | ${COUNT:3} | ${GREEN}✓ Supports 802.11r${NC}"
  fi
done <<< "$CHROMEBOOK_MODELS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total Chromebooks: ${TOTAL_DEVICES}"
echo "Potentially incompatible models: ${INCOMPATIBLE_COUNT}"
echo "Potentially incompatible devices: ${INCOMPATIBLE_DEVICES}"
echo ""

if [ "$INCOMPATIBLE_DEVICES" -gt 0 ]; then
  INCOMPATIBLE_PERCENT=$(echo "scale=1; $INCOMPATIBLE_DEVICES * 100 / $TOTAL_DEVICES" | bc)
  
  echo -e "${RED}❌ RECOMMENDATION: Disable 802.11r, use 802.11k/v instead${NC}"
  echo ""
  echo "Affected: ${INCOMPATIBLE_DEVICES} Chromebooks (${INCOMPATIBLE_PERCENT}% of fleet)"
  echo ""
  echo "Why 802.11k/v instead of 802.11r?"
  echo "  • 802.11r (Fast Roaming): Pre-authenticates with neighbor APs"
  echo "    - Faster handoff (<50ms)"
  echo "    - BUT: Older Chromebooks may disconnect or fail to roam"
  echo ""
  echo "  • 802.11k (Neighbor Reports): AP suggests best neighbor"
  echo "  • 802.11v (BSS Transition Management): AP directs client roaming"
  echo "    - Handoff: <200ms (acceptable for web browsing)"
  echo "    - Compatible with ALL Chromebook models (2015+)"
  echo ""
  echo "SSID Configuration Recommendation:"
  cat << 'EOF'
Student-WiFi:
  • 802.11k: Enabled
  • 802.11v: Enabled
  • 802.11r: Disabled
  • Rationale: Maximum compatibility with older Chromebook fleet

Staff-Secure:
  • 802.11k: Enabled
  • 802.11v: Enabled
  • 802.11r: Enabled
  • Rationale: Staff devices (2020+ laptops) support 802.11r
EOF
  echo ""
  echo "Mitigation Plan:"
  echo "  1. ✅ Configure Student-WiFi with 802.11k/v (NOT 802.11r)"
  echo "  2. Pilot with 10 Chromebooks (mix of old/new models)"
  echo "  3. Test roaming between APs: <200ms handoff acceptable"
  echo "  4. Deploy to full fleet after 1-week pilot"
  echo ""
  echo "  Alternative: Phase out AUE <2026 Chromebooks (2026-2027 refresh)"
  echo "              Then enable 802.11r for entire fleet"
  echo ""
  exit 1
else
  echo -e "${GREEN}✅ All Chromebooks support 802.11r (AUE 2026+)${NC}"
  echo ""
  echo "Safe to enable 802.11r on Student-WiFi SSID"
  echo "Expected roaming performance: <100ms handoff"
  echo ""
fi

echo "Validation Steps:"
echo "  1. Deploy Student-WiFi SSID with 802.11k/v (or 802.11r if fleet compatible)"
echo "  2. Pilot with 10 Chromebooks across campus"
echo "  3. Test roaming: Walk between APs while on Google Meet call"
echo "     - Target: No drops, minimal audio glitches"
echo "  4. Monitor connection logs for disconnect/re-associate events"
echo "  5. Full rollout after 1-week pilot validation"
echo ""

# Log analysis
mkdir -p logs
echo "$(date -Iseconds),chromebook_compatibility_check,total:${TOTAL_DEVICES},incompatible:${INCOMPATIBLE_DEVICES}" >> logs/t3-eternal-history.csv

echo "References:"
echo "  • ADR-003: docs/adr/003-wifi-802.11kvr.md"
echo "  • SSID Config: config/unifi/ssids.json"
echo "  • Chromebook AUE Database: https://support.google.com/chrome/a/answer/6220366"
echo ""
