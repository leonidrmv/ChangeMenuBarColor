# Menu Bar Size Detection for macOS 26

## Overview

ChangeMenuBarColor v2.0.0+ includes sophisticated menu bar size detection that properly handles:
- **Standard displays** (24pt menu bars)
- **Notched MacBook Pros** (30-32pt menu bars)
- **External displays** (various sizes)
- **Retina and non-Retina** scaling
- **Multiple display configurations**

## How Detection Works

### 1. Primary Method: Frame Calculation
```swift
let menuBarPoints = frame.height - visibleFrame.height - visibleFrame.origin.y
let menuBarPixels = menuBarPoints * backingScaleFactor
```

This calculates the actual visible menu bar space by comparing the screen's full frame with its visible frame.

### 2. Notch Detection (macOS 12+)

The tool uses multiple methods to detect displays with notches:

#### Safe Area Insets (Primary)
```swift
if #available(macOS 12.0, *) {
    let safeAreaInsets = screen.safeAreaInsets
    if safeAreaInsets.top > 0 {
        // Display has a notch
    }
}
```

#### Resolution Matching (Fallback)
Known notched display resolutions:
- 3024x1964 (14" MacBook Pro)
- 3456x2234 (16" MacBook Pro)
- 3456x2160 (16" MacBook Pro scaled)

#### Height Heuristic (Final Fallback)
If calculated menu bar > 28pt, infer notch presence.

### 3. Validation & Fallbacks

The calculated height is validated against reasonable bounds:
- **Minimum**: 20pt × scale factor
- **Maximum**: 50pt × scale factor

If validation fails, intelligent fallbacks are used:
- **Notched display**: 32pt × scale factor
- **Standard display**: 24pt × scale factor

## Menu Bar Heights by Device

| Device Type | Points | @2x Pixels | @3x Pixels |
|-------------|--------|------------|------------|
| Standard Mac | 24pt | 48px | 72px |
| MacBook Pro 14" (notch) | 30pt | 60px | N/A |
| MacBook Pro 16" (notch) | 30-32pt | 60-64px | N/A |
| External Display | 24pt | 48-72px | varies |

## Testing Your Display

Run the diagnostic command to see your display information:

```bash
swift run ChangeMenuBarColor Diagnostic
```

This will show:
- Screen resolution and backing scale
- Calculated menu bar height
- Notch detection status
- Safe area insets
- Frame and visible frame coordinates

## Common Issues & Solutions

### Issue: Menu Bar Too Small/Large

**Cause**: "Automatically hide and show the menu bar" is enabled

**Solution**:
1. Open System Settings
2. Go to Desktop & Dock
3. Disable "Automatically hide and show the menu bar"

The diagnostic command will warn you if this is enabled.

### Issue: External Display Detection

External displays are automatically detected and use standard 24pt menu bars unless they report different characteristics.

### Issue: Multiple Displays

When using `--all-displays`, each display is processed independently with its own menu bar height calculation.

## Debugging

Enable debug output to see detailed detection info:

```bash
swift run ChangeMenuBarColor SolidColor "#CCCCCC" 2>&1 | grep -A5 "Screen:"
```

You'll see:
- Frame dimensions
- Visible frame
- Backing scale factor
- Calculated menu bar height
- Notch detection results

## Implementation Details

### NSScreen Extensions

The `NSScreen+Extensions.swift` file provides:

1. **`menuBarHeight`** - Calculates menu bar height in pixels
2. **`detectNotch()`** - Multi-method notch detection
3. **`displayInfo`** - Formatted display information
4. **`size`** - Screen size in pixels (accounting for backing scale)

### Pixel-Perfect Rendering

The calculated menu bar height is used throughout the pipeline:

1. **Image Generation** (`createSolidImage`/`createGradientImage`)
   - Creates colored rectangle with exact calculated height

2. **Image Combination** (`combineImages`)
   - Uses the generated image's height (no hardcoded values)
   - Properly overlays at screen top

3. **Quality Preservation**
   - All operations in pixels
   - No rounding errors
   - Consistent across all display types

## macOS 26 (Sequoia) Specifics

macOS 26 introduces no breaking changes to menu bar sizing, but our implementation future-proofs for:

- **Dynamic Island on macOS** (if introduced)
- **Variable menu bar heights** (system-wide or per-app)
- **New display types** (folding displays, etc.)

The flexible detection system will adapt to new Apple Silicon displays automatically.

## Technical Notes

### Why Not Use Fixed Values?

Fixed values (like hardcoded 24pt) fail because:
- Notched displays use different heights
- External displays may use custom scaling
- Future macOS versions may introduce new sizes
- Stage Manager affects visible frame calculations

### Coordinate System

macOS uses bottom-left origin for screen coordinates:
- **Y=0** is at the bottom of the screen
- Menu bar is at **Y = height - menuBarHeight**
- Visible frame starts at Y > 0 when menu bar/dock present

### Backing Scale Factor

Critical for pixel-perfect rendering:
- **1.0x**: Standard displays (rare)
- **2.0x**: Most Retina displays
- **3.0x**: Some iPhone/iPad simulators

Always multiply point values by `backingScaleFactor` for pixel operations.

## Future Improvements

Possible enhancements for future versions:

1. **Notch Content Awareness**: Detect menu bar items and adjust color accordingly
2. **Dynamic Updates**: Respond to display configuration changes
3. **Custom Heights**: Allow manual override via command-line flag
4. **Profile Storage**: Remember settings per display
5. **HDR Support**: Handle extended dynamic range displays

## References

- [NSScreen Documentation](https://developer.apple.com/documentation/appkit/nsscreen)
- [Safe Area Insets (macOS 12+)](https://developer.apple.com/documentation/appkit/nsscreen/3882821-safeareainsets)
- [MacBook Pro Technical Specs](https://support.apple.com/kb/SP858)
