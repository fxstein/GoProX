# Issue #59: FreeBSD Port

**Issue Title**: Misc: Create FreeBSD Port  
**Status**: Open  
**Assignee**: Unassigned  
**Labels**: bug, enhancement, help wanted, good first issue, further investigation

## Overview

Create a FreeBSD port for GoProX to enable installation and usage on FreeBSD systems, leveraging the existing zsh compatibility and similar Unix heritage to macOS.

## Current State Analysis

### Existing Capabilities
- zsh script compatibility
- Unix-like system support
- Basic dependency management
- Installation scripts

### Current Limitations
- No FreeBSD-specific packaging
- Large source archive (~1GB)
- Manual installation process
- No package manager integration

## Implementation Strategy

### Phase 1: Port Infrastructure (High Priority)
**Estimated Effort**: 2-3 days

#### 1.1 Port Makefile Creation
```makefile
# FreeBSD port Makefile
PORTNAME=	goprox
DISTVERSION=	00.52.00
CATEGORIES=	multimedia
MAINTAINER=	joshua.michael.keyes@gmail.com
COMMENT=	Missing GoPro workflow manager for zsh
WWW=		https://github.com/fxstein/GoProX
LICENSE=	MIT

RUN_DEPENDS=	exiftool:graphics/p5-Image-ExifTool \
		jq:textproc/jq \
		zsh:shells/zsh

USES=		shebangfix
USE_GITHUB=	yes
GH_ACCOUNT=	fxstein
GH_PROJECT=	GoProX

SHEBANG_LANG=	zsh
SHEBANG_FILES=	goprox

NO_BUILD=	yes
DOCS=		README.md LICENSE

do-install:
	${MKDIR} ${STAGEDIR}${DATADIR}
	${INSTALL_SCRIPT} ${WRKSRC}/goprox ${STAGEDIR}${DATADIR}/goprox
	${LN} -fs ${DATADIR}/goprox ${STAGEDIR}${PREFIX}/bin/goprox
	${INSTALL_MAN} ${WRKSRC}/man/goprox.1 ${STAGEDIR}${PREFIX}/man/man1/
```

#### 1.2 Dependency Resolution
- Identify FreeBSD equivalents for dependencies
- Map macOS tools to FreeBSD alternatives
- Ensure compatibility with FreeBSD package system

### Phase 2: Size Optimization (High Priority)
**Estimated Effort**: 1-2 days

#### 2.1 Firmware Download Strategy
```makefile
# Exclude firmware from package
# NOTE: Firmware isn't included to keep the package size low.
#${MKDIR} ${STAGEDIR}${DATADIR}/firmware
#(cd ${WRKSRC}/firmware && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR}/firmware)
#${MKDIR} ${STAGEDIR}${DATADIR}/firmware.labs
#(cd ${WRKSRC}/firmware.labs && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR}/firmware.labs)
```

#### 2.2 On-Demand Download
- Implement firmware download on first use
- Cache firmware locally
- Provide user feedback during download

### Phase 3: Testing and Validation (Medium Priority)
**Estimated Effort**: 2-3 days

#### 3.1 FreeBSD Testing
```zsh
# Test script for FreeBSD
scripts/test/test-freebsd.zsh
```
- Test installation process
- Validate functionality
- Check dependency resolution

#### 3.2 Port Testing
- Test port building
- Validate package installation
- Check uninstallation process

## Technical Design

### Port Structure
```
/usr/ports/multimedia/goprox/
├── Makefile
├── pkg-descr
├── pkg-plist
└── files/
    ├── patch-*
    └── pkg-install
```

### Dependency Mapping
**macOS → FreeBSD**:
- `exiftool` → `graphics/p5-Image-ExifTool`
- `jq` → `textproc/jq`
- `zsh` → `shells/zsh`
- `diskutil` → `sysutils/geom`
- `launchd` → `sysutils/rc`

### Installation Process
```zsh
# FreeBSD installation workflow
1. Install port dependencies
2. Download and extract source
3. Install main script to /usr/local/share/goprox/
4. Create symlink in /usr/local/bin/
5. Install man page
6. Set up configuration directory
```

## Integration Points

### FreeBSD Package System
- Integrate with pkg package manager
- Follow FreeBSD port conventions
- Maintain port compatibility

### Existing GoProX System
- Maintain script compatibility
- Preserve functionality
- Adapt to FreeBSD environment

### User Experience
- Provide FreeBSD-specific documentation
- Handle platform differences
- Maintain consistent interface

## Success Metrics

- **Installation**: Successful port installation
- **Functionality**: 95% feature compatibility
- **Performance**: Comparable to macOS performance
- **User Adoption**: FreeBSD community acceptance

## Dependencies

- FreeBSD port system
- Existing GoProX functionality
- Platform-specific adaptations
- Community feedback

## Risk Assessment

### Low Risk
- Based on existing Unix compatibility
- Non-breaking changes
- Reversible implementation

### Medium Risk
- Platform-specific differences
- Dependency resolution
- Performance variations

### High Risk
- FreeBSD-specific issues
- Community acceptance
- Maintenance overhead

### Mitigation Strategies
- Extensive testing on FreeBSD
- Community engagement
- Clear documentation
- Fallback mechanisms

## Testing Strategy

### Port Testing
```zsh
# Test port functionality
make test
make install
make deinstall
```

### Functionality Testing
```zsh
# Test GoProX features
goprox --test
goprox --help
goprox --version
```

### Integration Testing
- Test with real SD cards
- Validate firmware operations
- Check file processing

## Example Usage

```zsh
# Install via ports
cd /usr/ports/multimedia/goprox
make install

# Install via pkg
pkg install goprox

# Basic usage
goprox --help
goprox --test
```

## Next Steps

1. **Immediate**: Create port Makefile
2. **Week 1**: Test port building
3. **Week 2**: Optimize package size
4. **Week 3**: Validate functionality
5. **Week 4**: Submit to FreeBSD ports

## Related Issues

- #60: Firmware URL-based fetch (reduces package size)
- #66: Repository cleanup (organization)
- #2: Windows support (cross-platform)
- #4: Automatic imports (FreeBSD adaptation) 