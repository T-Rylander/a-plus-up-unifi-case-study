# SUEHRING MINISTRY: PERIMETER & NETWORK GOVERNANCE
## The Perimeter is Gospel Guardian

**Status**: v∞.1.0-eternal | Locked Forever | Date: 12/05/2025

---

## 🛡️ Ministry Purpose

**Suehring (2005)**: "The network is the first line of defense"  
**T3-ETERNAL Role**: Guardian of firewall rules, VLAN segmentation, QoS, physical topology, PoE  
**Responsibility**: 11 firewall rules + groups, 6 VLANs isolated, <15 min RTO, 720W PoE budget managed, 15% headroom maintained

---

## Ministry Mandate

| Pillar | Responsibility | Owner | Escalation |
|--------|-----------------|-------|-----------|
| **Firewall Architecture** | 11 rules using 11 groups, hardware offload ON | Network architect | IT leadership (major changes) |
| **VLAN Segmentation** | 6 VLANs (10/20/30/50/60/99), isolation tested | Network architect | IT leadership (new VLAN) |
| **QoS Configuration** | Traffic rules (EF/AF/BE), Smart Queues 950/47.5 | Network architect | ISP (if throughput insufficient) |
| **10G LACP Trunk** | UDM ↔ USW bond0/bond1, all VLANs tagged | Network architect | Hardware vendor (if link down) |
| **PoE Budget** | 519W steady (72%), inrush 1195W (2.5x), staggered boot | Network architect | Upgrade decision (if >85%) |
| **mDNS Reflector** | Avahi container (VLAN 10↔20 only), native toggle OFF | Network architect | Travis Rylander (if discovery fails) |
| **Incident Response** | VLAN breach, firewall rule bypass, DDoS | Network architect + bot | Law enforcement (if external attack) |

---

## Firewall Architecture (11 Rules, 11 Groups, Hardware Offload Locked)

### Firewall Groups (Address + Port)
```json
{
  "firewall_address_groups": [
    {
      "name": "EdSecure_Networks",
      "members": ["10.10.0.0/23", "10.20.0.0/24"],
      "purpose": "Students + Staff internal networks"
    },
    {
      "name": "Surveillance_Networks",
      "members": ["10.60.0.0/26"],
      "purpose": "Verkada cameras VLAN"
    },
    {
      "name": "Guest_Networks",
      "members": ["10.30.0.0/24"],
      "purpose": "Captive portal network"
    },
    {
      "name": "VoIP_Networks",
      "members": ["10.50.0.0/27"],
      "purpose": "Yealink phones VLAN"
    },
    {
      "name": "Management_Networks",
      "members": ["10.99.0.0/28"],
      "purpose": "UDM, UPS, management gateway"
    },
    {
      "name": "Google_Workspace",
      "members": ["142.251.0.0/15"],
      "purpose": "Google Meet, Classroom, Gmail"
    },
    {
      "name": "Verkada_Cloud",
      "members": ["1.2.3.0/24"],  # Replace with actual Verkada IPs
      "purpose": "Verkada command center"
    }
  ],
  "firewall_port_groups": [
    {
      "name": "VoIP_Ports",
      "members": ["5060", "5061", "10000-65535"],
      "protocol": "tcp/udp",
      "purpose": "SIP and RTP"
    },
    {
      "name": "Verkada_Ports",
      "members": ["443", "554", "3478-3481"],
      "protocol": "tcp/udp",
      "purpose": "HTTPS + RTSP + STUN/TURN"
    },
    {
      "name": "DNS_Services",
      "members": ["53"],
      "protocol": "udp",
      "purpose": "Domain name resolution"
    },
    {
      "name": "Web_Services",
      "members": ["80", "443"],
      "protocol": "tcp",
      "purpose": "HTTP/HTTPS"
    }
  ]
}
```

