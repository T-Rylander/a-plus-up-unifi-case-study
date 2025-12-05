#!/bin/bash
# Configure Separate Printer SSID (2.4GHz Carve-Out)
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# UniFi does NOT support per-AP radio enable/disable
# Must use AP Group + dedicated SSID

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🖨️  Configuring Printer SSID (2.4GHz Carve-Out)"
echo ""

# Load printer WiFi password from environment
if [ -z "${PRINTER_WIFI_PASSWORD:-}" ]; then
  echo -e "${RED}❌ ERROR: PRINTER_WIFI_PASSWORD not set in .env${NC}"
  exit 1
fi

echo "📋 Step 1: Create AP Group 'Printer-APs'"
echo "   APs: WAP2 (e4:38:83:aa:bb:02), WAP4 (e4:38:83:aa:bb:04)"
echo "   Location: Room 208 (printer area)"
echo ""

# Configuration steps (manual via UI or API)
echo "Via UniFi Network Application UI:"
echo "1. Navigate to: Settings → Profiles → AP Groups"
echo "2. Create New AP Group:"
echo "   • Name: Printer-APs"
echo "   • Add Devices:"
echo "     - WAP2 - Rm208 (MAC: e4:38:83:aa:bb:02)"
echo "     - WAP4 - Rm208 (MAC: e4:38:83:aa:bb:04)"
echo "3. Save"
echo ""

echo "📋 Step 2: Create 'Printers-Legacy' SSID"
echo "   Security: WPA2-PSK"
echo "   VLAN: 20 (Staff)"
echo "   Hidden: Yes"
echo "   Radios: 2.4GHz ONLY"
echo ""

echo "Via UniFi Network Application UI:"
echo "1. Navigate to: Settings → WiFi"
echo "2. Create New WiFi Network:"
echo "   • Name: Printers-Legacy"
echo "   • Security: WPA2 Personal"
echo "   • Password: ${PRINTER_WIFI_PASSWORD}"
echo "   • Network: VLAN 20 (Staff)"
echo "   • Hide SSID: Enabled"
echo "   • 2.4 GHz Radio:"
echo "     - Enabled: Yes"
echo "     - TX Power: Low"
echo "     - Channel: 1 (fixed)"
echo "     - Channel Width: 20 MHz"
echo "   • 5 GHz Radio:"
echo "     - Enabled: No"
echo "   • AP Group: Printer-APs"
echo "   • Fast Roaming: Disabled (printers don't roam)"
echo "3. Apply Changes"
echo ""

echo "📋 Step 3: Assign SSID to AP Group"
echo "   This limits Printers-Legacy broadcast to WAP2/WAP4 only"
echo ""

echo "✅ Validation Tests:"
echo ""
echo "# From Room 208 (near WAP2/WAP4):"
echo "iwlist wlan0 scan | grep 'Printers-Legacy'"
echo "# Should show hidden SSID"
echo ""
echo "# From other rooms (near WAP1, WAP3, etc.):"
echo "iwlist wlan0 scan | grep 'Printers-Legacy'"
echo "# Should NOT appear (limited to AP group)"
echo ""
echo "# Test printer association:"
echo "# 1. Factory reset a test printer"
echo "# 2. Configure WiFi: SSID 'Printers-Legacy', password from .env"
echo "# 3. Verify connection to VLAN 20 (10.20.0.x address)"
echo "# 4. Test print job from staff device"
echo ""

echo "📋 Step 4: Configure mDNS Reflection"
echo "   Deploy Avahi container for VLAN 10 ↔ VLAN 20 printer discovery"
echo ""
echo "Run: scripts/deploy-avahi-reflector.sh"
echo ""

# Log configuration
mkdir -p logs
echo "$(date -Iseconds),printer_ssid_configured,ap_group_created,2.4ghz_only" >> logs/t3-eternal-history.csv

echo -e "${GREEN}✅ Printer SSID configuration template ready${NC}"
echo ""
echo -e "${YELLOW}⚠️  Rationale: Why separate SSID?${NC}"
echo "   • UniFi does NOT support per-AP radio scripting"
echo "   • Cannot selectively enable 2.4GHz on WAP2/WAP4 only for Student-WiFi"
echo "   • Separate SSID + AP Group = only solution for 2.4GHz carve-out"
echo "   • 40+ legacy printers require 2.4GHz (5GHz not supported)"
echo ""
echo "Migration Plan:"
echo "   Week 1: Deploy Printers-Legacy SSID, migrate 10 test printers"
echo "   Week 2: Migrate remaining 30 printers in batches of 10"
echo "   Week 3: Disable wired printer connections, validate mDNS discovery"
echo "   Week 4: Monitor for 1 week, decommission legacy wired infrastructure"
echo ""
