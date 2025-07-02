# GoProX Configuration Strategy Summary

## Current State: Dual Configuration Systems

### Legacy System (`~/.goprox`)
- **Format:** Shell variables
- **Location:** User home directory
- **Scope:** Core functionality (library, source, copyright, etc.)
- **Loading:** Direct `source` command

### New System (`config/goprox-settings.yaml`)
- **Format:** YAML
- **Location:** Project directory
- **Scope:** Enhanced features (SD naming, behavior, logging, etc.)
- **Loading:** `yq` parser

## Problems Identified

1. **Dual Systems:** Confusing for users, no integration
2. **Location Inconsistency:** User vs project configs
3. **Format Inconsistency:** Shell vs YAML, different loading
4. **Feature Fragmentation:** Core and enhanced features separated
5. **No Migration Path:** Users must maintain both configs

## Proposed Solution: Unified Configuration

### New Location: `~/.config/goprox/config.yaml`
- Follows XDG Base Directory Specification
- User-specific configuration
- Single source of truth for all settings

### Unified Structure
```yaml
# Core Configuration (migrated from legacy)
core:
  source: "."
  library:
    primary: "~/goprox"
    libraries:
      - name: "primary"
        path: "~/goprox"
        auto_import: true
      - name: "archive"
        path: "~/goprox-archive"
        auto_import: false
  copyright: "Oliver Ratzesberger"
  geonames_account: "goprox"
  mount_options: ["--archive", "--import", "--clean", "--firmware"]

# Enhanced Features (from new system)
enhanced_behavior:
  auto_execute: false
  default_confirm: false
  library_selection:
    auto_select: true
    default_library: "primary"
    rules:
      - condition: "file_count > 100"
        library: "archive"

sd_card_naming:
  auto_rename: true
  format: "{camera_type}-{serial_short}"
  clean_camera_type: true
  remove_words: ["Black", "White", "Silver"]

logging:
  level: "info"
  file_logging: true
  log_file: "~/.cache/goprox/logs/goprox.log"

firmware:
  auto_check: true
  auto_update: false
  confirm_updates: true
```

## Migration Strategy

### Phase 1: Migration Tool
- Create `scripts/maintenance/migrate-config.zsh`
- Parse legacy config and generate YAML
- Create backup of legacy config
- Validate new configuration

### Phase 2: Backward Compatibility
- Try new config first (`~/.config/goprox/config.yaml`)
- Fall back to legacy config (`~/.goprox`)
- Use defaults if neither exists
- Maintain compatibility during transition

### Phase 3: Enhanced Integration
- Enhanced default behavior uses unified config
- Multi-library support for complex workflows
- SD card naming integrated with core settings
- All features leverage unified configuration

## Implementation Benefits

### For Users
- **Single Config File:** All settings in one place
- **Better Organization:** Hierarchical structure
- **Multiple Libraries:** Support for complex workflows
- **Easy Migration:** Automated transition from legacy

### For Developers
- **Unified Interface:** Single config loading mechanism
- **Type Safety:** YAML validation and schema
- **Extensibility:** Easy to add new options
- **Testing:** Consistent configuration for tests

### For System
- **Performance:** Efficient YAML parsing
- **Reliability:** Validation and error handling
- **Standards Compliance:** XDG Base Directory spec
- **Scalability:** Support for complex configurations

## Next Steps

1. **Create Migration Tool** (`scripts/maintenance/migrate-config.zsh`)
2. **Enhance Config Module** (`scripts/core/config.zsh`)
3. **Update Enhanced Behavior** to use unified config
4. **Modify Main Script** for unified loading
5. **Add Documentation** and migration guide

## Key Advantages

- **Eliminates Confusion:** Single configuration system
- **Enables Multi-Library:** Support for complex workflows
- **Future-Proof:** Easy to extend with new features
- **User-Friendly:** Clear migration path from legacy system
- **Developer-Friendly:** Unified interface and validation 