# GoPro Official Firmware URL Format

## Overview
GoPro official firmware files follow a predictable URL pattern on their CDN server, making it possible to understand and potentially construct URLs for firmware versions.

## URL Format
```
https://device-firmware.gp-static.com/{DEVICE_ID}/{HASH}/{VERSION}/camera_fw/{FW_VERSION}/UPDATE.zip
```

## Pattern Components

### Base URL
- **CDN**: `https://device-firmware.gp-static.com/`

### Device ID
Each GoPro model has a unique device ID:
- **50**: HERO8 Black
- **51**: GoPro MAX
- **55**: HERO9 Black
- **57**: HERO10 Black / The Remote (older)
- **58**: HERO11 Black
- **60**: HERO11 Black Mini
- **62**: HERO12 Black
- **65**: HERO13 Black
- **66**: HERO (2024)
- **1000**: The Remote (newer)

### Hash
A unique hash identifier for each firmware version (appears to be SHA-1 or similar)

### Version
The camera firmware version in format `HXX.XX` (e.g., `H22.01`, `H19.03`)

### Firmware Version
The specific firmware version in format `XX.XX.XX` (e.g., `01.10.00`, `02.32.00`)

### File Extension
- **UPDATE.zip**: Standard firmware files
- **GP_REMOTE_FW_XX_XX_XX.bin**: Remote firmware files

## Examples

### HERO11 Black H22.01.01.10.00
```
https://device-firmware.gp-static.com/58/9eda9f71cbceda591d1563d9696df743a1200638/H22.01/camera_fw/01.10.00/UPDATE.zip
```

### GoPro MAX H19.03.02.00.00
```
https://device-firmware.gp-static.com/51/029419def60e5fdadfccfcecb69ce21ff679ddca/H19.03/camera_fw/02.00.00/UPDATE.zip
```

### HERO13 Black H24.01.02.02.00
```
https://device-firmware.gp-static.com/65/1dc286c02586da1450ee03b076349902fc44516b/H24.01/camera_fw/02.02.00/UPDATE.zip
```

## URL Pattern Analysis

### Device ID Mapping
| Model | Device ID | Example Version |
|-------|-----------|-----------------|
| HERO8 Black | 50 | HD8.01.02.50.00 |
| GoPro MAX | 51 | H19.03.02.00.00 |
| HERO9 Black | 55 | HD9.01.01.60.00 |
| HERO10 Black | 57 | H21.01.01.30.00 |
| HERO11 Black | 58 | H22.01.01.10.00 |
| HERO11 Black Mini | 60 | H22.03.02.00.00 |
| HERO12 Black | 62 | H23.01.02.32.00 |
| HERO13 Black | 65 | H24.01.02.02.00 |
| HERO (2024) | 66 | H24.03.02.20.00 |
| The Remote | 1000 | GP.REMOTE.FW.02.00.01 |

### Version Format Conversion
Convert firmware version `H22.01.01.10.00` to URL format:
- **Version**: `H22.01` (first two parts)
- **Firmware Version**: `01.10.00` (last three parts)

## Key Observations

1. **Consistent Structure**: All URLs follow the same pattern with device-specific IDs
2. **Hash-based Security**: Each firmware has a unique hash for integrity verification
3. **Version Mapping**: Clear relationship between firmware version and URL structure
4. **CDN Distribution**: Uses GoPro's static CDN for reliable delivery
5. **File Naming**: Standardized as `UPDATE.zip` for cameras, `.bin` for remotes

## Usage Notes

- **Hash Uniqueness**: Each firmware version has a unique hash that cannot be predicted
- **Device Specificity**: Device IDs are model-specific and consistent
- **Version Correlation**: URL structure directly maps to firmware version numbers
- **CDN Reliability**: Uses GoPro's official CDN for high availability

## Comparison with Labs Firmware

| Aspect | Official Firmware | Labs Firmware |
|--------|-------------------|---------------|
| Base URL | `device-firmware.gp-static.com` | `media.githubusercontent.com` |
| Device ID | Numeric (50, 58, etc.) | Model name (HERO11, MAX, etc.) |
| Hash | Unique per version | Not used |
| Version Format | `HXX.XX/camera_fw/XX.XX.XX` | `LABS_MODEL_XX_XX_XX` |
| Predictability | Hash not predictable | Fully predictable |

This pattern analysis helps understand how GoPro organizes their official firmware distribution and could be useful for firmware discovery and validation. 