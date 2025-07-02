# GoProX Hook System Developer Guide

## Overview

The GoProX project uses a consolidated Git hook system that automatically configures itself when users clone the repository. This guide covers how the system works, how to test it, and how to troubleshoot issues.

## System Architecture

### Repository-Tracked Hooks
- **Location:** `.githooks/` directory (version controlled)
- **Configuration:** `core.hooksPath` set to `.githooks`
- **Auto-Setup:** Hooks configure themselves automatically on clone/merge

### Hook Types
- **`commit-msg`:** Validates commit messages require GitHub issue references
- **`pre-commit`:** Runs content validation (YAML linting, logger usage, etc.)
- **`post-commit`:** Provides user feedback and tips
- **`post-checkout`:** Auto-configures hooks on repository checkout
- **`post-merge`:** Auto-configures hooks on merge/pull operations

## Testing the Hook System

### Quick Verification
For fast verification that hooks are working correctly:

```bash
./scripts/testing/verify-hooks.zsh
```

**Expected Output:**
```
🔍 Quick Hook System Verification
================================
📋 Core Configuration: ✅ OK
📋 Hook Files: ✅ OK
📋 Commit Validation: ✅ OK
📋 Pre-commit Hook: ✅ OK

🎉 Hook system verification complete!
✅ All checks passed
```

### Comprehensive Health Check
For complete system health assessment:

```bash
./scripts/maintenance/check-hook-health-simple.zsh
```

**Expected Output:**
```
🏥 GoProX Hook Health Check
================================

📋 Configuration Health
---------------------------
🔍 Git hooks path configured... ✅ HEALTHY
🔍 .githooks directory exists... ✅ HEALTHY

📋 Hook File Health
----------------------
🔍 commit-msg hook exists... ✅ HEALTHY
🔍 commit-msg hook executable... ✅ HEALTHY
🔍 pre-commit hook exists... ✅ HEALTHY
🔍 pre-commit hook executable... ✅ HEALTHY
🔍 post-commit hook exists... ✅ HEALTHY
🔍 post-commit hook executable... ✅ HEALTHY
🔍 post-checkout hook exists... ✅ HEALTHY
🔍 post-checkout hook executable... ✅ HEALTHY
🔍 post-merge hook exists... ✅ HEALTHY
🔍 post-merge hook executable... ✅ HEALTHY

📋 Hook Functionality Health
-------------------------------
🔍 Commit message validation (valid)... ✅ HEALTHY
🔍 Commit message validation (invalid rejected)... ✅ HEALTHY
🔍 Pre-commit hook execution... ✅ HEALTHY

📋 Dependencies Health
-------------------------
🔍 yamllint available for YAML linting... ⚠️  WARNING
🔍 Git version compatibility... ✅ HEALTHY (Git 2.39.5)

📋 Health Summary
==================
🎉 Hook system is HEALTHY!
   • 16 checks passed
   • 1 warnings (non-critical)

✅ All critical checks passed
   • Configuration is correct
   • All hooks are present and executable
   • Validation is working
```

## Manual Testing

### Test Commit Message Validation
```bash
# Test valid commit message (should pass)
echo "test: valid commit message (refs #73)" | .githooks/commit-msg /dev/stdin

# Test invalid commit message (should fail)
echo "test: invalid commit message" | .githooks/commit-msg /dev/stdin
```

### Test Auto-Configuration
```bash
# Simulate fresh clone by unsetting hooksPath
git config --local --unset core.hooksPath

# Test auto-configuration
.githooks/post-merge

# Verify configuration was set
git config --local core.hooksPath
# Should return: .githooks
```

### Test Pre-commit Hook
```bash
# Run pre-commit hook manually
.githooks/pre-commit
```

## Troubleshooting

### Common Issues

#### Issue: Hooks not working after clone
**Symptoms:** Commit messages not validated, pre-commit checks not running

**Solution:**
```bash
# Check if hooksPath is configured
git config --local core.hooksPath

# If not set, run auto-configuration
.githooks/post-merge

# Or manually configure
git config --local core.hooksPath .githooks
```

