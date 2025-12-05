# ARCHITECTURE.md — Network Topology & Technical Design

**Source**: AUP Network Overhaul Blueprint v2.5 | November 10, 2025

---

## Physical Topology Overview

### Building Dimensions & Facility
- **Total Square Footage**: 20,205 sq ft (~10,000 per floor)
- **Infrastructure**: Cat6 cabling (2021 retrofit), central network closet
- **Location**: Urban Houston (low ambient RF noise; 180-230 neighboring SSIDs detected)
- **Device Density**: 110-120 Chromebooks upstairs; 5-device cart downstairs

### Port Allocation (USW-Pro-Max-48-PoE)

```
PORTS 1-16:  Access Points (16× UAP-AC-PRO)
PORTS 17-24: VoIP Devices (8× Yealink T43U)
PORTS 25-39: Cameras (15× Verkada PoE+)
PORT 40:     Trunk to Camera Island (TP-Link switch)
PORTS 41-47: Spare ports (for future expansion)
PORT 48:     UPS Power Monitoring
```

**Fiber Handoff**: Comcast → LC connector → UDM SFP+ (UF-SM-1G-S, 1310nm validated)

---

## Access Point Deployment

### Upstairs (10 APs)

| ID | Location | Role | Channels | Coverage |
|----|----------|------|----------|----------|
| **WAP1** | NW (Rm201 adj) | Classrooms 201 | 36, 40MHz | Fair (-65 dBm edges) |
| **WAP2** | Office (Rm208) | Admin | 2.4GHz only | Redundant with WAP4 |
| **WAP3** | Rm201 | Classroom | 52, 80MHz | Strong (-55 dBm) |
| **WAP4** | Office/Rm208 | Admin | 2.4GHz only | Redundant with WAP2 |
| **WAP5** | Rm202 | Classroom | 100, 80MHz | Strong (-58 dBm) |
| **WAP6** | Rm206 | Classrooms 206+ | 132, 80MHz | Stretched to Rm205/207 |
| **WAP7** | Rm204 | Classroom east | 149, 80MHz | Strong (-56 dBm) |
| **WAP8** | Rm207 (NEW) | Library coverage | 165, 80MHz | Fills -70/-80 void |
| **WAP9** | Door edge (NEW) | Rm205 edge | 36, 40MHz fallback | -53 dBm target |
| **WAP10** | Central (Common 100) | Hall/common | 36/36 dual | Excellent (-43/-50) |

**Coverage Pre-Tuning**: 75% above -65 dBm (core 85%, edges 55%)  
**Coverage Post-Tuning**: 92% above -65 dBm (projected with 3 new APs + channel rebalance)

### Downstairs (6 APs)

| ID | Location | Role | Channels | Coverage |
|----|----------|------|----------|----------|
| **WAP8** | SW (Rms102-106) | Classrooms | 52, 80MHz | Strong (-55 dBm) |
| **WAP9** | Four Rooms | Classrooms | 100, 80MHz | Solid (-58 dBm) |
| **WAP10** | Central (Common 100) | Hall/common | 36/36 dual | Excellent (-43/-50) |
| **WAP11** | NE (Rm111) | Classrooms 109-111 | 132, 80MHz | Fair (-61 dBm) |
| **WAP12** | SE (Elevator, Rms118-120) | Offices/elevator | 149, 80MHz | Strong (-42/-57) |
| **WAP13** | Room 107 (RELOCATED) | NW coverage | 36, 40MHz | Fills -68/-75 void |

**Coverage Pre-Tuning**: 78% above -65 dBm (core 85%, edges 60%)  
**Coverage Post-Tuning**: 94% above -65 dBm (post-relocation)

---

## WiFi Channel Strategy

### 5GHz Channels (Primary)
- **Non-DFS**: 36 (20 MHz), 40, 44, 48 | 149, 153, 157, 161, 165
- **DFS**: 52, 56, 60, 64 | 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144
- **Deployment**: 80 MHz channel width (160 MHz not supported by UAP-AC-PRO)
- **Selected Spread**: 36, 52, 100, 116, 132, 149 (6 channels, 80 MHz each = no overlap)
- **Fallback**: 40 MHz if ACI issues detected (post-lab test)

