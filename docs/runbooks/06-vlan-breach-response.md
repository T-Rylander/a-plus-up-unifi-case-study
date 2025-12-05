# Security Runbook: VLAN Breach Response

**Severity Level:** CRITICAL + IMMEDIATE  
**Escalation:** Level 3 (IT Leadership + District IT)  
**RTO Target:** 30 seconds (VLAN isolation), 5 minutes (full remediation)  
**Owner:** Carter Ministry (Secrets & Identity) + Suehring Ministry (Perimeter)

## What Is a VLAN Breach?

A VLAN breach occurs when an unauthorized user gains access to a VLAN they shouldn't be on, either by:
1. **Rogue device**: Laptop/phone connects to wrong SSID
2. **VLAN hopping**: Attacker uses 802.1Q double-tagging or VLAN ID manipulation
3. **Compromised access point**: AP itself is compromised, serving wrong VLAN
4. **Firewall rule failure**: Firewall misconfiguration allows cross-VLAN traffic

### VLAN Structure (6 Total)
| VLAN | Purpose | Allowed Access | Isolation Priority |
|------|---------|---|---|
| **VLAN-10** | Students | WiFi + Print + Internet | HIGH |
| **VLAN-20** | Staff | WiFi + Print + Internet + Management | HIGH |
| **VLAN-30** | Guests | WiFi + Internet ONLY | CRITICAL |
| **VLAN-50** | VoIP | Yealink phones + SIP proxy | HIGH |
| **VLAN-60** | Cameras | Verkada cameras + Cloud sync | HIGH |
| **VLAN-99** | Printers | VLAN-10/20 discovery only | MEDIUM |

---

## Immediate Response (T+0 to T+2 min): VLAN Isolation

### Step 1: Identify the Breach (Discovery Phase)
```bash
#!/bin/bash
# Run this on UDM as soon as breach suspected

echo "=== VLAN BREACH DETECTION ==="
TARGET_VLAN=${1:-10}  # Specify affected VLAN (e.g., VLAN-10 = students)

# 1. List all devices on target VLAN
echo "Devices on VLAN-$TARGET_VLAN:"
unifi-api --query "vlan.$TARGET_VLAN.devices" | jq '.[] | {hostname, mac, ip_addr, last_seen}'

# 2. Check for unauthorized devices
echo ""
echo "Known device list for VLAN-$TARGET_VLAN:"
# (Compare against approved device list from inventory/chromebook-inventory.json)

# 3. Verify VLAN routing enabled (should be OFF)
echo ""
echo "VLAN Routing Status:"
unifi-api --query "vlan.routing.enabled" | grep -q "false" && echo "  ✅ Routing DISABLED (correct)" || echo "  ❌ ROUTING ENABLED (potential vulnerability)"

# 4. Check firewall rules for cross-VLAN traffic
echo ""
echo "Firewall Rules (checking for cross-VLAN leaks):"
unifi-api --query "firewall.rules" | jq '.[] | select(.src_vlan != .dst_vlan and .action == "ACCEPT") | {name, src_vlan, dst_vlan, action}'
```

### Step 2: Immediate Isolation (30-Second Action)
```bash
#!/bin/bash
# CRITICAL: Isolate affected VLAN NOW

TARGET_VLAN=${1:-10}
echo "🚨 ISOLATING VLAN-$TARGET_VLAN (30 SEC EMERGENCY)"

# Option A: Disable VLAN entirely (most aggressive)
unifi-api --command "disable-vlan" --vlan $TARGET_VLAN
echo "✅ VLAN-$TARGET_VLAN DISABLED"

# Option B: Drop all traffic (less destructive)
# unifi-api --command "firewall-drop-vlan" --vlan $TARGET_VLAN

# Option C: Isolate from specific VLANs only
# unifi-api --command "firewall-block-vlan-to-vlan" --src $TARGET_VLAN --dst 20 && \
# unifi-api --command "firewall-block-vlan-to-vlan" --src $TARGET_VLAN --dst 99
```

