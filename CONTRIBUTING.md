# Contributing to T3-ETERNAL

First off, thank you for considering contributing to the A+UP Charter School T3-ETERNAL migration! 

**The fortress is a classroom. The ride is eternal.** 🏍️🔥

---

## Code of Conduct

This project adheres to the principles of **Carter (2003), Bauer (2005), and Suehring (2005)**:

1. **Identity is programmable infrastructure** (Carter)  
   - All authentication changes must be tested with 802.1X RADIUS integration

2. **Trust nothing, verify everything** (Bauer)  
   - All code must pass pre-commit checks (ShellCheck, linting)
   - All firewall rules must be audited and logged

3. **The network is the first line of defense** (Suehring)  
   - Security is the default, not a feature
   - Zero tolerance for PII leakage

---

## The 10-Rule Lockdown (Pre-Commit Requirements)

Before you commit, your code MUST pass these checks:

### 1. ShellCheck (10/10 Required)
```bash
shellcheck scripts/*.sh
# Must return: No errors
```

### 2. LF Line Endings (No CRLF)
```bash
dos2unix scripts/*.sh
```

### 3. Execute Permissions on Scripts
```bash
chmod +x scripts/*.sh
```

### 4. No Hardcoded Credentials
```bash
grep -r "password\|secret\|token" scripts/ config/
# Must return: No matches
```

### 5. No PII in Logs
```bash
# All logs must be redacted
# Use: sed 's/[0-9]\{3\}-[0-9]\{2\}-[0-9]\{4\}/XXX-XX-XXXX/g'
```

### 6. Firewall Rules ≤ 10 (Hardware Offload Safe)
```bash
# Check config/unifi/firewall-rules.json
jq '. | length' config/unifi/firewall-rules.json
# Must return: ≤10
```

### 7. RTO Validation (≤15 minutes)
```bash
# Run orchestrator.sh and validate RTO
./scripts/validate-eternal.sh
# Must return: GREEN
```

### 8. Zero Lint Debt
```bash
# All Markdown files must pass markdownlint
markdownlint docs/**/*.md
# Must return: No errors
```

### 9. ADR Documentation for Major Changes
```bash
# If adding new ADR, follow naming convention:
# docs/adr/XXX-kebab-case-title.md
```

### 10. Test on Fresh Ubuntu 24.04
```bash
# All scripts must run on fresh Ubuntu 24.04 LTS
# No assumed dependencies (curl, jq, sshpass must be explicit)
```

---

## Pull Request Process

### 1. Fork the Repository
```bash
git clone https://github.com/T-Rylander/a-plus-up-unifi-case-study.git
cd a-plus-up-unifi-case-study
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes
- Follow existing code style (Bash best practices)
- Add comments for complex logic
- Update relevant ADRs if architecture changes

### 3. Run Pre-Commit Checks
```bash
# ShellCheck all scripts
shellcheck scripts/*.sh

# Validate UniFi config files
jq . config/unifi/*.json

# Run full validation suite
./scripts/validate-eternal.sh
```

### 4. Commit with Conventional Commits
```bash
git add .
git commit -m "feat: add Phase 6 UniFi Protect migration script"

# Commit types:
# - feat: New feature
# - fix: Bug fix
# - docs: Documentation only
# - style: Formatting (no code change)
# - refactor: Code refactor
# - test: Adding tests
# - chore: Maintenance
```

### 5. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```

**PR Title Format:**
```
[Phase X] Brief description of change
```

**PR Description Template:**
```markdown
## What does this PR do?
Brief description of changes.

## Why is this needed?
Explain the problem this solves.

## How was this tested?
- [ ] Ran validate-eternal.sh (GREEN)
- [ ] Tested on fresh Ubuntu 24.04
- [ ] ShellCheck passed (10/10)
- [ ] No hardcoded credentials

## Related ADRs
- ADR-XXX: Title

## Checklist
- [ ] Code follows style guide
- [ ] All pre-commit checks pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
```

---

## Branch Naming Convention

| Branch Type | Naming | Example |
|-------------|--------|---------|
| Feature | `feature/short-description` | `feature/phase6-protect-migration` |
| Bugfix | `fix/short-description` | `fix/vlan-50-qos-typo` |
| Documentation | `docs/short-description` | `docs/adr-009-wifi6e-upgrade` |
| Hotfix | `hotfix/short-description` | `hotfix/udm-backup-restore` |

---

## Style Guide

### Bash Scripts
```bash
#!/bin/bash
# Script Purpose: Brief description
# Author: Your Name
# Date: YYYY-MM-DD

set -euo pipefail  # Strict mode

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Functions should have comments
function validate_udm() {
    # Validates UDM Pro Max reachability
    local udm_host="${1:-192.168.1.1}"
    
    if ping -c 3 "$udm_host" &> /dev/null; then
        echo -e "${GREEN}✅ UDM reachable${NC}"
        return 0
    else
        echo -e "${RED}❌ UDM unreachable${NC}"
        return 1
    fi
}

# Main execution
main() {
    validate_udm
}

main "$@"
```

### Markdown Documentation
- Use ATX-style headers (`#` not underline)
- Code blocks must specify language (```bash not ```)
- Use tables for structured data
- Include emoji sparingly (only for status indicators)

### JSON Configuration
```json
{
  "description": "Brief description",
  "setting": "value",
  "nested": {
    "key": "value"
  }
}
```

---

## Testing Requirements

### Unit Tests (If Applicable)
```bash
# For complex functions, add tests
./tests/test-validate-eternal.sh
```

### Integration Tests
```bash
# Full stack validation
./scripts/ignite.sh --dry-run
```

### Manual Testing Checklist
- [ ] Test on fresh Ubuntu 24.04 LTS
- [ ] Test with UDM Pro Max (or mock)
- [ ] Test all error paths (e.g., UDM unreachable)
- [ ] Verify logging output (no PII)
- [ ] Check exit codes (0 = success, 1+ = failure)

---

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.x.x): Breaking changes (e.g., new hardware requirement)
- **MINOR** (x.1.x): New features (e.g., Phase 6 migration)
- **PATCH** (x.x.1): Bug fixes (e.g., typo in script)

---

## Security

### Reporting Security Issues
**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, email: **security@example.com** (replace with actual contact)

Include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Security Best Practices
- Never commit credentials (use `.env` files + `.gitignore`)
- Always validate input (never trust user data)
- Use parameterized queries (avoid SQL injection)
- Encrypt sensitive data at rest (e.g., backups)

---

## Recognition

Contributors will be recognized in the README.md "Contributors" section.

**Hall of Fame:**
- Travis Rylander (Network Architect, A+UP Charter School)
- (Your name here!)

---

## Questions?

- **General questions:** Open a GitHub Discussion
- **Bug reports:** Open a GitHub Issue
- **Feature requests:** Open a GitHub Issue with `[Feature Request]` label

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**The fortress is a classroom. The ride is eternal.** 🏍️🔥

**Thank you for helping secure 150+ students' education!**
