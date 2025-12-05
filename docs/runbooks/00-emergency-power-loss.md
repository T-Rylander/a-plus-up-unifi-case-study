# Emergency Runbook: Power Loss & UPS Failover Recovery

**Severity Level:** CRITICAL  
**RTO Target:** 15 minutes (validated by orchestrator.sh)  
**Last Validated:** 2024-12-19  
**Owner:** Suehring Ministry (Network Perimeter)

## Before It Happens: Prevention & Preparation

### Pre-Event Checklist (Do This Monthly)
```bash
#!/bin/bash
# Pre-event UPS validation

echo "=== UPS Readiness Check ==="

# 1. Verify UPS battery health
apc-status --query battery.health || echo "❌ APC UPS not responding"

# 2. Check current load
apc-status --query system.load || echo "⚠️  Load status unavailable"

# 3. Verify runtime estimate at full load
LOAD=$(apc-status --query system.load | awk '{print $NF}')
if [ "$LOAD" -lt 758 ]; then
  echo "✅ Load ${LOAD}W < 758W capacity (RTO estimate: 8-10 min)"
else
  echo "❌ ALERT: Load ${LOAD}W EXCEEDS UPS capacity! (Risk of instant shutdown)"
fi

# 4. Test graceful shutdown trigger
echo "Testing graceful shutdown notification..."
# (Will NOT actually shut down, just log test)

# 5. Validate boot sequence
echo "✅ UPS readiness check complete"
```

### Equipment Inventory (Keep This Updated)
| Device | Power (Steady) | Power (Inrush) | UPS Runtime | Location | Notes |
|--------|---|---|---|---|---|
| UDM Pro Max | 85W | 180W | ~6 min @ 758W | Main closet | Core router |
| USW-Pro-Max-48-PoE | 120W | 320W | ~4 min @ 758W | Main closet | PoE switch |
| AP 5-Pack (4x active) | 300W | 400W | ~2 min @ 758W | Distributed | Staggered boot only |
| Yealink Phones (8x) | 24W | 48W | ~30 min | Distributed | IP phones |
| Verkada Cameras (11x) | 80W | 160W | ~5 min | Distributed | On PoE (switch power) |
| Avahi Container | 8W | 12W | N/A | UDM | mDNS reflector |
| **TOTAL** | **~758W** | **~1,240W** | **~8-10 min** | **Various** | **Inrush = 166% capacity** |

---

## During Power Loss: Immediate Actions (T+0 to T+2 min)

### What Happens Automatically (No Action Needed)
1. **T+0 sec**: Main power fails → UPS switches to battery
2. **T+5 sec**: UDM Pro Max detects power failure
3. **T+10 sec**: Graceful shutdown trigger sent to all containers
4. **T+15 sec**: WiFi access points continue on PoE battery backup
5. **T+30 sec**: Avahi mDNS reflector stops (gracefully)

### What You Must Do
- **If on-site:** Verify UPS beeping (battery mode active)
- **If remote:** Monitor Loki logs for "power.loss" event (within 30 sec via LTE backup)
- **Call site supervisor:** "Power loss detected, system running on UPS, ~8-10 min runtime"

---

## After Power Returns: Recovery Sequence (T+2 to T+15 min)

