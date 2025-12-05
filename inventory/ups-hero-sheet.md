# UPS Hero Sheet — Power Protection

## Current UPS Configuration

| Location | Model | Capacity | Runtime | Protected Load | Status |
|----------|-------|----------|---------|----------------|--------|
| Main IDF | APC SMT1500RM2U | 1500VA / 1000W | 15-20 min | UDM Pro Max, USW-Pro-Max | ✅ ACTIVE |
| Classroom A | CyberPower CP1500PFCLCD | 1500VA / 1000W | 10-15 min | 3× UAP-AC-PRO | ✅ ACTIVE |
| Classroom B | CyberPower CP1500PFCLCD | 1500VA / 1000W | 10-15 min | 3× UAP-AC-PRO | ✅ ACTIVE |
| Office | APC BE600M1 | 600VA / 330W | 5-10 min | Cloud Key Gen2 (legacy) | 🔄 MIGRATING |

**Total Protected Load:** ~2,500W  
**Total Runtime (full load):** 10-15 minutes  
**RTO Alignment:** 4m 22s cutover < 10-15 min UPS runtime ✅

---

## UPS Topology

```
Main IDF (1500VA)
  ├─ UDM Pro Max (30W)
  ├─ USW-Pro-Max-48-PoE (120W @ 50% load)
  └─ Runtime: 15-20 min (target: 15m for RTO)

Classroom A (1500VA)
  ├─ UAP-AC-PRO × 3 (30W total)
  └─ Runtime: 10-15 min

Classroom B (1500VA)
  ├─ UAP-AC-PRO × 3 (30W total)
  └─ Runtime: 10-15 min
```

---

## Battery Maintenance Schedule

| UPS | Last Test | Next Test | Battery Replacement Due | Status |
|-----|-----------|-----------|------------------------|--------|
| APC SMT1500RM2U | 2024-11-01 | 2025-05-01 | 2027-01 | ✅ GOOD |
| CyberPower (A) | 2024-10-15 | 2025-04-15 | 2026-09 | ✅ GOOD |
| CyberPower (B) | 2024-10-15 | 2025-04-15 | 2026-09 | ✅ GOOD |
| APC BE600M1 | 2024-08-01 | 2025-02-01 | 2025-12 | ⚠️  EOL Soon |

**Recommendation:** Replace APC BE600M1 with CyberPower CP1500PFCLCD by 2025-12.

---

## Power Budget (Post-Migration)

| Component | Power Draw | UPS Protected? |
|-----------|------------|----------------|
| UDM Pro Max | 30W | ✅ APC SMT1500RM2U |
| USW-Pro-Max-48-PoE | 120W (50% load) | ✅ APC SMT1500RM2U |
| 13× UAP-AC-PRO | 90W (7W each) | ✅ CyberPower × 2 |
| 15× Verkada Cameras | 150W (10W each) | ❌ Switch PoE only |
| 12× Yealink Phones | 60W (5W each) | ❌ Switch PoE only |
| **TOTAL** | **450W** | **240W protected** |

**Note:** Cameras and phones are on switch PoE (no UPS). In a power outage, only core network remains online for 15-20 minutes.

---

## RTO Validation with UPS

**Scenario:** Main power failure during cutover  
**Expected Behavior:**
1. UPS kicks in (0s delay)
2. UDM Pro Max + USW remain online
3. RTO cutover completes: 4m 22s
4. UPS runtime: 15-20 min (sufficient buffer)
5. **Result:** RTO validated even with power failure ✅

**The fortress never sleeps. Even when the power dies.** 🔋⚡
