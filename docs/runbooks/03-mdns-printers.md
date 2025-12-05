# Runbook: Printer mDNS Discovery & AirPrint Configuration

**Scope**: Printer VLAN 20 assignment, mDNS reflector, cross-VLAN printing  
**Audience**: IT staff, facilities  
**Prerequisites**: VLAN 20 configured, UDM mDNS reflector enabled, firewall rules open  
**Estimated Time**: 3 hours for 40 printers  
**Source**: ADR 006 (Printer mDNS), Additional Considerations Addendum

---

## Pre-Deployment Checklist

- [ ] VLAN 20 created (10.20.0.0/24)
- [ ] UDM mDNS reflector enabled (Network > DNS > mDNS Reflector)
- [ ] Firewall rule: VLAN 10 → VLAN 20 ports 9100/515/631 **ALLOW**
- [ ] Firewall rule: VLAN 1 (legacy) → VLAN 20 (for existing printers)
- [ ] All 40+ printers physically inventoried (MAC addresses recorded)
- [ ] Test Chromebook available (for discovery testing)

---

## Phase 1: Printer Inventory & MAC Addresses

### 1.1 Collect Printer Information

**For Each Printer**:
1. Press **Menu** button on printer
2. Navigate: **Settings > Network > IPv4 > Show Details**
3. Write down:
   - **Printer Model** (e.g., "Brother MFC-L8390CDW")
   - **MAC Address** (e.g., "AA:BB:CC:DD:EE:01")
   - **Current IP** (e.g., "192.168.1.50")
   - **Location** (e.g., "Copy Room - 1st Floor")
   - **Department** (e.g., "Administrative", "Science Lab")

**Example Inventory Sheet**:
```
| # | Model | MAC | IP | Location | Dept |
|---|-------|-----|----|----|------|
| 1 | Brother MFC | AA:BB:CC:01 | 192.168.1.50 | Copy Room | Admin |
| 2 | HP LaserJet | AA:BB:CC:02 | 192.168.1.51 | Office | Staff |
| ... | ... | ... | ... | ... | ... |
```

### 1.2 Print Configuration Page (Verification)

1. On each printer, press **Menu**
2. Navigate: **Reports > Print Configuration**
3. Collect printed page showing:
   - MAC address
   - Model number
   - Current network settings
4. Store in folder (for reference during VLAN migration)

---

## Phase 2: VLAN 20 DHCP MAC Binding Setup (UDM)

### 2.1 Create DHCP Static Assignments

1. **UDM Dashboard > Settings > Networks > VLAN 20**
2. Scroll to **DHCP Server > Static Assignments**
3. **Add Entry** (for each printer):
   ```
   MAC Address: AA:BB:CC:DD:EE:01
   Hostname: Printer-CopyRoom-1
   IP Address: 10.20.0.50
   ```
4. Repeat for all 40+ printers

**Example VLAN 20 IP Allocation**:
```
| IP Range | Purpose |
|-----------|---------|
| 10.20.0.1-9 | Gateway + reserved |
| 10.20.0.50-99 | Printers (50 slots for 40+ printers) |
| 10.20.0.100-200 | Staff workstations |
| 10.20.0.201-254 | Guest/spare |
```

### 2.2 Enable mDNS Reflector (UDM)

1. **UDM Dashboard > Settings > Networks > VLAN 20**
2. Scroll to **DNS > mDNS Reflector**
3. [ ] **Enable mDNS Reflector**: Yes
4. **Reflector Rules**:
   - [ ] **Reflect _ipp._tcp.local** (Apple AirPrint)
   - [ ] **Reflect _printer._tcp.local** (Generic printers)
   - [ ] **Reflect _http._tcp.local** (Web admin interface)
5. **Reflector Source**: VLAN 20 (printers)
6. **Reflector Destination**: VLAN 10 (students can discover)
7. Save and **Restart UDM Network** (2 min downtime)

---

## Phase 3: Printer VLAN Migration (Phased)

### 3.1 Migrate Printers (5 per day, staged)

**Day 1 - Printers #1-5**:

1. **Day 1 Morning (Prep)**:
   - Identify first 5 printers
   - Notify affected departments: "Printers offline for 30 min, will restore by 10am"

2. **At Scheduled Time**:
   - Disconnect old network (Ethernet cable from old switch)
   - Connect to new USW-Pro-Max-48-PoE **VLAN 20 PoE port**
   - Power cycle printer (turn off 30 sec, turn on)
   - Wait 2-3 min for boot (LED stabilizes)

3. **Verify IP Assignment**:
   - Printer Menu > Network > IPv4
   - Verify IP is **10.20.0.50+** (VLAN 20 range)
   - Verify Gateway is **10.20.0.1**

4. **Verify Network Access**:
   - Print **Test Page** from printer (Menu > Print Test Page)
   - Should print normally

5. **Restore Service**:
   - Notify department: "Printers online, ready to use"

**Day 2-8 - Repeat process** (5 printers per day until all 40+ migrated)

### 3.2 Parallel Old Network (Cutover Strategy)

**If printers must remain online during migration**:

