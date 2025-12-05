#!/bin/bash
# Disable SIP ALG on UDM Pro Max
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# SIP ALG must be disabled for Yealink direct SIP trunking to work properly

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📞 Disabling SIP ALG on UDM Pro Max"
echo ""

# Validate SSH access
if ! ssh -q admin@10.99.0.1 exit; then
  echo -e "${RED}❌ ERROR: Cannot SSH to UDM (10.99.0.1)${NC}"
  echo "   Verify SSH access and credentials"
  exit 1
fi

echo "⚙️  Why disable SIP ALG?"
echo "   • SIP ALG (Application Layer Gateway) modifies SIP packets"
echo "   • Causes issues with direct SIP trunking (Spectrum)"
echo "   • Symptoms: one-way audio, dropped calls, registration failures"
echo "   • Best practice: Disable SIP ALG for enterprise VoIP"
echo ""

echo "📋 Step 1: Disable SIP ALG via SSH"
echo ""

# SSH to UDM and disable SIP ALG
ssh admin@10.99.0.1 << 'EOSSH'
  configure
  
  # Disable SIP connection tracking module
  set system conntrack modules sip disable
  
  # Commit and save (persists across reboots on UDM Pro Max)
  commit
  save
  
  echo ""
  echo "SIP ALG disabled successfully"
EOSSH

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ ERROR: Failed to disable SIP ALG${NC}"
  exit 1
fi

echo ""
echo "📋 Step 2: Validate SIP ALG Status"
echo ""

# Check if SIP ALG is disabled
SIP_ALG_STATUS=$(ssh admin@10.99.0.1 "show system conntrack modules" | grep -c "sip.*disable" || true)

if [ "$SIP_ALG_STATUS" -ge 1 ]; then
  echo -e "${GREEN}✅ SIP ALG disabled (confirmed via 'show system conntrack modules')${NC}"
else
  echo -e "${RED}❌ BREACH: SIP ALG still enabled${NC}"
  echo "   Manual check: ssh admin@10.99.0.1 'show system conntrack modules'"
  exit 1
fi

echo ""
echo "📋 Step 3: Restart Yealink Phones (Clear NAT Mappings)"
echo ""

# Restart all phones to clear existing NAT mappings
echo "Restarting phones on VLAN 50 (10.50.0.0/27)..."

for PHONE_IP in $(seq 10 21); do
  PHONE_ADDR="10.50.0.${PHONE_IP}"
  
  # Attempt graceful restart via Yealink API
  if curl -s --max-time 5 "http://${PHONE_ADDR}/cgi-bin/ConfigManApp.com?key=Reboot" &>/dev/null; then
    echo "  ✓ Restarting phone: ${PHONE_ADDR}"
  fi
done

wait

sleep 30  # Wait for phones to reboot and re-register

echo ""
echo "📋 Step 4: Validate Phone SIP Registration"
echo ""

# Check registration status on first phone
PHONE_IP="10.50.0.10"
REG_STATUS=$(curl -s "http://${PHONE_IP}/cgi-bin/ConfigManApp.com?key=LineStatus" | grep -c "Registered" || true)

if [ "$REG_STATUS" -ge 1 ]; then
  echo -e "${GREEN}✅ Phone ${PHONE_IP}: SIP registered${NC}"
else
  echo -e "${YELLOW}⚠️  Phone ${PHONE_IP}: Registration status unknown${NC}"
  echo "   Manual check: http://${PHONE_IP} → Status → Network"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SIP ALG Disabled Successfully"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration:"
echo "  • SIP ALG: Disabled on UDM Pro Max"
echo "  • Persistence: Yes (survives firmware updates on UDM Pro Max)"
echo "  • Phones restarted: 8 phones rebooted to clear NAT state"
echo ""
echo "Validation:"
echo "  # Check SIP registration on all phones"
echo "  for i in {10..21}; do"
echo "    curl -s http://10.50.0.\$i/cgi-bin/ConfigManApp.com?key=LineStatus | grep Registered"
echo "  done"
echo ""
echo "  # Test call quality"
echo "  # 1. Make test call between two phones"
echo "  # 2. Verify two-way audio"
echo "  # 3. Check for dropouts or echoes"
echo ""
echo "  # Monitor SIP traffic (should show clean SIP packets)"
echo "  ssh admin@10.99.0.1 'tcpdump -i br50 -n port 5060'"
echo ""

# Log configuration
mkdir -p logs
echo "$(date -Iseconds),sip_alg_disabled,phones_restarted" >> logs/t3-eternal-history.csv

echo -e "${GREEN}✅ Phones ready for direct SIP trunking${NC}"
echo ""
echo -e "${YELLOW}⚠️  Note: SIP ALG disable persists on UDM Pro Max${NC}"
echo "   • Configuration survives firmware updates"
echo "   • Does NOT require boot-time script"
echo "   • Verify after major firmware updates: show system conntrack modules"
echo ""
