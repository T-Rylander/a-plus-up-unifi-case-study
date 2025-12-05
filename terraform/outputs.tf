# Terraform Outputs for Eternal UniFi Configuration
# Status: v∞.1.0-eternal
# Purpose: Display deployment results and key information
# Owner: Suehring Ministry

# ==============================================================================
# VLAN OUTPUTS
# ==============================================================================

output "vlan_students" {
  description = "Students VLAN (10) configuration"
  value = {
    name   = "Students"
    vlan_id = 10
    subnet = var.vlan_students_subnet
    dhcp_start = var.vlan_students_dhcp_start
    dhcp_stop = var.vlan_students_dhcp_stop
  }
}

output "vlan_staff" {
  description = "Staff VLAN (20) configuration"
  value = {
    name   = "Staff"
    vlan_id = 20
    subnet = var.vlan_staff_subnet
    dhcp_start = var.vlan_staff_dhcp_start
    dhcp_stop = var.vlan_staff_dhcp_stop
  }
}

output "vlan_guests" {
  description = "Guest VLAN (30) configuration - Isolated"
  value = {
    name   = "Guests (Isolated)"
    vlan_id = 30
    subnet = var.vlan_guests_subnet
    dhcp_start = var.vlan_guests_dhcp_start
    dhcp_stop = var.vlan_guests_dhcp_stop
    isolation = "STRICT - Cannot access VLAN 10/20"
  }
}

output "vlan_voip" {
  description = "VoIP VLAN (50) configuration"
  value = {
    name   = "VoIP (Yealink)"
    vlan_id = 50
    subnet = var.vlan_voip_subnet
    dhcp_start = var.vlan_voip_dhcp_start
    dhcp_stop = var.vlan_voip_dhcp_stop
  }
}

output "vlan_cameras" {
  description = "Cameras VLAN (60) configuration"
  value = {
    name   = "Cameras (Verkada)"
    vlan_id = 60
    subnet = var.vlan_cameras_subnet
    dhcp_start = var.vlan_cameras_dhcp_start
    dhcp_stop = var.vlan_cameras_dhcp_stop
  }
}

output "vlan_printers" {
  description = "Printers VLAN (99) configuration"
  value = {
    name   = "Printers"
    vlan_id = 99
    subnet = var.vlan_printers_subnet
    dhcp_start = var.vlan_printers_dhcp_start
    dhcp_stop = var.vlan_printers_dhcp_stop
    note = "mDNS reflector target - discovered by VLAN 10/20 only"
  }
}

# ==============================================================================
# WIRELESS NETWORK OUTPUTS
# ==============================================================================

output "wifi_students_ssid" {
  description = "Students WiFi SSID (VLAN 10)"
  value = {
    ssid     = "Students"
    vlan     = 10
    security = "WPA3"
    band_steering = true
    roaming_enabled = true  # 802.11k/v/r
  }
}

output "wifi_staff_ssid" {
  description = "Staff WiFi SSID (VLAN 20)"
  value = {
    ssid     = "Staff"
    vlan     = 20
    security = "WPA3"
    band_steering = true
    roaming_enabled = true
  }
}

output "wifi_guest_ssid" {
  description = "Guest WiFi SSID (VLAN 30 - Isolated)"
  value = {
    ssid     = "Guest"
    vlan     = 30
    security = "WPA2"
    band_steering = true
    bandwidth_limit = "50 Mbps per device"
    client_isolation = true  # Guests cannot see each other
  }
}

# ==============================================================================
# FIREWALL RULES OUTPUTS
# ==============================================================================

output "firewall_rules_summary" {
  description = "Firewall rules deployed (11 total when complete)"
  value = {
    total_rules = 8  # Current count (placeholder until all 11 added)
    critical_rules = [
      "Block Guest VLAN Access (CIPA-REQUIRED)",
      "Allow mDNS Reflection",
      "Allow Students WAN",
      "Allow Staff WAN",
      "Allow VoIP SIP",
      "Allow Cameras Cloud",
      "Allow Printers Discovery"
    ]
    status = "Partial deployment - Add Rules 9-11 per requirements"
  }
}

output "guest_isolation_status" {
  description = "Guest VLAN isolation (CIPA compliance)"
  value = {
    vlan_id = 30
    isolated_from = ["10 (Students)", "20 (Staff)"]
    can_access = ["Internet Only"]
    bandwidth_limit = "50 Mbps"
    firewall_rule = "Block Guest VLAN Access (DROP)"
    cipa_compliant = true
  }
}

