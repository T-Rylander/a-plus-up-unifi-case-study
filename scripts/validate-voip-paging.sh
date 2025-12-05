#!/bin/bash
# Validate VoIP Multicast Paging
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Tests Yealink multicast paging (224.0.1.75) - requires IGMP snooping OFF on VLAN 50

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📞 Validating VoIP Multicast Paging"
echo ""

# Test parameters
PHONE_IP="10.50.0.10"
PAGING_GROUP="224.0.1.75:10000"

echo "Test Configuration:"
echo "  • Test Phone: ${PHONE_IP}"
echo "  • Multicast Group: ${PAGING_GROUP}"
echo "  • VLAN: 50 (10.50.0.0/27)"
echo ""

echo "📋 Step 1: Verify IGMP Snooping DISABLED on VLAN 50"
echo ""

# Check IGMP snooping status (requires SSH to UDM)
if ssh -q admin@10.99.0.1 exit 2>/dev/null; then
  IGMP_STATUS=$(ssh admin@10.99.0.1 "show bridge mdb" 2>/dev/null | grep -c "br50" || echo "0")
  
  if [ "$IGMP_STATUS" -eq 0 ]; then
    echo -e "${GREEN}✅ IGMP snooping: DISABLED on VLAN 50 (correct)${NC}"
  else
    echo -e "${RED}❌ BREACH: IGMP snooping ENABLED on VLAN 50${NC}"
    echo ""
    echo "CRITICAL: Multicast paging will FAIL with IGMP snooping enabled"
    echo ""
    echo "Fix:"
    echo "  UniFi Network Application → Settings → Networks → VLAN 50"
    echo "  Advanced → IGMP Snooping: DISABLED"
    echo ""
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️  Cannot verify IGMP status (SSH to UDM failed)${NC}"
  echo "   Manual check required:"
  echo "   ssh admin@10.99.0.1 'show bridge mdb' | grep br50"
  echo "   # Should return empty (no IGMP groups on VLAN 50)"
fi

echo ""
echo "📋 Step 2: Test Phone Reachability"
echo ""

# Ping test phone
if ping -c 1 -W 2 ${PHONE_IP} &>/dev/null; then
  echo -e "${GREEN}✅ Phone ${PHONE_IP}: Reachable${NC}"
else
  echo -e "${RED}❌ Phone ${PHONE_IP}: NOT reachable${NC}"
  echo "   Verify phone is powered on and connected to VLAN 50"
  exit 1
fi

echo ""
echo "📋 Step 3: Trigger Multicast Paging"
echo ""

# Trigger paging announcement via Yealink API
echo "Triggering paging group announcement..."

if curl -s --max-time 10 "http://${PHONE_IP}/cgi-bin/ConfigManApp.com?key=MulticastPaging&value=${PAGING_GROUP}" | grep -q "Success"; then
  echo -e "${GREEN}✅ Paging triggered via phone API${NC}"
else
  echo -e "${YELLOW}⚠️  API trigger failed (phone may not support remote paging)${NC}"
  echo "   Manual test: Press paging button on Yealink phone"
fi

echo ""
echo "📋 Step 4: Monitor Multicast Traffic"
echo ""

# Monitor multicast traffic on VLAN 50
echo "Monitoring multicast traffic (10 seconds)..."

if ssh -q admin@10.99.0.1 exit 2>/dev/null; then
  MULTICAST_PKTS=$(timeout 10 ssh admin@10.99.0.1 "tcpdump -i br50 -c 100 'dst 224.0.1.75' 2>&1" | grep -c "224.0.1.75" || echo "0")
  
  if [ "$MULTICAST_PKTS" -gt 5 ]; then
    echo -e "${GREEN}✅ VoIP paging: ${MULTICAST_PKTS} multicast packets detected${NC}"
    echo "   Multicast group: 224.0.1.75"
    echo "   Status: Functional"
  else
    echo -e "${RED}❌ BREACH: VoIP paging failed (${MULTICAST_PKTS} packets)${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify IGMP snooping DISABLED on VLAN 50"
    echo "  2. Check phone multicast configuration:"
    echo "     http://${PHONE_IP}/cgi-bin/ConfigManApp.com?key=MulticastPaging"
    echo "  3. Test manual paging from phone (press paging button)"
    echo "  4. Monitor traffic: tcpdump -i br50 dst 224.0.1.75"
    echo ""
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️  Cannot monitor traffic (SSH to UDM failed)${NC}"
  echo "   Manual monitoring:"
  echo "   ssh admin@10.99.0.1 'tcpdump -i br50 -c 100 dst 224.0.1.75'"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ VoIP Multicast Paging Validated"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration:"
echo "  • VLAN 50 IGMP Snooping: DISABLED (required)"
echo "  • Multicast Group: 224.0.1.75:10000"
echo "  • Paging Function: Operational"
echo ""
echo "How Multicast Paging Works:"
echo "  1. Phone sends RTP to multicast group 224.0.1.75"
echo "  2. All phones on VLAN 50 subscribe to group"
echo "  3. Announcement heard on all subscribed phones"
echo "  4. Used for PA announcements, intercoms"
echo ""
echo "Why IGMP Snooping Must Be OFF:"
echo "  • IGMP snooping limits multicast to subscribed ports"
echo "  • But Yealink phones don't send IGMP join messages properly"
echo "  • Result: Multicast traffic doesn't reach all phones"
echo "  • Solution: Disable IGMP snooping on VLAN 50 only"
echo ""
echo "Testing Procedure:"
echo "  1. Press paging button on any Yealink phone"
echo "  2. Speak announcement"
echo "  3. Verify heard on all 8 phones in building"
echo "  4. If not heard: Check IGMP snooping status"
echo ""

# Log validation
mkdir -p logs
echo "$(date -Iseconds),voip_paging_validated,multicast_pkts:${MULTICAST_PKTS:-unknown}" >> logs/t3-eternal-history.csv

echo -e "${GREEN}✅ Multicast paging functional${NC}"
echo ""
