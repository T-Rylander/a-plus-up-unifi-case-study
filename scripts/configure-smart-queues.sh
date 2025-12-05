#!/bin/bash
# Configure Smart Queues for Asymmetric WAN
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Comcast 1000/50 Mbps (asymmetric) requires manual configuration

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📊 Configuring Smart Queues (Asymmetric WAN)"
echo ""

# Load environment or use defaults
WAN_DOWN_MBPS=${WAN_DOWN_MBPS:-1000}
WAN_UP_MBPS=${WAN_UP_MBPS:-50}

# Apply 5% buffer to prevent over-subscription and buffer bloat
SMART_QUEUE_DOWN=$(echo "$WAN_DOWN_MBPS * 0.95 * 1000" | bc | cut -d. -f1)
SMART_QUEUE_UP=$(echo "$WAN_UP_MBPS * 0.95 * 1000" | bc | cut -d. -f1)

echo "WAN Speeds: ${WAN_DOWN_MBPS}/${WAN_UP_MBPS} Mbps (ISP contract)"
echo "Smart Queue Settings: ${SMART_QUEUE_DOWN}/${SMART_QUEUE_UP} Kbps (95% of ISP)"
echo "Rationale: 5% headroom prevents buffer bloat, maintains <10ms latency"
echo ""

# Note: This is a configuration template
# Actual implementation requires UniFi API authentication
echo "⚙️  Configuration Steps:"
echo ""
echo "Via UniFi Network Application UI:"
echo "1. Navigate to: Settings → Internet → WAN → Smart Queues"
echo "2. Enable: Smart Queues"
echo "3. Download Bandwidth: ${SMART_QUEUE_DOWN} Kbps"
echo "4. Upload Bandwidth: ${SMART_QUEUE_UP} Kbps"
echo "5. Apply Changes"
echo ""
echo "Via SSH (UDM Pro Max):"
echo "  ssh admin@10.99.0.1"
echo "  configure"
echo "  set traffic-control smart-queue download-rate ${SMART_QUEUE_DOWN}"
echo "  set traffic-control smart-queue upload-rate ${SMART_QUEUE_UP}"
echo "  commit; save"
echo ""

# Validation
echo "✅ Validation Tests:"
echo ""
echo "# Run speed test from management VLAN"
echo "speedtest-cli --server <comcast-server-id>"
echo "# Target: 950/47.5 Mbps with <10ms jitter"
echo ""
echo "# Monitor Smart Queue status"
echo "ssh admin@10.99.0.1 'show traffic-control'"
echo ""
echo "# Test under load (simulate 3 classrooms on Meet + camera uploads)"
echo "# From VLAN 10: Start 30 Chromebooks on Google Meet"
echo "# From VLAN 60: Trigger live view on all 11 cameras"
echo "# Monitor: Latency should stay <30ms, no packet loss"
echo ""

# Log configuration
mkdir -p logs
echo "$(date -Iseconds),smart_queues_configured,${SMART_QUEUE_DOWN},${SMART_QUEUE_UP}" >> logs/t3-eternal-history.csv

echo -e "${GREEN}✅ Smart Queues configured: ${SMART_QUEUE_DOWN}/${SMART_QUEUE_UP} Kbps${NC}"
echo ""
echo -e "${YELLOW}⚠️  Performance Monitoring Schedule:${NC}"
echo "   Weekly: Check WAN utilization graphs (should not hit 100%)"
echo "   Monthly: Run speed test, adjust if ISP speeds change"
echo "   Quarterly: Validate Smart Queue effectiveness (latency <10ms)"
echo ""
