# Runbook: PoE Power Monitoring & Alert Configuration

**Scope**: PoE+ power budget tracking, alert thresholds, load shedding procedures  
**Audience**: Network technician, IT staff  
**Prerequisites**: UDM controller online, PoE+ ports in use (cameras, phones, future APs)  
**Estimated Time**: 1 hour setup + ongoing 15 min monthly checks  
**Source**: ARCHITECTURE.md (PoE Budget Section), ADR 005 (Camera Power)

---

## Pre-Deployment Checklist

- [ ] USW-Pro-Max-48-PoE deployed (720W budget)
- [ ] PoE+ ports assigned to VLANs (VLAN 50 VoIP, VLAN 60 cameras, others)
- [ ] Power consumption baseline documented (all devices powered)
- [ ] UDM alerting configured (email/webhook)
- [ ] Load shedding procedure approved by IT leadership

---

## Phase 1: PoE+ Budget Overview

### 1.1 Current Deployment Power Draw

**All Deployed Devices** (as of Dec 2025):

| Device Category | Qty | Power/Device | Total | % of 720W |
|-----------------|-----|--------------|-------|-----------|
| **Yealink T43U** (VLAN 50) | 8 | 90W | 720W | 100% ❌ |
| **Verkada CD52** (VLAN 60) | 8 | 90W | 720W | 100% ❌ |
| **Verkada CD62** (VLAN 60) | 3 | 120W | 360W | 50% ✅ |
| **UAP-AC-PRO** (APs) | 16 | 30W avg | 480W | 67% ✅ |
| **UPS Monitor** (management) | 1 | 10W | 10W | 1% ✅ |
| **Subtotal (Phones + Cameras)** | 11 | — | 1,080W | **150% ❌** |
| **Subtotal (APs only)** | 16 | — | 480W | **67% ✅** |
| **Total if all deployed** | — | — | 1,650W | **229% ❌ WAY OVER** |

**Problem**: Phones (8×90W=720W) alone max the budget. Cameras add 1,080W more.

**Solution**: Phase deployment with low-power modes.

### 1.2 Phased Deployment Strategy

**Phase 1A (Weeks 1-2)**:
- APs: 16 units @ 30W avg = 480W ✅
- Phones: 8 Yealink @ 30W low-power mode = 240W ✅
- **Subtotal**: 720W (at budget limit)

**Phase 1B (Weeks 3-4)**:
- Add cameras: 8 CD52 @ 30W low-power mode = 240W ✅
- Add cameras: 3 CD62 @ 60W low-power mode = 180W ✅
- **Subtotal**: 720W (still at limit, cameras in low-power)

**Phase 2 (Future)**:
- If budget expanded or high-efficiency upgrades available
- Deploy additional cameras at full power

---

## Phase 2: PoE Power Budget Monitoring (UDM Dashboard)

### 2.1 Access PoE Monitoring

1. **UDM Dashboard > Insights > Network > Power**:
   ```
   USW-Pro-Max-48-PoE Usage:
     Current Draw: [X watts]
     Budget: 720W
     Utilization: X%
     Status: [GREEN/YELLOW/RED]
   ```

2. **Port-by-Port Breakdown**:
   ```
   Port 1: AP #1 → 30W
   Port 2: AP #2 → 30W
   ...
   Port 17: Phone #1 (VLAN 50) → 90W
   Port 18: Phone #2 (VLAN 50) → 90W
   ...
   Port 35: Camera #1 (VLAN 60) → 90W
   ...
   (view full list with scroll)
   ```

### 2.2 Alert Thresholds

**Configure Alerts** (UDM Settings > Alerts > Power):

| Threshold | Status | Action |
|-----------|--------|--------|
| **<600W** | 🟢 GREEN | Normal operation (80% utilization) |
| **600-680W** | 🟡 YELLOW | Caution (85-94% utilization) |
| **>680W** | 🔴 RED | Critical (>94% utilization, risk of shutdown) |