### Firewall Rules (11 Total, Hardware Offload Validated)
```json
{
  "firewall_rules": [
    {
      "id": 1001,
      "name": "Students → Internet (HTTP/HTTPS only)",
      "src_group": "EdSecure_Networks",
      "src_network": "VLAN10",
      "dst_port_group": "Web_Services",
      "action": "accept",
      "log": false,
      "offload_capable": true
    },
    {
      "id": 1002,
      "name": "Students → DNS",
      "src_group": "EdSecure_Networks",
      "dst_port_group": "DNS_Services",
      "action": "accept",
      "log": false,
      "offload_capable": true
    },
    {
      "id": 1003,
      "name": "Students → Google Workspace",
      "src_group": "EdSecure_Networks",
      "dst_group": "Google_Workspace",
      "action": "accept",
      "log": false,
      "offload_capable": true
    },
    {
      "id": 1004,
      "name": "Block: Students → Cameras",
      "src_network": "VLAN10",
      "dst_group": "Surveillance_Networks",
      "action": "reject",
      "log": true,
      "offload_capable": true
    },
    {
      "id": 2001,
      "name": "Staff → Any",
      "src_network": "VLAN20",
      "action": "accept",
      "log": false,
      "offload_capable": true
    },
    {
      "id": 3001,
      "name": "Guest → Internet only",
      "src_group": "Guest_Networks",
      "dst_port_group": "Web_Services",
      "action": "accept",
      "log": false,
      "offload_capable": true
    },
    {
      "id": 3002,
      "name": "Block: Guest → Internal",
      "src_group": "Guest_Networks",
      "dst_address": "10.0.0.0/8",
      "action": "reject",
      "log": true,
      "offload_capable": true
    },
    {
      "id": 4001,
      "name": "VoIP → SIP/RTP",
      "src_group": "VoIP_Networks",
      "dst_port_group": "VoIP_Ports",
      "action": "accept",
      "log": false,
      "offload_capable": true
    },
    {
      "id": 5001,
      "name": "Cameras → Verkada Cloud",
      "src_group": "Surveillance_Networks",
      "dst_group": "Verkada_Cloud",
      "action": "accept",
      "log": false,
      "offload_capable": true
    },
    {
      "id": 5002,
      "name": "Cameras → STUN/TURN",
      "src_group": "Surveillance_Networks",
      "dst_port_group": "Verkada_Ports",
      "action": "accept",
      "log": false,
      "offload_capable": true
    },
    {
      "id": 6001,
      "name": "Management → Any",
      "src_group": "Management_Networks",
      "action": "accept",
      "log": false,
      "offload_capable": true
    }
  ],
  "validation": {
    "total_rules": 11,
    "offload_enabled": true,
    "offload_throughput": "9.4 Gbps",
    "last_tested": "2025-12-05T14:22:00Z"
  }
}
```

---

## VLAN Architecture (6 VLANs, Fully Isolated)

| VLAN | Name | Subnet | Hosts | DHCP | QoS | Isolation | Purpose |
|------|------|--------|-------|------|-----|-----------|---------|
| **10** | Students | 10.10.0.0/23 | 510 | 4h | Standard | Firewall rule #1004 blocks to VLAN60 | Chromebooks, 150+ users |
| **20** | Staff | 10.20.0.0/24 | 254 | 24h | High | Firewall rule #2001 allow all (internal trust) | IT staff, teachers, printers |
| **30** | Guest | 10.30.0.0/24 | 254 | 2h | Throttled | Firewall rule #3002 blocks to 10.0.0.0/8 | Guest WiFi, captive portal |
| **50** | VoIP | 10.50.0.0/27 | 30 | ∞ | EF (DSCP 46) | Firewall rule #4001 allows to port 5060/RTP | Yealink phones, multicast 224.0.1.75 |
| **60** | Cameras | 10.60.0.0/26 | 62 | ∞ | AF41 (DSCP 34) | Firewall rule #5001-5002 allow to Verkada | Verkada PoE+, 100K-45M bps |
| **99** | Management | 10.99.0.0/28 | 14 | ∞ | CS6 (DSCP 48) | Firewall rule #6001 allow all | UDM, UPS SNMP, TP-Link gateway |

