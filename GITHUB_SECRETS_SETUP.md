# GitHub Secrets Configuration for T3-ETERNAL Validation

This guide explains how to configure the GitHub repository secrets required for the T3-ETERNAL validation workflow.

## Prerequisites

1. You must have admin access to the repository
2. Navigate to: **Settings → Secrets and variables → Actions**

## Required Secrets

### 1. `UDM_HOST`
- **Purpose:** IP address of the UniFi Dream Machine Pro Max
- **Example Value:** `10.99.0.1`
- **Required For:** `validate-eternal.sh` health checks
- **Notes:** This is the management VLAN (VLAN 99) address

### 2. `UDM_USER`
- **Purpose:** Admin username for UDM authentication
- **Example Value:** `admin`
- **Required For:** SSH/API authentication to UDM
- **Notes:** Use a service account with read-only access if possible

### 3. `UDM_PASS`
- **Purpose:** Password for UDM admin user
- **Example Value:** (your secure password)
- **Required For:** SSH authentication in `validate-eternal.sh`
- **Security Note:** ⚠️ This is sensitive — use a strong, unique password
- **Recommendation:** Create a dedicated read-only service account for CI/CD

## How to Add Secrets

### Via GitHub Web UI

1. Go to your repository on GitHub
2. Click **Settings** (top right)
3. Left sidebar → **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Enter the secret name (e.g., `UDM_HOST`)
6. Enter the value
7. Click **Add secret**

Repeat for each secret.

### Via GitHub CLI

```bash
# Set UDM_HOST
gh secret set UDM_HOST --body "10.99.0.1"

# Set UDM_USER
gh secret set UDM_USER --body "admin"

# Set UDM_PASS (will prompt for secure input)
gh secret set UDM_PASS
```

## Workflow Behavior Without Secrets

**Good news:** The workflow is designed to work **even without secrets configured**!

- ✅ `validate-eternal.sh` will skip UDM-specific checks if secrets are not set
- ✅ SNMP health checks will be skipped if the tool is unavailable
- ✅ Core validation gates (VLAN checks, mDNS validation, secrets scanning) **still run**
- ✅ All checks gracefully degrade in CI/CD environments

This means:
- Fork PRs won't fail due to missing secrets
- New contributors can run validations without configuration
- Only environment-specific checks are skipped

## When Secrets Are Required

Configure these secrets only if you want:
1. Real-time UDM connectivity health checks
2. SSH-based device validation
3. Direct API queries to UniFi infrastructure

## Verifying Secrets Are Set

To check if secrets are configured (without exposing values):

```bash
# List all secrets
gh secret list
```

Look for `UDM_HOST`, `UDM_USER`, and `UDM_PASS` in the output.

## Security Best Practices

1. **Never commit credentials** — Use GitHub Secrets, not hardcoded values
2. **Rotate credentials periodically** — Update the secrets every 90 days
3. **Use service accounts** — Don't use personal admin credentials
4. **Restrict permissions** — The service account should only have read access
5. **Audit access** — Check who has access to the repository

## Troubleshooting

### Secret appears not to be working
- GitHub actions have a ~1 minute delay after adding a secret
- Try re-running the workflow after 1 minute
- Verify the secret name matches exactly (case-sensitive): `UDM_HOST` not `udm_host`

### Tests pass locally but fail in GitHub Actions
- Confirm secrets are set in the repository (Settings → Secrets)
- Check that the secret values match your local configuration
- Review the workflow logs: GitHub Actions → Job → Step output

### I see "Context access might be invalid" warnings
- This is expected for optional secrets
- The workflow handles missing secrets gracefully

## Related Documentation

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [UDM Admin Account Management](../docs/runbooks/01-access-points.md)
- [T3-ETERNAL Validation Workflow](../.github/workflows/validate.yml)

---

**Last Updated:** December 5, 2025  
**Status:** ✅ Workflow is CI-ready without secrets configuration