### Step 3: Alert Stakeholders (Immediate)
```bash
#!/bin/bash
# Send alerts via Mattermost

VLAN=${1:-10}
BREACH_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Mattermost Alert (Carter Ministry)
curl -X POST https://mattermost.yourdomain.com/hooks/xxxxx \
  -d '{
    "text": "🚨 **VLAN BREACH ALERT**",
    "attachments": [{
      "fallback": "VLAN Breach Detected",
      "color": "danger",
      "title": "VLAN Breach Response Initiated",
      "fields": [
        {"title": "Affected VLAN", "value": "VLAN-'$VLAN'", "short": true},
        {"title": "Detection Time", "value": "'$BREACH_TIME'", "short": true},
        {"title": "Action Taken", "value": "VLAN ISOLATED (Emergency Mode)", "short": false},
        {"title": "Next Steps", "value": "1. Investigate device logs\n2. Check device inventory\n3. Re-enable after clearance", "short": false}
      ]
    }]
  }'

# SMS Alert to IT Lead (fallback, if Mattermost fails)
# twilio_send_sms "IT_LEAD_PHONE" "VLAN-$VLAN BREACH: Check Mattermost alerts immediately"
```

---

## Investigation Phase (T+2 to T+15 min): Root Cause Analysis

### Suspicious Device Investigation
```bash
#!/bin/bash
# Investigate specific device on affected VLAN

TARGET_MAC="00:1A:2B:3C:4D:5E"  # Replace with suspected device MAC
TARGET_VLAN=10

echo "=== DEVICE INVESTIGATION ==="
echo "MAC: $TARGET_MAC"
echo "VLAN: VLAN-$TARGET_VLAN"
echo ""

# 1. Get device info
DEVICE_INFO=$(unifi-api --query "device.by_mac" --mac $TARGET_MAC)
echo "Device Details:"
echo "$DEVICE_INFO" | jq '{hostname, ip_addr, vendor, ssid, signal_strength, last_seen}'

# 2. Check vendor (known/unknown?)
VENDOR=$(echo "$DEVICE_INFO" | jq -r '.vendor')
echo ""
echo "Vendor Analysis: $VENDOR"
if echo "$VENDOR" | grep -qi "chromebook\|apple\|dell\|lenovo"; then
  echo "  ✅ Known device type (likely legitimate)"
else
  echo "  ⚠️  UNKNOWN VENDOR (investigate further)"
fi

# 3. Compare against approved inventory
INVENTORY_MACS=$(jq -r '.[] | .mac_address' inventory/chromebook-inventory.json 2>/dev/null | tr '[:upper:]' '[:lower:]')
if echo "$INVENTORY_MACS" | grep -q $(echo $TARGET_MAC | tr '[:upper:]' '[:lower:]'); then
  echo "  ✅ Found in approved inventory"
else
  echo "  ❌ NOT IN INVENTORY (unauthorized device)"
fi

# 4. Check connection method
CONNECTION_TYPE=$(echo "$DEVICE_INFO" | jq -r '.connection_method')
echo ""
echo "Connection: $CONNECTION_TYPE"
case "$CONNECTION_TYPE" in
  "wireless") 
    SSID=$(echo "$DEVICE_INFO" | jq -r '.ssid')
    echo "  SSID: $SSID"
    echo "  Action: Check AP logs, may be SSID misconfiguration"
    ;;
  "ethernet") 
    PORT=$(echo "$DEVICE_INFO" | jq -r '.switch_port')
    echo "  Switch Port: $PORT"
    echo "  Action: Physically unplug port, check access control"
    ;;
esac

# 5. Activity log
echo ""
echo "Recent Activity:"
unifi-api --query "device.events" --mac $TARGET_MAC | jq -r '.[] | "\(.timestamp): \(.event_type)"' | tail -10
```

### Firewall Rule Audit
```bash
#!/bin/bash
# Check if firewall rule allowed the breach

echo "=== FIREWALL RULE AUDIT ==="
echo "Checking all 11 firewall rules for cross-VLAN leaks..."
echo ""

unifi-api --query "firewall.rules" | jq -r '.[] | 
  "\(.name): \(.src_vlan // "any") → \(.dst_vlan // "any") [\(.action)]"' | while read rule; do
  if echo "$rule" | grep -qi "accept"; then
    echo "  🔴 $rule  (⚠️ POTENTIAL LEAK)"
  else
    echo "  ✅ $rule"
  fi
done

# Verify expected rules exist
echo ""
echo "Critical Rules Check:"
unifi-api --query "firewall.rules" | jq '.[] | select(.name | contains("Block Guest VLAN")) | .action' | grep -q "DROP" && \
  echo "  ✅ Guest isolation rule active" || \
  echo "  ❌ Guest isolation rule MISSING or disabled!"
```

