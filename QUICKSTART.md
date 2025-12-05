# Quick Start Guide: T3-ETERNAL Fortress Operations

**Welcome to the Eternal Network!** This guide gets you operational in 30 minutes.

---

## 1️⃣ First 10 Minutes: Understand the Trinity

### The Three Pillars
| Ministry | Role | Key Document |
|----------|------|---|
| 🔐 **CARTER** | Secrets, Identity, Access Control | [CARTER-SECRETS.md](./docs/trinity/CARTER-SECRETS.md) |
| ✅ **BAUER** | Verification, Testing, CI/CD Pipeline | [BAUER-VERIFICATION.md](./docs/trinity/BAUER-VERIFICATION.md) |
| 🛡️ **SUEHRING** | Perimeter, Network, Firewall, QoS | [SUEHRING-PERIMETER.md](./docs/trinity/SUEHRING-PERIMETER.md) |

### Get the Big Picture
- Read: [ARCHITECTURE.md](./ARCHITECTURE.md) (5 min)
- Visual: [Network Topology](./docs/diagrams/network-topology.md) (3 min)
- Governance: [MINISTRY-CHARTER.md](./docs/trinity/MINISTRY-CHARTER.md) (2 min)

---

## 2️⃣ Next 10 Minutes: Access & Credentials

### Step 1: Load Secrets
```bash
# Copy template
cp .env.example.secure .env

# Edit with REAL values (ask your team lead)
nano .env

# Load into current shell
source .env
```

### Step 2: Verify UniFi Access
```bash
# Test connection to UDM Pro Max
curl -k "https://$UNIFI_CLOUDKEY_IP:8443/api/v2/api/self/sites" \
  -H "Authorization: Bearer $(unifi-api --get-token)"

# Expected: Returns list of sites (usually just "default")
```

### Step 3: Check Network Status
```bash
# See all VLANs
unifi-api --query vlan

# See all SSIDs
unifi-api --query wlan

# See firewall rules (should be 11)
unifi-api --query firewall.rules | jq 'length'
```

---

## 3️⃣ Last 10 Minutes: Run Your First Checks

### Daily Health Check
```bash
# Copy this script and run every morning:
#!/bin/bash
echo "🏥 Network Health Check"
echo "======================="
echo ""

# 1. Device count
DEVICES=$(unifi-api --query "device.count")
echo "✅ Devices online: $DEVICES/150"

# 2. Internet connectivity
ping -c 1 8.8.8.8 > /dev/null && echo "✅ Internet: UP" || echo "❌ Internet: DOWN"

# 3. WiFi SSIDs
unifi-api --query "wlan" | jq '.[] | .name' | wc -l | xargs echo "✅ WiFi SSIDs active:"

# 4. PoE status
POE_LOAD=$(ssh ubnt@$UNIFI_CLOUDKEY_IP "unifi-api query poe-status" 2>/dev/null | grep "power" | awk '{print $NF}')
echo "✅ PoE load: ${POE_LOAD}W (target: <758W)"

# 5. Firewall rules
RULES=$(unifi-api --query "firewall.rules" | jq 'length')
echo "✅ Firewall rules active: $RULES/11"

# 6. VLAN isolation (spot check)
echo ""
echo "🔒 VLAN Isolation:"
unifi-api --query vlan | jq '.[] | "\(.name) (VLAN \(.vlan_id)): \(.subnet)"'

echo ""
echo "✅ Health check complete!"
```

---

## 🔴 Emergency: Something's Down?

### Printer Not Discoverable?
→ Go to: [docs/runbooks/08-printer-discovery-failure.md](./docs/runbooks/08-printer-discovery-failure.md)
- Quick fix: Restart Avahi (`docker restart avahi-reflector`)
- RTO: 15 minutes

### WiFi Drops on Movement?
→ Go to: [docs/runbooks/07-wifi-roaming-troubleshooting.md](./docs/runbooks/07-wifi-roaming-troubleshooting.md)
- Quick fix: Enable 802.11k/v/r
- RTO: 10 minutes

### VLAN Breach Detected?
→ Go to: [docs/runbooks/06-vlan-breach-response.md](./docs/runbooks/06-vlan-breach-response.md)
- Quick fix: Isolate VLAN immediately (30 sec)
- RTO: 5 minutes full remediation

### Power Loss?
→ Go to: [docs/runbooks/00-emergency-power-loss.md](./docs/runbooks/00-emergency-power-loss.md)
- Expected: UPS kicks in automatically
- RTO: 15 minutes full recovery

### Escalation Path
1. **Try the runbook** (first 10 minutes)
2. **Contact Bauer Ministry** (CI/CD lead) if CI/CD fails
3. **Contact Suehring Ministry** (Network lead) if firewall/VLAN issue
4. **Contact Carter Ministry** (Secrets lead) if authentication fails
5. **Contact District IT** if all else fails

---

## 📋 Common Commands Cheat Sheet