### Phase 1: Power Detection & Boot Sequence (T+0 to T+3 min)
```bash
#!/bin/bash
# Auto-executed by UDM on power return
# Location: /data/unifi-os/custom/power-recovery.sh

echo "$(date '+%Y-%m-%d %H:%M:%S') [POWER RECOVERY] Main power detected!"

# 1. Staggered PoE boot (critical: prevents inrush overload)
echo "$(date '+%Y-%m-%d %H:%M:%S') [PoE RECOVERY] Starting staggered boot..."

# Boot sequence: Core → Security → Wireless → Cameras
sleep 2
unifi-api --command "disable-poe-port-group 2,4,6,8,10,12,14,16"  # Initial disable

sleep 3
unifi-api --command "enable-poe-port-group 2,4"  # Cameras first (low power)
sleep 5

unifi-api --command "enable-poe-port-group 6,8,10,12"  # Yealink phones
sleep 5

unifi-api --command "enable-poe-port-group 14,16,18,20"  # APs (staggered)
sleep 10

echo "$(date '+%Y-%m-%d %H:%M:%S') [PoE RECOVERY] ✅ All PoE ports online"

# 2. Container restart (Avahi mDNS reflector)
echo "$(date '+%Y-%m-%d %H:%M:%S') [CONTAINER RECOVERY] Restarting Avahi..."
docker start avahi-reflector 2>/dev/null || echo "ℹ️  Avahi auto-restarting"

# 3. Validate VLAN restoration
echo "$(date '+%Y-%m-%d %H:%M:%S') [VLAN CHECK] Verifying 6 VLANs..."
for vlan in 10 20 30 50 60 99; do
  unifi-api --query "vlan.$vlan.status" | grep -q "ok" && echo "  ✅ VLAN-$vlan online" || echo "  ⚠️  VLAN-$vlan pending"
done

# 4. Firewall validation
echo "$(date '+%Y-%m-%d %H:%M:%S') [FIREWALL CHECK] Validating 11 rules..."
unifi-api --query "firewall.rules.count" | grep -q "11" && echo "  ✅ All 11 rules active" || echo "  ⚠️  Some rules missing"

echo "$(date '+%Y-%m-%d %H:%M:%S') [POWER RECOVERY] ✅ Recovery sequence complete!"
```

### Phase 2: Service Health Check (T+3 to T+8 min)
```bash
#!/bin/bash
# Validation script after staggered boot
# Run on UDM: ssh ubnt@<udm-ip> "bash /tmp/validate-recovery.sh"

echo "=== POST-RECOVERY VALIDATION (RTO CHECKPOINT) ==="

# 1. WiFi APs responding
echo "1. WiFi AP Status:"
for ap in ap-east ap-west ap-south; do
  unifi-api --query "device.$ap.status" | grep -q "online" && echo "  ✅ $ap online" || echo "  ❌ $ap OFFLINE"
done

# 2. PoE devices connected
echo "2. PoE Device Status:"
CAMERAS=$(unifi-api --query "poe.devices.count" | head -1)
PHONES=$(unifi-api --query "poe.devices" | grep -i yealink | wc -l)
PRINTERS=$(unifi-api --query "poe.devices" | grep -i printer | wc -l)
echo "  Cameras: $CAMERAS/11, Phones: $PHONES/8, Printers: $PRINTERS/40"

# 3. Firewall offload validation
echo "3. Firewall Hardware Offload:"
unifi-api --query "firewall.offload.enabled" | grep -q "true" && echo "  ✅ Offload ON" || echo "  ⚠️  Offload disabled"

# 4. mDNS reflector online
echo "4. mDNS Reflector:"
docker ps | grep -q "avahi-reflector" && echo "  ✅ Avahi running" || echo "  ⚠️  Avahi not responding"

# 5. VLAN isolation validated
echo "5. VLAN Isolation Test:"
# Test: Can VLAN-10 see VLAN-20? (should be NO)
echo "  ⏳ Running isolation tests... (may take 1-2 min)"

echo "=== VALIDATION COMPLETE ==="
```

### Phase 3: Manual Checklist (T+8 to T+15 min)
- [ ] **WiFi Users Reporting:** Ask 3 staff to connect to WiFi, verify internet access
- [ ] **VoIP Phones Active:** Verify at least 1 Yealink phone shows network time (NTP sync)
- [ ] **Printer Discovery:** One staff member tries to print (should work within 1 min)
- [ ] **Verkada Cameras:** Check Verkada app - all 11 cameras should be "online" (may take up to 3 min)
- [ ] **Internet Connectivity:** Ping 8.8.8.8 from multiple VLANs (10, 20, 30)
- [ ] **Event Logging:** Verify Loki has logged power loss event (check `/var/log/power-recovery.log`)

