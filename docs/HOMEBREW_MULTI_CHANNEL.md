# GoProX Homebrew Multi-Channel System

GoProX supports a sophisticated multi-channel Homebrew system that provides different installation options for various user needs, from stable production releases to cutting-edge development builds.

## Overview

The multi-channel system allows users to choose the appropriate version of GoProX based on their needs:
- **Stability**: Official releases for production use
- **Testing**: Beta releases for early feature access
- **Compatibility**: Versioned releases for specific version requirements
- **Development**: Latest builds for developers and early adopters

## Channel Types

### 1. Official Channel (`goprox`)

**Installation:**
```zsh
brew install fxstein/fxstein/goprox
```

**Formula:** `goprox.rb` with class `Goprox`

**Purpose:** Latest stable release for general users and production environments

**Updates:** On official releases from main branch

**Use Case:** Recommended for most users who want stable, tested releases

### 2. Beta Channel (`goprox@beta`)

**Installation:**
```zsh
brew install fxstein/fxstein/goprox@beta
```

**Formula:** `goprox@beta.rb` with class `GoproxBeta`

**Purpose:** Pre-release testing for beta testers and advanced users

**Updates:** On beta releases from release branches

**Use Case:** For users who want to test new features before they're officially released

### 3. Versioned Channels (`goprox@X.XX`)

**Installation:**
```zsh
brew install fxstein/fxstein/goprox@1.50
```

**Formula:** `goprox@1.50.rb` with class `GoproxAT150`

**Purpose:** Specific version installation for compatibility and rollback scenarios

**Updates:** Created for each official release, maintained indefinitely

**Use Case:** For users who need a specific version for compatibility or want to rollback to a previous version

### 4. Development Channel (`goprox@latest`)

**Installation:**
```zsh
brew install fxstein/fxstein/goprox@latest
```

**Formula:** `goprox@latest.rb` with class `GoproxLatest`

**Purpose:** Latest development builds for developers and early adopters

**Updates:** On every develop branch push

**Use Case:** For developers and users who want the absolute latest features, even if they're not fully tested

## Installation and Management

### Adding the Tap

First, add the fxstein tap to your Homebrew installation:

```zsh
brew tap fxstein/fxstein
```

### Installing Different Channels

```zsh
# Official stable release (recommended)
brew install fxstein/fxstein/goprox

# Beta release for testing
brew install fxstein/fxstein/goprox@beta

# Specific version (e.g., 1.50)
brew install fxstein/fxstein/goprox@1.50

# Latest development build
brew install fxstein/fxstein/goprox@latest
```

### Upgrading

To upgrade to the latest version in your chosen channel:

```zsh
# Upgrade default channel
brew upgrade goprox

# Upgrade specific channels
brew upgrade goprox@beta
brew upgrade goprox@1.50
brew upgrade goprox@latest
```

### Switching Between Channels

To switch from one channel to another:

```zsh
# Uninstall current version
brew uninstall goprox

# Install desired channel
brew install fxstein/fxstein/goprox@beta
```

### Checking Installed Versions

```zsh
# Check which version is installed
goprox --version

# List all installed formulae
brew list | grep goprox
```

## Formula Naming Conventions

The system follows Homebrew's official naming conventions:

| Channel | Formula File | Class Name | Install Command |
|---------|--------------|------------|-----------------|
| Official | `goprox.rb` | `Goprox` | `brew install goprox` |
| Beta | `goprox@beta.rb` | `GoproxBeta` | `brew install goprox@beta` |
| Versioned | `goprox@1.50.rb` | `GoproxAT150` | `brew install goprox@1.50` |
| Development | `goprox@latest.rb` | `GoproxLatest` | `brew install goprox@latest` |

**Note:** For versioned formulae, the `@` symbol in the filename is converted to `AT` in the class name to follow Ruby naming conventions.

## Release Process Integration

The release automation system automatically manages all channels:

### Official Releases
- Updates `goprox` (default) formula to point to the latest stable release
- Creates `goprox@X.XX` (versioned) formula for the specific version
- Both formulae point to the same release but serve different purposes

### Beta Releases
- Updates only `goprox@beta` formula when triggered from release branches
- Does not affect the official channel
- Allows testing without impacting stable users

### Development Builds
- Updates `goprox@latest` formula on every develop branch push
- Provides continuous integration for developers
- May include experimental features

## Troubleshooting

### Common Issues

**1. Formula Not Found**
```zsh
Error: No available formula with the name "goprox@beta"
```

**Solution:** Ensure you have the correct tap added:
```zsh
brew tap fxstein/fxstein
```

**2. Version Conflicts**
```zsh
Error: Cannot install goprox@1.50 because conflicting formulae are installed
```

**Solution:** Uninstall conflicting versions first:
```zsh
brew uninstall goprox
brew install fxstein/fxstein/goprox@1.50
```

**3. SHA256 Mismatch**
```zsh
Error: SHA256 mismatch
```

**Solution:** This usually indicates a network issue or temporary problem. Try:
```zsh
brew update
brew install --force fxstein/fxstein/goprox@beta
```

### Channel-Specific Issues

**Beta Channel Issues:**
- Beta releases may be less stable than official releases
- Report issues to the project's issue tracker
- Consider switching to official channel if stability is critical

**Development Channel Issues:**
- Development builds may contain experimental features
- Not recommended for production use
- May have breaking changes between builds

**Versioned Channel Issues:**
- Older versions may have known bugs or security issues
- Consider upgrading to a newer version if possible
- Check release notes for known issues

## Best Practices

### For General Users
- Use the official channel (`goprox`) for production environments
- Only use beta channel if you need to test specific features
- Avoid development channel unless you're contributing to the project

### For Beta Testers
- Use beta channel to test new features
- Report bugs and issues promptly
- Provide feedback on new features
- Be prepared for potential instability

### For Developers
- Use development channel for latest features
- Test your changes against multiple channels
- Follow the project's contribution guidelines
- Report issues with specific channel information

### For System Administrators
- Use versioned channels for reproducible deployments
- Test new versions in staging before production
- Monitor for security updates and bug fixes
- Document which channel and version is deployed

## Security Considerations

- All channels use the same source code repository
- Official releases undergo more thorough testing
- Beta and development channels may contain experimental code
- Versioned channels provide stability but may miss security updates
- Always verify the source and authenticity of installations

## Support

For issues with the multi-channel system:

1. Check this documentation for common solutions
2. Verify you're using the correct tap and channel
3. Check the project's issue tracker for known issues
4. Provide specific channel and version information when reporting issues

## Links

- [GoProX Repository](https://github.com/fxstein/GoProX)
- [Homebrew Tap Repository](https://github.com/fxstein/homebrew-fxstein)
- [Release Process Documentation](./RELEASE_PROCESS.md)
- [Contributing Guidelines](../CONTRIBUTING.md) 