**UDM Configuration**:
```
UDM Dashboard > Settings > Alerts
  → Power Threshold Alert:
       Threshold: 680W (94%)
       Trigger: If PoE usage exceeds 680W
       Notification: Email to IT staff + Travis Rylander
       Frequency: Immediate (not batched)
```

---

## Phase 3: Real-Time Monitoring Procedures

### 3.1 Daily Check (5 minutes)

**Every Morning** (8:00am):
1. Log into UDM Dashboard
2. Check **Insights > Network > Power**:
   - Current draw: [X watts]
   - Status: 🟢 GREEN (or 🟡 YELLOW if overnight events)
3. If 🟡 YELLOW or 🔴 RED:
   - Investigate cause (see Phase 4 Troubleshooting)
   - Document in incident log

### 3.2 Weekly Check (10 minutes)

**Every Friday EOD**:
1. Export PoE usage graph (PDF for records)
2. Review trends:
   - Is power draw increasing over time?
   - Are there peak times (e.g., morning startup)?
3. Note any anomalies:
   - Unusual spikes (indicate new device or failure)
   - Devices offline (reduce power draw)
4. Archive in "PoE Reports" folder

### 3.3 Monthly Review (15 minutes)

**Last Friday of Month**:
1. Download full month of PoE data (UDM export)
2. Calculate average, peak, minimum power draws
3. Create summary report:
   ```
   Month: December 2025
   Average: 450W
   Peak: 650W (during camera adoption)
   Minimum: 200W (off-hours)
   Issues: None
   Recommendation: Current deployment sustainable
   ```
4. Share with IT leadership

---

## Phase 4: Troubleshooting & Load Shedding

### 4.1 Alert: YELLOW Threshold (600-680W)

**Triggered When**: PoE usage 85-94% for >2 minutes

**Immediate Actions**:
1. Identify which device(s) consuming excess power:
   ```
   UDM Dashboard > Ports > Sort by Power Consumption (descending)
   → Top 5 power consumers listed
   ```

2. **Check for New Devices**:
   - New camera adopted?
   - New phone connected?
   - AP in high-power mode (vs. low-power)?

3. **Reduce Power**:
   - If camera, enable **low-power mode** (see Section 4.3)
   - If phone, verify **low-power mode** active
   - If AP, reduce **TX power** temporarily (not ideal, test only)

4. **Monitor**:
   - Recheck in 5 minutes
   - Power should drop below 680W
   - Document action in log

### 4.2 Alert: RED Threshold (>680W)

**Triggered When**: PoE usage >94% (critical, risk of cascade shutdown)

**Immediate Actions** (within 5 minutes):
1. **Emergency Load Shedding**:
   - Identify non-critical devices (e.g., low-priority cameras)
   - Unplug PoE cable from that device
   - Announce to staff: "[Device] temporarily offline for power management"
   - Power draw should drop immediately

2. **Quick Assessment**:
   - Did power drop below 680W? ✅ Crisis averted
   - Still above 680W? ❌ Escalate to Travis Rylander

3. **Permanent Fix**:
   - Upgrade to higher-capacity PoE switch (USW-Pro-Max-48-PoE+ or equivalent)
   - Or defer camera deployment to Phase 2 (after switch upgrade)

### 4.3 Enable Low-Power Mode on Devices

**Yealink Phone** (Low-Power SIP):
```
Menu > Admin Settings > Power Saving:
  Low Power Mode: Enabled
  Display Off After: 5 min
  Expected Power: 30W (vs. 90W normal)
```

**Verkada Camera** (Low-Power Stream):
```
Verkada Dashboard > Device Settings > Camera #1:
  Streaming Mode: Low Power
  Frame Rate: 15 fps (vs. 30 fps)
  Resolution: 720p (vs. 1080p)
  Expected Power: 30W (vs. 90W normal)
```

**UAP-AC-PRO** (Low TX Power):
```
UDM Dashboard > Devices > AP #1 > Settings:
  TX Power: -10 dBm (low, ~50 mW)
  Expected Power: 15W (vs. 30W normal)
  Note: Reduces range (~50 feet vs. 150 feet), use only in emergency
```

