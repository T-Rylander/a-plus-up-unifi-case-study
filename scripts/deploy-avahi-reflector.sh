#!/bin/bash
# Deploy Avahi mDNS Reflector Container
# T3-ETERNAL v1.1 - Comprehensive Corrections
#
# Deploys VLAN-selective mDNS reflector (VLAN 10 ↔ VLAN 20 only)

set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

echo "🔁 Deploying Avahi mDNS Reflector (VLAN 10 ↔ VLAN 20 only)"
echo ""

# Validate files exist
if [ ! -f config/avahi/docker-compose.yml ]; then
  echo -e "${RED}❌ ERROR: config/avahi/docker-compose.yml not found${NC}"
  exit 1
fi

if [ ! -f config/avahi/avahi-daemon.conf ]; then
  echo -e "${RED}❌ ERROR: config/avahi/avahi-daemon.conf not found${NC}"
  exit 1
fi

echo "📋 Step 1: Deploy on UDM Pro Max via SSH"
echo ""

# Deploy container on UDM
ssh admin@10.99.0.1 << 'EOSSH'
  # Install podman-compose if not present
  if ! command -v podman-compose &>/dev/null; then
    echo "Installing podman-compose..."
    curl -o /usr/local/bin/podman-compose \
      https://raw.githubusercontent.com/containers/podman-compose/main/podman_compose.py
    chmod +x /usr/local/bin/podman-compose
  fi
  
  # Create deployment directory
  mkdir -p /mnt/data/avahi
  cd /mnt/data/avahi
  
  echo "Avahi mDNS reflector deployment directory ready"
EOSSH

# Copy configuration files to UDM
echo "Copying configuration files to UDM..."
scp config/avahi/docker-compose.yml admin@10.99.0.1:/mnt/data/avahi/
scp config/avahi/avahi-daemon.conf admin@10.99.0.1:/mnt/data/avahi/

# Deploy container
ssh admin@10.99.0.1 << 'EOSSH'
  cd /mnt/data/avahi
  
  # Start Avahi reflector container
  podman-compose up -d
  
  # Wait for container to start
  sleep 10
  
  # Check container status
  podman ps | grep avahi-mdns-reflector
EOSSH

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ ERROR: Failed to deploy Avahi container${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Avahi container deployed${NC}"
echo ""

echo "📋 Step 2: Disable Native UniFi mDNS (Conflicts with Avahi)"
echo ""

cat << 'EOF'
Via UniFi Network Application UI:
1. Navigate to: Settings → Networks → VLAN 10 → Advanced
   • mDNS: Disabled

2. Navigate to: Settings → Networks → VLAN 20 → Advanced
   • mDNS: Disabled

Rationale: Native mDNS affects ALL VLANs (cannot be selective)
           Avahi container provides precise VLAN 10 ↔ VLAN 20 reflection
EOF

echo ""
echo "📋 Step 3: Validate mDNS Reflection"
echo ""

echo "# From VLAN 10 (student Chromebook):"
echo "avahi-browse -a -t -r"
echo "# Should show printers from VLAN 20"
echo ""
echo "# Check Avahi logs:"
echo "ssh admin@10.99.0.1"
echo "podman logs avahi-mdns-reflector | grep 'Joining mDNS multicast group'"
echo "# Should show joins on both 10.10.x.x and 10.20.x.x"
echo ""
echo "# Test printer discovery from Chromebook:"
echo "# 1. Open Chrome on student Chromebook (VLAN 10)"
echo "# 2. Navigate to: chrome://print"
echo "# 3. Verify all 40+ printers appear in list"
echo ""

# Validate container health
echo "Checking container health..."
CONTAINER_STATUS=$(ssh admin@10.99.0.1 "podman ps --filter name=avahi-mdns-reflector --format '{{.Status}}'" | grep -c "Up" || echo "0")

if [ "$CONTAINER_STATUS" -ge 1 ]; then
  echo -e "${GREEN}✅ Avahi container: Running${NC}"
else
  echo -e "${RED}❌ Avahi container: Not running${NC}"
  echo "   Check logs: ssh admin@10.99.0.1 'podman logs avahi-mdns-reflector'"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Avahi mDNS Reflector Deployed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration:"
echo "  • Reflector: VLAN 10 ↔ VLAN 20 only"
echo "  • Interfaces: br10, br20"
echo "  • Native mDNS: Disabled (conflicts prevented)"
echo "  • Persistence: Container auto-restarts on reboot"
echo ""
echo "Monitoring:"
echo "  # Check container status"
echo "  ssh admin@10.99.0.1 'podman ps | grep avahi'"
echo ""
echo "  # View real-time logs"
echo "  ssh admin@10.99.0.1 'podman logs -f avahi-mdns-reflector'"
echo ""
echo "  # Monitor mDNS traffic"
echo "  ssh admin@10.99.0.1 'tcpdump -i br10 port 5353'"
echo ""
echo "Troubleshooting:"
echo "  # If printers not discovered from VLAN 10:"
echo "  1. Verify container running: podman ps"
echo "  2. Check br10/br20 interfaces exist: ip link show"
echo "  3. Verify native mDNS disabled on both VLANs"
echo "  4. Test mDNS query: avahi-browse -a -t"
echo ""
echo "Maintenance:"
echo "  # Restart container"
echo "  ssh admin@10.99.0.1 'cd /mnt/data/avahi && podman-compose restart'"
echo ""
echo "  # Update configuration"
echo "  # 1. Edit config/avahi/avahi-daemon.conf locally"
echo "  # 2. scp to UDM: /mnt/data/avahi/avahi-daemon.conf"
echo "  # 3. Restart container"
echo ""

# Log deployment
mkdir -p logs
echo "$(date -Iseconds),avahi_deployed,vlan10_vlan20_reflector" >> logs/t3-eternal-history.csv

echo -e "${GREEN}✅ mDNS reflection ready for printer discovery${NC}"
echo ""
