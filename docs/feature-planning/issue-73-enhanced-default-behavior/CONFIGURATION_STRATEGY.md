# GoProX Configuration Strategy

## Current Configuration Analysis

### Legacy Configuration System (`~/.goprox`)

**Location:** `~/.goprox` (user home directory)
**Format:** Shell script with variable assignments
**Loading:** Direct sourcing via `source $config` in main `goprox` script

**Current Structure:**
```zsh
# GoProX Configuration File
# Example configuration with all possible entries:
# source="."
# library="~/goprox"
# copyright="Your Name or Organization"
# geonamesacct="your_geonames_username"
# mountoptions=(--archive --import --clean --firmware)

source="."
library="/Users/oratzes/goprox"
copyright="Oliver Ratzesberger"
geonamesacct="goprox"
mountoptions=(--archive --import --clean --firmware)
```

**Variables Defined:**
- `source` - Source directory for media files (default: ".")
- `library` - Library directory for processed media (default: "~/goprox")
- `copyright` - Copyright information for processed files
- `geonamesacct` - GeoNames account for location data
- `mountoptions` - Array of mount event processing options

**Loading Mechanism:**
```zsh
# In main goprox script (line 1733)
if [[ -f "$config" ]]; then
  _info "Loading config file: $config"
  [[ $loglevel -le 1 ]] && tail $config
  source $config
  _validate_config
fi
```

### New YAML Configuration System (`config/goprox-settings.yaml`)

**Location:** `config/goprox-settings.yaml` (project directory)
**Format:** YAML with hierarchical structure
**Loading:** Via `yq` parser in `scripts/core/config.zsh`

**Current Structure:**
```yaml
# SD Card Naming Configuration
sd_card_naming:
  auto_rename: true
  format: "{camera_type}-{serial_short}"
  clean_camera_type: true
  remove_words: "Black"
  space_replacement: "-"
  remove_special_chars: true
  allowed_chars: "-"

# Enhanced Default Behavior Configuration
enhanced_behavior:
  auto_execute: false
  default_confirm: false
  show_details: true

# Logging Configuration
logging:
  level: "info"
  file_logging: true
  log_file: "output/goprox.log"

# Firmware Management
firmware:
  auto_check: true
  auto_update: false
  confirm_updates: true
```

**Loading Mechanism:**
```zsh
# In scripts/core/config.zsh
load_goprox_config() {
    local config_file="${1:-config/goprox-settings.yaml}"
    # Uses yq to parse YAML and export as environment variables
    # Format: GOPROX_${key//./_}
}
```

## Problems with Current System

### 1. **Dual Configuration Systems**
- Legacy shell-based config in `~/.goprox`
- New YAML-based config in project directory
- No integration between the two systems
- Confusing for users and developers

### 2. **Location Inconsistency**
- Legacy config in user home (`~/.goprox`)
- New config in project directory (`config/goprox-settings.yaml`)
- Project config not user-specific
- No per-user customization for new features

### 3. **Format Inconsistency**
- Legacy: Shell variables with basic validation
- New: YAML with complex validation but requires `yq` dependency
- Different loading mechanisms
- No unified configuration interface

### 4. **Feature Fragmentation**
- Legacy config handles core functionality (library, source, etc.)
- New config handles enhanced features (SD naming, behavior, etc.)
- No unified configuration for all features
- Enhanced features can't leverage legacy settings

### 5. **Migration Challenges**
- No migration path from legacy to new system
- Users must maintain both configs
- Risk of configuration conflicts
- No backward compatibility strategy

## Proposed Unified Configuration Strategy

### 1. **Single Configuration Location**
**New Location:** `~/.config/goprox/config.yaml`
- Follows XDG Base Directory Specification
- User-specific configuration
- Standard location for user configs
- Supports multiple users on same system

