# Runbook: Access Point Deployment & Configuration

**Scope**: UAP-AC-PRO adoption, channel assignment, coverage validation  
**Audience**: Network technician, IT staff  
**Prerequisites**: UDM controller online, APs powered via PoE  
**Estimated Time**: 2 hours per 4 APs  
**Source**: Comprehensive WiFi Assessment V2.1, ARCHITECTURE.md

---

## Pre-Deployment Checklist

- [ ] UDM online and accessible (10.99.0.1)
- [ ] UniFi app logged in (controller account)
- [ ] APs powered on (check PoE port LED green on USW)
- [ ] Lab validation complete (site survey with RSSI readings)
- [ ] Channel assignment plan printed (see Channel Allocation Table)
- [ ] Firmware version current (UDM auto-updates APs)

---

## Phase 1: AP Adoption (Automated)

### 1.1 Power On New AP

1. Locate new UAP-AC-PRO in staging area
2. Connect **Ethernet cable** from PoE port on USW-Pro-Max-48-PoE
3. Power LED should turn **blue** (booting)
4. Wait 3-5 minutes for full boot (LED turns green when ready)

**Verification**:
```
UniFi Dashboard > Devices
  → New AP should appear in "Pending Adoption" list
```

### 1.2 Adopt AP into UniFi Controller

1. Click **"Adopt"** on pending AP in UniFi dashboard
2. Select region: **United States**
3. Confirm adoption (controller pushes config)
4. Wait for LED to turn **amber** (adoption in progress)
5. After 2-3 min, LED turns **green** (adoption complete)

**Verification**:
```
UniFi Dashboard > Devices > Access Points
  → AP appears with model (UAP-AC-PRO), status "Online"
  → MAC address visible
  → TX/RX traffic showing (real-time)
```

### 1.3 Rename AP for Identification

1. Click AP in dashboard
2. Settings > General > **Name**: [descriptive name]
   - Example: "AP-Upstairs-Room207"
3. Save

---

## Phase 2: Channel Assignment

### 2.1 Assign Channel (UDM Dashboard)

1. Open **Unifi Dashboard > Settings > Wireless Networks**
2. Select network: **"AUP-Main"** (main WiFi SSID)
3. Scroll to **Channels** section:

| Location | Expected Channels | Current Assignment |
|----------|-------------------|-------------------|
| Upstairs | 36, 52, 100, 149 | Review per Table |
| Downstairs | 36, 116, 132, 149 | Review per Table |

4. For each AP, assign **manual channel** (do NOT use auto):
   - **Channel 36**: "AP-Upstairs-Room112" (3 APs total)
   - **Channel 52**: "AP-Upstairs-Room207" (3 APs total)
   - **Channel 100**: "AP-Upstairs-Lab" (2 APs total)
   - **Channel 149**: "AP-Downstairs-Hallway" (2 APs total)
   - **Channel 116**: "AP-Downstairs-Auditorium" (2 APs total)
   - **Channel 132**: "AP-Downstairs-Portable" (1 AP)

5. Save and apply

### 2.2 Verify Channel (AP LED & Dashboard)

1. **LED Indicator**: AP should cycle through colors:
   - Blue (booting) → Green (online) → Amber (updating) → Green (stable)
2. **Dashboard**: Refresh and verify channel appears:
   ```
   UniFi Dashboard > Devices > AP Details > Uptime
   → "Channel: 36" (or assigned channel)
   ```

---

## Phase 3: Band Steering & RSSI Configuration

### 3.1 Enable 802.11k/v/r

1. **UniFi Dashboard > Settings > Wireless Networks > AUP-Main**
2. Scroll to **Advanced Options**:
   - [ ] **802.11k Neighbor Reports**: Enabled
   - [ ] **802.11v BSS Transition**: Enabled
   - [ ] **802.11r Fast Roaming**: Enabled
3. **Band Steering**:
   - [ ] **Enabled**: Yes
   - [ ] **RSSI Threshold**: -67 dBm
   - [ ] **5GHz Preference**: Enabled
4. Save

**Verification**:
```
Connected client (Chromebook) → Settings > WiFi > AUP-Main
  → Should NOT show "2.4GHz" option (2.4GHz disabled globally)
  → Only "5GHz" available
```

### 3.2 Validate RSSI Levels

1. **Mobile Survey** (use WiFi analyzer app on phone or laptop):
   - Walk facility perimeter with WiFi scanner
   - Record RSSI at key locations (classrooms, hallways, bathrooms)
   - Target: **-67 dBm or better** (steering threshold)
   - Document results in coverage survey sheet

