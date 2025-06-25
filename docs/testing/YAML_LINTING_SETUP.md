# YAML Linting Setup

This document describes the YAML linting setup for the GoProX project, which ensures consistent formatting and catches errors before they reach GitHub Actions.

## Overview

The project uses `yamllint` to validate YAML files, particularly GitHub Actions workflow files. This helps prevent CI/CD failures due to formatting issues.

## Components

### 1. Pre-commit Hook

**Location**: `.git/hooks/pre-commit`

**Purpose**: Automatically runs YAML linting on staged workflow files before each commit.

**Features**:
- Only checks files in `.github/workflows/` directory
- Only validates staged files (not the entire codebase)
- Provides clear error messages with specific line numbers
- Prevents commits with YAML formatting issues

**How it works**:
1. Detects staged YAML files in `.github/workflows/`
2. Runs `yamllint` on each file
3. If any issues are found, the commit is blocked
4. Provides helpful error messages and suggestions

### 2. YAML Formatting Fixer Script

**Location**: `scripts/maintenance/fix-yaml-formatting.zsh`

**Purpose**: Automatically fixes common YAML formatting issues.

**Features**:
- Removes trailing spaces
- Ensures newlines at end of files
- Creates backups before making changes
- Reports which issues were fixed and which remain

**Usage**:
```zsh
./scripts/maintenance/fix-yaml-formatting.zsh
```

### 3. YAML Lint Configuration

**Location**: `.yamllint`

**Purpose**: Defines the linting rules and standards.

**Key Rules**:
- `trailing-spaces`: No trailing spaces allowed
- `new-line-at-end-of-file`: Files must end with newline
- `quoted-strings`: String values should be quoted
- `key-ordering`: Keys should be in consistent order
- `line-length`: Lines should not exceed 120 characters

## Workflow

### For Developers

1. **Normal Development**:
   - Make changes to workflow files
   - Stage files with `git add`
   - Attempt to commit
   - If YAML issues are found, the pre-commit hook will block the commit

2. **Fixing YAML Issues**:
   ```zsh
   # Option 1: Use the automatic fixer
   ./scripts/maintenance/fix-yaml-formatting.zsh
   
   # Option 2: Fix manually and check
   yamllint -f parsable -c .yamllint .github/workflows/
   ```

3. **After Fixing**:
   - Stage the fixed files
   - Commit again (pre-commit hook will pass)

### For CI/CD

The GitHub Actions workflows include YAML linting steps that use the same configuration, ensuring consistency between local and CI environments.

## Common Issues and Fixes

### 1. Trailing Spaces
**Error**: `trailing spaces (trailing-spaces)`
**Fix**: Remove spaces at end of lines

### 2. Missing Newline
**Error**: `no new line character at the end of file (new-line-at-end-of-file)`
**Fix**: Add newline at end of file

### 3. Unquoted Strings
**Error**: `string value is not quoted with any quotes (quoted-strings)`
**Fix**: Quote string values: `value: "string"` instead of `value: string`

### 4. Key Ordering
**Error**: `wrong ordering of key "key" in mapping (key-ordering)`
**Fix**: Reorder keys according to yamllint standards

### 5. Line Length
**Error**: `line too long (X > 120 characters) (line-length)`
**Fix**: Break long lines or use YAML multi-line syntax

## Installation Requirements

### Local Development
```bash
# Install yamllint
pip install yamllint

# Verify installation
yamllint --version
```

### CI/CD Environment
The GitHub Actions workflows automatically install yamllint as part of their setup.

## Troubleshooting

### Pre-commit Hook Not Running
1. Ensure the hook is executable: `chmod +x .git/hooks/pre-commit`
2. Check that yamllint is installed: `which yamllint`
3. Verify the hook is in the correct location: `.git/hooks/pre-commit`

### YAML Fixer Script Issues
1. Ensure the script is executable: `chmod +x scripts/maintenance/fix-yaml-formatting.zsh`
2. Check that yamllint is installed
3. Review backup files (`.bak`) if the script created them

### Persistent Linting Issues
Some issues (like key ordering and unquoted strings) require manual fixing. The fixer script will report which issues remain after automatic fixes.

## Benefits

1. **Prevents CI/CD Failures**: Catches YAML issues before they reach GitHub Actions
2. **Consistent Formatting**: Ensures all workflow files follow the same standards
3. **Developer Experience**: Clear error messages help developers fix issues quickly
4. **Automation**: Automatic fixing of common issues reduces manual work
5. **Quality Assurance**: Maintains high code quality standards

## Integration with Existing Workflows

The YAML linting setup integrates seamlessly with:
- Existing pre-commit hooks (commit message validation)
- GitHub Actions CI/CD pipelines
- Development workflow
- Code review process

This ensures that YAML formatting issues are caught early and consistently across all development environments. 