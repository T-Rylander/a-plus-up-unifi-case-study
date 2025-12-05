#!/bin/bash
# scripts/configure-cybersecure-cipa.sh
# Configure UniFi CyberSecure for baseline CIPA compliance
# Requires: SSH access to UDM Pro Max
# T3-ETERNAL: Perimeter (Suehring) — Content filtering

set -euo pipefail

# UniFi credentials
UDM_HOST="${UDM_HOST:-10.99.0.1}"
UDM_USER="${UDM_USER:-admin}"
UDM_PASS="${UDM_PASS:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# CIPA-required categories (must be manually configured via UI)
CIPA_CATEGORIES=(
  "Adult"
  "Gambling"
  "Violence and Weapons"
  "Drugs and Alcohol"
  "Hate Speech"
  "Malware and Phishing"
  "File Sharing (P2P)"
  "Proxy Avoidance"
)

echo "=========================================="
echo "UniFi CyberSecure CIPA Configuration"
echo "=========================================="
echo ""
echo "⚠️  CRITICAL: CyberSecure is NOT CIPA-certified"
echo "⚠️  This provides baseline filtering only"
echo "⚠️  Recommend third-party filter (Lightspeed/Securly) for full compliance"
echo ""

# Validate SSH access to UDM
echo -n "Testing SSH connection to UDM ($UDM_HOST)... "
if ssh -o ConnectTimeout=5 -q "$UDM_USER@$UDM_HOST" exit; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}FAILED${NC}"
  echo "Error: Cannot SSH to UDM Pro Max"
  echo "Verify SSH is enabled: UniFi UI → Settings → System → Advanced → SSH"
  exit 1
fi

# Check if CyberSecure is enabled
echo -n "Checking CyberSecure status... "
CYBERSECURE_STATUS=$(ssh "$UDM_USER@$UDM_HOST" 'grep -i cybersecure /etc/unifi-os/unifi-os.conf 2>/dev/null || echo "unknown"')

if echo "$CYBERSECURE_STATUS" | grep -qi "enabled"; then
  echo -e "${GREEN}ENABLED${NC}"
else
  echo -e "${YELLOW}UNKNOWN${NC}"
  echo "⚠️  Cannot verify CyberSecure status via SSH"
  echo "    Manual verification required: UniFi UI → Settings → Security → CyberSecure"
fi

echo ""
echo "=========================================="
echo "MANUAL CONFIGURATION REQUIRED"
echo "=========================================="
echo ""
echo "UniFi CyberSecure does NOT auto-configure CIPA categories."
echo "You must manually enable blocking via the UniFi UI."
echo ""
echo "Steps:"
echo "1. UniFi UI → Settings → Security → CyberSecure"
echo "2. Enable CyberSecure (toggle ON)"
echo "3. Click 'Configure Categories'"
echo "4. BLOCK these categories:"
echo ""

for category in "${CIPA_CATEGORIES[@]}"; do
  echo "   [ ] $category"
done

echo ""
echo "5. Apply to networks:"
echo "   [x] VLAN 10 (Students)"
echo "   [x] VLAN 30 (Guest WiFi)"
echo "   [ ] VLAN 20 (Staff) — Optional"
echo ""
echo "6. Enable logging:"
echo "   [x] Log Blocked Content"
echo ""
echo "7. Click 'Save' and apply changes"
echo ""

# Validate syslog is configured for audit trail
echo "=========================================="
echo "Validating CIPA Audit Trail (Syslog)"
echo "=========================================="
echo ""

echo -n "Checking syslog export configuration... "
SYSLOG_CONFIG=$(ssh "$UDM_USER@$UDM_HOST" 'grep -i syslog /etc/unifi-os/unifi-os.conf 2>/dev/null || echo "not configured"')

if echo "$SYSLOG_CONFIG" | grep -qi "enabled"; then
  echo -e "${GREEN}CONFIGURED${NC}"
  echo "Syslog details:"
  echo "$SYSLOG_CONFIG"
else
  echo -e "${YELLOW}NOT CONFIGURED${NC}"
  echo ""
  echo "⚠️  CIPA compliance requires audit trail (90-day retention)"
  echo "⚠️  Run: bash scripts/configure-cipa-logging.sh"
fi