### 2.4GHz Channels (Deprecated)
- **Globally Disabled** (reduces 70-80% saturation)
- **Exception**: WAP2/4 low-power carve for printers only (channels 1, 6, 11)
- **Rationale**: 40-60% collision rates; 12-25 neighboring APs per scan

### RSSI & Steering Parameters
- **RSSI Threshold**: -70 dBm (hard minimum)
- **Steering Min**: -67 dBm (encourage 5GHz roaming)
- **Target Coverage**: -65 dBm or better (92-96% of facility)
- **Transmission Power**: +7 dB boost (lab-validated improvement: +6 dB mean RSSI)

---

## VLAN Architecture

### VLAN 10: Students/Chromebooks (10.10.0.0/23)

```
Subnet:          10.10.0.0/23
Usable Hosts:    510
DHCP Range:      10.10.0.2 — 10.10.2.254
Lease Duration:  4 hours (transient users)
Default Gateway: 10.10.0.1
Wireless SSID:   "A+UP-Chromebooks"
Security:        WPA2-PSK (pre-shared key)
DPI Rules:       Google Meet, Google Classroom, YouTube (QoS priority)
Band Steering:   Enabled (-67 dBm minimum)
802.11k/v/r:     Enabled (fast roaming <5 sec)
```

**Access Points**: WAP1, WAP3, WAP5, WAP6, WAP7, WAP8, WAP9, WAP10 (Upstairs)  
**Access Points**: WAP8, WAP9, WAP10, WAP11, WAP12, WAP13 (Downstairs)

### VLAN 20: Staff & Printers (10.20.0.0/24)

```
Subnet:          10.20.0.0/24
Usable Hosts:    254
DHCP Range:      10.20.0.2 — 10.20.0.254
Lease Duration:  24 hours
Default Gateway: 10.20.0.1
Wireless SSID:   "A+UP-Staff"
Security:        WPA2-Enterprise (RADIUS, optional)
mDNS Reflector:  Enabled (cross-VLAN printing from VLAN 10)
Printer DHCP:    Reservation (static IPs via MAC binding)
2.4GHz AP:       WAP2, WAP4 only (low power)
QoS Profile:     High Priority (staff applications)
```

**Access Points**: WAP2, WAP4 (2.4GHz only; low power)  
**Multicast Services**: mDNS (UDP 5353), Bonjour/AirPrint, HP JetDirect (TCP 80, 161, 8289), SLP (UDP 427)

### VLAN 30: Guest WiFi (10.30.0.0/24)

```
Subnet:          10.30.0.0/24
Usable Hosts:    254
DHCP Range:      10.30.0.2 — 10.30.0.254
Lease Duration:  2 hours
Default Gateway: 10.30.0.1
Wireless SSID:   "A+UP-Guest"
Security:        Open (captive portal enforced)
Captive Portal:  Redirect to A+UP splash page
Bandwidth Limit: 25 Mbps down / 10 Mbps up (throttled)
Client Isolation: Enabled (inter-guest blocking)
Audit Logging:   90-day retention; syslog forwarding
Blacklist:       Optional content filtering
```

**Access Points**: All 16 APs (guest broadcast on all channels)  
**Firewall**: Complete isolation from internal VLANs (10, 20, 50, 60, 99)

### VLAN 50: VoIP/Yealink (10.50.0.0/27)

```
Subnet:          10.50.0.0/27
Usable Hosts:    30 (8 devices + 22 headroom)
DHCP Range:      10.50.0.2 — 10.50.0.30
Lease Duration:  Infinite (static assignment)
Default Gateway: 10.50.0.1
Port Allocation: USW ports 17-24 (8 physical ports)
Devices:         8× Yealink T43U phones
Codec:           G.722 (wideband)
QoS Profile:     EF (Expedited Forwarding, DSCP 46)
Jitter Target:   <30 milliseconds
Latency Target:  <150 milliseconds
RTP Ports:       8000-8800 (UDP bidirectional)
SIP Ports:       5060-5061 (TCP/UDP bidirectional)
SIP Provider:    Spectrum SIP (ALG disabled on UDM)
Firewall Rules:  Allow to Spectrum SIP carrier; allow to VLAN 20 (staff); block VLAN 10/30
```

