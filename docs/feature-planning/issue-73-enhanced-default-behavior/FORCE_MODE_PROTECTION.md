# Force Mode Protection Design

**Issue**: #73 - Enhanced Default Behavior  
**Status**: Planning  
**Priority**: High  
**Risk Level**: Critical (Data Loss Prevention)

## Overview

The `--force` option in GoProX can be destructive, especially when combined with operations like `--clean` or when used with auto-detection across multiple SD cards. This document outlines protection layers to prevent accidental data loss while maintaining the utility of force operations.

## Current Force Mode Behavior

### What `--force` Currently Does:
- Skips confirmations for individual operations
- Bypasses marker file checks (`.goprox.archived`, `.goprox.cleaned`, etc.)
- Re-processes already completed operations
- Works with auto-detection across multiple SD cards

### Current Safety Gaps:
- No explicit warning about destructive nature
- No visual indicators during force operations
- No operation-specific warnings for dangerous combinations
- No summary of what will happen before execution
- No enhanced logging for audit trails
- Allows dangerous combinations of operations with force mode
- No distinction between destructive and non-destructive force operations

## Enhanced Force Mode Restrictions

### New Force Mode Rules:

#### 1. Force Mode Scope Rules
- `--force --clean` = Force clean (standalone only, requires 'FORCE' confirmation)
- `--force --archive --clean` = Force archive, but clean uses normal safety checks
- `--force --import --clean` = Force import, but clean uses normal safety checks
- `--force --archive` = Force archive (standalone only)
- `--force --import` = Force import (standalone only)
- Allowed modifiers: `--verbose`, `--debug`, `--quiet`, `--dry-run`

#### 2. Required Confirmation for Clean
- When `--force --clean` is used (standalone), user MUST type `FORCE` to proceed
- When `--force --archive --clean` or `--force --import --clean` is used, clean operations still require normal safety checks and confirmations
- No other confirmation text is accepted for standalone force clean
- This applies even with `--dry-run`

#### 3. Archive/Import Force Restrictions
- `--force` with `--archive` or `--import` still requires successful completion
- Marker files (`.goprox.archived`, `.goprox.imported`) must be created successfully
- Force mode does NOT bypass the requirement for successful archive/import completion
- Force mode only skips confirmations and re-processes already completed operations
- When combined with `--clean`, force mode applies to archive/import but NOT to clean operations

#### 4. Operation Classification
**Processing Operations (Major)**:
- `--archive` - Archive media files
- `--import` - Import media files  
- `--process` - Process media files
- `--clean` - Clean SD cards

**Modifier Operations (Minor)**:
- `--verbose` - Increase output detail
- `--debug` - Enable debug logging
- `--quiet` - Reduce output detail
- `--dry-run` - Show what would happen
- `--force` - Skip confirmations and safety checks

## Proposed Protection Layers

### 1. Enhanced Force Confirmation

**Goal**: Make users explicitly acknowledge the destructive nature of force mode

**Implementation**:
```bash
# For standalone clean operations
⚠️  WARNING: --force --clean is destructive and will:
   • Remove media files from ALL detected SD cards
   • Skip archive/import safety requirements
   • Bypass all user confirmations
   • Potentially cause permanent data loss
   
   Type 'FORCE' to proceed with this destructive operation:

# For archive/import operations
⚠️  WARNING: --force with --archive/--import will:
   • Skip individual confirmations
   • Re-process already completed operations
   • Still require successful completion and marker file creation
   
   Type 'FORCE' to proceed:
```

**Triggers**:
- `--force --clean` (standalone) - Requires 'FORCE' confirmation
- `--force --archive` or `--force --import` - Requires 'FORCE' confirmation
- Invalid combinations - Show error and exit

### 2. Force Mode Visual Indicators

**Goal**: Provide clear visual feedback when force mode is active

**Implementation**:
```bash
🚨 FORCE MODE ACTIVE - Safety checks disabled

Found GoPro SD card: HERO10-2442
  🚨 FORCE: Will re-archive despite existing marker
  🚨 FORCE: Will re-clean despite safety requirements
```

