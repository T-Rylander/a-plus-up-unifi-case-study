# ADR-001: Why We Kept All 13 UAP-AC-PRO (Cost vs Coverage Math)

**Date:** 2024-11-10  
**Status:** ✅ ACCEPTED  
**Deciders:** Network Architect, School Administration  
**Replaces:** N/A

---

## Context

During the T3-ETERNAL migration from the multi-vendor Frankenstein stack to pure UniFi, we faced a critical decision: **Replace the 13× UAP-AC-PRO with newer Wi-Fi 6E models (U6-Enterprise), or keep them?**

### The Calculation

| Option | Cost | Coverage | Downtime | Risk |
|--------|------|----------|----------|------|
| **Replace with 13× U6-Enterprise** | $3,510 (13 × $270) | 100% (same) | 2-3 days | High (new AP config) |
| **Keep 13× UAP-AC-PRO** | $0 | 100% (proven) | 0 days | Zero (already deployed) |

**Math:**
- U6-Enterprise: $270/unit × 13 = **$3,510**
- UAP-AC-PRO: **$0** (already owned, working perfectly)

---

## Decision

**We kept all 13× UAP-AC-PRO.**

### Rationale

#### 1. Coverage Already Perfect
The 13 UAP-AC-PRO units provide 100% coverage for:
- 150+ Chromebook students
- 8-12 staff devices
- Entire campus (classrooms, offices, common areas)

**Heatmap analysis (conducted 2024-10-15):**
- Signal strength: -50 to -65 dBm in all instructional areas
- Zero dead zones
- Zero student/staff complaints

**Conclusion:** If coverage is already perfect, replacing APs is pure waste.

#### 2. Chromebooks Don't Need Wi-Fi 6E
**Student device profile:**
- 150+ Chromebooks (Dell 3100, HP 11 G9 EE)
- **All support:** 802.11ac (Wi-Fi 5)
- **None support:** 802.11ax (Wi-Fi 6) or 802.11be (Wi-Fi 7)

**Traffic profile:**
- Google Classroom: 1-2 Mbps per student
- YouTube EDU: 3-5 Mbps per student
- Google Docs: <1 Mbps per student
- **Peak load:** ~50 Mbps total (well within UAP-AC-PRO capacity)

**Math:**
- 150 students × 5 Mbps = 750 Mbps theoretical max
- Actual concurrent usage: ~50-100 Mbps (Chromebooks idle 80% of the time)
- UAP-AC-PRO capacity: 1.3 Gbps (5 GHz) → **13× overkill**

**Conclusion:** Wi-Fi 6E is a solution looking for a problem here.

#### 3. $3,510 Better Spent Elsewhere
**Alternative uses for $3,510:**
- Additional Chromebooks: 10 units @ $350/each
- Backup USW-Enterprise-8-PoE: $379
- 3-year UniFi CyberSecure license: $199
- Emergency fund for future UPS battery replacement
- **Or:** Simply save it (net migration cost: $0 after resale)

**Conclusion:** Wi-Fi 6E is a luxury, not a necessity.

#### 4. Zero-Downtime Migration
Replacing 13 APs = 2-3 days of:
- Taking down old APs
- Mounting new APs
- Re-configuring RF profiles
- Re-testing coverage
- Explaining to teachers why Wi-Fi is flaky

**With UAP-AC-PRO kept:**
- Downtime: **0 seconds**
- Risk: **0%**
- Teacher complaints: **0**

**Conclusion:** The best cutover is the one that doesn't happen.

---

## Consequences

### Positive
✅ **$3,510 saved** (net migration cost: $0 after resale)  
✅ **Zero downtime** during AP migration  
✅ **Proven coverage** maintained  
✅ **RF profile unchanged** (no new tuning needed)  
✅ **Teacher confidence** (no disruption)

### Negative
❌ **No Wi-Fi 6E** (but no devices need it)  
❌ **No 6 GHz spectrum** (but 5 GHz is uncongested)  
❌ **No "shiny new" marketing** (but this is a classroom, not a showroom)

### Mitigation
- **Future-proofing:** Document upgrade path to U6-Enterprise in ADR-009
- **Monitoring:** Enable RF scanning on all 13 APs to detect interference
- **Budget:** Reserve $3,500 in 2026-2027 budget for U6-Enterprise upgrade IF needed

---

## Upgrade Path (2026-2027)

**Condition:** Upgrade to U6-Enterprise if any of these occur:
1. Student Chromebooks refresh to Wi-Fi 6E models
2. 5 GHz spectrum becomes congested (DFS channels exhausted)
3. School adds VR/AR learning apps requiring >100 Mbps per device
4. UAP-AC-PRO hardware failures exceed 20% (3+ units)

**Until then:** Keep the 13× UAP-AC-PRO. They're eternal heroes.

---

## Lessons Learned

> **"The best technology is the one that already works."**  
> — Every network architect who's survived a failed upgrade

1. **Coverage math beats marketing hype**  
   - UAP-AC-PRO: 1.3 Gbps capacity  
   - Actual usage: 50 Mbps  
   - Utilization: **3.8%**  
   - Conclusion: We have 26× more capacity than needed

2. **Chromebooks don't care about Wi-Fi 6E**  
   - If clients don't support it, you're just heating the ceiling

3. **Zero downtime > shiny new gear**  
   - Teachers trust what works

4. **$0 spent is $0 saved**  
   - Every dollar not spent on Wi-Fi 6E = one more Chromebook for a student

---

## References

- UniFi AP Comparison: [ui.com/wi-fi](https://ui.com/wi-fi)
- UAP-AC-PRO datasheet: 1.3 Gbps (5 GHz), 450 Mbps (2.4 GHz)
- Chromebook specs: Dell 3100 (802.11ac), HP 11 G9 EE (802.11ac)
- Heatmap survey: 2024-10-15 (Ekahau Site Survey)

---

## Final Verdict

**The 13× UAP-AC-PRO stay.**

They've served this school faithfully. They'll keep serving until the Chromebooks demand better.

**The fortress is a classroom. The ride is eternal.** 🏍️🔥

---

**Signed:**  
Network Architect, A+UP Charter School  
Carter (2003): "Identity is programmable infrastructure."  
Bauer (2005): "Trust nothing, verify everything."  
Suehring (2005): "The network is the first line of defense."