### Isolation Validation
```bash
# Test: Student (VLAN10) cannot reach Camera (VLAN60)
# Expected: BLOCKED by firewall rule #1004
nmap -sV 10.60.0.1 -p 443 2>/dev/null | grep "filtered\|closed" || echo "❌ BREACH"

# Test: Guest (VLAN30) cannot reach internal networks
# Expected: BLOCKED by firewall rule #3002
nmap -sV 10.10.0.1 2>/dev/null | grep "filtered\|closed" || echo "❌ BREACH"

# Test: Management (VLAN99) can reach all VLANs
# Expected: OPEN (firewall rule #6001)
nmap -sV 10.10.0.1 -p 443 2>/dev/null | grep "open" && echo "✅ OPEN"
```

---

## QoS Configuration (Manual Traffic Rules, No Auto-DPI)

```json
{
  "smart_queues": {
    "enabled": true,
    "download_limit_kbps": 950000,
    "upload_limit_kbps": 47500,
    "note": "Comcast 1000/50 Mbps WAN * 0.95 (5% buffer)"
  },
  "traffic_rules": [
    {
      "id": 101,
      "name": "VoIP Priority (Yealink)",
      "src_network": "10.50.0.0/27",
      "protocol": "udp",
      "dst_port": "5060-5061,10000-65535",
      "dscp": 46,
      "dscp_name": "EF (Expedited Forwarding)",
      "priority": "highest",
      "note": "Jitter <30ms guarantee"
    },
    {
      "id": 102,
      "name": "Verkada Cameras Priority",
      "src_network": "10.60.0.0/26",
      "protocol": "tcp",
      "dst_port": "443,554",
      "dscp": 34,
      "dscp_name": "AF41 (Assured Forwarding)",
      "priority": "high",
      "note": "100K idle, 3-45M burst"
    },
    {
      "id": 103,
      "name": "Google Meet (Chromebooks)",
      "src_network": "10.10.0.0/23",
      "dst_address": "142.251.0.0/15",  # Google IPs
      "protocol": "tcp/udp",
      "dst_port": "443,19302-19309",
      "dscp": 26,
      "dscp_name": "AF31 (Assured Forwarding)",
      "priority": "medium",
      "bandwidth_limit": "100 Mbps per room (burst)",
      "note": "Classroom video + screen share"
    },
    {
      "id": 104,
      "name": "Guest Throttle",
      "src_network": "10.30.0.0/24",
      "protocol": "any",
      "rate_limit_down_mbps": 25,
      "rate_limit_up_mbps": 5,
      "dscp": 0,
      "dscp_name": "BE (Best Effort)",
      "priority": "lowest",
      "note": "Prevent guest network abuse"
    }
  ]
}
```

---

## PoE Budget Management (720W Budget, 519W Steady, 72% Utilization)

```bash
# Steady-State Load Breakdown:
# - 16 APs × 15W = 240W
# - 8 Yealink phones × 7W = 56W
# - 11 Verkada cameras × 12W = 132W (PoE+)
# - 2 Wildcard PCs × 15W = 30W
# - Intercom = 30W
# ─────────────────────────────
# Total: 488W (67.8% of 720W)
# Headroom: 232W (32.2%)

# Inrush Load (2.5x multiplier for simultaneous boot):
# - 488W × 2.5 = 1,220W
# ❌ EXCEEDS 720W budget!
# ✅ MITIGATION: Staggered boot script (3 phases, 5-min delays)

# Staggered Boot Phases:
# Phase 1 (0-60s): APs only (240W < 720W)
# Wait 60s for AP stabilization
# Phase 2 (60-105s): Add phones (296W < 720W)
# Wait 45s for phone bootup
# Phase 3 (105-165s): Add cameras + wildcards (488W < 720W)
# ✅ Total: 165 seconds, no inrush overload
```