2. **Dashboard Signal View**:
   ```
   UniFi Dashboard > Insights > WiFi > Throughput & RSSI
   → Graph showing RSSI distribution
   → Target: 90%+ clients above -70 dBm
   ```

---

## Phase 4: Coverage Validation

### 4.1 Conduct Site Survey

**Equipment Needed**:
- Mobile device with WiFi analyzer app (NetSpot, Ekahau Site Survey, or free alternative)
- Clipboard with survey map
- Pen for marking coverage areas

**Procedure**:
1. Walk through facility (all hallways, classrooms, bathrooms)
2. At each location (every 10-15 feet), record:
   - RSSI value (signal strength)
   - Connected AP (which AP is client connected to)
   - Data rate (throughput indicator)
3. Mark weak zones (<-70 dBm) on map
4. Compare with pre-deployment baseline

### 4.2 Coverage Targets

| Zone | RSSI Target | Threshold | Pass/Fail |
|------|-------------|-----------|-----------|
| Classrooms | -60 to -70 dBm | -67 dBm | ✅ |
| Hallways | -65 to -75 dBm | -70 dBm | ✅ |
| Bathrooms | -70 to -80 dBm | -75 dBm (acceptable edge) | ⚠️ |
| Portables | -65 to -75 dBm | -70 dBm | ✅ |

**Success Criteria**:
- ✅ 96% of facility above -65 dBm
- ✅ No dead zones (<-80 dBm)
- ✅ Coverage improvement +6 dBm vs. baseline (lab-validated)

### 4.3 Document Results

1. Save survey report with:
   - Date/time of survey
   - Map with RSSI zones marked
   - List of weak areas (if any)
   - Recommendation for additional APs (if needed)

---

## Phase 5: Roaming Test

### 5.1 Test Fast Roaming (802.11k/v/r)

**Procedure** (with test Chromebook):
1. Connect Chromebook to AUP-Main WiFi
2. Open YouTube or Google Classroom (active connection)
3. Walk from one AP coverage zone to another (e.g., Room112 → Hallway → Room207)
4. Observe video playback:
   - **Expected**: Video continues without interruption (roaming <5 sec)
   - **Failure**: Video pauses/buffers (roaming >5 sec)
5. Check connectivity status:
   ```
   Chromebook > Settings > WiFi > AUP-Main
   → "Signal strength: Excellent" (should switch APs smoothly)
   ```

### 5.2 Measure Roaming Time

**Using Terminal** (Linux/Mac) or **WiFi Analyzer** (mobile):
```bash
# Ping test during roaming (switch APs while pinging)
ping 8.8.8.8
# Expected: <5 sec gap in responses (roaming window)
# Failure: >10 sec gap (AP not roaming efficiently)
```

---

## Phase 6: Troubleshooting

### 6.1 AP LED Status Codes

| LED Color | Meaning | Action |
|-----------|---------|--------|
| **Blue** | Booting | Wait 3-5 min |
| **Green** | Online and healthy | OK |
| **Amber** | Updating or adopting | Wait 2-3 min |
| **Red** | Error or offline | Check PoE power, restart |
| **Off** | No power | Check PoE port, cable |

### 6.2 Common Issues

**Issue**: AP stuck on blue LED (not adopting)
- **Cause**: PoE not detected or adoption timeout
- **Fix**:
  1. Check PoE port LED on USW (should be lit)
  2. Restart AP (power cycle from PoE port)
  3. Manually adopt: Dashboard > Pending > Adopt

**Issue**: Client roaming <5 sec (slow)
- **Cause**: 802.11k/v/r not enabled or RSSI threshold too low
- **Fix**:
  1. Verify 802.11k/v/r enabled (Section 3.1)
  2. Increase RSSI threshold to -67 dBm
  3. Force roaming by walking away from current AP

**Issue**: Coverage gap in specific area
- **Cause**: AP not placed in line-of-sight or too far
- **Fix**:
  1. Relocate AP closer to gap
  2. Add additional AP (see Phase 1 for new AP adoption)
  3. Increase TX power (UDM > AP Settings > TX Power > Maximum)

---

## Post-Deployment Sign-Off

- [ ] All 16 APs adopted and online
- [ ] Channels assigned per allocation table
- [ ] 802.11k/v/r enabled globally
- [ ] Coverage validation complete (96% above -65 dBm)
- [ ] Roaming test passed (<5 sec)
- [ ] Client devices (Chromebooks) connecting and roaming
- [ ] Documentation saved (survey report, coverage map)

---

**Next Steps**: Proceed to VoIP phone deployment (Runbook 2)

**Escalation Contact**: Travis Rylander (network architect) if AP adoption fails or coverage targets not met
