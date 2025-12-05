# Troubleshooting Runbook: Printer Discovery & mDNS Issues

**Severity Level:** MEDIUM  
**RTO Target:** 15 minutes (printers back online)  
**Owner:** Suehring Ministry (Network Perimeter)

## Problem: Chromebooks/Staff Can't Find Printers

### Symptoms
- Chromebook goes to Settings > Printers & Scanners → "No printers found"
- Staff member tries to print → "Printer offline" (but printer shows in Verkada)
- Only some printers appear (old ones work, new ones invisible)
- Printers appear intermittently (30% success rate)

### Root Causes (In Order of Likelihood)
1. **Avahi mDNS reflector not running** ← Most common (80%)
2. Printer VLAN (99) isolated from Student/Staff VLANs (10/20)
3. mDNS firewall rule disabled or misconfigured
4. Printer misconfigured (wrong SSID, VLAN, or mDNS disabled)
5. VLAN routing enabled (prevents multicast from reflecting)

---

## Diagnosis: Check Printer Discovery Infrastructure

### Step 1: Verify Avahi Container Running
```bash
#!/bin/bash
# Check if mDNS reflector is alive

echo "=== PRINTER DISCOVERY DIAGNOSIS ==="

# SSH to UDM and check container
ssh ubnt@<udm-ip> "docker ps" | grep -i avahi && echo "✅ Avahi container running" || {
  echo "❌ Avahi container NOT running"
  ssh ubnt@<udm-ip> "docker ps -a" | grep -i avahi && echo "  (But exists, may be stopped)"
}

# If not running, try restart
if ! ssh ubnt@<udm-ip> "docker ps" | grep -q avahi; then
  echo "Attempting restart..."
  ssh ubnt@<udm-ip> "docker restart avahi-reflector" || echo "  Failed to restart"
  sleep 5
  ssh ubnt@<udm-ip> "docker ps" | grep -q avahi && echo "  ✅ Restart successful" || echo "  ❌ Restart failed"
fi
```

### Step 2: Check mDNS Multicast on Network
```bash
#!/bin/bash
# Verify mDNS traffic flowing (UDP 5353)

echo "=== mDNS TRAFFIC CHECK ==="

# Option A: Check from UDM
ssh ubnt@<udm-ip> "netstat -ulnp | grep 5353" && echo "✅ UDP 5353 listening" || echo "⚠️  mDNS port not responding"

# Option B: Check from staff computer (within VLAN-10 or 20)
# (Requires nmap or mdns tools on client)
mdns-query _services._dns-sd._udp.local 2>/dev/null | head -5 && echo "✅ mDNS responses detected" || echo "⚠️  No mDNS responses"

# Option C: Use avahi-browse directly
ssh ubnt@<udm-ip> "avahi-browse _ipp._tcp" 2>/dev/null | grep -i printer && echo "✅ Printers found via mDNS" || echo "❌ No printers discovered"
```

### Step 3: Check Firewall Rule for mDNS Reflection
```bash
#!/bin/bash
# Verify firewall rule allowing mDNS between VLANs

echo "=== FIREWALL mDNS RULE CHECK ==="

unifi-api --query "firewall.rules" | jq '.[] | select(.name | contains("mDNS") or contains("5353")) | {
  name: .name,
  enabled: .enabled,
  protocol: .protocol,
  port: .port,
  src_group: .src_group,
  dst_group: .dst_group,
  action: .action
}'

# Expected rule exists? (enabled=true, action=ACCEPT, port=5353 UDP)
# If missing: ❌ CRITICAL - create firewall rule
# If disabled: ⚠️  Enable it via UniFi WebUI
```