**TFTP Boot** (optional): DHCP Option 66 → UDM (10.99.0.1)  
**Future Scaling**: Ready for 30-device deployment (27 available slots)

### VLAN 60: Cameras/Verkada (10.60.0.0/26)

```
Subnet:          10.60.0.0/26
Usable Hosts:    62 (12-15 cameras + management IP)
DHCP Range:      10.60.0.2 — 10.60.0.62
Lease Duration:  Infinite (static assignment)
Default Gateway: 10.60.0.1
Management IP:   10.60.0.250 (TP-Link camera island gateway)
Port Allocation: USW ports 25-39 (15 physical PoE+ ports)
Devices:         12-15× Verkada CD52/CD62 cameras
PoE Power:       PoE+ (high-wattage models)
Power Budget:    100 Kbps idle; 3-5 Mbps live; 45 Mbps burst max
QoS Profile:     AF41 (Assured Forwarding)
Cloud Uplink:    HTTPS 443 to Verkada cloud (outbound only)
Firewall Rules:  Allow to Verkada cloud; allow RTSP from VLAN 99 (mgmt); block all other VLANs
Spanning Tree:   RSTP 802.1w (camera island trunk alignment)
```

**Camera Island Contingency** (if needed):
- Trunk: USW Port 40 → TP-Link Switch Port 24
- TP-Link config: Ports 1-15 ACCESS (PVID 60), Port 24 TRUNK (Tagged 60, PVID 1)
- Management: Via VLAN 60 gateway (10.60.0.250)

### VLAN 99: Management (10.99.0.0/28)

```
Subnet:          10.99.0.0/28
Usable Hosts:    14
Allocated:       
  - 10.99.0.1    UDM Pro Max (primary controller)
  - 10.99.0.2    USW-Pro-Max-48-PoE (switch mgmt)
  - 10.99.0.3    UPS (SNMP monitoring)
  - 10.99.0.4-14 Reserved (future expansion)
DHCP Range:      None (static assignment only)
Default Gateway: 10.99.0.1
QoS Profile:     CS6 (Network Control, DSCP 48)
SSH/HTTPS:       Enabled (encrypted management access)
Firewall Rules:  Unrestricted internal; no outbound except SNMP traps
SNMP OIDs:       UPS battery status, temperature, load; UDM CPU/memory; switch PoE budget
```

---

## PoE Budget & Power Management

### Current Utilization (Lab-Measured)

```
16× UAP-AC-PRO @ 27W average     = 432W (headroom for peaks)
8× Yealink T43U @ 3.5W each      = 28W
12× Verkada cameras @ 20W average = 240W (PoE+)
────────────────────────────────────────
TOTAL ACTIVE POWER               ≈ 290W (40% of 720W budget)
HEADROOM                         = 430W (60% available)
```

### Monitoring & Thresholds

| Utilization | Status | Action |
|-------------|--------|--------|
| <85% (612W) | GREEN | Normal operation |
| 85-94% (673W) | YELLOW | Investigate high-demand apps; log advisory |
| >94% (684W) | RED | Alert; reduce non-critical devices; escalate |
| >100% | BREACH | Automatic PoE load-shedding (cameras first) |

### APC UPS Configuration

- **Model**: SMX2000LVNC (backup power, ~8-12 min runtime at 290W)
- **Load**: PoE baseline (290W) + UDM (50W) + USW (100W) ≈ 440W total
- **Failover**: Graceful VoIP shutdown (Yealink graceful hold); cameras continue
- **Monitoring**: SNMP OIDs pulled by UDM (battery % health, temperature, load)
- **Maintenance**: Monthly self-test; replacement at 70% capacity retention

---

## Fiber WAN Connectivity

