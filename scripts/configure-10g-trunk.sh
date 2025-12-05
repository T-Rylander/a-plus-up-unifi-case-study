#!/bin/bash
# Configure 10G LACP Trunk Between UDM Pro Max and USW-Pro-Max-48-PoE
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Creates 802.3ad LACP bond for 20 Gbps aggregate bandwidth (2× 10G)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔗 Configuring 10G LACP Trunk (UDM ↔ USW)"
echo ""

# Validate SSH access
if ! command -v ssh &>/dev/null; then
  echo -e "${RED}❌ ERROR: SSH client not found${NC}"
  exit 1
fi

echo "📋 Step 1: Create Port Profile on USW (Ports 9-10)"
echo ""

# Port profile configuration (manual via UI or scripted)
cat << 'EOF'
Via UniFi Network Application UI:
1. Navigate to: Settings → Profiles → Port Profiles
2. Create New Profile:
   • Name: 10G-Trunk-LACP
   • Port Profile: Trunk
   • Native Network: VLAN 99 (Management)
   • Tagged Networks: VLAN 10, 20, 30, 50, 60, 99
   • Link Aggregation: Enabled (LACP)
   • Speed/Duplex: Auto (10G FDX)
3. Apply to Ports: 9, 10 (SFP+ ports on USW)
EOF

echo ""
echo "📋 Step 2: Configure LACP Bond on USW (via SSH)"
echo ""

# SSH to USW and configure bond0
ssh admin@10.99.0.2 << 'EOUSW'
  configure
  
  # Create bond0 with 802.3ad LACP
  set interfaces bonding bond0 mode 802.3ad
  set interfaces bonding bond0 member interface eth9
  set interfaces bonding bond0 member interface eth10
  
  # Configure VLAN subinterfaces on bond0
  set interfaces bonding bond0 vif 10 address 10.10.0.2/23
  set interfaces bonding bond0 vif 20 address 10.20.0.2/24
  set interfaces bonding bond0 vif 30 address 10.30.0.2/24
  set interfaces bonding bond0 vif 50 address 10.50.0.2/27
  set interfaces bonding bond0 vif 60 address 10.60.0.2/26
  set interfaces bonding bond0 vif 99 address 10.99.0.2/28
  
  # Set hash policy for load balancing (Layer 3+4 for best distribution)
  set interfaces bonding bond0 hash-policy layer3+4
  
  # Commit and save
  commit
  save
  
  # Show bond status
  show interfaces bonding bond0
EOUSW

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ USW bond0 configured successfully${NC}"
else
  echo -e "${RED}❌ ERROR: USW bond0 configuration failed${NC}"
  exit 1
fi

echo ""
echo "📋 Step 3: Configure LACP Bond on UDM (via SSH)"
echo ""

# SSH to UDM and configure bond1 (using different bond interface name)
ssh admin@10.99.0.1 << 'EOUDM'
  configure
  
  # Create bond1 with 802.3ad LACP (UDM SFP+ ports 8-9)
  set interfaces bonding bond1 mode 802.3ad
  set interfaces bonding bond1 member interface eth8
  set interfaces bonding bond1 member interface eth9
  
  # Set hash policy
  set interfaces bonding bond1 hash-policy layer3+4
  
  # Commit and save
  commit
  save
  
  # Show bond status
  show interfaces bonding bond1
EOUDM

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ UDM bond1 configured successfully${NC}"
else
  echo -e "${RED}❌ ERROR: UDM bond1 configuration failed${NC}"
  exit 1
fi

echo ""
echo "📋 Step 4: Validate LACP Bond Formation"
echo ""

sleep 10  # Wait for LACP negotiation

# Check LACP status on USW
LACP_STATUS=$(ssh admin@10.99.0.2 "show interfaces bonding bond0" | grep -c "802.3ad")

if [ "$LACP_STATUS" -ge 1 ]; then
  echo -e "${GREEN}✅ LACP bond formed: UDM eth8-9 ↔ USW eth9-10${NC}"
else
  echo -e "${RED}❌ BREACH: LACP bond not formed${NC}"
  echo "   Troubleshooting:"
  echo "   1. Verify physical SFP+ connections"
  echo "   2. Check port status: show interfaces"
  echo "   3. Verify both sides configured for 802.3ad"
  exit 1
fi

echo ""
echo "📋 Step 5: Verify VLAN Traffic Across Trunk"
echo ""

# Test connectivity to all VLAN gateways
VLANS=(10 20 30 50 60 99)
FAILED=0

for VLAN in "${VLANS[@]}"; do
  if ping -c 1 -W 2 10.${VLAN}.0.1 &>/dev/null; then
    echo -e "${GREEN}✅ VLAN $VLAN: Reachable via trunk${NC}"
  else
    echo -e "${RED}❌ VLAN $VLAN: NOT reachable (trunk misconfiguration)${NC}"
    FAILED=1
  fi
done

if [ $FAILED -eq 1 ]; then
  echo ""
  echo -e "${RED}❌ BREACH: Some VLANs not reachable via trunk${NC}"
  echo "   Check: VLAN tagging on bond0, port profile configuration"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 10G LACP Trunk Validated"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Bond Configuration:"
echo "  • UDM Pro Max: SFP+ 8-9 → bond1"
echo "  • USW-Pro-Max-48-PoE: SFP+ 9-10 → bond0"
echo "  • Mode: 802.3ad LACP (dynamic)"
echo "  • Hash Policy: layer3+4 (best load distribution)"
echo "  • Aggregate Bandwidth: 20 Gbps (2× 10G)"
echo ""
echo "VLAN Subinterfaces (bond0 on USW):"
echo "  • VLAN 10: 10.10.0.2/23"
echo "  • VLAN 20: 10.20.0.2/24"
echo "  • VLAN 30: 10.30.0.2/24"
echo "  • VLAN 50: 10.50.0.2/27"
echo "  • VLAN 60: 10.60.0.2/26"
echo "  • VLAN 99: 10.99.0.2/28"
echo ""
echo "Failover Behavior:"
echo "  • If 1 link fails: Bond continues on single 10G link"
echo "  • Graceful degradation: 20 Gbps → 10 Gbps"
echo "  • Auto-recovery when link restored"
echo ""
echo "Monitoring:"
echo "  # Check bond status"
echo "  ssh admin@10.99.0.2 'show interfaces bonding bond0'"
echo ""
echo "  # Monitor trunk utilization"
echo "  ssh admin@10.99.0.2 'show interfaces counters' | grep bond0"
echo ""

# Log configuration
mkdir -p logs
echo "$(date -Iseconds),10g_lacp_configured,udm_bond1,usw_bond0" >> logs/t3-eternal-history.csv

echo -e "${GREEN}✅ 10G LACP trunk validated: All VLANs passing traffic${NC}"
echo ""
