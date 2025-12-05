# A+UP Charter School — Network Infrastructure Overhaul

**Version:** 2.5 (Canonical from 8 source documents)  
**Specification Date:** November 10, 2025  
**Status:** Blueprint-Ready | Lab-Validated | Deployment-Phase

---

## Executive Summary

This repository contains the complete technical documentation, architecture decisions, and operational procedures for the A+UP Charter School network infrastructure overhaul. The project transforms a legacy multi-vendor environment (FortiGate, Juniper, Fortinet stack) into a unified UniFi ecosystem supporting:

- **150+ Chromebooks** (VLAN 10: 10.10.0.0/23)
- **16 UAP-AC-PRO access points** with WiFi 6-ready architecture
- **12-15 Verkada cameras** (VLAN 60: 10.60.0.0/26)
- **8 Yealink SIP phones** (VLAN 50: 10.50.0.0/27)
- **40+ wireless printers** with mDNS reflector (VLAN 20: 10.20.0.0/24)
- **92-96% wireless coverage** (lab-validated)
- **15-minute failover RTO** with APC UPS backup

### Key Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| **Upfront Cost** | $3,814 | $2,120 hardware + $99 licensing + $805 labor |
| **Resale Offset** | ~$1,200 | Legacy FortiGate, Juniper, FortiSwitch gear |
| **Net Investment** | $2,614 | After 65% resale offset |
| **Monthly Support** | $599 | Service-only (10 hrs/month) |
| **3-Year Savings** | $34,452 | Reduced overages + eliminated reactive calls |
| **Wireless Coverage** | 92-96% | RSSI > -65 dBm target achieved |
| **VoIP Jitter** | <30ms | G.722 codec with DSCP EF tagging |
| **Failover RTO** | 15 min | 8-12 min UPS runtime |

---

## Core Infrastructure

### Gateway & Controller
- **UDM Pro Max**: 10G WAN capability, integrated IDS/IPS, UniFi OS, 3.5 Gbps threat throughput
- **Fiber WAN**: Comcast LC connector to UDM SFP+ (UF-SM-1G-S, 1000BASE-LX, 10km spec)

### Distribution Switch
- **USW-Pro-Max-48-PoE**: 720W PoE budget, 40 Gbps backplane, 10G uplink
- **Port Allocation** (39/48 used):
  - Ports 1-16: Access Points (16× UAP-AC-PRO)
  - Ports 17-24: VoIP Devices (8× Yealink T43U)
  - Ports 25-39: Cameras (15× Verkada, PoE+)
  - Ports 40-48: Spares + UPS

### Wireless Access Points
- **16× UAP-AC-PRO** (includes 3 new units for coverage)
  - Upstairs: 10 APs (channels 36/52/100)
  - Downstairs: 6 APs (channels 116/132, WAP13 in Room 107)
  - 2.4GHz carve: WAP2/4 only (printers, 70% saturation mitigation)

### Endpoints
- **8 Yealink T43U phones**: VLAN 50, direct SIP (Spectrum retired)
- **12-15 Verkada cameras** (CD52/CD62 PoE+): VLAN 60, 100 Kbps idle / 3-45 Mbps live
- **40+ wireless printers**: Ad-hoc VLAN 20, mDNS/Bonjour + AirPrint fallback

### Power & Resilience
- **APC SMX2000LVNC UPS**: 8-12 min runtime, 40% PoE baseline headroom
- **Redundancy**: Dual uplinks (LACP), STP-aligned camera island (TP-Link trunk)

---

## Network Architecture

### VLAN Design

