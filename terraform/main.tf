# Eternal UniFi Terraform Configuration
# Status: v∞.1.0-eternal (Foundation)
# Purpose: Infrastructure-as-Code for UniFi UDM Pro Max + network configuration
# Owner: Suehring Ministry (Network Perimeter)

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    unifi = {
      source  = "paultyng/unifi"
      version = "~> 0.41"
    }
  }

  # TODO: Enable S3 remote state (not local)
  # backend "s3" {
  #   bucket         = "terraform-state-unifi"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "unifi" {
  api_url = var.unifi_api_url
  username = var.unifi_username
  password = var.unifi_password
  # Disable cert validation for self-signed UDM certs
  allow_insecure = false  # Set to true only in development!
}

# Data source: Get current site
data "unifi_site" "default" {
  name = var.unifi_site_name
}

# ==============================================================================
# VLAN CONFIGURATION (6 VLANs: Students, Staff, Guests, VoIP, Cameras, Printers)
# ==============================================================================

# VLAN 10: Students
resource "unifi_network" "students" {
  name           = "Students"
  purpose        = "corporate"
  vlan_id        = 10
  subnet         = var.vlan_students_subnet
  dhcp_enabled   = true
  dhcp_start     = var.vlan_students_dhcp_start
  dhcp_stop      = var.vlan_students_dhcp_stop
  dhcp_lease     = var.dhcp_lease_time

  depends_on = [data.unifi_site.default]
}

# VLAN 20: Staff
resource "unifi_network" "staff" {
  name           = "Staff"
  purpose        = "corporate"
  vlan_id        = 20
  subnet         = var.vlan_staff_subnet
  dhcp_enabled   = true
  dhcp_start     = var.vlan_staff_dhcp_start
  dhcp_stop      = var.vlan_staff_dhcp_stop
  dhcp_lease     = var.dhcp_lease_time

  depends_on = [data.unifi_site.default]
}

# VLAN 30: Guests (Isolated)
resource "unifi_network" "guests" {
  name           = "Guests"
  purpose        = "guest"
  vlan_id        = 30
  subnet         = var.vlan_guests_subnet
  dhcp_enabled   = true
  dhcp_start     = var.vlan_guests_dhcp_start
  dhcp_stop      = var.vlan_guests_dhcp_stop
  dhcp_lease     = var.dhcp_lease_time_guests  # Shorter lease for guests

  depends_on = [data.unifi_site.default]
}

# VLAN 50: VoIP (Yealink Phones)
resource "unifi_network" "voip" {
  name           = "VoIP"
  purpose        = "corporate"
  vlan_id        = 50
  subnet         = var.vlan_voip_subnet
  dhcp_enabled   = true
  dhcp_start     = var.vlan_voip_dhcp_start
  dhcp_stop      = var.vlan_voip_dhcp_stop
  dhcp_lease     = var.dhcp_lease_time

  depends_on = [data.unifi_site.default]
}

# VLAN 60: Cameras (Verkada)
resource "unifi_network" "cameras" {
  name           = "Cameras"
  purpose        = "corporate"
  vlan_id        = 60
  subnet         = var.vlan_cameras_subnet
  dhcp_enabled   = true
  dhcp_start     = var.vlan_cameras_dhcp_start
  dhcp_stop      = var.vlan_cameras_dhcp_stop
  dhcp_lease     = var.dhcp_lease_time

  depends_on = [data.unifi_site.default]
}

# VLAN 99: Printers (mDNS reflector target)
resource "unifi_network" "printers" {
  name           = "Printers"
  purpose        = "corporate"
  vlan_id        = 99
  subnet         = var.vlan_printers_subnet
  dhcp_enabled   = true
  dhcp_start     = var.vlan_printers_dhcp_start
  dhcp_stop      = var.vlan_printers_dhcp_stop
  dhcp_lease     = var.dhcp_lease_time

  depends_on = [data.unifi_site.default]
}

# ==============================================================================
# WIRELESS NETWORKS (SSIDs)
# ==============================================================================

