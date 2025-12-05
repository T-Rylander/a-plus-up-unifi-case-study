#!/bin/bash
# Calculate UPS Runtime (All Closet Loads)
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Must include ALL closet loads, not just PoE devices

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔋 UPS Runtime Calculation"
echo ""

# UPS specifications (adjust for your model)
UPS_VA=${UPS_VA:-1500}
UPS_WATTS=${UPS_WATTS:-900}
UPS_BATTERY_AH=${UPS_BATTERY_AH:-12}
UPS_VOLTAGE=${UPS_VOLTAGE:-120}

echo "UPS Specifications:"
echo "  Model: APC SMT1500RM2U (or similar)"
echo "  VA Rating: ${UPS_VA} VA"
echo "  Wattage: ${UPS_WATTS} W"
echo "  Battery: ${UPS_BATTERY_AH} Ah @ ${UPS_VOLTAGE}V"
echo ""

# Load breakdown (ALL closet equipment)
POE_LOAD=478        # From calculate-poe-budget.sh steady-state
UDM_LOAD=45         # UDM Pro Max
USW_LOAD=35         # USW-Pro-Max-48-PoE (non-PoE chassis consumption)
SERVER_LOAD=150     # NVR/file server (if present)
MISC_LOAD=50        # Patch panels, fans, monitoring equipment

TOTAL_LOAD=$((POE_LOAD + UDM_LOAD + USW_LOAD + SERVER_LOAD + MISC_LOAD))
LOAD_PERCENT=$(echo "scale=1; $TOTAL_LOAD * 100 / $UPS_WATTS" | bc)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Load Breakdown"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  PoE devices (APs/phones/cameras): ${POE_LOAD}W"
echo "  UDM Pro Max: ${UDM_LOAD}W"
echo "  USW-Pro-Max-48-PoE chassis: ${USW_LOAD}W"
echo "  Servers/NVR: ${SERVER_LOAD}W"
echo "  Miscellaneous (fans/patch panels): ${MISC_LOAD}W"
echo ""
echo "Total Load: ${TOTAL_LOAD}W (${LOAD_PERCENT}% of ${UPS_WATTS}W)"
echo ""

# Runtime calculation (based on typical UPS curves)
# At different load percentages, typical 1500VA UPS runtime:
# 50% load (~750W): 12-15 minutes
# 70% load (~630W): 10-12 minutes
# 80% load (~720W): 8-10 minutes
# 90% load (~810W): 5-7 minutes
# 100% load (~900W): 3-5 minutes

if [ "$TOTAL_LOAD" -lt 630 ]; then
  RUNTIME_MIN=12
  RUNTIME_RANGE="12-15 min"
elif [ "$TOTAL_LOAD" -lt 720 ]; then
  RUNTIME_MIN=10
  RUNTIME_RANGE="10-12 min"
elif [ "$TOTAL_LOAD" -lt 810 ]; then
  RUNTIME_MIN=8
  RUNTIME_RANGE="8-10 min"
elif [ "$TOTAL_LOAD" -lt 900 ]; then
  RUNTIME_MIN=6
  RUNTIME_RANGE="5-7 min"
else
  RUNTIME_MIN=4
  RUNTIME_RANGE="3-5 min"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Runtime Estimate"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Estimated Runtime: ${RUNTIME_RANGE}"
echo "Conservative: ${RUNTIME_MIN} minutes"
echo ""

# Alert conditions
if [ "$TOTAL_LOAD" -gt 810 ]; then
  echo -e "${RED}🔴 RED ALERT: Load >90% (${LOAD_PERCENT}%)${NC}"
  echo ""
  echo "Risk: Runtime <7 minutes (insufficient for graceful shutdown)"
  echo ""
  echo "Recommendations:"
  echo "  1. ✅ Upgrade to 2200VA UPS for 15+ minute runtime"
  echo "  2. Reduce load: Move servers to separate UPS circuit"
  echo "  3. Implement graceful shutdown script (triggers at 30% battery)"
  echo ""

elif [ "$TOTAL_LOAD" -gt 720 ]; then
  echo -e "${YELLOW}🟡 YELLOW ALERT: Load >80% (${LOAD_PERCENT}%)${NC}"
  echo ""
  echo "Warning: Runtime ${RUNTIME_RANGE} (marginal for 15-min RTO target)"
  echo ""
  echo "Recommendations:"
  echo "  1. Test actual runtime under load (UPS battery test)"
  echo "  2. Consider 2200VA upgrade for safety margin"
  echo "  3. Configure graceful shutdown at 40% battery"
  echo ""

elif [ "$RUNTIME_MIN" -lt 10 ]; then
  echo -e "${YELLOW}⚠️  WARNING: Runtime <10 minutes${NC}"
  echo ""
  echo "Recommendation: Test actual runtime, consider larger UPS"
  echo ""

else
  echo -e "${GREEN}✅ UPS Runtime: Adequate for graceful shutdown${NC}"
  echo ""
  echo "Sufficient time for:"
  echo "  • Graceful shutdown of servers (2-3 min)"
  echo "  • UPS battery recharge after brief outages"
  echo "  • Admin notification and manual intervention"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Validation & Monitoring"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "# Test UPS runtime (controlled outage):"
echo "  1. Disconnect UPS from wall power"
echo "  2. Monitor load and runtime via UPS LCD/web interface"
echo "  3. Allow battery to discharge to 50%"
echo "  4. Reconnect power, note actual runtime"
echo "  5. Compare to estimate above"
echo ""
echo "# Monitor UPS health:"
echo "  ssh admin@10.99.0.1"
echo "  curl http://10.99.0.3/cgi-bin/webproc?getpage=../html/status_batt.html"
echo "  # Check: Battery health, runtime remaining, load percentage"
echo ""
echo "# Configure SNMP alerts:"
echo "  UniFi Controller → Settings → Services → SNMP"
echo "  Monitor OID: 1.3.6.1.4.1.318.1.1.1.2.2.1.0 (battery runtime remaining)"
echo "  Alert if: <600 seconds (10 minutes)"
echo ""

# Log to CSV
mkdir -p logs
echo "$(date -Iseconds),$TOTAL_LOAD,$LOAD_PERCENT,$RUNTIME_MIN" >> logs/ups-runtime-history.csv

echo "Maintenance Schedule:"
echo "  Monthly: Check UPS battery health, runtime logs"
echo "  Quarterly: Run battery self-test"
echo "  Annually: Test actual runtime under load (controlled outage)"
echo "  Every 3-5 years: Replace UPS batteries"
echo ""
echo "Historical tracking:"
echo "  cat logs/ups-runtime-history.csv | tail -30"
echo ""
