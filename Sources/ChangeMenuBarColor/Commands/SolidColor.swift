//
//  SolidColor.swift
//  ArgumentParser
//
//  Created by Igor Kulman on 19.11.2020.
//

@preconcurrency import ArgumentParser
import Foundation
import Cocoa

@MainActor
final class SolidColor: Command, ParsableCommand {
    nonisolated static let configuration = CommandConfiguration(
        commandName: "SolidColor",
        abstract: "Adds solid color rectangle to create custom menu bar color"
    )

    @Argument(help: "HEX color to use for the menu bar (e.g., #CCCCCC)")
    var color: String

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

        guard let color = NSColor(hexString: self.color) else {
            Log.error("Invalid HEX color provided. Make sure it includes the '#' symbol, e.g: #FF0000")
            return nil
        }

        guard let resizedWallpaper = wallpaper.crop(size: screen.size) else {
            Log.error("Cannot resize provided wallpaper to screen size")
            return nil
        }

        Log.debug("Generating \(colorName(color)) solid color image")
        guard let topImage = createSolidImage(color: color, width: screen.size.width, height: screen.menuBarHeight) else {
            Log.error("Failed to create solid color image")
            return nil
        }

        return combineImages(baseImage: resizedWallpaper, addedImage: topImage)
    }
}

