# Terraform Variables for Eternal UniFi Configuration
# Status: v∞.1.0-eternal
# Purpose: Define all configurable parameters
# Owner: Suehring Ministry

# ==============================================================================
# PROVIDER CONFIGURATION
# ==============================================================================

variable "unifi_api_url" {
  description = "UniFi API URL (UDM Pro Max IP)"
  type        = string
  sensitive   = false
  default     = "https://192.168.1.1:8443"
  # Override in terraform.tfvars: unifi_api_url = "https://udm.yourdomain.com:8443"
}

variable "unifi_username" {
  description = "UniFi API username (usually 'ubnt')"
  type        = string
  sensitive   = false
  default     = "ubnt"
}

variable "unifi_password" {
  description = "UniFi API password (changed password, NOT default)"
  type        = string
  sensitive   = true
  # MUST be provided via environment or tfvars
  default     = ""
}

variable "unifi_site_name" {
  description = "UniFi Site name"
  type        = string
  default     = "default"
}

# ==============================================================================
# VLAN CONFIGURATION
# ==============================================================================

variable "vlan_students_subnet" {
  description = "VLAN 10 Students subnet (CIDR)"
  type        = string
  default     = "10.10.0.0/16"
}

variable "vlan_students_dhcp_start" {
  description = "VLAN 10 DHCP pool start"
  type        = string
  default     = "10.10.1.100"
}

variable "vlan_students_dhcp_stop" {
  description = "VLAN 10 DHCP pool end"
  type        = string
  default     = "10.10.1.200"
}

variable "vlan_staff_subnet" {
  description = "VLAN 20 Staff subnet (CIDR)"
  type        = string
  default     = "10.20.0.0/16"
}

variable "vlan_staff_dhcp_start" {
  description = "VLAN 20 DHCP pool start"
  type        = string
  default     = "10.20.1.100"
}

variable "vlan_staff_dhcp_stop" {
  description = "VLAN 20 DHCP pool end"
  type        = string
  default     = "10.20.1.200"
}

variable "vlan_guests_subnet" {
  description = "VLAN 30 Guest subnet (CIDR, isolated)"
  type        = string
  default     = "10.30.0.0/16"
}

variable "vlan_guests_dhcp_start" {
  description = "VLAN 30 DHCP pool start"
  type        = string
  default     = "10.30.1.100"
}

variable "vlan_guests_dhcp_stop" {
  description = "VLAN 30 DHCP pool end"
  type        = string
  default     = "10.30.1.200"
}

variable "vlan_voip_subnet" {
  description = "VLAN 50 VoIP subnet (CIDR)"
  type        = string
  default     = "10.50.0.0/16"
}

variable "vlan_voip_dhcp_start" {
  description = "VLAN 50 DHCP pool start"
  type        = string
  default     = "10.50.1.100"
}

variable "vlan_voip_dhcp_stop" {
  description = "VLAN 50 DHCP pool end"
  type        = string
  default     = "10.50.1.200"
}

variable "vlan_cameras_subnet" {
  description = "VLAN 60 Cameras subnet (CIDR)"
  type        = string
  default     = "10.60.0.0/16"
}

variable "vlan_cameras_dhcp_start" {
  description = "VLAN 60 DHCP pool start"
  type        = string
  default     = "10.60.1.100"
}

variable "vlan_cameras_dhcp_stop" {
  description = "VLAN 60 DHCP pool end"
  type        = string
  default     = "10.60.1.200"
}

variable "vlan_printers_subnet" {
  description = "VLAN 99 Printers subnet (CIDR)"
  type        = string
  default     = "10.99.0.0/16"
}

variable "vlan_printers_dhcp_start" {
  description = "VLAN 99 DHCP pool start"
  type        = string
  default     = "10.99.1.100"
}

variable "vlan_printers_dhcp_stop" {
  description = "VLAN 99 DHCP pool end"
  type        = string
  default     = "10.99.1.200"
}

# ==============================================================================
# DHCP CONFIGURATION
# ==============================================================================

variable "dhcp_lease_time" {
  description = "DHCP lease time (seconds) - standard 1 hour"
  type        = number
  default     = 3600
}

variable "dhcp_lease_time_guests" {
  description = "DHCP lease time for guests (seconds) - shorter 30 min"
  type        = number
  default     = 1800
}

# ==============================================================================
# WIRELESS CONFIGURATION
# ==============================================================================

variable "wifi_students_password" {
  description = "Students WiFi password (WPA3)"
  type        = string
  sensitive   = true
  # MUST be provided via environment or tfvars
  default     = ""
}

variable "wifi_staff_password" {
  description = "Staff WiFi password (WPA3)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "wifi_guest_password" {
  description = "Guest WiFi password (WPA2)"
  type        = string
  sensitive   = true
  default     = ""
}

# ==============================================================================
# DEPLOYMENT SETTINGS
# ==============================================================================

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "terraform_version" {
  description = "Required Terraform version"
  type        = string
  default     = "1.5"
}

# ==============================================================================
# TAGGING & METADATA
# ==============================================================================

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "prod"
    Owner       = "Suehring Ministry"
    Version     = "eternal-v1"
  }
}

# ==============================================================================
# LOCAL VALUES (Computed, not inputs)
# ==============================================================================

locals {
  # Network summary
  vlans = {
    10 = "Students"
    20 = "Staff"
    30 = "Guests"
    50 = "VoIP"
    60 = "Cameras"
    99 = "Printers"
  }

  # DSCP values for QoS
  dscp_voip    = 46   # EF (Expedited Forwarding)
  dscp_cameras = 34   # AF41 (Assured Forwarding)
  dscp_meet    = 26   # AF31
  dscp_default = 0    # BE (Best Effort)

  # Common filters
  management_vlans = [10, 20]  # VLANs that can manage network
  isolated_vlans   = [30]      # Completely isolated (guests)
}