---

## Phase 5: Preventive Maintenance

### 5.1 Quarterly Capacity Planning

**Q1, Q2, Q3, Q4** (beginning of each quarter):

1. **Trend Analysis**:
   - PoE power usage over last 3 months
   - Are new devices planned? (budget expansion)
   - Growth rate: Mbps/month?

2. **Forecast**:
   - If current trend continues, when will we exceed 680W?
   - Timeline for upgrade decision?

3. **Mitigation Options**:
   - **Option A**: Upgrade to 1200W PoE switch (Ubiquiti USW-Pro-Max-48-PoE+ or equivalent)
   - **Option B**: Deploy second PoE switch (for additional cameras, split load)
   - **Option C**: Reduce device count (defer non-essential devices)

### 5.2 Annual Audit

**End of Year** (December):

1. **Full Inventory**:
   - List all PoE devices (APs, phones, cameras, etc.)
   - Cross-reference with VLAN assignments
   - Verify MAC addresses match UDM database

2. **Power Audit**:
   - Measure actual vs. rated power for sample devices
   - Are devices operating in expected power mode?
   - Any anomalies (device drawing too much)?

3. **Plan Year Ahead**:
   - New departments requesting PoE devices?
   - Budget available for switch upgrade?
   - Document in IT strategic plan

---

## Phase 6: Documentation & Reporting

### 6.1 PoE Power Log

**Maintain Spreadsheet** (update monthly):

```
| Date | Avg Power | Peak | Min | Issues | Actions | Status |
|------|-----------|------|-----|--------|---------|--------|
| Dec 1 | 450W | 650W | 200W | None | Monitor | 🟢 OK |
| Dec 8 | 460W | 680W | 210W | Yellow alert | Low-power mode enabled | 🟡 Watch |
| Dec 15 | 440W | 620W | 190W | None | None | 🟢 OK |
| ... | ... | ... | ... | ... | ... | ... |
```

### 6.2 Alert Log

**Every Time Alert Triggered**:

```
Date: Dec 8, 2025 09:15am
Alert Level: YELLOW (680W threshold)
Cause: Verkada camera adoption in progress
Devices: 8 CD52 @ 90W each
Action Taken: Enabled low-power mode on cameras 5-8
Result: Power dropped to 640W (safe zone)
Duration: 45 minutes (until all cameras on low-power)
Escalated: No (resolved internally)
Notes: Camera adoption completed successfully by 10:00am
```

### 6.3 Monthly Report Template

```
Month: December 2025

Summary:
  Average PoE Usage: 450W (62% of 720W budget)
  Peak Usage: 680W (94%) - Yellow alert triggered Dec 8
  Minimum Usage: 200W (28%, off-hours)
  Uptime: 99.98% (no power-related outages)

Devices Added: 8 Verkada cameras (phased deployment)
Devices Removed: None
Alert Events: 1 Yellow (Dec 8, resolved)

Recommendations:
  ✓ Current deployment sustainable through Q1 2026
  ✓ Monitor during peak hours (9am-3pm school time)
  ✓ Plan USW upgrade for Phase 2 (cameras + additional APs)

Prepared By: Travis Rylander
Reviewed By: Principal/IT Leadership
Date: Dec 29, 2025
```

---

## Post-Deployment Validation

- [ ] PoE monitoring dashboard accessible and active
- [ ] Alert thresholds configured (600W yellow, 680W red)
- [ ] Low-power modes enabled on high-consumption devices
- [ ] Daily monitoring routine established (5 min checks)
- [ ] Current power draw <680W (GREEN status)
- [ ] At least one week of historical data collected
- [ ] Incident log and monthly reporting templates created
- [ ] Staff trained on load shedding procedure (emergency)
- [ ] Escalation procedure documented (contact Travis)

---

**Next Steps**: Archive all runbooks and finalize deployment checklist

**Escalation Contact**: Travis Rylander (network architect) for power budget expansion or device failure
