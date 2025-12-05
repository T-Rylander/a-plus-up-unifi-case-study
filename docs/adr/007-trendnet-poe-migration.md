# ADR-007: TRENDnet PoE → USW PoE Migration Playbook

**Date:** 2024-11-18  
**Status:** ✅ COMPLETE  
**Deciders:** Network Architect  
**Related:** Phase 3 (Verkada Camera Island)

---

## Context

The pre-migration stack relied on **3× TRENDnet TPE-TG44g** gigabit PoE injectors to power 12-15 Verkada cameras. These injectors were:
- ❌ Unreliable (frequent power cycling needed)
- ❌ Inefficient (60W total draw for 40W actual PoE delivery)
- ❌ Cable-spaghetti nightmare (each injector = 2 cables per camera)
- ❌ No centralized management (no SNMP, no logging)

**Problem:** How do we migrate 15 Verkada cameras from TRENDnet PoE → USW-Pro-Max-48-PoE **without** camera downtime during school hours?

---

## Decision

**Phased migration over 3 nights (Week 3):**

### Night 1 (Monday): Cameras 1-5
- **Time:** 9:00 PM – 11:00 PM (post-cleanup)
- **Plan:**
  1. Pre-configure USW ports 26-30 (VLAN 60, PoE+ enabled)
  2. Move Camera 1 from TRENDnet → USW port 26
  3. Verify Verkada cloud registration (cameras.verkada.com)
  4. Repeat for Cameras 2-5
  5. Leave TRENDnet injector 1 powered on (backup)

### Night 2 (Tuesday): Cameras 6-10
- **Time:** 9:00 PM – 11:00 PM
- **Plan:**
  1. Pre-configure USW ports 31-35
  2. Migrate Cameras 6-10
  3. Power off TRENDnet injector 1 (no longer needed)

### Night 3 (Wednesday): Cameras 11-15
- **Time:** 9:00 PM – 11:00 PM
- **Plan:**
  1. Pre-configure USW ports 36-40
  2. Migrate Cameras 11-15
  3. Power off TRENDnet injectors 2 & 3
  4. Factory reset all 3 TRENDnet units for resale

---

## Port Assignment (USW-Pro-Max-48-PoE)

| USW Port | Camera Location | VLAN | PoE Type | Status |
|----------|----------------|------|----------|--------|
| 26 | Front Entrance | 60 | PoE+ (30W) | ✅ ACTIVE |
| 27 | Main Hallway | 60 | PoE+ (30W) | ✅ ACTIVE |
| 28 | Classroom A | 60 | PoE+ (30W) | ✅ ACTIVE |
| 29 | Classroom B | 60 | PoE+ (30W) | ✅ ACTIVE |
| 30 | Cafeteria | 60 | PoE+ (30W) | ✅ ACTIVE |
| 31 | Playground | 60 | PoE+ (30W) | ✅ ACTIVE |
| 32 | Office | 60 | PoE+ (30W) | ✅ ACTIVE |
| 33 | Gym | 60 | PoE+ (30W) | ✅ ACTIVE |
| 34 | Library | 60 | PoE+ (30W) | ✅ ACTIVE |
| 35 | Back Entrance | 60 | PoE+ (30W) | ✅ ACTIVE |
| 36 | Parking Lot | 60 | PoE+ (30W) | ✅ ACTIVE |
| 37 | Storage Room | 60 | PoE+ (30W) | ✅ ACTIVE |
| 38 | Server Room | 60 | PoE+ (30W) | ✅ ACTIVE |
| 39 | Roof Access | 60 | PoE+ (30W) | ✅ ACTIVE |
| 40 | Emergency Exit | 60 | PoE+ (30W) | ✅ ACTIVE |

**Total PoE Load:** 15 cameras × 10W = 150W (out of 720W budget = **20.8% utilization**)

---

## VLAN 60 Configuration

```json
{
  "name": "Cameras",
  "vlan_id": 60,
  "purpose": "Security cameras (Verkada)",
  "network": "10.60.0.0/24",
  "gateway": "10.60.0.1",
  "dhcp_range": "10.60.0.10 - 10.60.0.254",
  "firewall_rules": [
    {
      "action": "ALLOW",
      "protocol": "TCP",
      "destination": "cameras.verkada.com",
      "port": 443,
      "description": "Verkada cloud access"
    },
    {
      "action": "BLOCK",
      "protocol": "ALL",
      "destination": "10.0.0.0/8",
      "description": "Isolate cameras from internal network"
    }
  ]
}
```

**Security principle:** Cameras talk to Verkada cloud **only**. No LAN access.

---

## Pre-Migration Checklist

### Hardware
- ✅ USW-Pro-Max-48-PoE installed and adopted
- ✅ 720W PoE budget verified (sufficient for 15 cameras + 12 phones + margin)
- ✅ Ports 26-40 cabled to camera locations
- ✅ TRENDnet injectors accessible for power-off

