# UniFi Configuration Files

This directory contains JSON configuration payloads for the UDM Pro Max and USW-Pro-Max-48-PoE.

## Files

- `networks.json` - VLAN configuration (10, 50, 60)
- `firewall-rules.json` - Core firewall rules (≤10 maximum)
- `port-profiles.json` - USW port profiles (Camera, VoIP, Default)
- `wifi-networks.json` - SSID configuration
- `backup-config.sh` - Automated backup script

## Usage

### Apply Configuration via UniFi API
```bash
# Example: Create VLAN 60 (Cameras)
curl -k -X POST https://192.168.1.1/api/s/default/rest/networkconf \
  -H "Content-Type: application/json" \
  -d @networks.json \
  --cookie "unifi_session=YOUR_SESSION_COOKIE"
```

### Backup Current Config
```bash
./backup-config.sh
# Output: /backups/udm-config-YYYYMMDD.json
```

## Security Note

These are **template** files. Real production configs may contain sensitive data.  
Always sanitize before committing to git.

**The fortress is a classroom. The ride is eternal.** 🏍️🔥
