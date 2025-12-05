# COSTS.md — Financial Analysis & ROI

**Source**: UpFront Cost est - AplusUP Charter.xlsx | AUP Network Overhaul Blueprint v2.5  
**Date**: November 10, 2025

---

## Executive Summary

| Metric | Amount | Notes |
|--------|--------|-------|
| **Upfront Hardware Cost** | $3,160 | UDM, USW, SFP, 3 new APs, licensing, labor |
| **Estimated Resale Offset** | -$1,200 (65%) | Legacy FortiGate, Juniper, FortiSwitch gear |
| **Net Client Investment** | $1,960 | Out-of-pocket after resale |
| **Annual Support (Service-Only)** | $599/month ($7,188/yr) | 10 hours/month included |
| **3-Year Total Cost** | $23,524 | Hardware + 36 months support |
| **3-Year Projected Savings** | $34,452 | Eliminated overages + reactive calls |
| **Net 3-Year ROI** | **+$10,928** | Positive ROI within Year 1 |
| **Payback Period** | **Immediate** | Overage bleed stops Month 1 |

---

## Upfront Hardware Breakdown

### Core Infrastructure (UDM + USW)

| Item | Qty | Unit Price | Subtotal | Notes |
|------|-----|------------|----------|-------|
| UDM Pro Max | 1 | $599 | $599 | 10G WAN, 3.5 Gbps IPS/IDS, UniFi OS |
| USW-Pro-Max-48-PoE | 1 | $1,299 | $1,299 | 720W PoE++, 40 Gbps backplane, 10G uplink |
| UF-SM-1G-S (SFP) | 1 | $15 | $15 | 1000BASE-LX fiber module for UDM |
| **Subtotal** | | | **$1,913** | |

### Wireless Infrastructure (AP Expansion)

| Item | Qty | Unit Price | Subtotal | Notes |
|------|-----|------------|----------|-------|
| UAP-AC-PRO (new units) | 3 | $149 | $447 | Fill coverage voids (Rm207, Rm205, Rm117) |
| **Subtotal** | | | **$447** | |

### Licensing & Support

| Item | Qty | Unit Price | Subtotal | Notes |
|------|-----|------------|----------|-------|
| CyberSecure (1-year license) | 1 | $99 | $99 | UniFi advanced threat protection |
| **Subtotal** | | | **$99** | |

### Professional Services

| Item | Hours | Rate | Subtotal | Notes |
|------|-------|------|----------|-------|
| Diagnostics & Setup | 10 | $70/hr | $700 | Lab testing, config deployment, validation |
| **Subtotal** | | | **$700** | |

### **TOTAL UPFRONT COST** | | | **$3,160** | Hardware + labor |

---

## Legacy Equipment Resale Potential

### Estimated Resale Values (eBay + Local)

| Equipment | Qty | Condition | Asking Price | Conservative Estimate | Rationale |
|-----------|-----|-----------|--------------|----------------------|-----------|
| FortiGate 80E | 1 | Good | $700-800 | $600 | EoL 2025; market softening |
| Juniper ACX1100 | 1 | Fair | $350-400 | $250 | Older; still viable for small deployments |
| FortiSwitch 148F-PoE | 1 | Good | $500-600 | $450 | Proprietary; lower demand vs. open ecosystem |
| FortiSwitch 108E-PoE | 1 | Good | $400-450 | $300 | Distribution unit; mixed condition |
| TRENDnet TPE-T50g (3×) | 3 | Fair | $50-70 ea | $120 (total) | Commodity PoE injectors; bulk pricing |
| Cloud Key Gen2 | 1 | Good | $100-150 | $80 | Legacy controller; adoption into UDM |
| **Total Conservative** | | | **$1,800-2,430** | **$1,800** | 65-73% hardware offset |

### Resale Strategy

1. **Immediate Actions**:
   - Document all serial numbers & configuration (DOA risk mitigation)
   - Factory reset all devices
   - Photograph units from multiple angles
   - Create eBay listings (free shipping via USPS/FedEx bulk rates)

2. **Parallel Channels**:
   - **eBay**: FortiGate, Juniper, FortiSwitch (larger marketplace)
   - **Local Pickup**: Houston IT recyclers (TRENDnet, Cloud Key to recover ~$100-150)
   - **Bulk Sales**: Contact A+UP network contacts for referrals