1. **Phase A (Week 1)**:
   - Connect new printers to VLAN 20 (parallel with old)
   - Broadcast to staff: "New printers available at 10.20.0.x"
   - Staff test new printers while old still functional

2. **Phase B (Week 2)**:
   - Once staff confirms new printers working
   - Gracefully disconnect old printers
   - Notify: "Old printers now offline"

---

## Phase 4: mDNS Reflector Validation

### 4.1 Test Printer Discovery from Chromebook (VLAN 10)

**Procedure**:
1. Connect test Chromebook to **AUP-Main** WiFi
2. Open **Google Cloud Print** (or native print dialog):
   - Chrome Browser > File > Print (Ctrl+P)
   - Click **Change** next to printer
3. **Available Printers** should list:
   - All 40+ printers by name (e.g., "Brother-CopyRoom-1")
   - Status: "Ready" or "Idle"

**Expected Outcome**:
- ✅ Printer list shows 40+ printers
- ✅ Printers appear within 5 seconds
- ✅ Multiple printers visible (not just first one)

### 4.2 Troubleshoot Missing Printers

**If printers NOT appearing**:

**Step 1 - Verify mDNS Reflector Running**:
```
UDM Dashboard > Settings > Networks > VLAN 20
  → mDNS Reflector: Enabled (confirmed)
  → Rules: _ipp._tcp.local, _printer._tcp.local, _http._tcp.local (all checked)
```

**Step 2 - Verify Firewall Rule**:
```
UDM Dashboard > Firewall > Rules
  → Rule: VLAN 10 → VLAN 20 ports 9100/515/631
  → Status: ALLOW (confirmed)
```

**Step 3 - Manual Printer Add** (fallback):
- Chromebook > Print > Change Printer
- Click **Add Custom Printer**
- Enter IP: 10.20.0.50 (first printer IP)
- Test print

**Step 4 - Escalate**:
- Check UDM system log for mDNS errors
- Restart UDM (UDM Dashboard > System > Restart)
- Re-enable mDNS Reflector

---

## Phase 5: Cross-VLAN Printing Test

### 5.1 Print from Student Chromebook (VLAN 10) to Printer (VLAN 20)

**Test Scenario**:
1. Connect Chromebook to AUP-Main WiFi
2. Open **Google Classroom** (student app)
3. Select document (e.g., PDF assignment)
4. File > Print (Ctrl+P)
5. Select printer from list (e.g., "HP-Lab-1")
6. **Submit Print**

**Verify**:
- [ ] Print dialog shows list of available printers
- [ ] Selected printer appears in list
- [ ] Print job sent successfully
- [ ] Document prints at physical printer

### 5.2 Print from Staff Device (VLAN 20) to Any Printer

**Test Scenario**:
1. Staff workstation (native VLAN 20, same as printers)
2. Open any document
3. File > Print
4. Select printer
5. Submit

**Verify**:
- [ ] Printer list shows (local VLAN discovery)
- [ ] Print completes successfully

---

## Phase 6: Band Steering Impact (WiFi AP Placement)

### 6.1 Verify Printer AP Placement (WAP2/4 Carve)

**Special 2.4GHz Printer AP** (for legacy printer setup):

1. **Locate WAP2/4 AP** (if deployed):
   - SSID: "Printer-Setup-2.4"
   - Location: Central area (copy room or break room)
   - 2.4GHz channel 11 (low power)

2. **Legacy Printer Setup**:
   - Some old printers only support 2.4GHz
   - Connect to "Printer-Setup-2.4" instead of "AUP-Main"
   - Once connected, manually assign static IP (10.20.0.x)
   - Then migrate to main VLAN 20

---

## Phase 7: AirPrint Fallback (Google Cloud Print)

### 7.1 Configure Google Cloud Print (Optional)

**If mDNS Reflector Fails**:

1. **Register Printers with Google**:
   - Admin account > google.com/cloudprint
   - Add each printer (one by one)
   - Assign to shared class

2. **Chromebook Discovery**:
   - Chromebook Print dialog will show "Cloud Printers"
   - Fall back to cloud-based printing

3. **Limitation**:
   - Slightly higher latency (cloud round-trip)
   - Works without mDNS reflector (resilience)

---

## Post-Deployment Validation

- [ ] All 40+ printers migrated to VLAN 20 (10.20.0.x)
- [ ] Each printer has static MAC binding in VLAN 20 DHCP
- [ ] mDNS reflector enabled (UDM)
- [ ] Firewall rule VLAN 10 → VLAN 20 (ports 9100/515/631) active
- [ ] Chromebook printer discovery working (lists all printers)
- [ ] Test print successful (from Chromebook to printer)
- [ ] Multiple printers discovered (not just first one)
- [ ] WAP2/4 AP online (if deployed for 2.4GHz legacy)
- [ ] Staff trained on new print workflow
- [ ] Documentation saved (printer inventory, IP mapping, MAC addresses)

---

**Next Steps**: Proceed to Verkada camera deployment (Runbook 4)

**Escalation Contact**: Travis Rylander (network architect) if printer discovery fails