**Visual Elements**:
- `🚨 FORCE MODE ACTIVE` header when force is enabled
- `🚨 FORCE:` prefix for force-specific actions
- Different color coding (red/yellow) for force operations

### 3. Operation-Specific Force Warnings

**Goal**: Provide targeted warnings based on operation combinations

**Examples**:

#### Standalone Clean + Force (Only Allowed Combination)
```bash
⚠️  DESTRUCTIVE OPERATION: --clean --force will:
   • Remove media files from ALL detected SD cards
   • Skip archive/import safety requirements
   • Bypass all user confirmations
   • Potentially cause permanent data loss
   
   Type 'FORCE' to proceed with this destructive operation
```

#### Archive + Force (Restricted)
```bash
⚠️  ARCHIVE OPERATION: --archive --force will:
   • Skip individual confirmations
   • Re-process already completed archives
   • Still require successful completion and marker file creation
   
   Type 'FORCE' to proceed
```

#### Import + Force (Restricted)
```bash
⚠️  IMPORT OPERATION: --import --force will:
   • Skip individual confirmations
   • Re-process already completed imports
   • Still require successful completion and marker file creation
   
   Type 'FORCE' to proceed
```

#### Combined Operations (Force Scope Limited)
```bash
⚠️  COMBINED OPERATION: --force --archive --clean will:
   • Force archive operations (skip confirmations, re-process completed)
   • Clean operations use normal safety checks (archive markers required)
   • Archive operations: FORCE MODE
   • Clean operations: NORMAL MODE
   
   Type 'FORCE' to proceed with archive operations
```

#### Invalid Combinations (Blocked)
```bash
❌ ERROR: Invalid force mode combination
   --force --clean cannot be combined with --process
   
   Allowed combinations:
   • --force --clean (standalone only, requires 'FORCE' confirmation)
   • --force --archive (standalone only)
   • --force --import (standalone only)
   • --force --archive --clean (force archive, normal clean)
   • --force --import --clean (force import, normal clean)
   
   Modifiers allowed: --verbose, --debug, --quiet, --dry-run
```

### 4. Force Mode Summary

**Goal**: Show users exactly what will happen before execution

**Implementation**:
```bash
# For standalone clean operations
📋 FORCE CLEAN SUMMARY:
   Cards detected: 3
   Operation: clean (standalone)
   Safety checks: DISABLED
   Archive requirements: BYPASSED
   Confirmations: SKIPPED
   Estimated time: 2-5 minutes
   
   Cards to clean:
   • HERO10-2442 (clean only)
   • HERO11-8909 (clean only)
   • HERO9-9650 (clean only)
   
   Type 'FORCE' to proceed with destructive clean operation

# For archive/import operations
📋 FORCE ARCHIVE SUMMARY:
   Cards detected: 2
   Operation: archive (standalone)
   Safety checks: PARTIAL (marker files still required)
   Confirmations: SKIPPED
   Re-process: ENABLED
   Estimated time: 5-10 minutes
   
   Cards to archive:
   • HERO10-2442 (archive only)
   • HERO11-8909 (archive only)
   
   Type 'FORCE' to proceed

# For combined operations
📋 FORCE COMBINED SUMMARY:
   Cards detected: 2
   Operations: archive (force) + clean (normal)
   Archive mode: FORCE (skip confirmations, re-process)
   Clean mode: NORMAL (safety checks required)
   Archive confirmations: SKIPPED
   Clean confirmations: REQUIRED
   Estimated time: 8-15 minutes
   
   Cards to process:
   • HERO10-2442 (archive: force, clean: normal)
   • HERO11-8909 (archive: force, clean: normal)
   
   Type 'FORCE' to proceed with archive operations
```

### 5. Enhanced Force Mode Logging

**Goal**: Provide audit trail for force operations

