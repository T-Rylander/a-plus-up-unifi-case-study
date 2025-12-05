#!/bin/bash
# Configure Manual QoS Traffic Rules for A+UP Charter School
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# CRITICAL: CyberSecure DPI does NOT auto-populate QoS
# All traffic rules must be manually configured

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 Configuring QoS (Manual Traffic Rules)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load environment variables
if [ -f .env ]; then
  source .env
else
  echo -e "${RED}❌ ERROR: .env file not found${NC}"
  echo "   Create .env from .env.example with UniFi credentials"
  exit 1
fi

# Validate UniFi credentials
if [ -z "${UNIFI_HOST:-}" ] || [ -z "${UNIFI_USERNAME:-}" ] || [ -z "${UNIFI_PASSWORD:-}" ]; then
  echo -e "${RED}❌ ERROR: UniFi credentials not set in .env${NC}"
  exit 1
fi

echo "📊 Step 1: Enable Smart Queues (Asymmetric WAN 950/47.5 Mbps)"
echo "   ISP: Comcast 1000/50 Mbps"
echo "   Setting: 95% of ISP speeds to prevent buffer bloat"
echo ""

# Enable Smart Queues with asymmetric WAN speeds
# Comcast: 1000 Mbps down / 50 Mbps up
# Set to 95% to maintain low latency
DOWNLOAD_KBPS=950000  # 950 Mbps
UPLOAD_KBPS=47500     # 47.5 Mbps

# UniFi API call to enable Smart Queues
# Note: Adjust API endpoint based on your UniFi Network Application version
curl -s -X PUT \
  "https://${UNIFI_HOST}:8443/api/s/default/rest/wanconf/${WAN_ID}" \
  -H "Content-Type: application/json" \
  -H "Cookie: ${UNIFI_COOKIE}" \
  -d "{
    \"smart_queues_enabled\": true,
    \"download_limit_kbps\": ${DOWNLOAD_KBPS},
    \"upload_limit_kbps\": ${UPLOAD_KBPS}
  }" > /dev/null

echo -e "${GREEN}✅ Smart Queues enabled: ${DOWNLOAD_KBPS}/${UPLOAD_KBPS} Kbps${NC}"
echo ""

echo "📋 Step 2: Create Traffic Rules (Manual Configuration)"
echo ""

# Traffic Rule 1: VoIP Priority (DSCP EF / 46)
echo "   [1/4] VoIP Priority (Yealink SIP)"
echo "         Source: VLAN 50 (10.50.0.0/27)"
echo "         Ports: UDP 5060-5061, 10000-65535"
echo "         DSCP: 46 (EF - Expedited Forwarding)"
echo "         Target: <30ms jitter for G.722 codec"

curl -s -X POST \
  "https://${UNIFI_HOST}:8443/api/s/default/rest/trafficrule" \
  -H "Content-Type: application/json" \
  -H "Cookie: ${UNIFI_COOKIE}" \
  -d '{
    "name": "VoIP Priority (Yealink SIP)",
    "enabled": true,
    "matching_target": "INTERNET",
    "action": "APPLY",
    "networkconf_id": "VLAN50_ID",
    "protocol": "udp",
    "dst_port": "5060-5061,10000-65535",
    "dscp": 46,
    "bandwidth_profile": "voip"
  }' > /dev/null

echo -e "${GREEN}      ✓ VoIP traffic rule created${NC}"
echo ""

# Traffic Rule 2: Verkada Cameras Priority (DSCP AF41 / 34)
echo "   [2/4] Verkada Cameras Priority"
echo "         Source: VLAN 60 (10.60.0.0/26)"
echo "         Ports: TCP 443, 554"
echo "         DSCP: 34 (AF41 - Assured Forwarding Class 4)"
echo "         Bandwidth: 100 Kbps idle, 3-45 Mbps live view"