### 2. **Unified YAML Format**
**Structure:**
```yaml
# GoProX Unified Configuration
# Version: 2.0
# Last Updated: 2025-07-02

# Core Configuration (migrated from legacy)
core:
  # Source directory for media files
  source: "."
  
  # Library configuration
  library:
    # Primary library location
    primary: "~/goprox"
    
    # Multiple library support
    libraries:
      - name: "primary"
        path: "~/goprox"
        description: "Main photo library"
        auto_import: true
        auto_process: true
      - name: "archive"
        path: "~/goprox-archive"
        description: "Long-term archive"
        auto_import: false
        auto_process: false
      - name: "backup"
        path: "/Volumes/Backup/goprox"
        description: "External backup"
        auto_import: false
        auto_process: false
  
  # Copyright information
  copyright: "Oliver Ratzesberger"
  
  # GeoNames account for location data
  geonames_account: "goprox"
  
  # Mount event processing options
  mount_options:
    - "--archive"
    - "--import"
    - "--clean"
    - "--firmware"

# Enhanced Default Behavior Configuration
enhanced_behavior:
  # Enable automatic workflow execution
  auto_execute: false
  
  # Default confirmation behavior
  default_confirm: false
  
  # Show detailed analysis
  show_details: true
  
  # Library selection strategy
  library_selection:
    # Auto-select library based on content
    auto_select: true
    
    # Default library for new content
    default_library: "primary"
    
    # Library selection rules
    rules:
      - condition: "file_count > 100"
        library: "archive"
      - condition: "total_size > 10GB"
        library: "backup"

# SD Card Naming Configuration
sd_card_naming:
  # Enable automatic renaming of GoPro SD cards
  auto_rename: true
  
  # Naming format for GoPro SD cards
  format: "{camera_type}-{serial_short}"
  
  # Clean camera type by removing common words/phrases
  clean_camera_type: true
  
  # Words to remove from camera type
  remove_words:
    - "Black"
    - "White"
    - "Silver"
  
  # Replace spaces with this character
  space_replacement: "-"
  
  # Remove special characters
  remove_special_chars: true
  
  # Characters to allow (in addition to alphanumeric)
  allowed_chars: "-"

# Logging Configuration
logging:
  # Log level (debug, info, warning, error)
  level: "info"
  
  # Enable file logging
  file_logging: true
  
  # Log file path
  log_file: "~/.cache/goprox/logs/goprox.log"
  
  # Log rotation
  rotation:
    enabled: true
    max_size: "10MB"
    max_files: 5

# Firmware Management
firmware:
  # Enable automatic firmware checking
  auto_check: true
  
  # Enable automatic firmware updates
  auto_update: false
  
  # Firmware update confirmation required
  confirm_updates: true
  
  # Firmware cache directory
  cache_directory: "~/.cache/goprox/firmware"
  
  # Firmware sources
  sources:
    - name: "official"
      enabled: true
      url_pattern: "https://firmware.gopro.com/{model}/{version}"
    - name: "labs"
      enabled: true
      url_pattern: "https://gopro.com/labs/{model}/{version}"

# Processing Configuration
processing:
  # File types to process
  file_types:
    - "JPG"
    - "MP4"
    - "360"
    - "JPEG"
    - "HEIC"
  
  # Processing options
  options:
    # Add copyright information
    add_copyright: true
    
    # Repair file creation dates
    repair_dates: true
    
    # Generate thumbnails
    generate_thumbnails: true
    
    # Extract GPS data
    extract_gps: true
    
    # Add location information
    add_location: true

# Storage Configuration
storage:
  # Archive configuration
  archive:
    # Enable automatic archiving
    auto_archive: true
    
    # Archive after processing
    archive_after_process: true
    
    # Archive structure
    structure:
      - "year"
      - "month"
      - "day"
  
  # Import configuration
  import:
    # Import strategy
    strategy: "copy"  # copy, move, link
    
    # Preserve original structure
    preserve_structure: true
    
    # Create import markers
    create_markers: true
  
  # Clean configuration
  clean:
    # Enable automatic cleaning
    auto_clean: true
    
    # Clean after import
    clean_after_import: true
    
    # Preserve metadata files
    preserve_metadata: true
```

### 3. **Migration Strategy**

#### Phase 1: Configuration Migration Tool
```zsh
# scripts/maintenance/migrate-config.zsh
#!/bin/zsh

migrate_legacy_config() {
    local legacy_config="$HOME/.goprox"
    local new_config="$HOME/.config/goprox/config.yaml"
    
    if [[ ! -f "$legacy_config" ]]; then
        echo "No legacy configuration found at $legacy_config"
        return 0
    fi
    
    echo "Migrating legacy configuration to new format..."
    
    # Create new config directory
    mkdir -p "$(dirname "$new_config")"
    
    # Parse legacy config and generate YAML
    generate_yaml_config "$legacy_config" "$new_config"
    
    # Create backup of legacy config
    cp "$legacy_config" "$legacy_config.backup.$(date +%Y%m%d)"
    
    echo "Migration completed. Legacy config backed up."
    echo "New config location: $new_config"
}
```