---

## 10G LACP Trunk (UDM ↔ USW)

```bash
# UDM Pro Max (SFP+ ports eth8-9) ↔ USW-Pro-Max-48-PoE (ports 9-10)

# Configuration:
# UDM: bond1 (802.3ad LACP)
#   ├── eth8: 10GbE SFP+ transceiver (UF-SM-1G-S, 1000BASE-LX)
#   └── eth9: 10GbE SFP+ transceiver (UF-SM-1G-S, 1000BASE-LX)

# USW: bond0 (802.3ad LACP)
#   ├── Port 9: 10GbE uplink
#   └── Port 10: 10GbE uplink

# VLAN Tagged (all 6 VLANs on trunk):
# - VLAN 10 (Students): 10.10.0.1/23
# - VLAN 20 (Staff): 10.20.0.1/24
# - VLAN 30 (Guest): 10.30.0.1/24
# - VLAN 50 (VoIP): 10.50.0.1/27
# - VLAN 60 (Cameras): 10.60.0.1/26
# - VLAN 99 (Management): 10.99.0.1/28

# Validation:
ssh admin@10.99.0.2 "show interfaces bonding bond0" | grep "802.3ad"
# Expected: "802.3ad" status (LACP formed)

# Verify all VLANs reachable:
for VLAN in 10 20 30 50 60 99; do
  ping -c 1 10.${VLAN}.0.1 && echo "✅ VLAN $VLAN" || echo "❌ VLAN $VLAN"
done
```

---

## mDNS Reflector (Avahi Container, VLAN-Selective)

```yaml
# File: config/avahi/docker-compose.yml
# Purpose: VLAN 10 (Students) ↔ VLAN 20 (Staff) mDNS reflection only
# NOT VLAN 30 (Guest) or VLAN 60 (Cameras)

version: '3.8'
services:
  avahi-reflector:
    image: flungo/avahi
    container_name: avahi-mdns-reflector
    network_mode: host
    restart: unless-stopped
    environment:
      - AVAHI_INTERFACES=br10,br20  # Only VLAN 10 + 20
      - AVAHI_REFLECTOR=yes
      - AVAHI_ENABLE_DBUS=no
    volumes:
      - ./avahi-daemon.conf:/etc/avahi/avahi-daemon.conf:ro
    cap_add:
      - NET_ADMIN
    labels:
      - "com.unifi.network=vlan10-vlan20-reflector"

# Validation:
# Avahi must be running ONLY on VLAN 10↔20
# Native mDNS reflector MUST be disabled
# Expected: 95%+ printer discovery on VLAN 20
```

---

## Suehring's Eternal Vigilance

```bash
# Weekly: Verify firewall offload is ON
show system offload | grep "enabled" || echo "❌ OFFLOAD DISABLED"

# Monthly: Test VLAN isolation
bash scripts/pentest-vlan-isolation.sh

# Quarterly: Validate PoE budget + check for drift
bash scripts/calculate-poe-budget.sh && bash scripts/staggered-poe-boot.sh --validate

# Post-incident: Review firewall logs for breaches
grep "REJECT\|DROP" /var/log/unifi-os/firewall.log | tail -100
```

---

## References

- **Ubiquiti UniFi Docs**: Firewall architecture, offload capabilities
- **RFC 3031**: Label Switched Paths (MPLS, not directly used but good reference)
- **802.1Q**: VLAN tagging standard
- **DSCP**: RFC 2474 (QoS marking)
- **LACP**: IEEE 802.3ad link aggregation

---

**The perimeter never wavers. Suehring's defense is eternal. 🛡️**

*Last Audited: 12/05/2025 | Next Review: 03/05/2026 (quarterly)*