### Step 4: Check Printer VLAN Assignment
```bash
#!/bin/bash
# Verify all printers on VLAN-99 with mDNS enabled

echo "=== PRINTER VLAN & mDNS CONFIG CHECK ==="

# Query all printers in Loki or via SNMP
# This is pseudo-code; adapt to your printer management system

# Example: Ricoh/Xerox printers via SNMP
PRINTERS=("10.20.99.10" "10.20.99.11" "10.20.99.12")

for printer_ip in "${PRINTERS[@]}"; do
  echo "Checking $printer_ip:"
  
  # 1. Ping printer
  ping -c 1 -W 2 "$printer_ip" &>/dev/null && echo "  ✅ Reachable" || echo "  ❌ Not responding"
  
  # 2. Check mDNS enabled via SNMP (if supported)
  snmpget -v2c -c public "$printer_ip" 1.3.6.1.4.1 2>/dev/null | grep -q "active" && echo "  ✅ mDNS active" || echo "  ⚠️  mDNS status unknown"
  
  # 3. Check VLAN (via printer WebUI)
  # Example: curl -s "http://$printer_ip/config" | grep -i vlan
  echo "  (Check printer WebUI manually for VLAN)"
done
```

### Step 5: Check if VLAN Routing Enabled (Blocks Multicast)
```bash
#!/bin/bash
# VLAN routing prevents multicast reflection (critical discovery issue)

echo "=== VLAN ROUTING STATUS CHECK ==="

unifi-api --query "vlan.routing.enabled" | jq '.'

if unifi-api --query "vlan.routing.enabled" | jq -e '.enabled == true' >/dev/null 2>&1; then
  echo "❌ CRITICAL: VLAN routing ENABLED (blocks multicast reflection)"
  echo "  Action: Disable via UniFi WebUI > Network > VLAN > Routing: OFF"
  echo "         (This is normal - we use firewall rules, not routing)"
else
  echo "✅ VLAN routing disabled (correct for mDNS reflection)"
fi
```

---

## Solution: Enable Printer Discovery

### Quick Fix: Restart Avahi Container
```bash
#!/bin/bash
# 90% of issues solved by restarting mDNS reflector

echo "=== AVAHI QUICK RESTART ==="

ssh ubnt@<udm-ip> << 'EOF'
echo "Stopping Avahi container..."
docker stop avahi-reflector || echo "(Not running)"
sleep 2

echo "Starting Avahi container..."
docker start avahi-reflector

sleep 5
docker ps | grep avahi && echo "✅ Avahi restarted successfully" || echo "❌ Restart failed"

# Verify mDNS traffic
netstat -ulnp 2>/dev/null | grep 5353 && echo "✅ UDP 5353 listening" || echo "⚠️  mDNS not listening"
EOF

echo ""
echo "Waiting for printers to re-advertise (1-2 min)..."
sleep 60

echo "Testing from client device:"
echo "  1. Go to Chromebook Settings > Printers & Scanners"
echo "  2. Click 'Add Printer'"
echo "  3. Do you see printers? (expected: yes)"
```

### Medium Fix: Verify Firewall Rule
```bash
#!/bin/bash
# Enable mDNS firewall rule if disabled

echo "=== FIREWALL RULE VERIFICATION ==="

# Check if mDNS rule exists
RULE_ID=$(unifi-api --query "firewall.rules" | jq -r '.[] | select(.name | contains("mDNS")) | .id' | head -1)

if [ -z "$RULE_ID" ]; then
  echo "❌ No mDNS firewall rule found"
  echo "Action: Create rule via UniFi WebUI"
  echo "  1. Settings > Firewall > Rules"
  echo "  2. Click '+ Create New Rule'"
  echo "  3. Name: 'Allow mDNS Reflection'"
  echo "  4. Protocol: UDP, Port: 5353"
  echo "  5. Action: Accept"
  echo "  6. Click Save & Apply"
else
  echo "Rule ID: $RULE_ID"
  
  # Check if enabled
  ENABLED=$(unifi-api --query "firewall.rules.$RULE_ID.enabled")
  if [ "$ENABLED" == "true" ]; then
    echo "✅ mDNS rule is enabled"
  else
    echo "⚠️  mDNS rule DISABLED"
    echo "Enabling..."
    unifi-api --command "update-firewall-rule" --rule_id "$RULE_ID" --enabled true
    echo "✅ Rule enabled"
  fi
fi
```

