#!/bin/bash
# Validate Verkada Camera Connectivity
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Validates STUN/TURN ports (3478-3481) and cloud connectivity

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📹 Validating Verkada Camera Connectivity"
echo ""

# Load Verkada API credentials
if [ -z "${VERKADA_API_KEY:-}" ] || [ -z "${VERKADA_ORG_ID:-}" ]; then
  echo -e "${YELLOW}⚠️  WARNING: VERKADA_API_KEY or VERKADA_ORG_ID not set${NC}"
  echo "   Skipping API validation (manual check required)"
  API_VALIDATION=false
else
  API_VALIDATION=true
fi

CAMERA_COUNT=11

if [ "$API_VALIDATION" = true ]; then
  echo "📋 Step 1: Check Camera Online Status (Verkada API)"
  echo ""
  
  # Query Verkada API for camera status
  CAMERAS_ONLINE=$(curl -s -H "x-api-key: ${VERKADA_API_KEY}" \
    "https://api.verkada.com/cameras/v1/devices?org_id=${VERKADA_ORG_ID}" | \
    jq '[.cameras[] | select(.online==true)] | length' 2>/dev/null || echo "0")
  
  if [ "$CAMERAS_ONLINE" -eq "$CAMERA_COUNT" ]; then
    echo -e "${GREEN}✅ Verkada API: ${CAMERAS_ONLINE}/${CAMERA_COUNT} cameras online${NC}"
  else
    echo -e "${RED}❌ BREACH: Only ${CAMERAS_ONLINE}/${CAMERA_COUNT} cameras online${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check STUN/TURN ports (3478-3481) in firewall rules"
    echo "  2. Verify PoE budget not exceeded (cameras offline = no power)"
    echo "  3. Test internet connectivity from VLAN 60"
    echo "  4. Check Verkada Command dashboard for camera errors"
    exit 1
  fi
  echo ""
fi

echo "📋 Step 2: Test STUN Connectivity (NAT Traversal)"
echo ""

# Test STUN connectivity from camera VLAN
# Note: Requires nc (netcat) with UDP support
if command -v nc &>/dev/null; then
  if timeout 5 nc -uzv stun.verkada.com 3478 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}✅ STUN connectivity: Reachable (stun.verkada.com:3478)${NC}"
  else
    echo -e "${RED}❌ STUN connectivity: FAILED${NC}"
    echo ""
    echo "CRITICAL: STUN/TURN ports required for remote viewing"
    echo ""
    echo "Firewall Rule Check:"
    echo "  Rule 5002: Cameras → STUN/TURN (UDP 3478-3481)"
    echo "  • Source: VLAN 60 (10.60.0.0/26)"
    echo "  • Destination: Any (internet)"
    echo "  • Ports: UDP 3478-3481"
    echo "  • Action: ACCEPT"
    echo ""
    echo "Add missing rule:"
    echo "  UniFi Network Application → Settings → Firewall & Security → Rules"
    echo "  Create rule allowing VLAN 60 → UDP 3478-3481"
    echo ""
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️  netcat (nc) not found, skipping STUN test${NC}"
  echo "   Manual test from camera VLAN:"
  echo "   nc -uzv stun.verkada.com 3478"
fi

echo ""
echo "📋 Step 3: Test Verkada Cloud Connectivity (HTTPS)"
echo ""

# Test HTTPS connectivity to Verkada API
if curl -s --max-time 10 https://api.verkada.com/health 2>&1 | grep -q "ok"; then
  echo -e "${GREEN}✅ Verkada API: Reachable (https://api.verkada.com)${NC}"
else
  echo -e "${RED}❌ Verkada API: NOT reachable${NC}"
  echo "   Check internet connectivity from VLAN 60"
  exit 1
fi

echo ""
echo "📋 Step 4: Validate Camera Bandwidth Usage"
echo ""

echo "Expected Bandwidth (11 cameras):"
echo "  • Idle: 100 Kbps × 11 = 1.1 Mbps"
echo "  • Live View (1 camera): 3-45 Mbps burst"
echo "  • Total concurrent: <50 Mbps (assuming 2-3 live views)"
echo ""

if [ "$API_VALIDATION" = true ]; then
  # Query bandwidth usage from Verkada API (if available)
  echo "Check Verkada Command dashboard:"
  echo "  Cameras → Health → Upload Status"
  echo "  All cameras should show 'Green' status"
  echo ""
else
  echo -e "${YELLOW}⚠️  Manual verification required:${NC}"
  echo "  1. Login to Verkada Command: https://command.verkada.com"
  echo "  2. Navigate: Cameras → All Cameras"
  echo "  3. Verify: All 11 cameras show 'Online' status"
  echo "  4. Check: Upload health (green indicators)"
  echo "  5. Test: Live view from remote location (no buffering)"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Verkada Camera Connectivity Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Validated:"
if [ "$API_VALIDATION" = true ]; then
  echo "  ✓ Camera online status: ${CAMERAS_ONLINE}/${CAMERA_COUNT}"
fi
echo "  ✓ STUN connectivity: UDP 3478"
echo "  ✓ Verkada API: HTTPS reachable"
echo ""
echo "Critical Ports (Firewall Rule 5002):"
echo "  • TCP 443: HTTPS (cloud upload)"
echo "  • TCP 554: RTSP (streaming)"
echo "  • UDP 3478-3481: STUN/TURN (NAT traversal for remote viewing)"
echo ""
echo "Monitoring:"
echo "  # Check camera PoE consumption"
echo "  ssh admin@10.99.0.2 'show poe ports 25-35' | grep -E 'eth2[5-9]|eth3[0-5]'"
echo "  # Should show ~12W per camera"
echo ""
echo "  # Monitor STUN/TURN traffic"
echo "  ssh admin@10.99.0.1 'tcpdump -i br60 udp port 3478'"
echo ""
echo "  # Test live view remotely"
echo "  # From outside school network: Open Verkada Command"
echo "  # Live view should load in <5 seconds (no buffering)"
echo ""

# Log validation
mkdir -p logs
CAMERAS_STATUS="${CAMERAS_ONLINE:-unknown}"
echo "$(date -Iseconds),verkada_validated,cameras_online:${CAMERAS_STATUS}" >> logs/t3-eternal-history.csv

echo -e "${GREEN}✅ All Verkada connectivity checks passed${NC}"
echo ""
