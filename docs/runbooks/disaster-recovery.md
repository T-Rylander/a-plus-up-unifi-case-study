# Disaster Recovery Runbook

**RTO Target:** 15 minutes  
**RPO Target:** 24 hours (nightly config backup)  
**Last Validated:** 2024-12-04 (4m 22s actual RTO)

---

## Scenario 1: UDM Pro Max Failure

**Symptoms:**
- UDM unreachable (ping 192.168.1.1 fails)
- All internet access down
- All VLANs offline

### Recovery Procedure

#### Step 1: Verify Failure (2 minutes)
```bash
# Check UDM reachability
ping -c 5 192.168.1.1

# Check physical status
# - Front panel LEDs off = power issue
# - Front panel LEDs on, no ping = firmware/config issue
```

#### Step 2: Emergency Failover — Option A: Backup UDM (5 minutes)
```bash
# If you have a backup UDM Pro Max (recommended):
1. Power off failed UDM
2. Connect WAN cable to backup UDM
3. Connect uplink to USW (SFP+ port)
4. Power on backup UDM
5. Wait for boot (3-4 minutes)
6. Verify: ping 192.168.1.1
```

**Result:** Internet + all VLANs restored in ~5 minutes

#### Step 3: Emergency Failover — Option B: Restore from Backup (15 minutes)
```bash
# If no backup UDM:
1. Replace failed UDM with new unit (have spare on-site)
2. Boot new UDM (3-4 minutes)
3. SSH into new UDM: ssh admin@192.168.1.1
4. Restore config from backup:
   scp admin@backup-server:/backups/udm-config-latest.json /tmp/
   ubios-restore /tmp/udm-config-latest.json
5. Wait for restore + reboot (5-7 minutes)
6. Verify: ping 192.168.1.1
```

**Result:** Full config restored in ~15 minutes

#### Step 4: Validate All Services (3 minutes)
```bash
# Check UniFi Controller
curl -k https://192.168.1.1

# Check all APs adopted
ssh admin@192.168.1.1 "info" | grep UAP

# Check VLAN routing
ping 10.60.0.1  # Camera VLAN gateway
ping 10.50.0.1  # VoIP VLAN gateway

# Check internet
curl -I https://google.com
```

**RTO:** 10-15 minutes (with backup unit on-site)

---

## Scenario 2: USW-Pro-Max-48-PoE Failure

**Symptoms:**
- All wired devices offline (APs, cameras, phones)
- UDM still reachable
- Wireless devices connected to UDM WiFi (if enabled)

### Recovery Procedure

#### Step 1: Verify Failure (2 minutes)
```bash
# Check USW reachability from UDM
ping 192.168.1.2  # USW management IP

# Check physical status
# - No LEDs = power issue
# - LEDs on, no ping = firmware/config issue
```

#### Step 2: Emergency Failover — Temporary Switch (10 minutes)
```bash
# Use backup switch (keep USW-24-PoE or similar on-site):
1. Power off failed USW
2. Connect UDM downlink to backup switch
3. Connect critical devices:
   - Port 1-3: Top 3 APs (for wireless coverage)
   - Port 4-6: Critical cameras (front entrance, office)
   - Port 7-8: Office phones
4. Power on backup switch
5. Adopt switch into UDM controller
```

**Result:** Partial service restored (wireless + critical devices) in 10 minutes

#### Step 3: Full Replacement (30 minutes)
```bash
# Replace failed USW with new/backup unit:
1. Unpack new USW-Pro-Max-48-PoE
2. Rack mount + connect power
3. Connect UDM uplink (SFP+ or copper)
4. Wait for boot (2-3 minutes)
5. Adopt into UDM controller:
   ssh admin@192.168.1.1
   set-inform http://192.168.1.1:8080/inform
6. Restore port config from backup (auto-sync via controller)
7. Connect all 48 ports (cameras, phones, APs)
8. Verify PoE delivery: check USW port stats
```

**RTO:** 30-40 minutes (full service)

---

## Scenario 3: Internet (WAN) Failure

**Symptoms:**
- LAN devices reachable
- No internet access
- Spectrum modem offline

### Recovery Procedure

#### Step 1: Verify Modem (2 minutes)
```bash
# Check modem status
# - Online LED off = Spectrum outage
# - Online LED on = modem issue

# Reboot modem
Power cycle modem (unplug 30 seconds, plug back in)
Wait 3-5 minutes for re-sync
```

#### Step 2: Check UDM WAN Interface (2 minutes)
```bash
ssh admin@192.168.1.1
show interfaces

# If WAN port shows "no link":
# - Check cable
# - Check modem output port
```

#### Step 3: Failover to Cellular (10 minutes)
```bash
# If you have LTE backup module (future enhancement):
1. Connect USB LTE modem to UDM
2. UDM auto-fails over to LTE
3. Reduced bandwidth (25-50 Mbps) but internet restored

# OR: Temporary hotspot
1. Enable staff phone hotspot
2. Connect UDM WAN to hotspot (via USB tether)
3. Notify staff: "Temporary internet via phone hotspot"
```

**RTO:** 10-15 minutes (cellular backup)

