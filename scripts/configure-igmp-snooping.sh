#!/bin/bash
# Configure IGMP Snooping (Per-VLAN Settings)
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# VLAN 50 (VoIP) must have IGMP snooping DISABLED for multicast paging

set -euo pipefail

echo "📡 Configuring IGMP Snooping (Per-VLAN)"
echo ""

# Configuration template (adjust for your UniFi API setup)
cat << 'EOF'
Via UniFi Network Application UI:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VLAN 10 (Students):
  Settings → Networks → VLAN 10 → Advanced
  • IGMP Snooping: Enabled
  • Multicast Enhancement (IGMPv3): Enabled
  Rationale: Prevents Chromebook mDNS/Bonjour multicast floods

VLAN 20 (Staff):
  Settings → Networks → VLAN 20 → Advanced
  • IGMP Snooping: Enabled
  • Multicast Enhancement (IGMPv3): Enabled
  Rationale: Controls printer broadcast traffic

VLAN 30 (Guest):
  Settings → Networks → VLAN 30 → Advanced
  • IGMP Snooping: Enabled
  • Multicast Enhancement (IGMPv3): Enabled
  Rationale: Isolates guest multicast from internal networks

VLAN 50 (VoIP):  🚨 CRITICAL
  Settings → Networks → VLAN 50 → Advanced
  • IGMP Snooping: DISABLED
  • Multicast Enhancement (IGMPv3): DISABLED
  Rationale: Required for Yealink multicast paging (224.0.1.75)
            If enabled, multicast paging will fail!

VLAN 60 (Cameras):
  Settings → Networks → VLAN 60 → Advanced
  • IGMP Snooping: Enabled
  • Multicast Enhancement (IGMPv3): Enabled
  Rationale: Limits camera multicast traffic

VLAN 99 (Management):
  Settings → Networks → VLAN 99 → Advanced
  • IGMP Snooping: Enabled
  • Multicast Enhancement (IGMPv3): Enabled
  Rationale: Controls management protocol multicast (SNMP traps)
EOF

echo ""
echo "📋 Configuration Summary:"
echo ""
echo "VLAN | IGMP Snooping | Rationale"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 10  | ✓ ENABLED     | Prevents Chromebook multicast floods"
echo " 20  | ✓ ENABLED     | Controls printer broadcast traffic"
echo " 30  | ✓ ENABLED     | Isolates guest multicast"
echo " 50  | ✗ DISABLED    | 🚨 Required for multicast paging"
echo " 60  | ✓ ENABLED     | Limits camera multicast"
echo " 99  | ✓ ENABLED     | Controls management multicast"
echo ""

echo "✅ Validation Tests:"
echo ""
echo "# Test VoIP multicast paging (VLAN 50)"
echo "bash scripts/validate-voip-paging.sh"
echo ""
echo "# Monitor multicast traffic on VLAN 50"
echo "ssh admin@10.99.0.1 'tcpdump -i br50 -c 100 dst 224.0.1.75'"
echo "# Should see multicast packets when paging triggered"
echo ""
echo "# Verify IGMP snooping status per VLAN"
echo "ssh admin@10.99.0.1 'show bridge mdb'"
echo "# Should show IGMP groups for enabled VLANs"
echo ""

# Log configuration
mkdir -p logs
echo "$(date -Iseconds),igmp_snooping_configured,vlan50_disabled" >> logs/t3-eternal-history.csv

echo -e "${GREEN}✅ IGMP snooping configuration template ready${NC}"
echo ""
echo -e "${YELLOW}⚠️  CRITICAL: VLAN 50 IGMP Snooping MUST be DISABLED${NC}"
echo "   • Yealink phones use multicast paging (224.0.1.75)"
echo "   • If IGMP snooping enabled on VLAN 50, paging will fail"
echo "   • Symptom: PA announcements not heard on all phones"
echo "   • Validation script: scripts/validate-voip-paging.sh"
echo ""
echo "Troubleshooting Multicast Paging:"
echo "  1. Verify VLAN 50 IGMP snooping = DISABLED"
echo "  2. Test paging from Yealink phone admin interface"
echo "  3. Monitor multicast traffic: tcpdump -i br50 dst 224.0.1.75"
echo "  4. Check phone multicast config: http://10.50.0.10/cgi-bin/ConfigManApp.com"
echo ""