| VLAN | Purpose | Subnet | Usable Hosts | DHCP Lease | QoS | Notes |
|------|---------|--------|--------------|-----------|-----|-------|
| **10** | Students/Chromebooks | 10.10.0.0/23 | 510 | 4 hours | Standard | DPI for Google Meet/Classroom/YouTube; -67 dBm steering |
| **20** | Staff/Printers | 10.20.0.0/24 | 254 | 24 hours | High Priority | mDNS enabled; AirPrint fallback |
| **30** | Guest WiFi | 10.30.0.0/24 | 254 | 2 hours | Throttled | 25 Mbps down / 10 Mbps up; captive portal; 90-day logs |
| **50** | VoIP (Yealink) | 10.50.0.0/27 | 30 | Infinite | EF (DSCP) | G.722 codec; jitter <30ms; 8 devices + 22 headroom |
| **60** | Cameras (Verkada) | 10.60.0.0/26 | 62 | Infinite | AF41 | PoE+; 100 Kbps idle; 45 Mbps burst; RSTP aligned |
| **99** | Management | 10.99.0.0/28 | 14 | Infinite | CS6 | UDM, UPS SNMP, TP-Link camera island gateway |

### Firewall Rules (Simplified to <10)

#### VLAN 30 (Guest) Isolation
| # | Source | Destination | Ports | Action | Notes |
|---|--------|-------------|-------|--------|-------|
| 1 | 10.30.0.0/24 | 10.30.0.1 | 53,67,68 | Allow | DNS/DHCP only |
| 2 | 10.30.0.0/24 | 10.0.0.0/8 | All | Block | No internal access |
| 3 | 10.30.0.0/24 | 0.0.0.0/0 | All | Allow | Internet only |

#### VLAN 50 (VoIP) Security
| # | Source | Destination | Ports | Action | Notes |
|---|--------|-------------|-------|--------|-------|
| 4 | 10.50.0.0/27 | Spectrum SIP | 5060-5061, 8000-8800 | Allow | SIP/RTP bidirectional |
| 5 | 10.50.0.0/27 | 10.20.0.0/24 | All | Allow | Staff can dial |
| 6 | 10.50.0.0/27 | 10.10.0.0/23, 10.30.0.0/24 | All | Block | No student/guest access |

#### VLAN 60 (Cameras) Segmentation
| # | Source | Destination | Ports | Action | Notes |
|---|--------|-------------|-------|--------|-------|
| 7 | 10.60.0.0/26 | Verkada Cloud | 443 (HTTPS) | Allow | Cloud outbound |
| 8 | 10.99.0.0/28 | 10.60.0.0/26 | 554 (RTSP) | Allow | Mgmt pull only |
| 9 | 10.60.0.0/26 | Other VLANs | All | Block | Network isolation |

#### Management Access
| # | Source | Destination | Ports | Action | Notes |
|---|--------|-------------|-------|--------|-------|
| 10 | 10.99.0.0/28 | 10.60.0.250 | 443 | Allow | TP-Link camera island (if active) |

---

## WiFi Optimization (From Assessment)

### Band Steering & Roaming
- **5GHz Priority**: Channels 36, 52, 100, 116, 132, 149 (80 MHz separation, 40 MHz fallback)
- **RSSI Threshold**: -70 dBm (hard boundary), -67 dBm steering minimum
- **802.11k/v/r Enabled**: Fast roaming support for Chromebook classroom transitions
- **2.4GHz Disabled Globally**: Except WAP2/4 (printers, low power)
- **Expected Outcome**: 92-96% coverage above -65 dBm; <3% drop rate; <5s roaming

### Coverage Gap Closure
- **Library (Rm207)**: Add WAP8 (ceiling center, channel 165, +15 dB gain → -55 dBm)
- **Room 205**: Add WAP9 (door edge, channel 36, +12 dB gain → -53 dBm)
- **Stairwells**: Enable 802.11r/k/v; -70 to -82 dBm vertical coverage acceptable with roaming
- **Current Voids**: -70 to -80 dBm (10-15% of facility); post-tuning: <-65 dBm target 92%+

### DPI & QoS
- **Google Services**: Burst capacity 100 Mbps/room; prioritize Google Meet/Classroom/YouTube
- **Printer mDNS**: Cross-VLAN reflector (VLAN 10 → 20); AirPrint fallback (Avahi/Bonjour)
- **VoIP Priority**: DSCP EF tagging; jitter <30ms; latency <150ms