---

## Remediation Phase (T+15 to T+30 min): Fix & Restore

### If Cause Was: Unauthorized Device
```bash
#!/bin/bash
# Remove rogue device and block its MAC

ROGUE_MAC="00:1A:2B:3C:4D:5E"
ROGUE_VLAN=10

echo "=== REMOVING ROGUE DEVICE ==="

# 1. Kick device off network (via AP)
unifi-api --command "disconnect-client" --mac $ROGUE_MAC
echo "✅ Device disconnected from WiFi"

# 2. Block MAC address
unifi-api --command "block-mac" --mac $ROGUE_MAC
echo "✅ MAC address blocked"

# 3. Send admin alert
curl -X POST https://mattermost.yourdomain.com/hooks/xxxxx \
  -d '{"text": "✅ Rogue device blocked: '$ROGUE_MAC' (was on VLAN-'$ROGUE_VLAN')"}'
```

### If Cause Was: Firewall Rule Error
```bash
#!/bin/bash
# Restore correct firewall rules

echo "=== FIREWALL RULE RESTORATION ==="

# Backup current (broken) rules
cp config/unifi/firewall-rules.json config/unifi/firewall-rules.json.broken

# Restore from git (last known good)
git checkout config/unifi/firewall-rules.json
echo "✅ Firewall rules restored to last known good"

# Re-apply rules
unifi-api --command "import-firewall-rules" --file config/unifi/firewall-rules.json
echo "✅ Rules applied to UDM"

# Validate
unifi-api --query "firewall.rules.count" | grep -q "11" && echo "✅ All 11 rules active" || echo "⚠️  Rule count mismatch"
```

### If Cause Was: Compromised Access Point
```bash
#!/bin/bash
# Isolate and investigate AP

COMPROMISED_AP="ap-east"

echo "=== COMPROMISED AP RESPONSE ==="

# 1. Disconnect all clients
unifi-api --command "disconnect-ap-clients" --device $COMPROMISED_AP
echo "✅ All clients disconnected from $COMPROMISED_AP"

# 2. Disable AP (take offline)
unifi-api --command "disable-device" --device $COMPROMISED_AP
echo "⚠️  $COMPROMISED_AP disabled for investigation"

# 3. Check AP firmware
FIRMWARE=$(unifi-api --query "device.$COMPROMISED_AP.firmware")
echo "Firmware: $FIRMWARE"
echo "  Action: Check for known vulnerabilities (CVE database)"

# 4. Reset AP to factory (if confirmed compromised)
read -p "Reset to factory? (y/n): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  unifi-api --command "reset-device" --device $COMPROMISED_AP
  echo "✅ AP reset to factory defaults"
  echo "⚠️  Will need reconfiguration (SSID, VLAN, etc.)"
fi
```

---

## Restore Phase (T+30 to T+60 min): VLAN Re-enablement

### Safety Checklist Before Re-enabling VLAN
- [ ] Rogue device removed or MAC address blocked
- [ ] Firewall rules verified (all 11 rules correct)
- [ ] Access point firmware up-to-date
- [ ] Firewall rule audit complete (no cross-VLAN leaks found)
- [ ] Incident documented in Loki log
- [ ] All-clear from Carter Ministry (Identity/Access control)

### Re-enable VLAN Safely
```bash
#!/bin/bash
# Restore VLAN with monitoring

RESTORED_VLAN=10
echo "=== VLAN RESTORATION ($RESTORED_VLAN) ==="

# 1. Enable VLAN
unifi-api --command "enable-vlan" --vlan $RESTORED_VLAN
echo "✅ VLAN-$RESTORED_VLAN re-enabled"

# 2. Verify traffic flow (test devices reconnect)
sleep 5
DEVICE_COUNT=$(unifi-api --query "vlan.$RESTORED_VLAN.devices" | jq 'length')
echo "Devices on VLAN-$RESTORED_VLAN: $DEVICE_COUNT"

# 3. Test connectivity
echo "Testing connectivity..."
unifi-api --command "test-vlan-ping" --vlan $RESTORED_VLAN 8.8.8.8 && echo "  ✅ Internet connectivity OK" || echo "  ❌ No internet (investigate WAN)"

# 4. Alert stakeholders
curl -X POST https://mattermost.yourdomain.com/hooks/xxxxx \
  -d '{"text": "✅ VLAN-'$RESTORED_VLAN' restored. Breach contained. Investigation ongoing."}'
```

