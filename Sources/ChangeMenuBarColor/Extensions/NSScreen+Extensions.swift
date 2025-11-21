//
//  NSScreen+Extensions.swift
//  ChangeMenuBarColor
//
//  Created by Igor Kulman on 21.11.2020.
//

import Foundation
import Cocoa

extension NSScreen {
    var size: CGSize {
        CGSize(width: frame.size.width * backingScaleFactor, height: frame.size.height * backingScaleFactor)
    }

    /// Returns the menu bar height in pixels, accounting for modern macOS features
    var menuBarHeight: CGFloat {
        // First, try to get the accurate height from visible frame difference
        let frameHeight = frame.size.height
        let visibleHeight = visibleFrame.height
        let visibleOriginY = visibleFrame.origin.y

        // Calculate the menu bar height in points
        let menuBarPoints = frameHeight - visibleHeight - visibleOriginY

        // Convert to pixels using backing scale factor
        let menuBarPixels = menuBarPoints * backingScaleFactor

        Log.debug("Screen: \(localizedName)")
        Log.debug("  Frame: \(frame)")
        Log.debug("  Visible Frame: \(visibleFrame)")
        Log.debug("  Backing Scale: \(backingScaleFactor)x")
        Log.debug("  Calculated menu bar: \(menuBarPoints)pt (\(menuBarPixels)px)")

        // Detect if this is the main built-in display (likely has notch on modern Macs)
        let isMainDisplay = self == NSScreen.main
        let hasNotch = detectNotch()

        if hasNotch {
            Log.debug("  Display has notch detected")
        }

        // Validate the calculated height
        // Modern macOS menu bars:
        // - Standard displays: 24pt (48-72px depending on resolution)
        // - Displays with notch: 32pt or more (64-96px)
        // - External displays: typically 24pt

        let minValidHeight: CGFloat = 20 * backingScaleFactor  // 20pt minimum
        let maxValidHeight: CGFloat = 50 * backingScaleFactor  // 50pt maximum (notch + padding)

        if menuBarPixels >= minValidHeight && menuBarPixels <= maxValidHeight {
            Log.debug("  Using calculated height: \(menuBarPixels)px")
            return menuBarPixels
        }

        // Fallback logic based on display characteristics
        let fallbackHeight: CGFloat

        if hasNotch && isMainDisplay {
            // MacBook Pro 14"/16" with notch: typically 32pt
            fallbackHeight = 32 * backingScaleFactor
            Log.warning("Menu bar calculation failed, using notch fallback: \(fallbackHeight)px")
        } else {
            // Standard display: 24pt
            fallbackHeight = 24 * backingScaleFactor
            Log.warning("Menu bar calculation failed (\(menuBarPixels)px), using standard fallback: \(fallbackHeight)px")
        }

        return fallbackHeight
    }

    /// Detects if the display has a notch (like MacBook Pro 14"/16")
    private func detectNotch() -> Bool {
        // Check for safe area insets (available macOS 12+)
        if #available(macOS 12.0, *) {
            // Safe area insets are non-zero when there's a notch
            let safeAreaInsets = safeAreaInsets
            let hasTopInset = safeAreaInsets.top > 0

            if hasTopInset {
                Log.debug("  Safe area top inset: \(safeAreaInsets.top)pt")
                return true
            }
        }

        // Additional heuristic: Check if this is a built-in display with specific aspect ratios
        // MacBook Pro 14" (3024x1964) and 16" (3456x2234) have notches
        let screenWidth = Int(frame.size.width * backingScaleFactor)
        let screenHeight = Int(frame.size.height * backingScaleFactor)

        // Known notched display resolutions
        let notchedResolutions: [(width: Int, height: Int)] = [
            (3024, 1964),  // 14" MacBook Pro
            (3456, 2234),  // 16" MacBook Pro
            (3456, 2160),  // 16" MacBook Pro (scaled)
        ]

        for resolution in notchedResolutions {
            if screenWidth == resolution.width && screenHeight == resolution.height {
                Log.debug("  Detected notched display by resolution: \(screenWidth)x\(screenHeight)")
                return true
            }
        }

        // Check if menu bar height is significantly larger than standard
        let menuBarPoints = frame.size.height - visibleFrame.height - visibleFrame.origin.y
        if menuBarPoints > 28 {  // Notch displays typically have 32pt+ menu bars
            Log.debug("  Inferred notch from large menu bar height: \(menuBarPoints)pt")
            return true
        }

        return false
    }

    /// Returns detailed display information for debugging
    var displayInfo: String {
        """
        Display: \(localizedName)
        Resolution: \(Int(frame.width * backingScaleFactor))x\(Int(frame.height * backingScaleFactor)) (\(backingScaleFactor)x)
        Frame: \(frame)
        Visible Frame: \(visibleFrame)
        Menu Bar Height: \(menuBarHeight)px
        Has Notch: \(detectNotch())
        """
    }
}