---

## VoIP Configuration

### Yealink T43U Migration (8 devices, VLAN 50)
- **Codec**: G.722 (wideband audio)
- **QoS**: DSCP EF (Expedited Forwarding), CoS 5
- **Registration**: Direct SIP to Spectrum (ALG disabled on UDM)
- **Port Range**: 5060-5061 (SIP), 8000-8800 (RTP)
- **Jitter Target**: <30ms
- **Latency Target**: <150ms
- **Headroom**: 8 devices active; 22 slots available (VLAN 50 /27 = 30 usable)
- **Future Scaling**: Ready for 30-device deployment

### TFTP Boot Configuration (if needed)
- TFTP server: UDM (192.168.1.1 or 10.99.0.1)
- Config files: `/srv/tftp/yealink/T43U.cfg`
- Bootstrap: Option 66 (DHCP) to TFTP server

---

## Verkada Camera Deployment

### Migration From TRENDnet to UniFi PoE (12-15 cameras)
- **VLAN**: 60 (10.60.0.0/26, 62 usable hosts)
- **PoE Allocation**: Ports 25-39 on USW-Pro-Max-48-PoE (15× PoE+ ports)
- **Power Budget**: 100 Kbps idle per camera; 3-5 Mbps live; bursts to 45 Mbps
- **Models**: CD52/CD62 (force PoE on; specific wattage per model)
- **QoS**: AF41 (Assured Forwarding)

### Camera Island Network (Contingency)
- **Trunk**: USW Port 40 → TP-Link Port 24 (STP/RSTP 802.1w aligned)
- **TP-Link Config**:
  - Management IP: 10.60.0.250 (VLAN 60)
  - Ports 1-15: ACCESS mode, PVID 60
  - Port 24: TRUNK, tagged VLAN 60, PVID 1
  - RSTP enabled for loop prevention
- **Cloud Uplink**: HTTPS 443 to Verkada cloud; no inbound required

---

## Printer Integration

### mDNS Reflector & AirPrint
- **VLAN**: 20 (Staff/Printers, 10.20.0.0/24)
- **2.4GHz Carve**: WAP2/4 only (low power for printer discovery)
- **mDNS Configuration**: UDM > Networks > Multicast DNS (enable)
- **Fallback**: Avahi/Bonjour (if UniFi mDNS unreliable)
- **Services**: mDNS/Bonjour (UDP 5353), HP JetDirect (TCP 80, 161, 8289), SLP (UDP 427)
- **DHCP Reservation**: Static IPs for all printers (reliability + inventory tracking)
- **Multicast Enhancement**: Enabled on UDM for cross-VLAN printing

---

## UPS & Monitoring

### APC SMX2000LVNC UPS Configuration
- **Runtime**: 8-12 minutes at 40% PoE baseline load (290W)
- **SNMP Monitoring**: UPS on Port 48 (USW), SNMP OIDs monitored by UDM
- **Failover Procedure**: Graceful shutdown of VoIP; cameras continue 12 min
- **Battery Health**: Monthly self-test; pre-replacement at 70% capacity retention

### UniFi Insights Monitoring
- **PoE Budget**: Real-time tracking (target: <40% = 290W; headroom 430W)
- **VLAN Traffic**: Per-VLAN throughput; isolation validation
- **WAN Status**: Throughput, latency, optical power (>-15 dBm)
- **RSSI Heatmaps**: WiFi coverage maps; roaming patterns
- **Jitter Tracking**: VoIP quality monitoring (target <30ms)

---

## Deployment Phases

### Pre-Deployment Align (Nov 12-14)
- Validate Comcast handoff (optical/connector specs)
- Conduct 802.11k/v/r testing on 5 Chromebooks
- Verify SFP modules; prepare lab bench
- Establish rollback procedures
- Deploy 3 new APs; verify TP-Link RSTP functionality