---

## Post-Incident (T+60+ min): Documentation & Prevention

### Incident Report Template
```yaml
incident_id: VLAN_BREACH_2024_12_19_001
severity: CRITICAL
date: 2024-12-19T14:23:00Z
affected_vlan: 10  # Students

# TIMELINE
timeline:
  - time: 14:23
    event: Breach detected (unauthorized device on VLAN-10)
    action: VLAN isolated (30 sec)
  - time: 14:28
    event: Investigation started
    action: Scanned device inventory
  - time: 14:35
    event: Root cause found: MAC address not in approved inventory
    action: Device blocked, MAC added to deny-list
  - time: 14:42
    event: Firewall rules audited
    action: All 11 rules verified correct
  - time: 14:50
    event: VLAN restored
    action: Monitored device reconnection

# FINDINGS
root_cause: |
  Visiting family member connected personal laptop to Staff SSID (VLAN-20).
  Device misconfigured to use VLAN-10 (attempted to reach student data).
  Firewall rules correctly blocked cross-VLAN access.
  NO unauthorized data access occurred.

impact: |
  - Duration of breach: ~25 minutes
  - Data exposed: NONE (firewall prevented access)
  - User impact: NONE (staff/student WiFi remained available)
  - System impact: No firewall rule degradation

# IMPROVEMENTS
improvements:
  - Add device to MAC deny-list (prevent future reconnection)
  - Update visitor WiFi policy (require IT enrollment)
  - Add quarterly VLAN isolation testing to validation schedule

next_validation: 2024-12-26 (7 days post-incident)
```

### Firewall Rule Validation (Post-Incident)
```bash
#!/bin/bash
# Ensure all firewall rules still working correctly

echo "=== POST-INCIDENT FIREWALL VALIDATION ==="

# 1. Test all 11 rules individually
unifi-api --query "firewall.rules" | jq -r '.[] | "\(.id): \(.name)"' | while read rule; do
  RULE_ID=$(echo $rule | cut -d: -f1)
  RULE_NAME=$(echo $rule | cut -d: -f2-)
  
  # Check if rule is enabled
  unifi-api --query "firewall.rules.$RULE_ID.enabled" | grep -q "true" && echo "✅ $RULE_NAME" || echo "❌ $RULE_NAME (disabled)"
done

# 2. Verify VLAN isolation still enforced
echo ""
echo "VLAN Isolation Test:"
unifi-api --command "test-vlan-isolation" --vlan1 10 --vlan2 30 && echo "  ✅ VLAN-10 ✘ VLAN-30 (correct)" || echo "  ❌ Cross-VLAN traffic detected"

echo ""
echo "✅ Post-incident validation complete"
```

---

## Prevention: Quarterly Security Review

### Monthly Checklist
- [ ] Review unauthorized device logs (look for MACs not in inventory)
- [ ] Verify all firewall rules still enabled (none accidentally disabled)
- [ ] Test VLAN isolation (ping test between VLANs, should fail)
- [ ] Review access point logs for suspicious SSID changes

### Quarterly Drill
- [ ] Simulate VLAN breach (intentional, controlled)
- [ ] Time response (target: isolation <1 min)
- [ ] Document what went well / what to improve
- [ ] Update this runbook based on findings

---

## Related Documents
- [SUEHRING-PERIMETER.md](../trinity/SUEHRING-PERIMETER.md) - Firewall rules & VLAN architecture
- [CARTER-SECRETS.md](../trinity/CARTER-SECRETS.md) - Identity & access control
- [MINISTRY-CHARTER.md](../trinity/MINISTRY-CHARTER.md) - Incident escalation matrix
- [inventory/chromebook-inventory.json](../../inventory/chromebook-inventory.json) - Approved device list

**CRITICAL REMINDER:** Time is key in VLAN breaches. The first 30 seconds (VLAN isolation) matter more than perfect investigation. Isolate first, investigate second.