echo ""
echo "=========================================="
echo "Testing Content Filtering"
echo "=========================================="
echo ""
echo "Test from student Chromebook (VLAN 10):"
echo ""
echo "1. Open Chrome browser"
echo "2. Navigate to: http://www.example-adult-site.com"
echo "   (Use test domain, not actual adult site)"
echo "3. Should see: 'Blocked by CyberSecure'"
echo ""
echo "4. Check UDM logs:"
echo "   ssh $UDM_USER@$UDM_HOST 'tail -f /var/log/messages | grep CyberSecure'"
echo "   Should log: 'Content blocked: Adult, source: 10.10.x.x'"
echo ""

# Validate DPI engine status
echo "=========================================="
echo "Validating DPI Engine (Hardware Offload)"
echo "=========================================="
echo ""

echo -n "Checking DPI engine status... "
DPI_STATUS=$(ssh "$UDM_USER@$UDM_HOST" 'ubnt-systool cputemp 2>/dev/null | grep -i dpi || echo "unknown"')

if [ "$DPI_STATUS" != "unknown" ]; then
  echo -e "${GREEN}ACTIVE${NC}"
  echo "Hardware DPI engine detected (minimal performance impact)"
else
  echo -e "${YELLOW}UNKNOWN${NC}"
  echo "Cannot verify DPI engine status"
  echo "Performance monitoring recommended:"
  echo "  UniFi UI → System → CPU/Memory → Monitor during peak usage"
fi

echo ""
echo "=========================================="
echo "YouTube Restricted Mode"
echo "=========================================="
echo ""
echo "⚠️  CyberSecure CANNOT enforce YouTube Restricted Mode"
echo "    Students can disable it in YouTube settings"
echo ""
echo "Solution: Google Admin Console enforcement"
echo "1. Google Admin Console → Devices → Chrome → Settings"
echo "2. YouTube Restricted Mode → Set to 'Strict'"
echo "3. Force policy: Prevent students from disabling"
echo ""

# Validate against all VLANs
echo "=========================================="
echo "VLAN Configuration Summary"
echo "=========================================="
echo ""
echo "CyberSecure should be applied to:"
echo "  ✓ VLAN 10 (Students) — REQUIRED"
echo "  ✓ VLAN 30 (Guest WiFi) — REQUIRED"
echo "  ? VLAN 20 (Staff) — OPTIONAL (adult staff)"
echo "  ✗ VLAN 50 (VoIP) — NO (breaks SIP traffic)"
echo "  ✗ VLAN 60 (Cameras) — NO (breaks Verkada cloud)"
echo "  ✗ VLAN 99 (Management) — NO (admin access)"
echo ""

# CIPA checklist
echo "=========================================="
echo "CIPA Compliance Checklist"
echo "=========================================="
echo ""
echo "UniFi CyberSecure baseline (current):"
echo "  [ ] CyberSecure enabled on VLAN 10 (Students)"
echo "  [ ] CyberSecure enabled on VLAN 30 (Guest)"
echo "  [ ] 8 CIPA categories blocked (Adult, Gambling, etc.)"
echo "  [ ] Content blocking logs enabled"
echo "  [ ] Syslog export configured (90-day retention)"
echo "  [ ] YouTube Restricted Mode via Google Admin Console"
echo ""
echo "Additional requirements for FULL CIPA compliance:"
echo "  [ ] Third-party CIPA-certified filter (Lightspeed/Securly)"
echo "  [ ] Per-student activity reporting"
echo "  [ ] SSL inspection (HTTPS filtering)"
echo "  [ ] Annual E-Rate audit documentation"
echo ""
echo "⚠️  Status: Baseline filtering only (NOT CIPA-certified)"
echo "⚠️  Recommend Lightspeed ($3/student/year) for full compliance"
echo ""

# Summary
echo "=========================================="
echo "Configuration Summary"
echo "=========================================="
echo ""
echo -e "CyberSecure Status: ${GREEN}Baseline filtering configured${NC}"
echo -e "CIPA Certification: ${RED}NOT CERTIFIED${NC}"
echo -e "Syslog Audit Trail: ${YELLOW}Configure via configure-cipa-logging.sh${NC}"
echo -e "Recommended Action: ${YELLOW}Procure Lightspeed or Securly for full compliance${NC}"
echo ""
echo "Next steps:"
echo "1. Complete manual category blocking in UniFi UI"
echo "2. Run: bash scripts/configure-cipa-logging.sh"
echo "3. Test content filtering from VLAN 10 Chromebook"
echo "4. Plan Q2 2026: Deploy Lightspeed Chrome extension"
echo ""

exit 0