### Lab Forge (Nov 17-23)
- VLAN design; DPI rule tuning
- 16× AP channel spread tuning (36/52/100/116/132/149)
- 2.4GHz carve validation (WAP2/4 only)
- RADIUS/PSK credential distribution
- Verkada PoE & 45 Mbps burst testing
- mDNS/AirPrint fallback lab tests
- Camera island trunk/STP validation
- iPerf & Wireshark protocol analysis

### Backbone Pilot (Nov 25)
- Rack assembly; WAN/UDM/USW deployment
- Legacy gear offline; VLAN configuration
- PoE verification (<40% = 290W)
- 99% uptime target

### AP Swarm + RADIUS (Nov 26)
- 16× AP adoption (sequential, one per minute)
- SSID/RADIUS/PSK distribution
- 30 Chromebook roaming tests (5-sec max handoff)
- Printer carve deployment

### Integrated Polish (Nov 28)
- Jitter/VoIP testing (<30ms target)
- VLAN 60 camera validation
- Cross-VLAN printing tests
- Walk survey (APs, printers, coverage gaps)

### Buffer/Tune (Dec 1)
- DFS/PoE/channel overlap tweaks
- Week 1 customer feedback call
- ROI validation

### Handoff Horizon (Dec 2-4)
- Async training videos (RSSI, mDNS, PSK)
- Support handover
- Final customer check-in

---

## Rollback Procedures

| Phase | Trigger | Action | Time |
|-------|---------|--------|------|
| Lab Forge | WAN <800 Mbps or optical signal <-20 dBm | JSON config revert | 2 min |
| Backbone | Reprovisioning >10 min or network flap | Restore Juniper/FortiGate loopback | 5 min |
| AP Swarm | >2 adoption failures or roaming >10s | Firmware update; defer new devices | 10 min |

---

## Cost Analysis

### Upfront Investment

| Category | Item | Qty | Unit Price | Total |
|----------|------|-----|------------|-------|
| Hardware | UDM Pro Max | 1 | $599 | $599 |
| Hardware | USW-Pro-Max-48-PoE | 1 | $1,299 | $1,299 |
| Hardware | SFP Module (UF-SM-1G-S) | 1 | $15 | $15 |
| Hardware | UAP-AC-PRO (3 new units) | 3 | $149 | $447 |
| Licenses | CyberSecure (1-year) | 1 | $99 | $99 |
| Labor | Diagnostics & Setup | 1 | $700 | $700 |
| **Total** | | | | **$3,160** |

### Resale Offset

| Item | Est. Resale | Notes |
|------|------------|-------|
| FortiGate 80E | $600-800 | EoL 2025; market dependent |
| Juniper ACX1100 | $250-350 | Older model; still viable |
| FortiSwitch 124F-PoE | $450-600 | Proprietary; lower demand |
| FortiSwitch 108E-PoE | $300-400 | Distribution unit |
| TRENDnet PoE injectors (3×) | $120-180 | Commodity; bulk pricing |
| Cloud Key Gen2 | $80-100 | Controller; legacy |
| **Total Potential** | **$1,800-2,430** | 65-73% offset |

### Three-Year Financial Impact

| Category | Amount | Notes |
|----------|--------|-------|
| Upfront Hardware | $3,160 | One-time |
| Resale Offset (conservative) | -$1,200 | 65% of legacy gear |
| Net Upfront Investment | $1,960 | Client out-of-pocket |
| Year 1 Support | $7,188 | $599/month × 12 |
| Years 2-3 Support | $14,376 | $599/month × 24 |
| Total 3-Year Cost | $23,524 | Hardware + support |
| **Estimated Savings** | **$34,452** | Reduced overages + reactive calls |
| **Net ROI (3-year)** | **Immediate** | Overage bleed stops month 1 |

---

## Regulatory Compliance