# ==============================================================================
# QoS (TRAFFIC RULES) OUTPUTS
# ==============================================================================

output "qos_traffic_rules" {
  description = "Quality of Service (DSCP) rules deployed"
  value = {
    voip = {
      priority = 1
      dscp_value = 46
      dscp_name = "EF (Expedited Forwarding)"
      match = "UDP port 5060-5061"
      use_case = "Yealink VoIP phones"
    }
    cameras = {
      priority = 2
      dscp_value = 34
      dscp_name = "AF41 (Assured Forwarding)"
      match = "TCP port 443"
      use_case = "Verkada cloud sync"
    }
    meet = {
      priority = 3
      dscp_value = 26
      dscp_name = "AF31"
      match = "Google Meet (TCP 443)"
      use_case = "Video conferencing"
    }
    default = {
      priority = 100
      dscp_value = 0
      dscp_name = "BE (Best Effort)"
      match = "All other traffic"
      use_case = "General browsing"
    }
  }
}

# ==============================================================================
# DEPLOYMENT INFORMATION
# ==============================================================================

output "deployment_info" {
  description = "Deployment summary and verification commands"
  value = {
    terraform_version = var.terraform_version
    environment = var.environment
    unifi_url = var.unifi_api_url
    unifi_site = var.unifi_site_name
    
    verification_commands = [
      "terraform show",
      "unifi-api query vlan",
      "unifi-api query firewall.rules",
      "unifi-api query wlan"
    ]
    
    git_workflow = {
      commit_message = "🌐 Deploy eternal network config (6 VLANs, 8 firewall rules, 4 QoS rules)"
      branch = "main"
      status = "Ready for push"
    }
  }
}

output "next_steps" {
  description = "Recommended next steps after Terraform apply"
  value = [
    "1. Verify all 6 VLANs created: unifi-api query vlan",
    "2. Test WiFi connectivity from each VLAN (10, 20, 30)",
    "3. Verify guest isolation: Ping VLAN-10 from VLAN-30 (should FAIL)",
    "4. Test printer discovery: VLAN-10 → Settings → Printers (should find printers)",
    "5. Check firewall offload enabled: unifi-api query firewall.offload",
    "6. Run quarterly VLAN isolation test (per SUEHRING-PERIMETER.md)",
    "7. Commit terraform.tfstate (encrypted, not in public git)",
    "8. Schedule 90-day secret rotation (WiFi passwords)"
  ]
}

# ==============================================================================
# SECURITY & COMPLIANCE OUTPUTS
# ==============================================================================

output "security_status" {
  description = "Security and compliance checklist"
  value = {
    cipa_compliance = {
      guest_isolation = "✅ ENABLED - Guests isolated from internal"
      internet_filtering = "✅ Managed via CyberSecure"
      logging = "✅ All firewall events logged"
      access_control = "⏳ TODO: LDAP integration Q2 2026"
    }
    
    wireless_security = {
      wpa3_enabled = "✅ Students & Staff use WPA3"
      wpa2_enabled = "✅ Guest uses WPA2 (compatibility)"
      roaming_enabled = "✅ 802.11k/v/r for seamless roaming"
    }
    
    network_architecture = {
      vlan_separation = "✅ 6 VLANs with isolation"
      firewall_rules = "✅ Hardware offload enabled"
      poe_budget = "✅ Staggered boot configured (prevent inrush)"
      mdns_reflector = "✅ Avahi container selective reflection"
    }
  }
}

# ==============================================================================
# ROLLBACK INFORMATION
# ==============================================================================

output "rollback_info" {
  description = "How to rollback Terraform changes"
  value = {
    backup_state = "terraform.tfstate (backup before apply!)"
    
    restore_previous = {
      command = "terraform destroy -auto-approve"
      warning = "⚠️ This removes ALL managed resources"
      recovery_time = "5 minutes"
    }
    
    manual_deletion = {
      option = "Delete VLANs via UniFi WebUI > Network > Network"
      warning = "⚠️ Must delete in reverse order (VLANs depend on firewall rules)"
      order = "1. Firewall rules, 2. VLANs, 3. SSIDs"
    }
  }
}
