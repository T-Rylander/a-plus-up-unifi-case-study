# CARTER MINISTRY: IDENTITY & SECRETS GOVERNANCE
## The Programmable Infrastructure Guardian

**Status**: v∞.1.0-eternal | Locked Forever | Date: 12/05/2025

---

## 🔐 Ministry Purpose

**Carter (2003)**: "Identity is programmable infrastructure"  
**T3-ETERNAL Role**: Guardian of all secrets, authentication systems, and identity provisioning  
**Responsibility**: Ensure zero credential leakage, one-shot LDAP resurrection, secure ephemeral deployments

---

## Ministry Mandate

| Pillar | Responsibility | Owner | Escalation |
|--------|-----------------|-------|-----------|
| **LDAP Sync** | User provisioning (150 staff + students) | Travis Rylander | Principal (if sync fails) |
| **Secrets Management** | API keys, passwords, TLS certs | Travis Rylander | Backup: external consultant |
| **802.1X Future** | FreeRADIUS deployment (Q2 2026) | Travis Rylander | Google Workspace Enterprise PM |
| **Credential Rotation** | 90-day password cycles, cert renewal | Automated (cron) | Travis Rylander (on failure) |
| **Access Control** | RBAC (staff/student/guest), VLAN mapping | Travis Rylander | IT Leadership |
| **Incident Response** | Compromised credentials, brute-force attacks | Travis Rylander + Bot | Law enforcement (if needed) |

---

## Core Secrets (Encrypted in .env, Never in Git)

```bash
# File: .env (GITIGNORED, ONLY ON UDM)
# Each secret MUST be rotated quarterly

LDAP_BIND_PASS="[90-day rotation]"           # cn=admin,dc=aplusup,dc=org
LDAP_BIND_USER="cn=admin,dc=aplusup,dc=org"

UNIFI_USERNAME="ubnt"                         # UDM local user
UNIFI_PASSWORD="[UDM-generated, 32-char]"    # Random, 90-day rotation
UNIFI_API_KEY="[UniFi API provisioning]"     # From UniFi OS > Settings > API

UDM_HOST="10.99.0.1"                         # UDM Pro Max
UDM_USER="admin"                              # SSH user
UDM_PASS="[UDM SSH password, 90-day]"        # Separate from UniFi password

MATTERMOST_ADMIN_PASS="[Mattermost setup]"   # Future collaboration platform
RADIUS_SECRET="testing123"                    # FreeRADIUS shared secret (Q2 2026)

POSTGRES_PASS="[Database password]"          # For Mattermost DB (future)
VERKADA_API_KEY="[Verkada command center]"   # Camera cloud integration
SYSLOG_ENCRYPTION_KEY="[TLS cert key]"       # For audit log export

WIFI_PASSWORD_STUDENT="[WPA2 passphrase]"    # VLAN 10 Student-WiFi
WIFI_PASSWORD_PRINTER="[WPA2 passphrase]"    # VLAN 20 Printers-Legacy
WIFI_PASSWORD_STAFF="[WPA2 passphrase]"      # VLAN 20 Staff-Secure

TLS_CERT_PATH="/etc/ssl/certs/unifi.pem"     # UDM TLS (auto-renewed)
TLS_KEY_PATH="/etc/ssl/private/unifi.key"    # UDM TLS key
```

---

## Identity Matrix: One-Shot LDAP Resurrection

**Scripts**: `scripts/ldap-sync-eternal.sh` + `tests/test_identity_matrix.py`

### LDAP Structure (aplusup.org)
```
dc=aplusup,dc=org
├── ou=staff
│   ├── uid=travis (Principal, admin role)
│   ├── uid=itstaff (IT Technician, operator role)
│   └── uid=teachers (Faculty, staff role)
├── ou=students
│   ├── uid=student001 (Chromebook account)
│   ├── uid=student002
│   └── ... (150+ student accounts)
├── ou=guests
│   └── uid=guest (Temporary, revoked monthly)
└── ou=services
    ├── uid=unifi (API provisioning)
    ├── uid=mattermost (Collaboration future)
    └── uid=radius (802.1X future, Q2 2026)
```

### Auto-Provisioning Rules
```bash
# VLAN Mapping (automatic via LDAP objectClass):
- Staff (uid in ou=staff) → VLAN 20 (10.20.0.0/24)
- Students (uid in ou=students) → VLAN 10 (10.10.0.0/23)
- Guests (uid in ou=guests) → VLAN 30 (10.30.0.0/24)
- Services (uid in ou=services) → VLAN 99 (10.99.0.0/28)

# Chromebook Google Workspace Sync (Future 802.1X):
- LDAP user ← Sync ← Google Directory
- Credential update every 24 hours via FreeRADIUS
- Deprovisioning: AUE date trigger (auto-remove expired Chromebooks)
```

---

## Secrets Rotation Schedule

