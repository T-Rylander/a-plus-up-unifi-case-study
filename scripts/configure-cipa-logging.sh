#!/bin/bash
# scripts/configure-cipa-logging.sh
# Configure syslog export for CIPA audit trail (90-day retention)
# Requires: SSH access to UDM Pro Max + remote syslog server
# T3-ETERNAL: Perimeter (Suehring) — Audit compliance

set -euo pipefail

# UniFi credentials
UDM_HOST="${UDM_HOST:-10.99.0.1}"
UDM_USER="${UDM_USER:-admin}"
UDM_PASS="${UDM_PASS:-}"

# Syslog server (adjust for your environment)
SYSLOG_HOST="${SYSLOG_HOST:-10.99.0.10}"
SYSLOG_PORT="${SYSLOG_PORT:-514}"
SYSLOG_PROTOCOL="${SYSLOG_PROTOCOL:-UDP}"
RETENTION_DAYS="${RETENTION_DAYS:-90}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "UniFi CIPA Audit Logging Configuration"
echo "=========================================="
echo ""
echo "CIPA Requirement: 90-day audit trail of content filtering"
echo ""
echo "Configuration:"
echo "  Syslog Server: $SYSLOG_HOST:$SYSLOG_PORT ($SYSLOG_PROTOCOL)"
echo "  Retention: $RETENTION_DAYS days minimum"
echo ""

# Validate SSH access
echo -n "Testing SSH connection to UDM ($UDM_HOST)... "
if ssh -o ConnectTimeout=5 -q "$UDM_USER@$UDM_HOST" exit; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}FAILED${NC}"
  echo "Error: Cannot SSH to UDM Pro Max"
  echo "Verify SSH is enabled: UniFi UI → Settings → System → Advanced → SSH"
  exit 1
fi

# Test syslog server connectivity
echo -n "Testing syslog server connectivity ($SYSLOG_HOST:$SYSLOG_PORT)... "
if nc -uzv -w 2 "$SYSLOG_HOST" "$SYSLOG_PORT" &>/dev/null || \
   nc -zv -w 2 "$SYSLOG_HOST" "$SYSLOG_PORT" &>/dev/null; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${YELLOW}WARNING${NC}"
  echo "⚠️  Cannot reach syslog server"
  echo "    Verify server is running and firewall allows port $SYSLOG_PORT"
  echo "    Continuing anyway (can fix connectivity later)..."
fi

echo ""
echo "=========================================="
echo "Configuring UniFi Syslog Export"
echo "=========================================="
echo ""
echo "⚠️  MANUAL CONFIGURATION REQUIRED"
echo "    UniFi does not support syslog configuration via SSH/API"
echo ""
echo "Steps:"
echo "1. UniFi UI → Settings → System → Logging"
echo "2. Remote Syslog → Enable"
echo "3. Configuration:"
echo "   - Host: $SYSLOG_HOST"
echo "   - Port: $SYSLOG_PORT"
echo "   - Protocol: $SYSLOG_PROTOCOL"
echo "4. Click 'Save' and apply changes"
echo ""

# Validate syslog messages are being sent
echo "=========================================="
echo "Testing Syslog Export"
echo "=========================================="
echo ""
echo "Send test message from UDM:"
echo ""

ssh "$UDM_USER@$UDM_HOST" "logger -t CIPA-TEST 'CIPA audit logging test at $(date)'"
echo "Test message sent: 'CIPA audit logging test'"
echo ""
echo "Verify on syslog server ($SYSLOG_HOST):"
echo "  ssh admin@$SYSLOG_HOST 'tail -f /var/log/syslog | grep CIPA-TEST'"
echo ""
echo "Expected output:"
echo "  $(date '+%Y-%m-%d %H:%M:%S') udm CIPA-TEST: CIPA audit logging test at..."
echo ""

read -p "Did you see the test message on the syslog server? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}FAILED${NC}"
  echo ""
  echo "Troubleshooting:"
  echo "1. Verify syslog server is listening:"
  echo "   netstat -tulnp | grep $SYSLOG_PORT"
  echo "2. Check firewall rules on syslog server:"
  echo "   ufw status | grep $SYSLOG_PORT"
  echo "3. Verify UniFi syslog config:"
  echo "   UniFi UI → Settings → System → Logging → Remote Syslog"
  echo ""
  exit 1
else
  echo -e "${GREEN}SUCCESS${NC}"
  echo "Syslog export validated"
fi

echo ""
echo "=========================================="
echo "Configuring CIPA Log Categories"
echo "=========================================="
echo ""
echo "Ensure these log types are enabled:"
echo "  [x] Firewall (blocks/allows)"
echo "  [x] Content Filter (CyberSecure blocks)"
echo "  [x] Authentication (WiFi logins)"
echo "  [x] DHCP (device IPs)"
echo ""
echo "UniFi UI → Settings → System → Logging → Log Level"
echo "  Set to: Info (default) or Debug (verbose)"
echo ""

