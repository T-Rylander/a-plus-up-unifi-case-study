# Changelog

All notable changes to the A+UP Charter School T3-ETERNAL migration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2024-12-05 - T3-ETERNAL ACHIEVED

### 🎉 MISSION COMPLETE

The fortress is a classroom. The ride is eternal.

---

## [0.5.0] - 2024-11-25 - Phase 5: T3-ETERNAL Validation

### Added
- Daily `validate-eternal.sh` health checks
- GitHub Actions workflow for nightly validation
- Resale tracker automation
- Security scanning (Trivy)
- ShellCheck linting for all scripts

### Changed
- RTO validated: **4m 22s** (vs 15m target — 3.4× better)
- Resale tracker: **$1,430 realized** (71% of $2,000 target)

### Status
- ✅ All systems operational
- 🟢 T3-ETERNAL: GREEN

---

## [0.4.0] - 2024-11-22 - Phase 4: Yealink VoIP Liberation

### Added
- 12× Yealink T43U phones migrated to direct SIP
- VLAN 50 (VoIP) configured with QoS (DSCP EF, CoS 5)
- SIP trunk: `sip.spectrum.net:5060`
- Call quality validation: MOS 4.3/5.0, latency <8ms

### Removed
- Spectrum SIP box (eliminated)

### Changed
- All phones now on USW-Pro-Max ports 41-46
- Centralized management via UniFi console

---

## [0.3.0] - 2024-11-18 - Phase 3: Verkada Camera Island

### Added
- 15× Verkada cameras migrated to USW-Pro-Max ports 26-40
- VLAN 60 (Cameras) configured
- Firewall rule: Cameras → `cameras.verkada.com:443` (HTTPS only)
- ADR-007: TRENDnet PoE Migration Playbook

### Removed
- 3× TRENDnet TPE-TG44g PoE injectors (factory reset for resale)

### Changed
- Power savings: **-60W** (TRENDnet waste eliminated)
- Resale value: **+$160** (TRENDnet units listed on eBay)

---

## [0.2.0] - 2024-11-15 - Phase 2: Wireless Tuning

### Added
- All 13× UAP-AC-PRO adopted into UDM controller
- High-density radio settings applied (minRSSI -75 dBm)
- RF optimization: 2.4 GHz (channels 1, 6, 11), 5 GHz (DFS enabled)
- ADR-001: Why We Kept All 13 UAP-AC-PRO

### Changed
- Zero new AP purchases (hero move: $3,510 saved)
- Coverage validated: -50 to -65 dBm (excellent)

---

## [0.1.0] - 2024-11-10 - Phase 1: Core Swap (Day 1 Cutover)

### Added
- UDM Pro Max installed (192.168.1.1)
- USW-Pro-Max-48-PoE installed (720W PoE budget)
- CyberSecure license activated on UDM
- Cloud Key Gen2 adopted into UDM (failover controller)

### Removed
- FortiGate 80E decommissioned → **$630 resale** ✅
- FortiSwitch 124F-PoE decommissioned → **$480 resale** ✅
- FortiSwitch 108E-PoE decommissioned → **$320 resale** ✅
- Juniper ACX1100 powered off → **$250 pending resale** 🟡

### Changed
- RTO achieved: **4m 22s** (target: 15m) — 🏆 CRUSHED IT
- Power savings: **-140W** (Juniper + TRENDnet eliminated)
- Licensing savings: **$960/year** (FortiGate renewal eliminated)

---

## [0.0.1] - 2024-11-01 - Phase 0: Decommission Prep

### Added
- Resale value calculated: **$1,800–$2,500**
- Factory reset procedures for all legacy gear
- Backup configurations exported (FortiGate, Juniper)
- ADR-008: $2,500 Resale Offset Strategy

### Changed
- TRENDnet switches listed on eBay
- Juniper ACX1100 config archived

---

## Pre-T3-ETERNAL (Before 2024-11-01)

### The Chaos Era

**Stack:**
- FortiGate 80E (EoL 2025, $960/year licensing)
- Juniper ACX1100 (enterprise overkill, 80W power draw)
- FortiSwitch 124F-PoE + 108E-PoE (proprietary fabric)
- 3× TRENDnet TPE-TG44g PoE injectors (unreliable)
- Cloud Key Gen2 (orphaned UniFi Classic controller)
- 13× UAP-AC-PRO (only good part)

**Pain Points:**
- 4 vendor dashboards (FortiCloud, JUNOS, TRENDnet, UniFi Classic)
- No centralized logging
- $200/month hidden costs (licensing + power waste)
- Frequent TRENDnet PoE failures
- Zero disaster recovery plan

**Status:** ❌ UNACCEPTABLE

---

## Key Metrics Summary

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| **Vendors** | 4 | 1 | -75% |
| **Dashboards** | 4 | 1 | -75% |
| **Licensing Fees** | $960/year | $0/year | -100% |
| **Power Draw** | 590W | 450W | -140W (-24%) |
| **RTO** | Unknown | 4m 22s | ✅ Validated |
| **AP Count** | 13 | 13 | 0 (kept) |
| **Net Cost** | — | $0-$100 | Resale offset |

---

## Lessons Learned

1. **Single vendor = single pane of glass** (Carter 2003)
2. **Coverage math beats marketing hype** (Wi-Fi 6E not needed)
3. **Resale offset works** ($1,430 realized so far)
4. **RTO validation matters** (4m 22s vs 15m target)
5. **Power waste is real** (140W eliminated = $150/year saved)

---

## Future Roadmap

### Phase 6: UniFi Protect Migration (2025 Q2)
- Add 4TB HDD to UDM Pro Max
- Migrate Verkada cameras to UniFi G4 series
- Eliminate Verkada licensing ($1,200/year saved)

### Phase 7: Wi-Fi 6E Upgrade (2026-2027)
- Replace 13× UAP-AC-PRO with 13× U6-Enterprise
- Requires student Chromebook refresh to Wi-Fi 6E models
- Estimated cost: $3,510

### Phase 8: Cellular Failover (2025 Q3)
- Add LTE backup module to UDM Pro Max
- Auto-failover if Spectrum WAN fails
- Estimated cost: $299 (module) + $30/month (data plan)

---

## Contributors

**Network Architect:** Travis Rylander  
**School Administration:** A+UP Charter School, Houston, TX  
**The Trinity:** Carter (2003), Bauer (2005), Suehring (2005)

---

## References

- GitHub Repository: [a-plus-up-unifi-case-study](https://github.com/T-Rylander/a-plus-up-unifi-case-study)
- Parent Project: [rylan-unifi-case-study](https://github.com/T-Rylander/rylan-unifi-case-study)
- UniFi Documentation: [ui.com](https://ui.com)

---

**The fortress is a classroom. The ride is eternal.** 🏍️🔥