### Comprehensive Fix: Validate Entire Printer Discovery Stack
```bash
#!/bin/bash
# Full diagnostic + fix procedure

echo "=== COMPREHENSIVE PRINTER DISCOVERY FIX ==="

# 1. Stop & restart Avahi
echo "Step 1: Restart Avahi container..."
ssh ubnt@<udm-ip> "docker restart avahi-reflector"
sleep 10

# 2. Enable firewall rule
echo "Step 2: Verify firewall rule..."
unifi-api --query "firewall.rules" | jq '.[] | select(.name | contains("mDNS")) | .id' | while read rule_id; do
  unifi-api --command "update-firewall-rule" --rule_id "$rule_id" --enabled true
done

# 3. Disable VLAN routing (if enabled)
echo "Step 3: Check VLAN routing..."
unifi-api --query "vlan.routing" | jq -e '.enabled == true' && {
  echo "Disabling VLAN routing..."
  unifi-api --command "update-vlan-routing" --enabled false
}

# 4. Broadcast AP update
echo "Step 4: Broadcasting changes to APs..."
unifi-api --command "force-provision-all-devices"

# 5. Wait & test
echo "Step 5: Waiting for convergence (2 min)..."
sleep 120

# 6. Verify printers now discoverable
echo "Step 6: Testing printer discovery..."
PRINTER_COUNT=$(unifi-api --query "device.type:printer" 2>/dev/null | jq 'length')
echo "Printers found on network: $PRINTER_COUNT"

if [ "$PRINTER_COUNT" -gt 0 ]; then
  echo "✅ PRINTER DISCOVERY RESTORED"
  echo "Printers should now be visible in Settings > Printers & Scanners"
else
  echo "⚠️  No printers still not detected"
  echo "Run manual checks above (printer VLAN, SSID, mDNS enabled on printer)"
fi
```

---

## Printer-Side Troubleshooting: Check Individual Printer

### Step 1: Verify Printer Network Config
```bash
#!/bin/bash
# Access printer WebUI to check settings

PRINTER_IP="10.20.99.10"  # Example printer IP

echo "=== PRINTER NETWORK CONFIG CHECK ==="
echo "Accessing $PRINTER_IP..."

# 1. Is printer on correct VLAN?
# Open browser: http://<printer_ip>/
# Network > TCP/IP > Verify IP is 10.20.99.x (VLAN-99)

# 2. Is mDNS enabled?
# Open browser: http://<printer_ip>/
# Network > mDNS > Ensure "Enable mDNS" = ON

# 3. Check printer hostname
# Settings > Device Info > Hostname should be unique
# Example: "ricoh-printer-east" (not "Printer" or "RICOH")

# 4. Ping printer from UDM
ssh ubnt@<udm-ip> "ping -c 2 $PRINTER_IP" && echo "✅ Printer reachable" || echo "❌ Printer not responding"
```

### Step 2: Restart Printer mDNS Service
```bash
# If printer has built-in mDNS toggle:
# 1. Open printer WebUI: http://<printer_ip>/
# 2. Go to Network > mDNS
# 3. Toggle OFF then ON (soft restart)
# 4. Wait 30 seconds
# 5. Attempt discovery again

echo "✅ Printer mDNS restarted"
echo "If still not discovered: Check printer's physical network cable (may be loose)"
```

---

## Testing: Verify Printer Discovery End-to-End

### Test 1: mDNS Broadcast from Printer
```bash
#!/bin/bash
# Listen for printer mDNS announcements (from UDM)

PRINTER_IP="10.20.99.10"

echo "=== LISTENING FOR PRINTER MDNS ANNOUNCEMENTS ==="
echo "Listening on UDP 5353 for printer mDNS packets..."
echo "Trigger printer mDNS: Restart printer or toggle mDNS OFF/ON"
echo ""

ssh ubnt@<udm-ip> << 'EOF'
timeout 30 tcpdump -i eth0 -n 'udp port 5353' | grep -E "PRINTER_NAME|_ipp._tcp|_http._tcp"
EOF

# Expected: See multicast packets from printer
```

