# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ChangeMenuBarColor is a Swift 6 command-line tool for macOS that modifies wallpapers to change the menu bar color in Big Sur and later. It works by appending a solid color or gradient rectangle to the top of a wallpaper image where the menu bar appears.

The tool creates adjusted wallpapers and saves them to `~/Library/Application Support/ChangeMenuBarColor/`, then sets them as the desktop wallpaper. Old wallpapers from previous runs are automatically cleaned up.

**Current Version**: 2.0.0 (Modernized for Swift 6 and macOS 26)

## Build & Development Commands

### Building
```bash
# Standard debug build
swift build

# Release build (single architecture)
swift build --configuration release

# Create universal binary (Intel + ARM, macOS 13.0+)
./build.sh
```

The `build.sh` script creates a universal binary in `./build/release/` and a versioned zip file in `./build/`.

### Running
```bash
# Check version
swift run ChangeMenuBarColor --version  # 2.0.0

# During development
swift run ChangeMenuBarColor SolidColor "#CCCCCC"
swift run ChangeMenuBarColor Gradient "#FF0000" "#00FF00"

# After building
.build/debug/ChangeMenuBarColor SolidColor "#CCCCCC" "/path/to/wallpaper.jpg"
.build/debug/ChangeMenuBarColor Gradient "#FF0000" "#00FF00" --all-displays
```

### Dependencies
The project uses Swift Package Manager with three dependencies (all Swift 6 compatible):
- `swift-argument-parser` (1.6.2+) - Command-line parsing
- `Rainbow` (4.2.0+) - Terminal color output
- `Files` (4.3.0+) - File system operations

To update dependencies: `swift package update`

### Requirements
- **macOS 13.0+ (Ventura, Sonoma, Sequoia)**
- **Swift 6.0+**
- **Xcode 16+**

## Architecture

### Command Pattern Structure
The tool uses ArgumentParser's subcommand architecture with a shared abstract base class:

1. **ChangeMenuBarColor.swift** - Entry point defining subcommands (SolidColor, Gradient)
2. **Command.swift** (abstract base) - Implements the main workflow:
   - `run()` orchestrates the entire process for each screen
   - `loadWallpaperImage()` loads existing wallpaper or uses provided path
   - `setWallpaper()` saves generated wallpaper to Application Support and applies it
   - Subclasses override `createWallpaper(screen:)` and `useAllDisplays`

3. **SolidColor.swift** & **Gradient.swift** - Concrete command implementations that:
   - Parse command-line arguments
   - Create color/gradient rectangles matching menu bar dimensions
   - Combine rectangles with wallpaper

### Image Processing Pipeline
The core image manipulation flow in ImageFunctions.swift (all @MainActor isolated):

1. Load original wallpaper via `getOriginalWallpaper()` or from provided path
2. Crop/resize wallpaper to exact screen dimensions using modern NSBitmapImageRep
3. Create menu bar sized rectangle (solid or gradient) using CoreGraphics context
4. Combine images with `combineImages()` - draws wallpaper then overlays menu bar portion at top

Menu bar height is obtained from `NSScreen.menuBarHeight` extension. For multi-display setups, the process runs independently for each screen.

**Modern Approach**: All image manipulation uses `NSBitmapImageRep` with `NSGraphicsContext` instead of deprecated `lockFocus()`/`unlockFocus()` APIs.

### Key Extensions
- **NSColor+HEX.swift** - Parse hex color strings like "#FF0000"
- **NSImage+Extensions.swift** - Modern image cropping, resizing, and JPEG data export (no lockFocus)
- **NSScreen+Extensions.swift** - Menu bar height detection and screen utilities
- **ImageFunctions.swift** - @MainActor isolated image generation functions
- **Log.swift** - Sendable enum for colored console output using Rainbow

## Important Constraints

### Menu Bar Detection (Critical for macOS 26)

The utility uses **sophisticated multi-method detection** for menu bar sizing:

1. **Safe Area Insets** (macOS 12+) - Primary method for notch detection
2. **Frame Calculation** - Compares full frame vs visible frame
3. **Resolution Matching** - Known notched display resolutions (3024x1964, 3456x2234)
4. **Height Heuristics** - Infers notch from large menu bars (>28pt)

**Supported Display Types:**
- Standard displays: 24pt (48px @2x)
- MacBook Pro 14"/16" with notch: 30-32pt (60-64px @2x)
- External displays: Auto-detected

**Critical Requirement**: **"Automatically hide and show the menu bar"** must be disabled in System Settings > Desktop & Dock. When enabled, frame calculations fail.

**Diagnostic Tool**: Use `ChangeMenuBarColor Diagnostic` to verify display detection and troubleshoot issues.

### Wallpaper Formats
- Dynamic wallpapers are not supported - they get converted to static .jpg
- Original wallpapers are accessed directly from file when possible via `getOriginalWallpaper()`
- Final output is always JPEG format for compatibility

### Image Quality
Recent improvements in ImageFunctions.swift:765155c use `NSBitmapImageRep` with high-quality settings and proper scale factor calculations to avoid quality degradation in generated wallpapers.

## macOS Version Support

- **Minimum: macOS 13.0 (Ventura)** - Hard requirement due to Swift 6 and modern APIs
- **Target: macOS 11+ (Big Sur and later)** - Where menu bar behavior is consistent
- **Best Experience: macOS 14+ (Sonoma, Sequoia)** - Full Swift 6 concurrency support

**Note**: Dropped Catalina support (was 10.15) in v2.0.0 modernization.

## Swift Concurrency Notes

- Command classes are `@MainActor` isolated for AppKit safety
- Image manipulation functions are main-actor isolated
- `MainActor.assumeIsolated` used in `run()` method (safe because ArgumentParser always runs on main thread)
- Strict concurrency checking set to minimal for ArgumentParser compatibility
- Uses `@preconcurrency import ArgumentParser` during transition period

## File Locations

Generated wallpapers: `~/Library/Application Support/ChangeMenuBarColor/wallpaper-screen-adjusted-<UUID>.jpg`

Old wallpapers are automatically deleted after successfully setting a new one using atomic file operations.