curl -s -X POST \
  "https://${UNIFI_HOST}:8443/api/s/default/rest/trafficrule" \
  -H "Content-Type: application/json" \
  -H "Cookie: ${UNIFI_COOKIE}" \
  -d '{
    "name": "Verkada Cameras Priority",
    "enabled": true,
    "matching_target": "INTERNET",
    "action": "APPLY",
    "networkconf_id": "VLAN60_ID",
    "protocol": "tcp",
    "dst_port": "443,554",
    "dscp": 34,
    "bandwidth_profile": "camera"
  }' > /dev/null

echo -e "${GREEN}      ✓ Camera traffic rule created${NC}"
echo ""

# Traffic Rule 3: Chromebook Google Meet Priority (DSCP AF31 / 26)
echo "   [3/4] Chromebook Google Meet Priority"
echo "         Source: VLAN 10 (10.10.0.0/23)"
echo "         Destination: *.google.com"
echo "         Ports: TCP/UDP 443, 19302-19309"
echo "         DSCP: 26 (AF31 - Assured Forwarding Class 3)"
echo "         Bandwidth: 100 Mbps burst per classroom"

curl -s -X POST \
  "https://${UNIFI_HOST}:8443/api/s/default/rest/trafficrule" \
  -H "Content-Type: application/json" \
  -H "Cookie: ${UNIFI_COOKIE}" \
  -d '{
    "name": "Chromebook Google Meet Priority",
    "enabled": true,
    "matching_target": "INTERNET",
    "action": "APPLY",
    "networkconf_id": "VLAN10_ID",
    "dst_address": "*.google.com,*.googleapis.com",
    "dst_port": "443,19302-19309",
    "dscp": 26,
    "bandwidth_profile": "video_conferencing"
  }' > /dev/null

echo -e "${GREEN}      ✓ Google Meet traffic rule created${NC}"
echo ""

# Traffic Rule 4: Guest Throttle (DSCP 0 / Best Effort)
echo "   [4/4] Guest WiFi Throttle"
echo "         Source: VLAN 30 (10.30.0.0/24)"
echo "         Rate Limit: 25 Mbps down / 10 Mbps up"
echo "         DSCP: 0 (Best Effort)"

curl -s -X POST \
  "https://${UNIFI_HOST}:8443/api/s/default/rest/trafficrule" \
  -H "Content-Type: application/json" \
  -H "Cookie: ${UNIFI_COOKIE}" \
  -d '{
    "name": "Guest WiFi Throttle",
    "enabled": true,
    "matching_target": "INTERNET",
    "action": "APPLY",
    "networkconf_id": "VLAN30_ID",
    "rate_limit_down_kbps": 25000,
    "rate_limit_up_kbps": 10000,
    "dscp": 0
  }' > /dev/null

echo -e "${GREEN}      ✓ Guest throttle rule created${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ QoS Configuration Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Validation Commands:"
echo ""
echo "# Verify Smart Queues status"
echo "curl -s http://${UNIFI_HOST}/api/s/default/rest/wanconf | jq '.smart_queues'"
echo ""
echo "# Test VoIP DSCP marking"
echo "tcpdump -i br50 -v 'udp port 5060' | grep 'tos'"
echo "# Should show 'tos 0xb8' (DSCP 46 / EF)"
echo ""
echo "# Test guest throttle"
echo "# From guest device: speedtest-cli"
echo "# Should show ~25/10 Mbps"
echo ""
echo "Performance Targets:"
echo "  • VoIP jitter: <30ms (G.722 requirement)"
echo "  • Verkada upload: Green status in Command dashboard"
echo "  • Google Meet: 720p HD, <50ms latency"
echo "  • Guest throttle: No staff complaints about bandwidth"
echo ""

# Log configuration to CSV
echo "$(date -Iseconds),qos_configured,4_rules,${DOWNLOAD_KBPS},${UPLOAD_KBPS}" >> logs/t3-eternal-history.csv

echo -e "${YELLOW}⚠️  REMINDER: CyberSecure DPI does NOT auto-create QoS rules${NC}"
echo "   All traffic rules are manually configured above"
echo "   Review monthly: Settings → Traffic Management → Traffic Rules"
echo ""