### Test 2: Client Discovers Printer
```bash
#!/bin/bash
# From Chromebook or staff computer

echo "=== CLIENT PRINTER DISCOVERY TEST ==="

# Method 1: Chromebook
echo "On Chromebook: Settings > Printers & Scanners > 'Add Printer'"
echo "Do you see desired printer? (Yes/No)"

# Method 2: Linux/Mac command line
avahi-browse -r _ipp._tcp 2>/dev/null | grep -i printer

# Expected: Print queue appears within 10 seconds
```

### Test 3: Actual Print Job
```bash
#!/bin/bash
# Send test page to printer (validates end-to-end)

PRINTER_NAME="Ricoh-Office"  # Printer's mDNS name
PRINTER_QUEUE="Ricoh-Office"  # Print queue name

echo "=== PRINT TEST ==="
echo "Sending test page to $PRINTER_NAME..."

# Option 1: Via lp command (Linux)
echo "Test Page" | lp -h <cups-server> -d "$PRINTER_QUEUE" -n 1

# Option 2: Via Chromebook native print
# Chromebook: Ctrl+P > Select printer > Print test page

# Expected: Page prints within 30 seconds
echo "✅ Print test complete"
```

---

## If Printer Still Not Found: Advanced Debugging

### Check Avahi Configuration
```bash
#!/bin/bash
# Avahi must reflect between VLAN 10/20 and VLAN 99

echo "=== AVAHI CONFIGURATION CHECK ==="

ssh ubnt@<udm-ip> << 'EOF'
cat /etc/avahi/avahi-reflector.conf | grep -E "enable-reflector|reflect-ipv|interfaces"

# Expected output:
# enable-reflector=yes
# reflect-ipv4=yes
# interfaces: br0 br1 (or similar, must include Avahi network interfaces)
EOF
```

### Manual mDNS Query Test
```bash
#!/bin/bash
# Manually query mDNS without going through Chromebook

VLAN_IP="10.20.1.50"  # Any device on VLAN-10 or 20

echo "=== MANUAL MDNS QUERY ==="

# From UDM, query mDNS directly
ssh ubnt@<udm-ip> "avahi-resolve-address $VLAN_IP" && echo "✅ Avahi responding to queries" || echo "❌ Avahi not responding"

# Query printer services
ssh ubnt@<udm-ip> "avahi-browse -p _ipp._tcp 2>/dev/null" | head -5
```

---

## Permanent Fix: Validate Quarterly

### Monthly Printer Check
```bash
#!/bin/bash
# Run monthly to ensure printers stay discoverable

echo "=== MONTHLY PRINTER HEALTH CHECK ==="

PRINTER_VLANS="10.20.99"  # VLAN 99 for printers

# 1. Count printers online
ONLINE=$(ping -b -c 1 10.20.99.255 2>/dev/null | grep "bytes from" | wc -l)
echo "Printers online: $ONLINE"

# 2. Verify Avahi running
docker ps | grep -q avahi && echo "✅ Avahi running" || echo "⚠️  Avahi down"

# 3. Verify firewall rule enabled
unifi-api --query "firewall.rules" | jq '.[] | select(.name | contains("mDNS")) | .enabled' | grep -q "true" && echo "✅ mDNS firewall rule ON" || echo "⚠️  Rule disabled"

# 4. Test discovery from client
# (Manual: Use Chromebook, should find all printers)

echo "✅ Monthly check complete"
```

---

## Related Documents
- [SUEHRING-PERIMETER.md](../trinity/SUEHRING-PERIMETER.md) - Firewall rules & VLAN architecture
- [ADR-010: mDNS Selective Reflection](../adr/010-mdns-selective-reflection.md) - mDNS architecture rationale
- [03-mdns-printers.md](03-mdns-printers.md) - Printer deployment runbook
- [config/avahi/docker-compose.yml](../../config/avahi/docker-compose.yml) - Avahi container config

**CRITICAL REMINDER:** 90% of printer discovery issues are Avahi container crashes. Always check container status first (`docker ps`).