| Secret | Frequency | Procedure | Automation |
|--------|-----------|-----------|-----------|
| LDAP bind pass | 90 days | Manual update in AD, restart sync | Reminder email 7 days prior |
| UniFi API key | 90 days | Regenerate in UniFi OS, update .env | Pre-commit hook warns |
| UDM SSH password | 90 days | Change via UniFi UI, backup to secure location | Scheduled reminder |
| WiFi passphrase | 180 days | Announce to staff/students, update SSIDs | Deployment script |
| TLS certificate | 365 days | Auto-renewal via Let's Encrypt (UDM built-in) | Loki alert on 30-day warning |
| Verkada API key | 180 days | Regenerate in Verkada Command, update .env | Script validation |

**Validation**:
```bash
# Verify all secrets are rotated
scripts/validate-eternal.sh | grep -i "secret\|credential\|password"
# Expected: All rotation dates within SLA
```

---

## Secure Deployment Checklist

### Pre-Deployment (Carter's 3-Point Lockdown)

- [ ] All secrets in `.env` (never in scripts or config files)
- [ ] `.env` is GITIGNORED (verify in `.gitignore`)
- [ ] `.env.example` provides template (with placeholder values)
- [ ] Pre-commit hook blocks commits with exposed secrets:
  ```bash
  grep -r "password\|api.key\|secret" scripts/ config/ docs/ && exit 1
  ```
- [ ] Verify no hardcoded credentials in:
  - Python files (no `MM_LDAPSETTINGS_BINDPASSWORD="password"`)
  - Shell scripts (no `curl -u "admin:password"`)
  - JSON configs (no `"secret": "value"`)

### Deployment Sequence (One-Shot Wizardry)

```bash
# 1. Decrypt .env from secure backup
ansible-vault decrypt .env.vault

# 2. Export to environment (NOT to shell history)
set +o history
source .env
set -o history

# 3. Run identity sync (LDAP only)
bash scripts/ldap-sync-eternal.sh

# 4. Verify 150+ users provisioned
ldapsearch -x -D "cn=admin,dc=aplusup,dc=org" -w "$LDAP_BIND_PASS" \
  -b "dc=aplusup,dc=org" 'uid=*' | wc -l
# Expected: 150+

# 5. Deploy credentials to network devices
unifi-api-client set-network VLAN10 --name "Student-WiFi" --passphrase "$WIFI_PASSWORD_STUDENT"
unifi-api-client set-network VLAN30 --name "Guest-Portal" --passphrase "$WIFI_GUEST_PASS"

# 6. Wipe environment variables
unset LDAP_BIND_PASS UNIFI_PASSWORD UDM_PASS MATTERMOST_ADMIN_PASS
unset WIFI_PASSWORD_STUDENT WIFI_PASSWORD_PRINTER WIFI_PASSWORD_STAFF

# 7. Audit via Loki (verify no credentials in logs)
grep -r "password\|secret" /var/log/unifi-os/ && echo "❌ BREACH" || echo "✅ CLEAN"
```

---

## Crisis Response (Compromised Credentials)

### If LDAP Bind Password Exposed
```bash
# 1. IMMEDIATELY generate new password in Active Directory
# 2. Update .env on UDM only (SSH, not via network)
# 3. Restart LDAP sync service
# 4. Force re-authentication of all users (clear WiFi credentials)
# 5. Audit all LDAP queries in past 24 hours (Loki)
# 6. Notify IT leadership + sign incident report

# Automation:
bash scripts/crisis-ldap-rotate.sh  # Rotate LDAP password
```

### If UniFi API Key Exposed
```bash
# 1. Regenerate in UniFi OS > Settings > API
# 2. Update all scripts to use new key
# 3. Audit API logs for unauthorized calls (last 24h)
# 4. Revoke old key completely
# 5. Test all scripts with new key before deployment

bash scripts/crisis-unifi-key-rotate.sh
```

### If WiFi Password Breached
```bash
# 1. Announce to all staff (email + Mattermost)
# 2. Change WiFi passphrase immediately
# 3. Force re-authentication (disable, re-enable SSID)
# 4. Block known attacker IP via firewall rule
# 5. Audit all VLAN crossings (Loki)

bash scripts/crisis-wifi-rotate.sh --vlan 10 --announce
```

---

## Carter's Eternal Vigilance

```bash
# Weekly: Verify no secrets in git history
git log --all -p | grep -i "password\|secret" && echo "❌ BREACH FOUND IN HISTORY"

# Monthly: Audit .env file permissions (600 = rw-------)
[ $(stat -f%A .env) == "600" ] || chmod 600 .env

# Quarterly: Rotate all 90-day secrets
bash scripts/rotate-all-secrets.sh

# Post-incident: Review secret handling procedures
docs/trinity/CARTER-INCIDENT-LOG.md
```

---

## References

- **NIST Cybersecurity Framework**: Secret management best practices
- **OWASP**: Secrets Management Cheat Sheet
- **UniFi Docs**: API key provisioning + security
- **Google Workspace**: Secure LDAP setup (future 802.1X)
- **FreeRADIUS**: EAP-PEAP + Chromebook integration (Q2 2026)

---

**The fortress trusts nothing. Secrets are golden. 🔐**

*Last Audited: 12/05/2025 | Next Review: 03/05/2026 (90-day rotation cycle)*