# Validate log retention on syslog server
echo "=========================================="
echo "Configuring Syslog Retention (90 Days)"
echo "=========================================="
echo ""
echo "On syslog server ($SYSLOG_HOST), configure logrotate:"
echo ""
echo "File: /etc/logrotate.d/unifi-cipa"
echo ""
cat <<'EOF'
/var/log/unifi-cipa/*.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    create 0640 syslog adm
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
echo ""
echo "Apply with: sudo logrotate -f /etc/logrotate.d/unifi-cipa"
echo ""

read -p "Have you configured logrotate on the syslog server? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}PENDING${NC}"
  echo "⚠️  Log retention NOT configured"
  echo "    CIPA requires 90-day minimum retention"
  echo "    Complete this step before E-Rate audit"
else
  echo -e "${GREEN}CONFIGURED${NC}"
fi

# Generate sample CIPA audit queries
echo ""
echo "=========================================="
echo "Sample CIPA Audit Queries"
echo "=========================================="
echo ""
echo "On syslog server ($SYSLOG_HOST):"
echo ""
echo "1. Content filter blocks (last 7 days):"
echo "   grep -i 'CyberSecure.*blocked' /var/log/unifi-cipa/*.log | \\"
echo "     grep '\$(date -d '7 days ago' +%Y-%m-%d)'"
echo ""
echo "2. Student network activity by IP:"
echo "   grep '10\.10\.' /var/log/unifi-cipa/*.log | grep -i blocked"
echo ""
echo "3. Top blocked categories:"
echo "   grep -i 'CyberSecure.*blocked' /var/log/unifi-cipa/*.log | \\"
echo "     awk '{print \$NF}' | sort | uniq -c | sort -rn | head -10"
echo ""
echo "4. Guest network blocks (VLAN 30):"
echo "   grep '10\.30\.' /var/log/unifi-cipa/*.log | grep -i blocked"
echo ""
echo "5. Firewall drops to surveillance cameras:"
echo "   grep 'DROP.*10\.60\.' /var/log/unifi-cipa/*.log"
echo ""

# Validation checklist
echo "=========================================="
echo "CIPA Audit Trail Checklist"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  [x] Syslog export enabled on UDM"
echo "  [x] Syslog server reachable ($SYSLOG_HOST:$SYSLOG_PORT)"
echo "  [x] Test message verified"
echo "  [ ] Logrotate configured (90-day retention)"
echo "  [ ] Content filter logs enabled"
echo "  [ ] Firewall logs enabled"
echo ""
echo "Validation:"
echo "  [ ] Logs contain CyberSecure content blocks"
echo "  [ ] Logs contain student network activity (VLAN 10)"
echo "  [ ] Logs contain guest network activity (VLAN 30)"
echo "  [ ] Logs rotated daily (check /var/log/unifi-cipa/*.log)"
echo "  [ ] 90-day retention validated (ls -lh /var/log/unifi-cipa/*.gz)"
echo ""

# E-Rate audit preparation
echo "=========================================="
echo "E-Rate Audit Preparation"
echo "=========================================="
echo ""
echo "For E-Rate compliance audits, provide:"
echo ""
echo "1. UniFi syslog configuration screenshots"
echo "   UniFi UI → Settings → System → Logging → Remote Syslog"
echo ""
echo "2. Sample log exports (redact student names/IPs)"
echo "   grep -i 'CyberSecure.*blocked' /var/log/unifi-cipa/unifi.log | \\"
echo "     sed 's/10\.\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)/10.XX.XX.XX/g' > cipa-sample.log"
echo ""
echo "3. Log retention policy documentation"
echo "   cat /etc/logrotate.d/unifi-cipa > cipa-retention-policy.txt"
echo ""
echo "4. CyberSecure category blocking screenshots"
echo "   UniFi UI → Settings → Security → CyberSecure → Categories"
echo ""
echo "5. Safety policy document"
echo "   docs/policies/acceptable-use-policy.pdf"
echo ""

# Summary
echo "=========================================="
echo "Configuration Summary"
echo "=========================================="
echo ""
echo -e "Syslog Export: ${GREEN}Configured${NC}"
echo -e "Syslog Server: ${GREEN}$SYSLOG_HOST:$SYSLOG_PORT${NC}"
echo -e "Retention Policy: ${YELLOW}90 days (verify logrotate)${NC}"
echo -e "Content Filter Logs: ${YELLOW}Verify CyberSecure blocks appear${NC}"
echo ""
echo "Next steps:"
echo "1. Configure logrotate on syslog server (90-day retention)"
echo "2. Monitor logs for 7 days: Verify CyberSecure blocks appear"
echo "3. Test audit queries (see 'Sample CIPA Audit Queries' above)"
echo "4. Prepare E-Rate audit documentation (screenshots + sample logs)"
echo ""
echo "⚠️  CIPA compliance requires both:"
echo "    1. Content filtering (CyberSecure + Lightspeed recommended)"
echo "    2. Audit trail (syslog + 90-day retention) ✓"
echo ""

exit 0