#### Issue: Permission denied errors
**Symptoms:** `Permission denied` when running hooks

**Solution:**
```bash
# Make hooks executable
chmod +x .githooks/*

# Verify permissions
ls -la .githooks/
```

#### Issue: Commit message validation failing
**Symptoms:** Valid commit messages being rejected

**Solution:**
```bash
# Check commit message format
# Must include: (refs #n) where n is issue number
# Example: "feat: add new feature (refs #73)"

# Test validation manually
echo "test: valid message (refs #73)" | .githooks/commit-msg /dev/stdin
```

#### Issue: YAML linting warnings
**Symptoms:** Warnings about yamllint not available

**Solution:**
```bash
# Install yamllint (optional but recommended)
brew install yamllint
# or
pip3 install yamllint
```

### Health Check Failures

#### Configuration Health Failures
- **Git hooks path not configured:** Run `.githooks/post-merge`
- **`.githooks` directory missing:** Re-clone repository or restore from backup

#### Hook File Health Failures
- **Hook files missing:** Run `./scripts/maintenance/setup-hooks.zsh`
- **Hook files not executable:** Run `chmod +x .githooks/*`

#### Functionality Health Failures
- **Commit validation failing:** Check hook file permissions and content
- **Pre-commit hook errors:** Review hook script for syntax errors

## Development Workflow

### When to Run Health Checks

1. **After cloning repository:** Verify auto-configuration worked
2. **After major changes:** Ensure hooks still function correctly
3. **Before important commits:** Quick verification
4. **When troubleshooting:** Comprehensive health assessment
5. **Periodic maintenance:** Monthly health checks

### Recommended Commands

```bash
# Daily development workflow
./scripts/testing/verify-hooks.zsh          # Quick check

# After system changes
./scripts/maintenance/check-hook-health-simple.zsh  # Full health check

# If issues found
./scripts/maintenance/setup-hooks.zsh        # Repair system
```

### CI/CD Integration

For automated environments, add health checks to your CI/CD pipeline:

```yaml
# Example GitHub Actions step
- name: Verify Hook System
  run: |
    ./scripts/testing/verify-hooks.zsh
    ./scripts/maintenance/check-hook-health-simple.zsh
```

## Best Practices

### For Developers
1. **Always use issue references:** `(refs #n)` in commit messages
2. **Run health checks:** After cloning or major changes
3. **Use logger functions:** In zsh scripts for consistent logging
4. **Install yamllint:** For YAML file validation

### For Maintainers
1. **Test with fresh clones:** Verify auto-configuration works
2. **Monitor health checks:** In CI/CD pipelines
3. **Update hooks carefully:** Test thoroughly before committing
4. **Document changes:** Update this guide when modifying hooks

### For Contributors
1. **Follow commit message format:** Include issue references
2. **Run pre-commit checks:** Let hooks validate your changes
3. **Report issues:** If hooks aren't working as expected
4. **Read feedback:** Post-commit hooks provide helpful tips

## Hook System Benefits

### Automatic Setup
- **Zero manual configuration:** Hooks work immediately after clone
- **Self-healing:** Auto-configuration on merge/pull operations
- **Team consistency:** All developers get same hooks automatically

### Quality Assurance
- **Commit message validation:** Ensures issue tracking
- **Content validation:** YAML linting, logger usage checks
- **Best practices enforcement:** Consistent development standards

### Developer Experience
- **Immediate feedback:** Post-commit hooks provide helpful tips
- **Clear guidance:** Warnings about TODO/FIXME comments
- **Easy troubleshooting:** Health check tools for diagnostics

## Related Documentation

- [Hook Consolidation Test Results](../feature-planning/issue-73-enhanced-default-behavior/HOOK_CONSOLIDATION_TEST_RESULTS.md)
- [AI Instructions](../AI_INSTRUCTIONS.md)
- [Design Principles](../architecture/DESIGN_PRINCIPLES.md)
- [Contributing Guide](../CONTRIBUTING.md)

---

**Last Updated:** 2025-07-02  
**Hook System Version:** 1.0 (Consolidated)  
**Test Coverage:** 16 health checks, 100% pass rate 