### Comcast Demarcation
- **Interface**: LC single-mode fiber (1310nm, 10km spec validated)
- **Optical Power**: -15 to +3 dBm (healthy range)
- **Module**: UF-SM-1G-S (1000BASE-LX) in UDM SFP+ port
- **Throughput**: 1 Gbps (fiber verified; WAN throughput target >900 Mbps)
- **Backup**: Terrestrial failover available (Spectrum backup SIP, optional)

### Redundancy & Failover
- **Primary Link**: Fiber to UDM
- **LACP Trunk**: 10G uplink from UDM → USW (if available)
- **Failover RTO**: 15 minutes (5-min WAN + 10-min VLAN config)

---

## Firewall Rules Summary (Simplified to <10)

### Rule 1-3: VLAN 30 (Guest) Isolation
- **Rule 1**: 10.30.0.0/24 → 10.30.0.1 (DNS/DHCP) Allow
- **Rule 2**: 10.30.0.0/24 → 10.0.0.0/8 (Internal) Block
- **Rule 3**: 10.30.0.0/24 → 0.0.0.0/0 (Internet) Allow

### Rule 4-6: VLAN 50 (VoIP) Security
- **Rule 4**: 10.50.0.0/27 → Spectrum SIP (5060-5061, 8000-8800) Allow
- **Rule 5**: 10.50.0.0/27 → 10.20.0.0/24 (Staff) Allow
- **Rule 6**: 10.50.0.0/27 → 10.10.0.0/23, 10.30.0.0/24 (Students/Guests) Block

### Rule 7-9: VLAN 60 (Cameras) Segmentation
- **Rule 7**: 10.60.0.0/26 → Verkada cloud (443) Allow
- **Rule 8**: 10.99.0.0/28 → 10.60.0.0/26 (RTSP 554) Allow
- **Rule 9**: 10.60.0.0/26 → Other VLANs (All) Block

### Rule 10: Management Access
- **Rule 10**: 10.99.0.0/28 → 10.60.0.250 (TP-Link camera gateway, 443) Allow (if camera island active)

---

## Monitoring & Observability

### UniFi Insights Dashboards

| Dashboard | Metrics | Target |
|-----------|---------|--------|
| **PoE Budget** | Real-time W/usage %; alerts at 85% | <40% nominal |
| **VLAN Traffic** | Per-VLAN throughput; isolation validation | No inter-VLAN leakage |
| **WAN Status** | Throughput, latency, jitter, optical power | >900 Mbps; <50ms latency |
| **RSSI Heatmaps** | WiFi coverage; dead zones; roaming patterns | >-65 dBm in 92% of facility |
| **VoIP Jitter** | Real-time jitter trace; codec quality | <30ms target |
| **Device Health** | AP uptime; camera adoption; phone registration | 99.5%+ uptime |

### SNMP Monitoring
- **UPS**: Battery health %, load W, temperature C, time-on-battery sec
- **UDM**: CPU %, memory %, thermal status, IDS/IPS threat count
- **USW**: PoE budget W, per-port stats, temperature C

---

## Incident Response & Rollback

### Fiber WAN Failure
- **Trigger**: Optical signal <-20 dBm OR WAN throughput <800 Mbps
- **Action**: Export JSON config; revert to JSON backup; document issue
- **RTO**: 2 minutes
- **Escalation**: Contact Comcast; verify optical plant

### Switch/PoE Failure
- **Trigger**: PoE reprovisioning >10 min OR network flap detected
- **Action**: Restore Juniper ACX1100 loopback; reroute PoE via legacy injectors
- **RTO**: 5 minutes
- **Escalation**: Order replacement USW within 24 hrs

### AP Adoption Failure
- **Trigger**: >2 consecutive adoption failures OR roaming latency >10s
- **Action**: Firmware update; defer adding new devices; run manual adoption
- **RTO**: 10 minutes
- **Escalation**: Check UniFi controller logs; reboot controller if needed

---

**Document Source**: AUP Network Overhaul Blueprint v2.5, November 10, 2025  
**Last Updated**: November 10, 2025  
**Next Review**: Post-deployment validation (Dec 4, 2025)
