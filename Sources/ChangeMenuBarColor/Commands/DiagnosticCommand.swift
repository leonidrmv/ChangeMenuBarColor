//
//  DiagnosticCommand.swift
//  ChangeMenuBarColor
//
//  Created for macOS 26 compatibility
//

@preconcurrency import ArgumentParser
import Foundation
import Cocoa

@MainActor
struct DiagnosticCommand: ParsableCommand {
    nonisolated static let configuration = CommandConfiguration(
        commandName: "Diagnostic",
        abstract: "Display detailed information about connected displays and menu bar sizing"
    )

    nonisolated func run() throws {
        try MainActor.assumeIsolated {
            try self.runDiagnostic()
        }
    }

    private func runDiagnostic() throws {
        Log.info("=== ChangeMenuBarColor Display Diagnostic ===\n")

        let screens = NSScreen.screens
        Log.info("Found \(screens.count) display(s)\n")

        for (index, screen) in screens.enumerated() {
            Log.info("--- Display \(index + 1) ---")
            print(screen.displayInfo)

            // Additional technical details
            let isMain = screen == NSScreen.main
            Log.info("Is Main Display: \(isMain)")

            if #available(macOS 12.0, *) {
                let safeArea = screen.safeAreaInsets
                Log.info("Safe Area Insets: top=\(safeArea.top), bottom=\(safeArea.bottom), left=\(safeArea.left), right=\(safeArea.right)")
            }

            // Calculate menu bar characteristics
            let menuBarPoints = screen.frame.size.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
            let menuBarPixels = menuBarPoints * screen.backingScaleFactor

            Log.info("Menu Bar Analysis:")
            Log.info("  - Points: \(menuBarPoints)pt")
            Log.info("  - Pixels: \(menuBarPixels)px")
            Log.info("  - Backing Scale: \(screen.backingScaleFactor)x")

            // Check for auto-hide setting
            let autoHideMenuBar = UserDefaults.standard.bool(forKey: "autohide-menu-bar")
            if autoHideMenuBar {
                Log.warning("⚠️  'Automatically hide and show the menu bar' is ENABLED")
                Log.warning("   This may cause incorrect menu bar size detection!")
                Log.warning("   Please disable this setting in System Settings > Desktop & Dock")
            }

            print("")
        }

        Log.info("=== Recommendations ===")
        Log.info("✓ Menu bar 'auto-hide' should be DISABLED")
        Log.info("✓ Expected menu bar heights:")
        Log.info("  - Standard displays: 24pt (48px @2x, 72px @3x)")
        Log.info("  - Notched MacBook Pro: 30-32pt (60-64px @2x)")
        Log.info("  - External displays: 24pt (varies by scale)")
        print("")
    }
}