**Implementation**:
```bash
[FORCE] Force mode activated
[FORCE] Skipping safety check: archive marker exists on HERO10-2442
[FORCE] Bypassing user confirmation for HERO10-2442
[FORCE] Re-processing already completed operation: archive
[FORCE] Skipping safety check: import marker required for clean
[FORCE] Bypassing user confirmation for HERO10-2442 clean
```

### 6. Dry-Run Protection (Optional)

**Goal**: Require dry-run before destructive force operations

**Implementation**:
```bash
# For destructive operations, require dry-run first
./goprox --clean --force --dry-run  # Required first
./goprox --clean --force            # Only after dry-run

# Or provide option to skip dry-run requirement
./goprox --clean --force --no-dry-run-protection
```

## Implementation Priority

### Phase 1 (High Priority)
1. Enhanced force confirmation with explicit warnings
2. Force mode visual indicators
3. Basic force mode logging

### Phase 2 (Medium Priority)
4. Operation-specific force warnings
5. Force mode summary
6. Enhanced logging with audit trail

### Phase 3 (Optional)
7. Dry-run protection for destructive operations
8. Advanced force mode analytics

## Technical Implementation

### New Functions Needed:
- `_validate_force_combination()` - Check if force combination is valid
- `_show_force_warning()` - Display force mode warnings
- `_confirm_force_operation()` - Enhanced force confirmation (requires 'FORCE')
- `_show_force_summary()` - Display operation summary
- `_log_force_action()` - Enhanced force logging
- `_check_force_restrictions()` - Validate archive/import completion requirements
- `_determine_force_scope()` - Determine which operations are in force mode vs normal mode
- `_apply_force_mode()` - Apply force mode to specific operations while preserving normal mode for others

### Configuration Options:
- `FORCE_CONFIRMATION_LEVEL` - Strictness of confirmation
- `FORCE_DRY_RUN_REQUIRED` - Require dry-run for destructive ops
- `FORCE_LOGGING_LEVEL` - Detail level for force logging

### Environment Variables:
- `GOPROX_FORCE_SAFETY` - Override force safety (for automation)
- `GOPROX_FORCE_CONFIRM` - Auto-confirm force operations (for CI/CD)

## Testing Strategy

### Test Cases:
1. **Valid force combinations** - Test standalone clean, archive, import with force
2. **Combined operations** - Test force archive + normal clean, force import + normal clean
3. **Invalid force combinations** - Test forbidden combinations (clean+process+force)
4. **Force confirmation** - Verify 'FORCE' typing requirement for standalone clean
5. **Force scope isolation** - Test that force mode doesn't affect clean operations in combined mode
6. **Archive/import restrictions** - Test that marker files are still required for clean operations
7. **Visual indicators** - Verify force mode is clearly indicated for each operation type
8. **Logging verification** - Ensure audit trail is created for force vs normal operations
9. **Safety override** - Test environment variable overrides
10. **Dry-run integration** - Test with existing dry-run functionality

### Safety Tests:
1. **Invalid combination blocking** - Ensure forbidden combinations are rejected
2. **Force confirmation requirement** - Test that 'FORCE' typing is mandatory for standalone clean
3. **Force scope isolation** - Test that clean operations maintain normal safety in combined mode
4. **Archive/import completion** - Verify marker files are still required for clean operations
5. **Multi-card operations** - Test with multiple SD cards
6. **Operation mode separation** - Test that force mode only applies to intended operations

## Success Metrics

- **Zero accidental data loss** from force operations
- **Clear user understanding** of force mode implications
- **Comprehensive audit trail** for all force operations
- **User feedback** indicating confidence in force mode safety

## Future Enhancements

- **Force mode analytics** - Track force operation usage
- **Smart force suggestions** - Suggest safer alternatives
- **Force mode profiles** - Pre-configured force operation sets
- **Integration with backup systems** - Automatic backup before force operations

## Related Issues

- #73 - Enhanced Default Behavior (parent issue)
- #65 - Firmware Automation (force mode for firmware updates)
- #69 - Enhanced SD Card Management (force mode for card operations)

---

**Last Updated**: 2025-07-04  
**Status**: Planning Phase  
**Next Steps**: Implement Phase 1 protection layers 