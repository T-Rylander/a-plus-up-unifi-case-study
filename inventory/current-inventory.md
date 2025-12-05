# Current Inventory — A+UP Charter School

## Pre-Migration Stack (Chaos)

| Category | Make/Model | Quantity | Status | Notes |
|----------|------------|----------|--------|-------|
| **Router/Firewall** | FortiGate 80E | 1 | EoL 2025 | $960/year licensing |
| **Backhaul Router** | Juniper ACX1100 | 1 | Enterprise overkill | 80W power draw |
| **Core Switch** | FortiSwitch 124F-PoE | 1 | Proprietary | Fabric lock-in |
| **Distribution Switch** | FortiSwitch 108E-PoE | 1 | Proprietary | Fabric lock-in |
| **PoE Injectors** | TRENDnet TPE-TG44g | 3 | Unreliable | Frequent failures |
| **Controller** | Cloud Key Gen2 | 1 | Orphaned | Classic UI only |
| **Access Points** | UAP-AC-PRO | 13 | KEEPING | Hero move |
| **Cameras** | Verkada | 12-15 | Active | TRENDnet PoE |
| **VoIP Phones** | Yealink T43U | 8-12 | Active | Spectrum SIP box |

**Pain Points:**
- 4 vendor dashboards (FortiCloud, JUNOS, TRENDnet, UniFi Classic)
- No centralized logging
- $960/year FortiGate renewal
- 140W wasted on Juniper + TRENDnet gear

---

## Post-Migration Stack (T3-ETERNAL)

| Category | Make/Model | Quantity | Status | Notes |
|----------|------------|----------|--------|-------|
| **Router/Firewall** | UDM Pro Max | 1 | ACTIVE | 3.5 Gbps IDS/IPS |
| **Core Switch** | USW-Pro-Max-48-PoE | 1 | ACTIVE | 720W PoE budget |
| **Access Points** | UAP-AC-PRO | 13 | ACTIVE | Kept from old stack |
| **Cameras** | Verkada | 15 | ACTIVE | VLAN 60, ports 26-40 |
| **VoIP Phones** | Yealink T43U | 12 | ACTIVE | VLAN 50, direct SIP |

**Wins:**
- Single vendor (UniFi)
- Single dashboard (UniFi Console)
- Zero licensing fees
- -140W power consumption
- $2,500 resale offset

---

## Client Breakdown

| Client Type | Quantity | VLAN | Notes |
|-------------|----------|------|-------|
| Chromebooks | 150+ | 10 (Default) | Student devices |
| Staff Laptops | 8-12 | 10 (Default) | Teacher + admin |
| Verkada Cameras | 15 | 60 (Cameras) | USW ports 26-40 |
| Yealink Phones | 12 | 50 (VoIP) | Direct SIP, QoS enabled |
| Printers | 2-3 | 10 (Default) | Shared resources |

**Total Concurrent Clients:** ~180 devices

---

## Resale Summary

| Item | Sold Price | Projected Price | Status |
|------|------------|-----------------|--------|
| FortiGate 80E | $630 | $600-$800 | ✅ SOLD |
| FortiSwitch 124F-PoE | $480 | $450-$600 | ✅ SOLD |
| FortiSwitch 108E-PoE | $320 | $300-$400 | ✅ SOLD |
| Juniper ACX1100 | — | $250-$350 | 🟡 PENDING |
| TRENDnet (3×) | — | $120-$180 | 🟡 LISTED |
| **TOTAL** | **$1,430** | **$1,800-$2,500** | 71% |