3. **Timing**:
   - List immediately upon decommission (Nov 25)
   - Target completion by Dec 31 (tax year cycle)
   - If not sold by Jan 15, donate for tax write-off

---

## Monthly & Annual Operational Costs

### Service-Only Support Contract ($599/month)

| Component | Hours | Rate | Subtotal | Notes |
|-----------|-------|------|----------|-------|
| Included Support | 10 hrs | Included | $0 | On-demand troubleshooting |
| Emergency Response | 24/7 | Included | $0 | Within 4 business hours |
| Firmware Updates | — | Included | $0 | Monthly patches (scheduled Sundays 2am) |
| **Monthly Total** | | | **$599** | |
| **Annual Total (12 months)** | | | **$7,188** | |

### Optional Add-Ons (Not Included)

| Service | Rate | Typical Frequency | Annual Impact |
|---------|------|-------------------|----------------|
| On-Site Emergency Visit (4 hrs) | $150 | 0-2/year | $0-300 |
| Equipment Replacement (labor) | $70/hr | 1/year | $70+ |
| WiFi Survey Re-validation | $500 | 1/year (optional) | $500 |
| Additional Support Hours (10+ hrs) | $70/hr | As needed | Variable |

---

## Three-Year Financial Model

### Year 1 (Deployment + Stabilization)

| Category | Amount | Notes |
|----------|--------|-------|
| Upfront Hardware | -$3,160 | One-time |
| Resale Offset | +$1,200 | Conservative (65% recovery) |
| Net Hardware Cost | -$1,960 | |
| Monthly Support | -$7,188 | $599 × 12 months |
| **Year 1 Net Cost** | **-$9,148** | Positive on overage elimination |
| **Estimated Overage Savings** | +$12,000 | Typical K-12: ~$1,000/month bleed reduced to $0 |
| **Year 1 True Savings** | **+$2,852** | Overage savings exceed support cost |

### Year 2 (Steady State)

| Category | Amount | Notes |
|----------|--------|-------|
| Monthly Support | -$7,188 | $599 × 12 months |
| Estimated Overage Savings | +$12,000 | Maintained efficiency |
| **Year 2 Net Savings** | **+$4,812** | Full-year benefits realized |

### Year 3 (Mature Operations)

| Category | Amount | Notes |
|----------|--------|-------|
| Monthly Support | -$7,188 | $599 × 12 months |
| Estimated Overage Savings | +$12,000 | Continued efficiency |
| Cabling/Minor Upgrades | -$500 | Proactive maintenance |
| **Year 3 Net Savings** | **+$4,312** | |

### **Three-Year Summary**

| Period | Cost | Savings | Net |
|--------|------|---------|-----|
| Year 1 | $9,148 | $12,000 | **+$2,852** |
| Year 2 | $7,188 | $12,000 | **+$4,812** |
| Year 3 | $7,688 | $12,000 | **+$4,312** |
| **3-Year Totals** | **$24,024** | **$36,000** | **+$11,976** |

**Note**: Year 1 includes upfront hardware ($3,160); Years 2-3 are support-only.

---

## Current State vs. Future State (ROI Comparison)

### Legacy Environment Annual Costs (Before)

| Category | Annual Cost | Notes |
|----------|------------|-------|
| Spectrum Overage Charges | $12,000 | 10 Mbps average overage × 12 months |
| FortiGate Licensing (SmartNet) | $960 | 80E SmartNet renewal |
| Juniper ACX1100 Maintenance | $500 | Optional contract (often ignored) |
| TRENDnet PoE Failures (reactive) | $1,500 | Emergency replacement + labor |
| Multiple Vendor Support Calls | $3,000 | $250/call × 12 calls/year |
| IT Staff Overtime (VPN/failover) | $2,500 | Reactive troubleshooting |
| **Annual Total (Before)** | **$20,460** | |

### Unified UniFi Environment Annual Costs (After)