### Software
- ✅ VLAN 60 created on UDM Pro Max
- ✅ DHCP pool configured (10.60.0.10 - 10.60.0.254)
- ✅ Firewall rule: Cameras → cameras.verkada.com (HTTPS only)
- ✅ Port profile "Camera-VLAN60" created (PoE+, no loop detection)

### Testing
- ✅ Plug laptop into port 26, set manual IP 10.60.0.100
- ✅ Ping 10.60.0.1 (gateway) → SUCCESS
- ✅ Verify Verkada cloud access: `curl https://cameras.verkada.com` → 200 OK

---

## Migration Procedure (Per Camera)

### Step 1: Pre-Stage USW Port
```bash
# Via UniFi console
Port: 26-40
Profile: Camera-VLAN60
PoE: PoE+ (30W)
Native VLAN: 60
```

### Step 2: Identify Camera
- Note camera serial number (e.g., CD21-XYZ123)
- Log into Verkada dashboard: [https://www.verkada.com](https://www.verkada.com)
- Verify camera is online (TRENDnet PoE)

### Step 3: Hot-Swap Cable
1. Unplug Ethernet from TRENDnet injector output
2. Immediately plug into USW port (e.g., port 26)
3. Camera POE LED should light within 5 seconds

### Step 4: Verify Registration
- Camera should appear online in Verkada dashboard within 30 seconds
- Check IP: should be in 10.60.0.x range
- Test live view: playback should work

### Step 5: Document
```bash
echo "Camera CD21-XYZ123 migrated to USW port 26" >> migration-log.txt
```

### Step 6: Repeat
- Move to next camera
- DO NOT power off TRENDnet injector until all cameras on that injector are migrated

---

## Post-Migration Validation

### Immediate (Same Night)
```bash
# Check all cameras online
ssh admin@192.168.1.1
show clients vlan 60
# Should see 15 clients (all cameras)
```

### 24-Hour Soak Test
- Monitor Verkada dashboard for disconnects
- Check USW port stats for errors/drops
- Verify PoE power draw: 150W (15 cameras × 10W)

### 7-Day Validation
- Zero camera disconnects → SUCCESS
- Zero PoE power cycling → SUCCESS
- Zero Verkada alerts → SUCCESS

---

## Rollback Plan (If Needed)

**Scenario:** Camera fails to connect to Verkada cloud after migration

**Rollback:**
1. Unplug camera from USW port
2. Reconnect to TRENDnet injector (keep it powered during migration week)
3. Investigate: wrong VLAN? Firewall blocking Verkada cloud?
4. Fix issue on USW
5. Retry migration

**Time to rollback:** <2 minutes per camera

---

## Consequences

### Positive
✅ **60W power saved** (TRENDnet waste eliminated)  
✅ **$160 resale value** (3× TRENDnet TPE-TG44g listed on eBay)  
✅ **Zero camera downtime** during school hours  
✅ **Centralized management** (UniFi console shows PoE draw per port)  
✅ **Cable cleanup** (1 cable per camera instead of 2)

### Negative
❌ **3 nights of after-hours work** (but worth it)  
❌ **Verkada cameras still not UniFi Protect** (future ADR-011)

---

## TRENDnet Resale Strategy

### Factory Reset Procedure
```bash
# For each TPE-TG44g:
1. Hold reset button 10 seconds
2. Verify all LEDs flash (reset confirmed)
3. Power cycle
4. Test: plug in laptop, verify PoE delivery
```

### eBay Listing
- **Title:** "TRENDnet TPE-TG44g Gigabit PoE+ Injector (Set of 3)"
- **Condition:** Good (light scuffs, fully functional)
- **Price:** $60 each / $160 for all 3
- **Shipping:** USPS Priority Mail ($15)
- **Photos:** Clean, show all ports, power adapter included

**Expected Sale Time:** 2-3 weeks  
**Realized Value:** $140–$180

---

## Lessons Learned

1. **Phased migration = zero downtime**  
   - Never migrate all cameras at once (Murphy's Law)

2. **Keep backup power during migration**  
   - TRENDnet injectors stayed on until all cameras verified

3. **VLAN isolation is mandatory**  
   - Cameras should NEVER access LAN (Bauer 2005: "Trust nothing")

4. **PoE budget math matters**  
   - 15 cameras × 10W = 150W (21% of 720W budget → safe)

5. **Centralized logging is a game-changer**  
   - UniFi console shows PoE draw per port → instant troubleshooting

---

## References

- TRENDnet TPE-TG44g datasheet: [trendnet.com](https://www.trendnet.com)
- USW-Pro-Max-48-PoE specs: 720W PoE budget, PoE++ (90W per port)
- Verkada cloud requirements: HTTPS (443) to cameras.verkada.com

---

## Final Verdict

**TRENDnet injectors eliminated. Verkada cameras liberated.**

The migration took 3 nights, zero school hours, and resulted in:
- $160 resale value
- 60W power savings
- 100% camera uptime

**The fortress is a classroom. The ride is eternal.** 🏍️🔥

---

**Signed:**  
Network Architect, A+UP Charter School  
Bauer (2005): "Trust nothing, verify everything."  
Suehring (2005): "The network is the first line of defense."
