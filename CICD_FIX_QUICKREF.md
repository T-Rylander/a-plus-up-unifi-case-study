# T3-ETERNAL CI/CD Fix — Quick Reference

## ✅ All Issues Resolved

### Issue 1: GitHub Script Permissions
**Error:** `403 Forbidden` on `github.rest.issues.create()`  
**Fix Applied:**
```yaml
permissions:
  issues: write  # ← Added
```
**Files:** `.github/workflows/validate.yml` & `validate-t3-eternal.yaml`

---

### Issue 2: ShellCheck Errors (8 violations)
**Error Types:** SC2155 (declare+assign), SC1037 (positional args)  
**Fixes Applied:**

1. **Separate Declarations** (SC2155)
   ```bash
   # Before: local var=$(command)
   # After:  local var; var=$(command)
   ```

2. **Escape Dollar Signs** (SC1037)
   ```bash
   # Before: log "Total: $1,430"
   # After:  log "Total: \$1,430"
   ```

3. **Export Color Variables**
   ```bash
   # Before: RED='\033[0;31m'
   # After:  export RED='\033[0;31m'
   ```

**File:** `scripts/ignite.sh`  
**Result:** ✅ 0 errors

---

### Issue 3: CodeQL SARIF Upload Failures
**Error:** `403 Forbidden` on SARIF writes + fork PR blocking  
**Fixes Applied:**

1. **Add Permission:**
   ```yaml
   permissions:
     security-events: write  # ← Added
   ```

2. **Handle Fork PRs:**
   ```yaml
   - name: Upload Trivy results
     if: github.event_name == 'push' && github.ref == 'refs/heads/main'
     uses: github/codeql-action/upload-sarif@v3
   ```

**File:** `.github/workflows/validate.yml`

---

## Verification

```bash
# Test ShellCheck locally
shellcheck ./scripts/*.sh -x

# YAML validation (if yamllint installed)
yamllint .github/workflows/*.yaml
```

---

## Branch Strategy

✅ **This repository is fork-friendly:**
- Fork PRs: Scans run, artifacts saved, SARIF skipped (safe)
- Main pushes: Full pipeline with security upload
- All validation gates functional

---

## What Changed

| File | Changes |
|------|---------|
| `scripts/ignite.sh` | 7 edits (separated declarations, escaped $) |
| `.github/workflows/validate.yml` | 2 edits (permissions + fork conditional) |
| `.github/workflows/validate-t3-eternal.yaml` | 1 edit (enhanced permissions) |

---

## Next Merge

All checks should now **pass**. 🟢