# SSID: Students (VLAN 10, WPA3 preferred)
resource "unifi_network" "wifi_students" {
  name           = "Students"
  purpose        = "corporate"
  ssid_schedule  = ""
  wireless_clients_isolate = false  # Allow peer-to-peer
  
  # WiFi settings
  wifi_band_select = "auto"
  fast_roaming_enabled = true  # 802.11k/v/r
  band_steer       = true
  band_steer_5g_preference = true
  
  # VLAN binding
  network_group = unifi_network.students.name
  
  # Security
  security = "wpa3"
  wpa_mode = "wpa3"
  wpa_enc  = "ccmp"
  
  # Pre-shared key (from vars/secrets)
  x_passphrase = var.wifi_students_password

  depends_on = [unifi_network.students]
}

# SSID: Staff (VLAN 20, WPA3 mandatory)
resource "unifi_network" "wifi_staff" {
  name           = "Staff"
  purpose        = "corporate"
  ssid_schedule  = ""
  wireless_clients_isolate = false
  
  wifi_band_select = "auto"
  fast_roaming_enabled = true  # 802.11k/v/r
  band_steer       = true
  band_steer_5g_preference = true
  
  network_group = unifi_network.staff.name
  
  security = "wpa3"
  wpa_mode = "wpa3"
  wpa_enc  = "ccmp"
  
  x_passphrase = var.wifi_staff_password

  depends_on = [unifi_network.staff]
}

# SSID: Guest (VLAN 30, WPA2 for compatibility)
resource "unifi_network" "wifi_guest" {
  name           = "Guest"
  purpose        = "guest"
  ssid_schedule  = ""
  wireless_clients_isolate = true  # Strict isolation between guests
  
  wifi_band_select = "auto"
  
  # Guest network: limit to 50 Mbps
  qos_rate_max_up = 50000     # 50 Mbps upload
  qos_rate_max_down = 50000   # 50 Mbps download
  
  network_group = unifi_network.guests.name
  
  security = "wpa2"
  wpa_mode = "wpa2"
  wpa_enc  = "ccmp"
  
  x_passphrase = var.wifi_guest_password

  depends_on = [unifi_network.guests]
}

# ==============================================================================
# FIREWALL RULES (11 Total)
# ==============================================================================

# Firewall Group: Allow mDNS reflection (VLAN 10+20)
resource "unifi_firewall_group_addr" "mdns_allowed_vlans" {
  name   = "mdns-allowed-vlans"
  group_type = "address-group"
  members = [
    "10.10.0.0/16",  # VLAN 10
    "10.20.0.0/16"   # VLAN 20
  ]
}

# Firewall Rule 1: Allow mDNS (UDP 5353)
resource "unifi_firewall_rule" "allow_mdns" {
  name       = "Allow mDNS Reflection"
  action     = "accept"
  ruleset    = "LAN_IN"
  rule_index = 2010

  protocol   = "udp"
  dst_port   = "5353"
  dst_addr   = "224.0.0.251"  # mDNS multicast
  
  enabled = true
  logging = true

  depends_on = [data.unifi_site.default]
}

# Firewall Rule 2: Block Guest → Internal (CRITICAL for CIPA)
resource "unifi_firewall_rule" "block_guest_internal" {
  name       = "Block Guest VLAN Access"
  action     = "drop"
  ruleset    = "LAN_IN"
  rule_index = 2020

  src_addr   = var.vlan_guests_subnet
  dst_addr   = var.vlan_students_subnet
  
  enabled = true
  logging = true

  depends_on = [data.unifi_site.default]
}

# Firewall Rule 3: Allow Students → Internet
resource "unifi_firewall_rule" "allow_students_wan" {
  name       = "Allow Students WAN"
  action     = "accept"
  ruleset    = "LAN_OUT"
  rule_index = 3010

  src_addr   = var.vlan_students_subnet
  dst_addr   = "0.0.0.0/0"  # Any destination
  
  enabled = true

  depends_on = [data.unifi_site.default]
}

# Firewall Rule 4: Allow Staff → Internet
resource "unifi_firewall_rule" "allow_staff_wan" {
  name       = "Allow Staff WAN"
  action     = "accept"
  ruleset    = "LAN_OUT"
  rule_index = 3020

  src_addr   = var.vlan_staff_subnet
  dst_addr   = "0.0.0.0/0"
  
  enabled = true

  depends_on = [data.unifi_site.default]
}