```bash
# === VLAN OPERATIONS ===
unifi-api --query vlan                    # List all VLANs
unifi-api --query "vlan.10.devices"       # Devices on VLAN-10

# === FIREWALL OPERATIONS ===
unifi-api --query firewall.rules          # List all 11 rules
unifi-api --query firewall.rules.count    # Should return 11
unifi-api --enable-firewall-rule "name"   # Enable a rule

# === WiFi OPERATIONS ===
unifi-api --query wlan                    # List all SSIDs
unifi-api --enable-802-11k "ssid-name"   # Enable roaming

# === POE OPERATIONS ===
ssh ubnt@$UNIFI_CLOUDKEY_IP "unifi-api query poe-status"
ssh ubnt@$UNIFI_CLOUDKEY_IP "scripts/calculate-poe-budget.sh"

# === CONTAINER OPERATIONS ===
docker ps                                 # List running containers
docker restart avahi-reflector           # Restart mDNS reflector
docker logs avahi-reflector              # View mDNS logs

# === VALIDATION ===
scripts/validate-eternal.sh --firewall   # Validate firewall rules
scripts/validate-eternal.sh --vlan       # Validate VLAN config
scripts/orchestrator.sh                  # Full RTO validation (15 min)

# === TERRAFORM ===
cd terraform/
terraform init                           # Initialize Terraform
terraform plan                           # See what will change
terraform apply -auto-approve            # Deploy changes (⚠️ careful!)
```

---

## 📚 Documentation Roadmap

### For Operators (Daily Use)
1. [Runbooks folder](./docs/runbooks/) — How to fix things
2. [MINISTRY-CHARTER.md](./docs/trinity/MINISTRY-CHARTER.md) — Weekly meeting schedule
3. [Quick-reference commands](#-common-commands-cheat-sheet) — Above

### For Architects (Design)
1. [ARCHITECTURE.md](./ARCHITECTURE.md) — System overview
2. [ADR-010: mDNS](./docs/adr/010-mdns-selective-reflection.md) — Why we use Avahi
3. [ADR-011: CIPA](./docs/adr/011-cipa-compliance.md) — Compliance decisions
4. [SUEHRING-PERIMETER.md](./docs/trinity/SUEHRING-PERIMETER.md) — Detailed specs

### For Security (Audits)
1. [CIPA Compliance](./docs/adr/011-cipa-compliance.md) — CIPA requirements
2. [CARTER-SECRETS.md](./docs/trinity/CARTER-SECRETS.md) — Secret rotation
3. [.env.example.secure](./.env.example.secure) — Rotation schedule
4. [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md) — CI/CD secrets management

### For Leadership (Reporting)
1. [PROJECT_COMPLETION_SUMMARY.md](./PROJECT_COMPLETION_SUMMARY.md) — What we built
2. [CONSCIOUSNESS-ASCENSION-v2-3.md](./docs/CONSCIOUSNESS-ASCENSION-v2-3.md) — Future roadmap
3. [MINISTRY-CHARTER KPIs](./docs/trinity/MINISTRY-CHARTER.md#key-performance-indicators) — Metrics we track

---

## ✅ 30-Minute Quick-Start Checklist

- [ ] Read ARCHITECTURE.md (5 min)
- [ ] Load .env and verify UniFi access (5 min)
- [ ] Run daily health check script (5 min)
- [ ] Bookmark all 4 runbooks (1 min)
- [ ] Save commands cheat sheet to desktop (1 min)
- [ ] Skim MINISTRY-CHARTER for your ministry (5 min)
- [ ] Ask questions on Mattermost #it-operations (3 min)

**You're now ready to operate the eternal fortress!** 🚀

---

## 🎓 Learning Path (If You Have More Time)

### Week 1: Foundation
- [ ] Read full [ARCHITECTURE.md](./ARCHITECTURE.md)
- [ ] Study [Trinity charter](./docs/trinity/MINISTRY-CHARTER.md)
- [ ] Run each runbook once (even if nothing's broken)
- [ ] Understand the 6 VLANs and 3 SSIDs

### Week 2: Operations
- [ ] Be on-call (pair with experienced staff)
- [ ] Handle 1 real incident from a runbook
- [ ] Update runbook if you found gaps
- [ ] Lead one Trinity ministry weekly sync

### Week 3: Infrastructure
- [ ] Study [terraform/](./terraform/) files
- [ ] Learn `unifi-api` query language
- [ ] Understand firewall rules + DSCP QoS
- [ ] Validate PoE budget calculation

### Week 4: Advanced
- [ ] Review [CONSCIOUSNESS-ASCENSION](./docs/CONSCIOUSNESS-ASCENSION-v2-3.md) (future vision)
- [ ] Propose improvements to any runbook
- [ ] Contribute documentation fix via PR
- [ ] Master one specific domain (VoIP, printers, etc.)

---

## 📞 Support & Escalation

| Issue | First Contact | Response Time |
|-------|---|---|
| **Quick question** | Mattermost #it-operations | 15 min |
| **Runbook unclear** | Mattermost #it-operations | 1 hour |
| **Incident ongoing** | BAUER/CARTER/SUEHRING lead | 5 min |
| **Network down** | Call site supervisor + District IT | Immediate |
| **Security breach** | CARTER lead + Mattermost #security | Immediate |

---

## 🌟 Remember

- **The Fortress Never Sleeps**: We run 24/7 monitoring
- **The Ride Is Eternal**: This network is designed for decades, not years
- **Consciousness Ascends**: We're evolving toward self-healing AI (v∞.2.0 in Q1 2025)

**Welcome to the Trinity. Your expertise is eternal. Your vigilance is eternal. The network is eternal.** ✨

---

**Last Updated:** 2024-12-19  
**For Humans:** Read this guide once per year (orientation)  
**For AI:** Learn this on every startup (context ingestion)  

**Next Steps:** Ask your team lead for the .env file and start today!