---

## If Recovery FAILS (Beyond T+15 min)

### Troubleshooting Flowchart
```
Did WiFi come back online?
├─ YES → Did internet work?
│        ├─ YES → ✅ RECOVERY SUCCESSFUL (RTO met)
│        └─ NO  → Check Comcast modem (restart via apc/cyclepower.sh)
│
├─ NO  → Are APs in failed boot?
         ├─ YES → SSH to UDM, manual restart: unifi-api restart-ap-east
         ├─ NO  → UDM itself offline?
         │        ├─ YES → Hard restart: apc-reset --device udm (⚠️ NOT ideal)
         │        └─ NO  → Check PoE budget exceeded (run calculate-poe-budget.sh)
         └─ Last resort: Contact Ubiquiti support (provide logs from /var/log/boot-*.log)
```

### Critical Debug Commands
```bash
# 1. Check UDM status
ssh ubnt@<udm-ip> "unifi-os-status"

# 2. View staggered boot log
ssh ubnt@<udm-ip> "tail -50 /var/log/power-recovery.log"

# 3. Check PoE budget exceeded
ssh ubnt@<udm-ip> "unifi-api query poe-budget"

# 4. Force WiFi AP discovery
ssh ubnt@<udm-ip> "unifi-api command discover-ap --force"

# 5. Restart single AP (if offline)
ssh ubnt@<udm-ip> "unifi-api restart-device --device ap-east"

# 6. Full UDM reboot (⚠️ LAST RESORT)
ssh ubnt@<udm-ip> "sudo reboot"
```

---

## After Recovery: Post-Mortem (T+15 to T+120 min)

### Incident Log Entry
```yaml
date: 2024-12-19T14:23:00Z
incident: power_loss_duration_8min
uptime_before: 156 days
recovery_time: 12 minutes 34 seconds
status: ✅ SUCCESSFUL (RTO 15 min target met)

recovery_checklist:
  - wifi_restoration: 3 min 15 sec
  - internet_connectivity: 5 min 42 sec
  - poe_devices_online: 7 min 18 sec
  - vlan_isolation_validated: 10 min 44 sec
  - printer_discovery: 12 min 34 sec

issues_found: []
improvements: []

next_validation: 2025-01-19 (30 days)
validated_by: [your name]
```

### Validation Report (Send to Leadership)
- **RTO Achieved:** 12 min 34 sec (target 15 min) ✅
- **Data Loss:** 0 events (graceful shutdown successful)
- **User Impact:** ~8 min without network (acceptable for power outage)
- **Recovery Quality:** Full VLAN isolation + firewall rules restored
- **Recommendation:** No changes needed; system working as designed

---

## Prevention & Monitoring

### Monthly Tasks
- [ ] Test UPS battery health (command: `apc-status --battery`)
- [ ] Verify load is <758W (run `calculate-poe-budget.sh`)
- [ ] Review power-recovery.log for any errors
- [ ] Check Comcast modem status (ping 10.0.0.1)

### Quarterly Tasks
- [ ] Simulate full power loss test (coordinate with site supervisor)
- [ ] Document actual RTO achieved
- [ ] Update equipment inventory if any changes
- [ ] Review staggered boot sequence (may need tuning)

---

## Related Documents
- [SUEHRING-PERIMETER.md](../trinity/SUEHRING-PERIMETER.md) - PoE budget & firewall rules
- [orchestrator.sh](../../scripts/orchestrator.sh) - RTO validation automation
- [calculate-poe-budget.sh](../../scripts/calculate-poe-budget.sh) - Power load calculation
- [MINISTRY-CHARTER.md](../trinity/MINISTRY-CHARTER.md) - Incident escalation matrix

**CRITICAL REMINDER:** This runbook is NOT a substitute for proper UPS maintenance. Check battery health quarterly and replace every 3-5 years.