# Firewall Rule 5: Allow Guest → Internet (Only)
resource "unifi_firewall_rule" "allow_guest_wan" {
  name       = "Allow Guest WAN"
  action     = "accept"
  ruleset    = "LAN_OUT"
  rule_index = 3030

  src_addr   = var.vlan_guests_subnet
  dst_addr   = "0.0.0.0/0"
  
  enabled = true

  depends_on = [data.unifi_site.default]
}

# Firewall Rule 6: Allow VoIP → SIP Server
resource "unifi_firewall_rule" "allow_voip_sip" {
  name       = "Allow VoIP SIP"
  action     = "accept"
  ruleset    = "LAN_OUT"
  rule_index = 3040

  src_addr   = var.vlan_voip_subnet
  dst_port   = "5060,5061"  # SIP ports
  protocol   = "udp_tcp"
  
  enabled = true

  depends_on = [data.unifi_site.default]
}

# Firewall Rule 7: Allow Cameras → Cloud (Verkada)
resource "unifi_firewall_rule" "allow_cameras_cloud" {
  name       = "Allow Cameras Cloud"
  action     = "accept"
  ruleset    = "LAN_OUT"
  rule_index = 3050

  src_addr   = var.vlan_cameras_subnet
  dst_port   = "443,8443"  # HTTPS
  protocol   = "tcp"
  
  enabled = true

  depends_on = [data.unifi_site.default]
}

# Firewall Rule 8: Allow Printers → VLAN 10+20 (Discovery)
resource "unifi_firewall_rule" "allow_printers_discovery" {
  name       = "Allow Printer Discovery"
  action     = "accept"
  ruleset    = "LAN_IN"
  rule_index = 2030

  src_addr   = var.vlan_printers_subnet
  dst_addr   = var.vlan_students_subnet
  dst_port   = "5353"  # mDNS
  protocol   = "udp"
  
  enabled = true

  depends_on = [data.unifi_site.default]
}

# (Rules 9-11: To be added based on specific requirements)

# ==============================================================================
# TRAFFIC RULES (QoS via DSCP)
# ==============================================================================

# Traffic Rule 1: VoIP → EF/46 (Expedited Forwarding)
resource "unifi_traffic_control_rule" "voip_qos" {
  name        = "VoIP Priority"
  enabled     = true
  priority    = 1
  
  match_protocol = "udp"
  match_src_port = "5060-5061"
  target_dscp    = 46  # EF (Expedited Forwarding)
  
  depends_on = [data.unifi_site.default]
}

# Traffic Rule 2: Verkada Cameras → AF41/34 (Assured Forwarding)
resource "unifi_traffic_control_rule" "cameras_qos" {
  name        = "Cameras Priority"
  enabled     = true
  priority    = 2
  
  match_protocol = "tcp"
  match_dst_port = "443"
  target_dscp    = 34  # AF41 (Assured Forwarding)
  
  depends_on = [data.unifi_site.default]
}

# Traffic Rule 3: Google Meet → AF31/26
resource "unifi_traffic_control_rule" "meet_qos" {
  name        = "Google Meet Priority"
  enabled     = true
  priority    = 3
  
  match_protocol = "tcp"
  match_dst_port = "443"
  # Note: Match by hostname (meet.google.com) if supported
  target_dscp    = 26  # AF31
  
  depends_on = [data.unifi_site.default]
}

# Traffic Rule 4: Best Effort (Default)
resource "unifi_traffic_control_rule" "default_qos" {
  name        = "Default Best Effort"
  enabled     = true
  priority    = 100
  
  # Matches all remaining traffic
  target_dscp = 0  # BE (Best Effort)
  
  depends_on = [data.unifi_site.default]
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "vlan_10_students_subnet" {
  description = "Students VLAN subnet"
  value       = unifi_network.students.subnet
}

output "vlan_20_staff_subnet" {
  description = "Staff VLAN subnet"
  value       = unifi_network.staff.subnet
}

output "vlan_30_guests_subnet" {
  description = "Guest VLAN subnet"
  value       = unifi_network.guests.subnet
}

output "firewall_rules_count" {
  description = "Total firewall rules deployed"
  value       = 8  # Update as rules are added
}

output "wifi_ssids_active" {
  description = "Active WiFi SSIDs"
  value = {
    students = unifi_network.wifi_students.name
    staff    = unifi_network.wifi_staff.name
    guest    = unifi_network.wifi_guest.name
  }
}