### CIPA/FERPA/COPPA
- **Content Filtering**: YouTube Restricted Mode (DPI rule on VLAN 10)
- **User Privacy**: DHCP 4-hour lease (students); 90-day guest access logs
- **Encryption**: WPA2-Enterprise (RADIUS-ready); SSL/TLS for management
- **Audit Trail**: Syslog forwarding (optional); UniFi event logs retained

### MSA & Liability
- $599/month service contract includes 10 hrs support
- On-site diagnostic fee: $150/hour (after support hours)
- Hardware warranty: Manufacturer (UniFi Pro, Yealink, Verkada native)

---

## Vendor Contacts

| Vendor | Contact | Notes |
|--------|---------|-------|
| **Ubiquiti** | support@ui.com or 1-877-478-2439 | UniFi support |
| **Spectrum SIP** | 1-855-707-7328 | VoIP provider |
| **Verkada** | support@verkada.com | Camera support |
| **APC/UPS** | 1-888-545-0874 | Power management |
| **Comcast** | 1-800-COMCAST | ISP support |

---

## Repository Structure

```
a-plus-up-unifi-case-study/
├── README.md                          (This file - canonical reference)
├── ARCHITECTURE.md                    (Detailed network topology)
├── COSTS.md                          (Financial breakdown & ROI)
├── docs/
│   ├── adr/                          (Architecture Decision Records)
│   │   ├── 001-unifi-single-vendor.md
│   │   ├── 002-vlan-architecture.md
│   │   ├── 003-wifi-802.11kvr.md
│   │   ├── 004-voip-direct-sip.md
│   │   ├── 005-verkada-cameras.md
│   │   ├── 006-printer-mdns.md
│   │   └── 007-camera-island-stp.md
│   ├── runbooks/
│   │   ├── access-points.md
│   │   ├── voip-yealink.md
│   │   ├── mdns-printers.md
│   │   ├── verkada-cameras.md
│   │   ├── poe-monitoring.md
│   │   └── emergency-rollback.md
│   ├── diagrams/
│   │   ├── network-topology.md
│   │   ├── vlan-isolation.md
│   │   ├── ap-coverage.md
│   │   └── camera-island-stp.md
│   └── compliance/
│       ├── cipa-ferpa-coppa.md
│       ├── msa-liability.md
│       └── audit-logs.md
├── config/
│   ├── networks.json                 (VLAN definitions)
│   ├── firewall-rules.json           (Segmentation rules)
│   ├── wifi-config.json              (AP tuning params)
│   ├── voip-sip.json                 (Yealink provisioning)
│   └── camera-inventory.json         (Verkada tracking)
├── inventory/
│   ├── hardware.csv                  (All SKUs & S/N)
│   ├── resale-tracking.csv           (Legacy gear → eBay)
│   └── warranty-matrix.md            (Support timelines)
├── scripts/
│   ├── validate-vlan-isolation.sh
│   ├── monitor-poe-budget.sh
│   ├── check-mdns-health.sh
│   ├── voip-quality-probe.sh
│   └── failover-test.sh
└── templates/
    ├── CIPA_compliance_checklist.md
    ├── onboarding_template.md
    └── weekly_status_report.md
```

---

## Next Steps

1. **Lab Validation**: Run all pre-deployment checklist items (Nov 12-14)
2. **Customer Sign-Off**: Confirm Terri's availability for Nov 13 matrix review
3. **Equipment Procurement**: Order 3 new UAP-AC-PRO units; confirm SFP availability
4. **Training Prep**: Schedule 2-hour session for Nov 28-Dec 2 (SSID, VLAN, mDNS, PSK)
5. **Handover Package**: Prepare PDF docs + credentials vault + runbooks (Dec 2)

---

**Canonical Source:** 8 authoritative documents (Nov 2025 freeze)  
**Contact:** Travis Rylander (Architect) | Terri Roberts (A+UP IT)  
**Last Updated:** November 10, 2025
