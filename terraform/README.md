# Terraform Configuration (Stub)

This directory is reserved for future Infrastructure-as-Code (IaC) implementation.

## Planned Features

### Phase 8: Terraform Integration (2025 Q4)
- Automate UDM Pro Max configuration
- Version-control all network policies
- Enable GitOps workflow (commit → apply)

### Example Structure
```
terraform/
├── main.tf               # Core resources
├── variables.tf          # Input variables
├── outputs.tf            # Outputs (IPs, hostnames)
├── terraform.tfvars      # Secrets (gitignored)
├── modules/
│   ├── unifi/            # UniFi provider module
│   ├── vlans/            # VLAN management
│   └── firewall/         # Firewall rules
└── README.md             # This file
```

## Why Terraform?

### Current State (Manual)
- ❌ Click-ops in UniFi console
- ❌ No version control for network changes
- ❌ Manual backup/restore
- ❌ No audit trail for policy changes

### Future State (Terraform)
- ✅ `git diff` shows all network changes
- ✅ `terraform plan` previews changes before apply
- ✅ `terraform apply` enforces desired state
- ✅ Pull requests for network policy review (Bauer 2005: "Trust nothing, verify everything")

## UniFi Terraform Provider

**Community Provider:**
- GitHub: [paultyng/terraform-provider-unifi](https://github.com/paultyng/terraform-provider-unifi)
- Documentation: [registry.terraform.io/providers/paultyng/unifi](https://registry.terraform.io/providers/paultyng/unifi/latest/docs)

### Example: Create VLAN 60 (Cameras)
```hcl
resource "unifi_network" "cameras" {
  name    = "Cameras"
  purpose = "corporate"

  subnet       = "10.60.0.0/24"
  vlan_id      = 60
  dhcp_enabled = true
  dhcp_start   = "10.60.0.10"
  dhcp_stop    = "10.60.0.254"

  domain_name = "cameras.aplusup.local"
  
  igmp_snooping = false
}
```

### Example: Firewall Rule (Block Cameras → LAN)
```hcl
resource "unifi_firewall_rule" "block_cameras_lan" {
  name    = "Block Cameras -> LAN"
  action  = "drop"
  
  rule_index = 2000
  
  protocol = "all"
  
  src_network_id = unifi_network.cameras.id
  dst_address    = "10.0.0.0/8"
  
  logging = true
}
```

## Adoption Plan

### Step 1: Import Existing Config (Week 1)
```bash
terraform import unifi_network.default 5f8e2d3c4b1a2e3f4c5d6e7f
terraform import unifi_network.cameras 6f9e3d4c5b2a3f4d5c6e7f8g
terraform import unifi_network.voip 7f0e4d5c6b3a4f5d6c7e8f9h
```

### Step 2: Test in Dev Environment (Week 2)
```bash
terraform plan
# Review changes (should be zero diff if import was correct)
```

### Step 3: Apply to Production (Week 3)
```bash
terraform apply
# Verify all networks + firewall rules match
```

### Step 4: Enable GitOps (Week 4)
```yaml
# .github/workflows/terraform.yml
name: Terraform Apply
on:
  push:
    branches:
      - main
    paths:
      - 'terraform/**'
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan
      - run: terraform apply -auto-approve
```

## Carter (2003): "Identity is Programmable Infrastructure"

With Terraform:
- Network policies = code
- Code = version controlled
- Version control = auditable
- Auditable = compliant (Bauer 2005)

## Future State Vision

```bash
# Network architect wants to add VLAN 70 (IoT)
git checkout -b feature/vlan-70-iot

# Edit terraform/modules/vlans/iot.tf
cat > terraform/modules/vlans/iot.tf <<EOF
resource "unifi_network" "iot" {
  name    = "IoT"
  vlan_id = 70
  subnet  = "10.70.0.0/24"
}

resource "unifi_firewall_rule" "block_iot_lan" {
  name   = "Block IoT -> LAN"
  action = "drop"
  src_network_id = unifi_network.iot.id
  dst_address    = "10.0.0.0/8"
}
EOF

# Commit + push
git add terraform/modules/vlans/iot.tf
git commit -m "feat: add VLAN 70 (IoT) with isolation"
git push origin feature/vlan-70-iot

# GitHub Actions runs terraform plan in PR comment
# Reviewer approves
# Merge → terraform apply (auto-applied to UDM)
```

**Result:** Zero click-ops. 100% auditable. Full Bauer (2005) compliance.

---

## Status

🟡 **STUB** — Implementation planned for 2025 Q4

**The fortress is a classroom. The ride is eternal.** 🏍️🔥