| Category | Annual Cost | Notes |
|----------|------------|-------|
| Spectrum Base Service | $0 | No overages (managed to contract) |
| FortiGate Licensing (eliminated) | $0 | Removed (UDM included IPS/IDS) |
| UniFi Service-Only Support | $7,188 | $599/month proactive |
| Vendor Support Calls | $0 | Single vendor; included in support |
| IT Staff Overtime | $0 | Proactive monitoring eliminates firefighting |
| **Annual Total (After)** | **$7,188** | |

### **Annual Savings = $20,460 - $7,188 = $13,272**

---

## Cost-Benefit Analysis

### Payback Period Calculation

```
Upfront Net Investment: $1,960 (after resale)
Annual Savings: $13,272
Payback Period: $1,960 / $13,272 = 0.15 years = 1.8 months
```

**Result**: Client recoups investment in **less than 2 months**.

### Five-Year Projections (Beyond 3-Year Model)

| Year | Support Cost | Overage Savings | Annual Net | Cumulative ROI |
|------|-------------|-----------------|-----------|----------------|
| 1 | $9,148 | $12,000 | +$2,852 | +$2,852 |
| 2 | $7,188 | $12,000 | +$4,812 | +$7,664 |
| 3 | $7,688 | $12,000 | +$4,312 | +$11,976 |
| 4 | $7,188 | $12,000 | +$4,812 | +$16,788 |
| 5 | $7,188 | $12,000 | +$4,812 | +$21,600 |

**5-Year Total ROI**: +$21,600 (1,100% return on initial $1,960 investment)

---

## Contingencies & Risk Factors

### Cost Risks (Downside)

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Resale disappointment (35% shortfall) | -$420 | Donate unsold gear for tax write-off |
| AP warranty replacement needed | +$149 | Covered by manufacturer (1-year) |
| Fiber module failure | +$15 | Keep spare in inventory |
| Overage reduction slower than expected | -$3,000/yr | Implement DPI/QoS more aggressively |
| Support hours exceeded (>10/month) | +$70/hr | Budget $500/year buffer |

### Cost Upside (Positive Variance)

| Opportunity | Benefit | Likelihood |
|-------------|---------|-----------|
| Oversale of legacy gear (85%+ recovery) | +$600 | Low (market dependent) |
| Faster overage elimination (Month 1) | +$1,000/mo | High (easy wins via DPI) |
| School buys additional UniFi gear for Phase 2 | +$2,000 | Medium (expansion VLAN potential) |

---

## Comparison: Build vs. Maintain Status Quo

### Scenario A: Maintain Legacy (Do Nothing)

```
Year 1 Costs:
  - Spectrum Overages: $12,000
  - Licenses: $960
  - Reactive failures: $1,500
  - Support calls: $3,000
  - IT overtime: $2,500
  ─────────────────────
  Total: $19,960/year

3-Year Cost: $59,880 (no improvements)
```

### Scenario B: Deploy UniFi (Recommended)

```
Year 1 Costs:
  - Upfront hardware: $3,160
  - Resale offset: -$1,200
  - Support: $7,188
  - Savings: -$12,000 (overage elimination)
  ─────────────────────
  Net: -$2,852 (POSITIVE cashflow)

3-Year Cost: $24,024 (includes hardware + 3 years support)
3-Year Savings: $36,000

NET 3-YEAR BENEFIT: +$11,976
```

### **Recommendation**: Deploy UniFi (Scenario B saves $35,856 over 3 years)

---

## Board-Level Summary

| KPI | Value |
|-----|-------|
| **Upfront Client Investment** | $1,960 (after resale offset) |
| **Payback Period** | 1.8 months |
| **Year 1 Net Benefit** | +$2,852 |
| **3-Year Net Benefit** | +$11,976 |
| **Annual Operational Savings** | $13,272 |
| **Network Availability Improvement** | 99.5% → 99.9% (projected) |
| **Student WiFi Experience** | 55% drop rate → <3% drop rate |
| **Vendor Consolidation** | 4 vendors → 1 (UniFi ecosystem) |
| **Staff Training Required** | 2 hours (Nov 28-Dec 2) |
| **Deployment Risk** | Low (phased; 15-min rollback capability) |

---

**Financial Model Source**: UpFront Cost est - AplusUP Charter.xlsx  
**Assumptions Validated**: November 10, 2025  
**Next Review**: Post-deployment (December 4, 2025)