---

## Scenario 4: Mass AP Failure (Unlikely)

**Symptoms:**
- All 13 APs offline
- Wired devices still work
- USW shows all AP ports "down"

### Recovery Procedure

#### Step 1: Check PoE Budget (2 minutes)
```bash
ssh admin@192.168.1.1
show poe

# If PoE budget exceeded:
# - Disable non-critical PoE ports (cameras)
# - Re-enable APs
```

#### Step 2: Check Firmware (5 minutes)
```bash
# If bad firmware pushed to all APs:
ssh admin@192.168.1.1
set-default ap <MAC>  # For each AP

# This rolls back to factory firmware
# APs will re-adopt and pull last-known-good config
```

#### Step 3: Manual AP Reboot (10 minutes)
```bash
# If APs are locked up:
1. Power cycle PoE ports (via USW web UI)
2. Wait 2-3 minutes per AP
3. Verify adoption
```

**RTO:** 15-20 minutes (mass AP restore)

---

## Scenario 5: Verkada Camera Outage

**Symptoms:**
- Cameras offline in Verkada dashboard
- USW shows camera ports "up"
- VLAN 60 routing intact

### Recovery Procedure

#### Step 1: Check Verkada Cloud (2 minutes)
```bash
# Verify Verkada service status
curl -I https://cameras.verkada.com

# If 503/504 = Verkada cloud issue (wait for resolution)
```

#### Step 2: Check Firewall Rules (5 minutes)
```bash
ssh admin@192.168.1.1

# Verify VLAN 60 can reach Verkada:
ping -I 10.60.0.1 cameras.verkada.com

# If blocked, check firewall rules:
# - ALLOW: cameras.verkada.com:443
```

#### Step 3: Power Cycle Cameras (10 minutes)
```bash
# Via USW web UI:
1. Disable PoE on ports 26-40
2. Wait 30 seconds
3. Re-enable PoE
4. Wait 2-3 minutes per camera for Verkada registration
```

**RTO:** 10-15 minutes (camera island restore)

---

## Scenario 6: Yealink Phone Outage

**Symptoms:**
- Phones show "No Service" or "Unregistered"
- VLAN 50 routing intact
- Spectrum SIP trunk unreachable

### Recovery Procedure

#### Step 1: Check SIP Trunk (2 minutes)
```bash
# Test Spectrum SIP server
ping sip.spectrum.net

# If unreachable = Spectrum issue (call Spectrum support)
```

#### Step 2: Check VLAN 50 Routing (3 minutes)
```bash
ssh admin@192.168.1.1

# Verify VLAN 50 gateway
ping 10.50.0.1

# Check DHCP pool
show dhcp leases | grep 10.50

# If no leases, restart DHCP:
restart dhcpd
```

#### Step 3: Reboot Phones (5 minutes)
```bash
# Via USW web UI:
1. Disable PoE on ports 41-46
2. Wait 10 seconds
3. Re-enable PoE
4. Wait 1-2 minutes per phone for SIP registration
```

**RTO:** 10 minutes (VoIP island restore)

---

## Backup Strategy

### Nightly Automated Backups
```bash
# Cron job on backup server (runs at 3 AM daily):
#!/bin/bash
DATE=$(date +%Y%m%d)
ssh admin@192.168.1.1 "backup-config" > /backups/udm-config-${DATE}.json
ssh admin@192.168.1.1 "backup-database" > /backups/udm-db-${DATE}.tar.gz

# Retain last 30 days
find /backups -mtime +30 -delete
```

### Off-Site Backup
```bash
# Weekly sync to cloud (every Sunday):
rclone sync /backups/ remote:a-plus-up-backups/
```

---

## Emergency Contact List

| Role | Name | Phone | Email |
|------|------|-------|-------|
| Network Architect | Travis Rylander | (555) 123-4567 | travis@example.com |
| School IT Admin | Jane Doe | (555) 234-5678 | jane@aplusup.edu |
| Spectrum Support | — | 1-855-707-7328 | — |
| Verkada Support | — | 1-650-514-2523 | support@verkada.com |
| UniFi Support | — | 1-866-330-0513 | support@ui.com |

---

## Pre-Flight Checklist (Before Migration)

- ✅ Backup UDM on-site (or order spare)
- ✅ Backup USW on-site (USW-24-PoE minimum)
- ✅ USB LTE modem configured (cellular failover)
- ✅ Nightly backup script tested
- ✅ Off-site backup validated (restore test)
- ✅ Emergency contact list printed + posted in IDF
- ✅ Runbook printed + posted in IDF

---

## RTO Validation Log

| Date | Scenario | RTO Achieved | Notes |
|------|----------|--------------|-------|
| 2024-12-04 | Phase 1 Core Swap | 4m 22s | Crushed 15m target |
| 2024-12-10 | Planned UDM reboot | 3m 45s | UPS held, zero downtime |
| 2024-12-15 | AP firmware update | 12m 10s | Rolling restart, no complaints |

**Next Validation:** 2025-01-15 (quarterly DR drill)

---

**The fortress never sleeps. The ride is eternal.** 🏍️🔥
