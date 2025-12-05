# Repository Index & Navigation Guide

**Project**: A+UP Charter School Network Infrastructure Rebuild (T3-ETERNAL Phase 3 - Canonical)  
**Last Updated**: November 10, 2025  
**Canonical Source**: 8 Authoritative Documents (extracted via EXTRACTED_CONTENT.txt)  
**Repository**: https://github.com/T-Rylander/a-plus-up-unifi-case-study  

---

## 📚 Quick Navigation

| Document | Purpose | Audience | Read Time |
|----------|---------|----------|-----------|
| **README.md** | Executive summary + deployment phases | Leadership + IT staff | 10 min |
| **ARCHITECTURE.md** | Detailed network topology + specs | Network admins | 15 min |
| **COSTS.md** | Financial breakdown + ROI analysis | Finance + leadership | 8 min |
| **docs/adr/*** | Architectural decisions (7 records) | Engineers + architects | 30 min (all) |
| **docs/runbooks/*** | Operational procedures (5 guides) | IT technicians | 15 min each |
| **config/networks.json** | VLAN configuration reference | Network ops | 5 min |

---

## 🎯 Document Hierarchy

### Level 1: Executive (Non-Technical Leadership)

**Start Here**: README.md
- What's the project?
- Why now? (problems solved)
- What does it cost? (COSTS.md)
- When is it done? (deployment phases)

**Then Read**: COSTS.md
- Financial justification
- 3-year ROI (+$11,976 net benefit)
- Payback period (1.8 months)

### Level 2: IT Leadership (Technical Decision-Makers)

**Start Here**: ARCHITECTURE.md
- Physical topology (20,205 sq ft facility)
- All 6 VLANs (10/20/30/50/60/99) with specs
- 16 AP deployment strategy
- PoE budget tracking (290W/720W)
- 10 firewall rules + QoS

**Then Read**: docs/adr/ (all 7 ADRs)
- Why UniFi vs. competitors?
- Why 6 VLANs (not 3 or 10)?
- Why 802.11k/v/r band steering?
- Why Yealink phones?
- Why Verkada cameras?
- Why mDNS reflector?
- Why TP-Link trunk?

### Level 3: IT Operations (Technicians)

**Start Here**: docs/runbooks/ (all 5 runbooks)
1. **01-access-points.md** - AP adoption + channel config
2. **02-voip-yealink.md** - Phone deployment + SIP setup
3. **03-mdns-printers.md** - Printer VLAN migration + discovery
4. **04-verkada-cameras.md** - Camera adoption + cloud config
5. **05-poe-monitoring.md** - Power budget tracking + load shedding

**Reference**: config/networks.json
- VLAN subnets + DHCP scopes
- Firewall rule specifications
- QoS class mappings

---

## 📋 Complete File Listing

```
a-plus-up-unifi-case-study/
├── README.md                          # Executive summary (334 lines)
├── ARCHITECTURE.md                    # Technical topology (600+ lines)
├── COSTS.md                           # Financial analysis (450+ lines)
├── docs/
│   ├── adr/                           # Architectural Decision Records (7 files)
│   │   ├── 001-unifi-single-vendor.md   # UniFi vs. alternatives analysis
│   │   ├── 002-vlan-architecture.md     # 6-VLAN design rationale
│   │   ├── 003-wifi-802.11kvr.md        # Band steering + fast roaming
│   │   ├── 004-voip-direct-sip.md       # Yealink direct SIP deployment
│   │   ├── 005-verkada-cameras.md       # Cloud camera integration
│   │   ├── 006-printer-mdns.md          # mDNS reflector + cross-VLAN printing
│   │   └── 007-camera-island-stp.md     # TP-Link trunk + STP alignment
│   └── runbooks/                      # Operational Procedures (5 files)
│       ├── 01-access-points.md          # AP deployment (checklists + troubleshooting)
│       ├── 02-voip-yealink.md           # Phone deployment (SIP config + training)
│       ├── 03-mdns-printers.md          # Printer migration (VLAN 20 + discovery)
│       ├── 04-verkada-cameras.md        # Camera deployment (cloud + monitoring)
│       └── 05-poe-monitoring.md         # Power budget (alerts + load shedding)
├── config/
│   ├── networks.json                  # VLAN configuration reference (JSON)
│   ├── firewall-rules.json            # Firewall rules template (planned)
│   ├── wifi-config.json               # AP channel + QoS mapping (planned)
│   ├── voip-sip.json                  # Yealink SIP provisioning (planned)
│   └── camera-inventory.json          # Verkada model tracking (planned)
├── inventory/                         # Hardware tracking (planned)
│   ├── hardware.csv                   # Devices + S/N + warranty
│   └── resale-tracking.csv            # Legacy gear resale status
└── .git/                              # Git history (commits + tags)
    ├── refs/tags/v1.0-canonical       # Final release tag
    └── [commit history]
```

---

## 🔧 Key Specifications (Quick Reference)

### Infrastructure Summary

| Component | Model | Qty | Specs |
|-----------|-------|-----|-------|
| **Gateway** | UDM Pro Max | 1 | 10G WAN, 3.5 Gbps IDS/IDS |
| **Switch** | USW-Pro-Max-48-PoE | 1 | 720W PoE++, 40 Gbps backplane |
| **APs** | UAP-AC-PRO | 16 | WiFi 5, dual-band (5GHz prim), 802.11k/v/r |
| **Phones** | Yealink T43U | 8 | VLAN 50, G.722, <30ms jitter |
| **Cameras** | Verkada CD52/CD62 | 11 | VLAN 60, cloud-connected, 365-day retention |
| **Printers** | Various | 40+ | VLAN 20, mDNS discovery |
| **UPS** | APC SMX2000LVNC | 1 | 8-12 min runtime, SNMP monitored |

### VLAN Architecture

| VLAN | Name | Subnet | Hosts | QoS | Use Case |
|------|------|--------|-------|-----|----------|
| 10 | Students | 10.10.0.0/23 | 510 | Standard | Chromebooks (CIPA compliance) |
| 20 | Staff | 10.20.0.0/24 | 254 | High | Workstations + 40+ printers |
| 30 | Guest | 10.30.0.0/24 | 254 | Throttled (25/10) | Public WiFi (parents, contractors) |
| 50 | VoIP | 10.50.0.0/27 | 30 | DSCP EF | Yealink phones (8 + 22 headroom) |
| 60 | Cameras | 10.60.0.0/26 | 62 | AF41 | Verkada surveillance |
| 99 | Management | 10.99.0.0/28 | 14 | CS6 | UDM, switch, UPS (locked down) |

### WiFi Channel Allocation

| Upstairs | Downstairs | Non-DFS |
|----------|-----------|---------|
| 3× Ch 36 | 2× Ch 36 | Primary: 36, 149 (no DFS) |
| 3× Ch 52 | 2× Ch 116 | Secondary: 52, 100, 116, 132 (DFS) |
| 2× Ch 100 | 2× Ch 132 | |
| 2× Ch 149 | 1× Ch 132 | Band steering: -67 dBm threshold |

### Financial Summary

| Metric | Amount | Note |
|--------|--------|------|
| **Upfront** | $3,160 | UDM, USW, APs, labor |
| **Resale Offset** | -$1,200 | Legacy FortiGate/Juniper |
| **Net Investment** | $1,960 | Out-of-pocket |
| **Annual Support** | $7,188 | $599/month (10 hrs included) |
| **Payback** | 1.8 months | Via overage elimination |
| **3-Year Savings** | $11,976 | vs. legacy maintenance |

---

## 📅 Deployment Timeline

**Total Duration**: 6 weeks (Nov 12 - Dec 23, 2025)

| Phase | Dates | Milestone | Duration |
|-------|-------|-----------|----------|
| **1 (Lab Prep)** | Nov 12-22 | Validate config + test | 10 days |
| **2 (Core Deploy)** | Nov 25-Dec 2 | APs + phones + cameras | 8 days |
| **3 (Printer Migration)** | Dec 3-10 | VLAN 20 migration | 8 days |
| **4 (Validation)** | Dec 11-18 | Test + troubleshoot | 8 days |
| **5 (Training)** | Dec 19-22 | Staff + principal | 4 days |
| **Handoff** | Dec 23 | Go-live support | 1 day |

---

## ✅ Deployment Checklist

### Pre-Deployment (Week 1)

- [ ] Procurement complete (UDM, USW, APs, phones, cameras, cabling)
- [ ] Lab environment set up (UDM controller + test APs)
- [ ] VLAN configuration tested (all 6 VLANs created + DHCP working)
- [ ] Firewall rules validated (10 rules, no gaps)
- [ ] WiFi coverage pre-survey complete (baseline measured)
- [ ] VoIP SIP credentials from Spectrum obtained
- [ ] Verkada cloud account created + organization configured
- [ ] Staff trained on basic procedures (APs, phones, cameras)

### Deployment Phase (Weeks 2-3)

- [ ] APs adopted and channels assigned (16 units, 6-channel spread)
- [ ] Band steering verified (802.11k/v/r working, <5 sec roaming)
- [ ] Yealink phones deployed (8 units, SIP registered, jitter <30ms)
- [ ] Printers migrated to VLAN 20 (40+ units, mDNS discovery working)
- [ ] Cameras adopted to VLAN 60 (11 units, cloud recording started)
- [ ] PoE monitoring active (power draw <720W)
- [ ] WiFi post-survey complete (coverage improved +6 dBm)

### Validation Phase (Weeks 4-5)

- [ ] Coverage targets met (96% above -65 dBm)
- [ ] Call quality validated (jitter <30ms under load)
- [ ] Printer discovery tested (40+ printers visible from Chromebooks)
- [ ] Camera recording verified (24-hour continuous, no gaps)
- [ ] Rollback procedures tested (RTO <15 min for each failure scenario)
- [ ] Staff feedback collected + issues resolved
- [ ] Documentation complete (runbooks, configs, inventory)

### Go-Live (Week 6)

- [ ] All systems operational (green status on dashboards)
- [ ] On-call rotation established (24/7 support first 2 weeks)
- [ ] Escalation procedures documented
- [ ] Monthly monitoring routine activated
- [ ] Handoff to school IT completed
- [ ] Repository tagged v1.0-canonical (release published)

---

## 🚨 Incident Response

### Priority 1 (Critical - <15 min RTO)

| Incident | Symptom | Resolution |
|----------|---------|-----------|
| **WAN Down** | No internet | Failover to 4G (if available), restore in 2 min |
| **Switch Down** | All network offline | Restart USW (power cycle), 5 min recovery |
| **UDM Down** | Controller offline | Restart UDM (APs continue operating), 10 min recovery |

### Priority 2 (High - <1 hour RTO)

| Incident | Symptom | Resolution |
|----------|---------|-----------|
| **All APs Down** | WiFi completely offline | Check UDM controller, restart if needed |
| **VLAN Down** | Specific VLAN unreachable | Check firewall rule + UDM VLAN config |
| **VoIP Down** | Phones offline | Check VLAN 50 DHCP + SIP server connectivity |

### Priority 3 (Medium - <4 hour RTO)

| Incident | Symptom | Resolution |
|----------|---------|-----------|
| **Single AP Down** | WiFi gap in one area | Replace AP, re-adopt to cluster |
| **Printer Offline** | Specific printer unreachable | Power cycle + check VLAN 20 connectivity |
| **Camera Offline** | Single camera no video | Power cycle (PoE unplug 30s), re-adopt if needed |

---

## 📞 Escalation Contacts

| Role | Name | Email | Phone | Availability |
|------|------|-------|-------|---------------|
| **Network Architect** | Travis Rylander | travis@... | [phone] | 24/7 (emergencies) |
| **IT Lead** | [TBD] | itlead@... | [phone] | Business hours + on-call |
| **Principal (Approver)** | [TBD] | principal@... | [phone] | Business hours |
| **Vendor Support** | Ubiquiti | support@ubiquiti.com | 1-888-UBIQUITI | 24/7 |
| **Vendor Support** | Spectrum VoIP | [phone] | 1-855-707-7328 | 24/7 |
| **Vendor Support** | Verkada | support@verkada.com | 1-855-VERKADA | 24/7 |

---

## 🔐 Security & Compliance

### Network Segmentation (Compliance Mapped)

| Regulation | VLAN | Requirement | How Achieved |
|-----------|------|-------------|---------------|
| **CIPA** | 10 | Content filtering + monitoring | DPI on student VLAN only |
| **FERPA** | 20 | Sensitive data isolation | Staff VLAN segregated, encrypted |
| **COPPA** | 10 | Parental consent tracking | Student VLAN firewall prevents unauthorized uploads |
| **MSA** | 99 | Infrastructure auditing | Management VLAN logs all UDM/USW changes |

### Firewall Rules (Segmentation-Focused)

- ✅ **10 rules total** (simple, maintainable)
- ✅ **Block-by-default** (explicitly allow only needed traffic)
- ✅ **Least privilege** (each VLAN has minimal permissions)
- ✅ **Hardware offload safe** (USW can accelerate with simple rules)

---

## 📖 How to Use This Repository

### 1. **Planning Phase** (Week 1)
- Read: README.md → COSTS.md → ARCHITECTURE.md
- Understand: Project scope, budget, timeline
- Approve: Leadership sign-off on ROI + deployment plan

### 2. **Design Review** (Week 1-2)
- Read: All 7 ADRs (docs/adr/)
- Understand: Why each decision was made
- Approve: Architecture design + vendor selection

### 3. **Deployment Prep** (Week 2)
- Read: All 5 runbooks (docs/runbooks/)
- Prepare: Checklists, lab environment, staff training
- Practice: Run through procedures in lab

### 4. **Go-Live** (Weeks 3-5)
- Execute: Follow runbooks step-by-step
- Monitor: Check dashboards, respond to alerts
- Document: Record actual timings + issues

### 5. **Ongoing Operations** (After Go-Live)
- Reference: config/networks.json for VLAN specs
- Monitor: 05-poe-monitoring.md for power tracking
- Escalate: Use runbook troubleshooting sections

---

## 📝 Contributing & Updates

### For Future Phases (Phase 2+)

1. **Major Changes**: Create new ADR (008, 009, etc.)
2. **Bug Fixes**: Update runbook version + date
3. **New Devices**: Add to config/hardware.csv
4. **Lessons Learned**: Document in docs/
5. **Commit Message Format**: `[adr|docs|config|ops] category: brief description`

### Versioning

- **v1.0-canonical** (Current): Initial deployment (Nov 2025)
- **v1.1** (TBD): Phase 2 expansion + additional cameras
- **v2.0** (TBD): Major upgrade (new generation hardware)

---

## 🎓 Learning Resources

### Key Concepts

- **802.11k/v/r**: WiFi fast roaming (5-sec handoff)
- **RSSI Steering**: Automatic AP selection based on signal strength
- **DSCP EF**: Voice priority (expedited forwarding)
- **PoE++**: High-power over Ethernet (90-120W per port)
- **mDNS Reflector**: Cross-VLAN service discovery
- **STP**: Spanning Tree (prevent bridge loops)

### External Documentation

- UniFi OS: https://docs.ubiquiti.com/
- Yealink SIP: https://support.yealink.com/
- Verkada: https://docs.verkada.com/
- Spectrum Business: https://business.spectrum.com/support

---

## ✨ Credits

**Original Architecture**: AUP Network Overhaul Blueprint v2.5 (Nov 2025)  
**WiFi Optimization**: Comprehensive WiFi Assessment Summary V2.1 (Oct-Nov 2025)  
**Financial Analysis**: UpFront Cost est - AplusUP Charter.xlsx  
**Repository Structure**: T3-ETERNAL Phase 3 Canonical Rebuild (Nov 2025)  

**Prepared By**: Travis Rylander (Network Architect)  
**Reviewed By**: [TBD]  
**Approved By**: [TBD]  

---

**Last Updated**: November 10, 2025  
**Next Review**: December 4, 2025 (post-deployment validation)  
**Repository**: https://github.com/T-Rylander/a-plus-up-unifi-case-study  
**Status**: 🟢 READY FOR DEPLOYMENT  
