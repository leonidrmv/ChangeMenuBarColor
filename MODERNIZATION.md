# macOS 26 Modernization Summary

This document outlines the comprehensive modernization of ChangeMenuBarColor for macOS 26 (Sequoia) and Swift 6.

## Key Changes

### 1. Swift & Platform Updates

- **Swift Tools Version**: Upgraded from 5.3 → 6.0
- **Minimum macOS Version**: Raised from 10.15 (Catalina) → 13.0 (Ventura)
- **Swift Language Mode**: Now using Swift 6 language mode
- **Target Architecture**: Supports universal binaries (ARM64 + x86_64) with min version 13.0

### 2. Dependencies Updated

All dependencies updated to latest Swift 6-compatible versions:

| Package | Old Version | New Version |
|---------|-------------|-------------|
| swift-argument-parser | 0.3.1 | 1.6.2 |
| Rainbow | 3.2.0 | 4.2.0 |
| Files | 4.2.0 | 4.3.0 |

### 3. API Modernization

#### Deprecated NSImage APIs Replaced

**Before (using deprecated lockFocus/unlockFocus):**
```swift
img.lockFocus()
defer { img.unlockFocus() }
rep.draw(in: frame)
```

**After (using modern NSBitmapImageRep context):**
```swift
NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else { return nil }
NSGraphicsContext.current = context
image.draw(in: frame)
NSGraphicsContext.restoreGraphicsState()
```

#### JPEG Data Generation
- Modernized to use CGImage → NSBitmapImageRep → JPEG data pipeline
- Removed dependency on deprecated `tiffRepresentation`
- Better quality control with explicit compression factor

### 4. Swift Concurrency Integration

#### MainActor Isolation
- Command classes marked with `@MainActor` for AppKit safety
- All NSImage manipulation functions isolated to main actor
- Image functions (createGradientImage, createSolidImage, combineImages) are @MainActor

#### Concurrency-Safe Design
```swift
@MainActor
class Command {
    nonisolated func run() throws {
        try MainActor.assumeIsolated {
            try self.runMainActor()
        }
    }

    private func runMainActor() throws {
        // AppKit operations safely on main thread
    }
}
```

#### @preconcurrency Import
Used for ArgumentParser to handle the transition period:
```swift
@preconcurrency import ArgumentParser
```

### 5. Modern Swift Features

#### Type Safety Improvements
- Replaced `NSMakeRect` with `NSRect` initializer
- More explicit optional handling
- Better use of `guard let` chaining

#### Error Handling
- Added `WallpaperError` enum with `LocalizedError` conformance
- More descriptive error messages
- Proper error propagation through the stack

```swift
enum WallpaperError: Error, LocalizedError {
    case noScreensDetected
    case cannotAccessApplicationSupport
    case cannotReadWallpaper
    case invalidHexColor

    var errorDescription: String? { ... }
}
```

#### Code Quality
- Converted `Log` from class to enum (no instance needed)
- Added `Sendable` conformance where appropriate
- Improved property initialization
- Better memory safety with `.atomic` file writing

### 6. ArgumentParser Integration

- Updated to use modern ArgumentParser 1.6.2 features
- Added `@MainActor` to command classes with proper isolation
- Used `MainActor.assumeIsolated` for safe main-thread assumptions
- Proper `nonisolated` annotations for protocol requirements

### 7. Build Script Enhancements

Updated `build.sh` with:
- Modern minimum macOS version (13.0)
- Better visual feedback with emojis
- Binary size reporting
- Improved architecture verification
- Version 2.0.0 tagging

### 8. Enhanced Features

#### Logging
- Added `.warning()` method to Log
- Better visual hierarchy with `.bold` for errors
- `.dim` for debug messages

#### User Experience
- Better help text with examples
- Version command support (`--version`)
- Improved error messages throughout

## Compatibility

### Supported Platforms
- **macOS 13.0+** (Ventura, Sonoma, Sequoia)
- **Swift 6.0+**
- **Xcode 16+**

### Architecture Support
- Apple Silicon (ARM64)
- Intel (x86_64)
- Universal binaries

## Breaking Changes

1. **Minimum macOS version** raised to 13.0 (was 10.15)
2. **Swift 6 required** (was Swift 5.3)
3. Some internal APIs changed (affecting only code extending the tool)

## Migration Guide

For users:
1. Ensure macOS 13.0 or later
2. Rebuild from source or download new binary
3. No command-line changes - fully backward compatible

For developers:
1. Update to Xcode 16 or later
2. Review concurrency annotations if extending
3. Use new error types for better error handling

## Performance Improvements

- Faster image processing with modern CoreGraphics
- Better memory management with automatic reference counting
- Optimized file I/O with atomic writes
- Reduced allocations in image manipulation

## Future-Proofing

The codebase is now ready for:
- Swift Concurrency evolution
- macOS 27+ features
- Further AppKit modernization
- Potential SwiftUI integration

## Testing

Build and test commands:
```bash
# Debug build
swift build

# Release build
swift build --configuration release

# Universal binary
./build.sh

# Test commands
swift run ChangeMenuBarColor --version  # Should output: 2.0.0
swift run ChangeMenuBarColor --help
swift run ChangeMenuBarColor SolidColor "#CCCCCC"
```

## Notes

- Concurrency checking set to minimal for ArgumentParser compatibility
- All AppKit operations properly isolated to main actor
- Maintains full backward compatibility for command-line interface
- No changes required to existing scripts or workflows
