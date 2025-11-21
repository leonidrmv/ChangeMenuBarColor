//
//  Gradient.swift
//  ArgumentParser
//
//  Created by Igor Kulman on 19.11.2020.
//

import Accessibility
@preconcurrency import ArgumentParser
import Foundation
import Cocoa

@MainActor
final class Gradient: Command, ParsableCommand {
    nonisolated static let configuration = CommandConfiguration(
        commandName: "Gradient",
        abstract: "Adds gradient rectangle to create custom menu bar gradient"
    )

    @Argument(help: "HEX color to use for gradient start (e.g., #FF0000)")
    var startColor: String

    @Argument(help: "HEX color to use for gradient end (e.g., #00FF00)")
    var endColor: String

    @Argument(help: "Wallpaper to use. If not provided the current macOS wallpaper will be used")
    var wallpaper: String?

    @Flag(name: .long, help: "Set wallpaper for all displays not just the main display")
    var allDisplays: Bool = false

    nonisolated override var useAllDisplays: Bool {
        // This is safe to access without synchronization because ArgumentParser initializes
        // command properties before calling run() on the main thread
        MainActor.assumeIsolated { allDisplays }
    }

    override func createWallpaper(screen: NSScreen) -> NSImage? {
        guard let wallpaper = loadWallpaperImage(wallpaper: wallpaper, screen: screen) else {
            return nil
        }

        guard let startColor = NSColor(hexString: self.startColor) else {
            Log.error("Invalid HEX color provided as gradient start color. Make sure it includes the '#' symbol, e.g: #FF0000")
            return nil
        }

        guard let endColor = NSColor(hexString: self.endColor) else {
            Log.error("Invalid HEX color provided as gradient end color. Make sure it includes the '#' symbol, e.g: #FF0000")
            return nil
        }

        guard let resizedWallpaper = wallpaper.crop(size: screen.size) else {
            Log.error("Cannot resize provided wallpaper to screen size")
            return nil
        }

        Log.debug("Generating gradient image from \(colorName(startColor)) to \(colorName(endColor))")
        guard let topImage = createGradientImage(startColor: startColor, endColor: endColor, width: screen.size.width, height: screen.menuBarHeight) else {
            Log.error("Failed to create gradient image")
            return nil
        }

        return combineImages(baseImage: resizedWallpaper, addedImage: topImage)
    }
}


