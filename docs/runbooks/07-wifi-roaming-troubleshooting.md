# Troubleshooting Runbook: WiFi Roaming & Connectivity Issues

**Severity Level:** MEDIUM  
**RTO Target:** 10 minutes (user-facing resolution)  
**Owner:** Suehring Ministry (Network Perimeter)

## Problem: WiFi Devices Not Roaming Between Access Points

### Symptoms
- User walks between buildings → WiFi disconnects for 30+ seconds (should be <1 sec)
- Chromebook connects to distant AP instead of nearest
- Devices "stuck" on one AP, won't switch even when signal drops to -80 dBm
- VoIP calls drop during movement between buildings

### Root Causes (In Order of Likelihood)
1. **802.11k (Fast Roaming) disabled** ← Most common (95%)
2. Improper band steering (2.4 GHz preferred, should be 5 GHz)
3. TX power too high on one AP (others can't compete)
4. VLAN mismatch between APs (802.1X authentication failing)
5. Insufficient overlap between AP coverage zones

---

## Diagnosis: Check Roaming Configuration

### Step 1: Verify 802.11k/v/r Enabled
```bash
#!/bin/bash
# Check if UniFi has fast roaming enabled

echo "=== WiFi ROAMING DIAGNOSIS ==="

# Query all APs
unifi-api --query "device.type:access_point" | jq '.[] | {name: .name, model: .model, status: .status}' > /tmp/aps.json

echo "Access Points Found:"
cat /tmp/aps.json

echo ""
echo "Checking 802.11k/v/r Configuration:"
unifi-api --query "wireless.fast_roaming" | jq '.'

if [ $? -ne 0 ]; then
  echo "❌ 802.11k/v/r status unavailable (may be disabled)"
else
  echo "✅ 802.11k/v/r query successful"
fi

# Check per-SSID roaming settings
echo ""
echo "SSID Roaming Settings:"
unifi-api --query "wlan" | jq '.[] | {name: .name, fast_roaming_enabled: .fast_roaming_enabled, band_steer: .band_steer}'
```

### Step 2: Check AP Power Levels
```bash
#!/bin/bash
# Compare TX power across APs (should be balanced)

echo "=== AP TRANSMIT POWER ANALYSIS ==="

unifi-api --query "device.type:access_point" | jq -r '.[] | "\(.name): \(.tx_power_percent)% (\(.tx_power_dbm) dBm)"' | while read ap; do
  POWER=$(echo "$ap" | grep -oP '\(\K[^)]+ dBm')
  if echo "$POWER" | grep -qE "^(30|29|28|27|26)"; then
    echo "  ✅ $ap (balanced)"
  elif echo "$POWER" | grep -qE "^(31|32|33)"; then
    echo "  ⚠️  $ap (HIGH - may dominate, blocking roaming)"
  else
    echo "  ℹ️  $ap"
  fi
done

# Ideal: All APs 26-28 dBm (similar strength, force roaming decisions)
```

### Step 3: Check SSID Band Steering
```bash
#!/bin/bash
# Verify band steering (prefer 5 GHz for capable devices)

echo "=== SSID BAND STEERING CHECK ==="

unifi-api --query "wlan" | jq '.[] | {
  name: .name,
  band_steer: .band_steer,
  band_steer_5g_preference: .band_steer_5g_preference,
  min_rssi_5g: .min_rssi_5g
}' | while IFS= read -r line; do
  echo "$line"
done

# Expected for Chromebooks (5 GHz capable):
#   band_steer: true (or "enabled")
#   band_steer_5g_preference: true
#   min_rssi_5g: -75  (force 5 GHz if signal strong enough)
```

### Step 4: Check VLAN Configuration Per AP
```bash
#!/bin/bash
# Ensure all APs serving same VLAN for same SSID

echo "=== VLAN CONSISTENCY CHECK ==="

SSID="Students"
echo "SSID: $SSID"
echo ""

unifi-api --query "device.type:access_point" | jq -r ".[] | .name" | while read ap; do
  VLAN=$(unifi-api --query "device.$ap.wireless.network" | grep -A 5 "$SSID" | jq '.vlan')
  echo "  $ap → VLAN $VLAN"
done

# All should report same VLAN (e.g., VLAN-10)
# If mismatched → roaming fails, authentication resets
```

### Step 5: Check Minimum Signal Strength (RSSI Threshold)
```bash
#!/bin/bash
# If AP signal too weak, devices won't roam

echo "=== MIN RSSI THRESHOLD CHECK ==="

# Measure signal strength at building edges (where roaming happens)
# Run this from edge area (e.g., hallway between east/west buildings)

echo "Scanning WiFi signal strength (Students SSID)..."
# Note: Requires WiFi monitoring tool (iw, iwlist, or UniFi scanner)

# Expected behavior:
# - When signal drops to -70 dBm from current AP
# - Device should roam to new AP with -65 dBm or better
# - This should be <1 second handoff

# If devices stick to weak AP:
#   → min_rssi_5g may be set incorrectly (too low)
#   → TX power imbalance (one AP too strong, drowns others out)
```

---

## Solution: Enable 802.11k/v/r (Fast Roaming)

### Method 1: Via UniFi WebUI (Recommended for Most)
1. Log in to UniFi Controller (UDM Pro Max WebUI)
2. Go to **WiFi > Manage Networks**
3. Select SSID (e.g., "Students")
4. Expand **Advanced Options**
5. Find **802.11k (Fast Roaming)** section:
   - ✅ Enable 802.11k/v/r
   - ✅ Enable Band Steering
   - Set Min RSSI 5G: **-75 dBm** (force 5 GHz for capable devices)
   - Set Min RSSI 2.4G: **-70 dBm** (fallback only)
6. Click **Save & Apply**
7. Wait 2 minutes for AP config push

### Method 2: Via UniFi API (For Automation)
```bash
#!/bin/bash
# Enable 802.11k for all SSIDs

echo "=== ENABLING 802.11k/v/r VIA API ==="

# 1. Get all WLANs
WLANS=$(unifi-api --query "wlan" | jq -r '.[] | .id')

# 2. Update each WLAN
for wlan_id in $WLANS; do
  echo "Updating WLAN: $wlan_id"
  
  unifi-api --command "update-wlan" \
    --wlan_id "$wlan_id" \
    --fast_roaming_enabled true \
    --band_steer true \
    --band_steer_5g_preference true \
    --min_rssi_5g -75 \
    --min_rssi_2g -70
  
  echo "  ✅ Updated"
done

echo ""
echo "Waiting for AP updates (2 min)..."
sleep 120

# 3. Verify
echo "Verification:"
unifi-api --query "wlan" | jq '.[] | {name: .name, fast_roaming: .fast_roaming_enabled}'
```

### Method 3: Via UniFi Backup File (Power User)
```bash
#!/bin/bash
# Edit backup JSON directly (risky, backup first!)

BACKUP_FILE="unifi-backup.json"

# Ensure backup downloaded from UDM
# scp ubnt@<udm-ip>:/data/backup/*.unf ./

# Extract backup
unzip -q "$BACKUP_FILE"

# Edit network config
jq '.network.wireless[] |= . + {
  "802_11k": true,
  "802_11v": true,
  "802_11r": true,
  "band_steer": true,
  "band_steer_5g_preference": true,
  "min_rssi_5g": -75
}' site.json > site.json.new

# Re-create backup
zip -q "$BACKUP_FILE" site.json.new
# Upload via UniFi WebUI > Settings > Backup
```

---

## Verification: Test Roaming

### Real-World Roaming Test (10-15 minutes)
1. **Setup**: Have a Chromebook/phone with WiFi analyzer open (Android: "WiFi Analyzer" app)
2. **Position 1** (Building A, 5m from AP-East):
   - Expected: Connected to AP-East, signal -45 dBm
   - Verify in WiFi analyzer: See AP-East strong, others weak
3. **Walk Slowly** (Hallway between buildings):
   - Watch signal from AP-East drop: -45 → -55 → -65 → -75 dBm
   - Watch signal from AP-West rise: -90 → -85 → -75 → -65 dBm
   - **Expected Roaming Point**: Around -70 dBm from both
   - **Verify**: Connected drops for <1 sec, then jumps to AP-West
   - **Verify**: SSH/ping session continues (seamless roaming)
4. **Position 2** (Building B, 5m from AP-West):
   - Expected: Connected to AP-West, signal -45 dBm
5. **Return Walk**: Repeat process back to Building A
6. **Document Results**:
   ```
   ✅ or ❌ Roaming Successful?
   Handoff Time: ___ seconds (target: <1 sec)
   SSH/Ping Interrupted? Yes/No (should be No)
   Any Visible Lag? Yes/No
   ```

### Automated Roaming Test (Using iperf)
```bash
#!/bin/bash
# Run continuous data transfer while moving between APs
# Measures actual throughput drop during roaming

TARGET_DEVICE="chromebook.localdomain"  # Or IP address

echo "=== ROAMING PERFORMANCE TEST ==="
echo "Start iperf server on target device:"
echo "  $ iperf3 -s (server mode)"
echo ""
echo "Press Enter when server ready..."
read

# Run 5-minute data transfer
iperf3 -c "$TARGET_DEVICE" -t 300 -R | tee roaming-test.log

# Analyze results
echo ""
echo "Results:"
grep "bits/sec" roaming-test.log | tail -3
echo ""
echo "Look for: Throughput gaps during roaming"
echo "  Good: <1% throughput drop, <100ms latency spike"
echo "  Bad: >50% throughput drop, >1 sec interruption"
```

---

## If Roaming Still Fails: Advanced Debugging

### Check VLAN on Each AP
```bash
#!/bin/bash
# VLAN mismatch prevents 802.1X re-authentication during roaming

SSID="Students"
echo "=== VLAN VERIFICATION FOR $SSID ==="

unifi-api --query "device.type:access_point" | jq -r '.[] | .name' | while read ap; do
  VLAN=$(unifi-api --query "device.$ap.config.wireless" | jq --arg ssid "$SSID" '.[] | select(.name == $ssid) | .vlan')
  if [ -z "$VLAN" ] || [ "$VLAN" == "null" ]; then
    echo "❌ $ap: VLAN NOT ASSIGNED (CRITICAL - roaming will fail)"
  else
    echo "✅ $ap: VLAN $VLAN"
  fi
done

# All APs must report same VLAN for same SSID
```

### Check AP Distances (Coverage Overlap)
```bash
# Roaming requires ~20% signal overlap at AP boundaries
# Use WiFi Survey tool (UniFi built-in or external)

echo "=== AP COVERAGE OVERLAP CHECK ==="
echo "Recommended: Use UniFi Controller > Settings > WiFi > Survey"
echo "Or use external tool: https://www.ekahau.com/site-survey/"
echo ""
echo "Target overlap: -70 to -75 dBm zone (overlap area)"
echo "If gap >5 m with no overlap: roaming may fail in that zone"
```

### Force Reassociation Test
```bash
#!/bin/bash
# Disconnect and reconnect to same AP (tests 802.11k capability)

DEVICE_MAC="00:1A:2B:3C:4D:5E"
SSID="Students"

echo "=== REASSOCIATION TEST ==="
echo "Forcing device to reassociate..."

# Option 1: Disconnect from AP
unifi-api --command "disconnect-client" --mac "$DEVICE_MAC"
sleep 2

# Option 2: Device auto-reconnects (watch for <2 sec)
# Expected: Device reconnects to same AP in <2 seconds (should be instantaneous with 802.11k)

echo "Monitor device WiFi connection time: Should be <2 sec"
```

---

## Permanent Fix: Roaming Configuration Best Practices

### Configuration Checklist
```yaml
# config/unifi/roaming-config.yaml (apply after 802.11k enabled)

# 1. Band Steering (Prefer 5 GHz)
band_steer: true
band_steer_5g_preference: true

# 2. Min RSSI Thresholds
min_rssi_5g: -75        # Force 5 GHz unless signal <-75 dBm
min_rssi_2g: -70        # Allow 2.4 GHz only if 5 GHz unavailable

# 3. 802.11 Amendment Settings
ieee_802_11k: true     # Neighbor reports (helps devices decide where to roam)
ieee_802_11v: true     # BSS transition management
ieee_802_11r: true     # Fast roaming (FT/802.11r)

# 4. TX Power Balancing
# All APs should be similar strength (26-28 dBm)
# If imbalanced: manually set via UniFi WebUI > Device > Radios > TX Power

# 5. Channel Selection (Non-overlapping)
# 5 GHz: 36, 40, 44, 48 (or 100+, depending on region)
# 2.4 GHz: 1, 6, 11 (USA standard)
# Use UniFi Auto channel selection (unless interference detected)

# 6. SSID Per-Band Splitting (Optional, for fine control)
# Chromebooks/Staff: "Students-5G" (5 GHz only, force fast roaming)
# Legacy devices: "Students-2.4G" (2.4 GHz only)
# Combined (recommended): "Students" (dual-band, band steering handles it)
```

### Quarterly Validation
- [ ] Run roaming test (walk between buildings)
- [ ] Verify 802.11k/v/r enabled in all SSIDs
- [ ] Check AP TX power levels (should be balanced)
- [ ] Confirm min RSSI settings correct (-75 5GHz, -70 2.4GHz)
- [ ] Review any roaming-related support tickets

---

## Related Documents
- [SUEHRING-PERIMETER.md](../trinity/SUEHRING-PERIMETER.md) - VLAN & wireless architecture
- [01-access-points.md](01-access-points.md) - AP deployment & configuration
- [MINISTRY-CHARTER.md](../trinity/MINISTRY-CHARTER.md) - Support escalation matrix

**CRITICAL REMINDER:** 802.11k/v/r can take 2-5 minutes to push to all APs. Changes aren't immediate. Wait before testing.