#### Phase 2: Backward Compatibility Layer
```zsh
# scripts/core/config-compat.zsh
load_config_with_fallback() {
    local new_config="$HOME/.config/goprox/config.yaml"
    local legacy_config="$HOME/.goprox"
    
    # Try new config first
    if [[ -f "$new_config" ]]; then
        load_yaml_config "$new_config"
        return 0
    fi
    
    # Fall back to legacy config
    if [[ -f "$legacy_config" ]]; then
        load_legacy_config "$legacy_config"
        return 0
    fi
    
    # Use defaults
    load_default_config
}
```

### 4. **Enhanced Default Behavior Integration**

#### Library Selection Logic
```yaml
# Enhanced behavior uses unified config for library selection
enhanced_behavior:
  library_selection:
    auto_select: true
    default_library: "primary"
    rules:
      - condition: "file_count > 100"
        library: "archive"
      - condition: "total_size > 10GB"
        library: "backup"
      - condition: "camera_type == 'MAX'"
        library: "360-content"
```

#### SD Card Naming Integration
```yaml
# SD naming uses unified config for all naming preferences
sd_card_naming:
  auto_rename: true
  format: "{camera_type}-{serial_short}"
  # All naming preferences in one place
```

### 5. **Implementation Plan**

#### Step 1: Create Migration Tool
- [ ] Create `scripts/maintenance/migrate-config.zsh`
- [ ] Implement legacy config parsing
- [ ] Implement YAML generation
- [ ] Add validation and backup functionality

#### Step 2: Update Configuration Module
- [ ] Enhance `scripts/core/config.zsh`
- [ ] Add unified config loading
- [ ] Implement backward compatibility
- [ ] Add configuration validation

#### Step 3: Update Enhanced Default Behavior
- [ ] Modify `scripts/core/enhanced-default-behavior.zsh`
- [ ] Use unified config for library selection
- [ ] Integrate with SD card naming
- [ ] Add multi-library support

#### Step 4: Update Main Script
- [ ] Modify main `goprox` script
- [ ] Use unified config loading
- [ ] Maintain backward compatibility
- [ ] Add config migration prompts

#### Step 5: Documentation and Testing
- [ ] Update documentation
- [ ] Create configuration examples
- [ ] Add comprehensive tests
- [ ] Create migration guide

### 6. **Benefits of New Strategy**

#### For Users
- **Single Configuration File:** All settings in one place
- **Better Organization:** Hierarchical structure
- **Multiple Libraries:** Support for complex workflows
- **Enhanced Features:** All new features use unified config
- **Migration Path:** Easy transition from legacy system

#### For Developers
- **Unified Interface:** Single config loading mechanism
- **Type Safety:** YAML validation and schema
- **Extensibility:** Easy to add new configuration options
- **Testing:** Consistent configuration for tests
- **Documentation:** Self-documenting YAML format

#### For System
- **Performance:** Efficient YAML parsing
- **Reliability:** Validation and error handling
- **Maintainability:** Clear separation of concerns
- **Scalability:** Support for complex configurations
- **Standards Compliance:** Follows XDG Base Directory spec

### 7. **Configuration Validation**

#### Schema Validation
```yaml
# config-schema.yaml
type: object
properties:
  core:
    type: object
    required: ["library"]
    properties:
      library:
        type: object
        required: ["primary"]
        properties:
          primary:
            type: string
          libraries:
            type: array
            items:
              type: object
              required: ["name", "path"]
              properties:
                name:
                  type: string
                path:
                  type: string
                description:
                  type: string
                auto_import:
                  type: boolean
                auto_process:
                  type: boolean
```

#### Runtime Validation
```zsh
validate_config() {
    local config_file="$1"
    
    # Validate YAML syntax
    if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
        log_error "Invalid YAML syntax in configuration file"
        return 1
    fi
    
    # Validate required fields
    validate_required_fields "$config_file"
    
    # Validate paths
    validate_paths "$config_file"
    
    # Validate library structure
    validate_library_structure "$config_file"
}
```

This unified configuration strategy provides a clear path forward for GoProX configuration management, addressing all current issues while providing a solid foundation for future enhancements. 