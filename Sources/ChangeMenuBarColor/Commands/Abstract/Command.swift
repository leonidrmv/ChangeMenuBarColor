//
//  Command.swift
//  ChangeMenuBarColor
//
//  Created by Igor Kulman on 19.11.2020.
//

@preconcurrency import ArgumentParser
import Files
import Foundation
import Cocoa

@MainActor
class Command {
    func createWallpaper(screen: NSScreen) -> NSImage? {
        fatalError("Override for each type")
    }

    nonisolated var useAllDisplays: Bool {
        fatalError("Override for each type")
    }

    nonisolated func run() throws {
        // ArgumentParser calls run() on the main thread, so we can use assumeIsolated
        // This is safe because AppKit requires main thread anyway
        try MainActor.assumeIsolated {
            try self.runMainActor()
        }
    }

    private func runMainActor() throws {
        Log.info("Starting up\n")

        let screens: [NSScreen] = useAllDisplays ? NSScreen.screens : [NSScreen.main].compactMap({ $0 })

        guard !screens.isEmpty else {
            Log.error("Could not detect any screens")
            throw WallpaperError.noScreensDetected
        }

        Log.info("Found \(screens.count) screen(s) to process")
        for (index, screen) in screens.enumerated() {
            Log.debug("\nScreen \(index + 1):")
            Log.debug(screen.displayInfo)
            guard let adjustedWallpaper = createWallpaper(screen: screen) else {
                Log.error("Could not generate new wallpaper screen \(index)")
                continue
            }

            guard let data = adjustedWallpaper.jpgData else {
                Log.error("Could not convert wallpaper to JPEG data for screen \(index)")
                continue
            }

            do {
                try setWallpaper(screen: screen, wallpaper: data)
            } catch {
                Log.error("Failed to set wallpaper for screen \(index): \(error.localizedDescription)")
            }
        }

        Log.info("\nAll done!")
    }

    func loadWallpaperImage(wallpaper: String?, screen: NSScreen) -> NSImage? {
        if let path = wallpaper {
            guard let wallpaper = NSImage(contentsOfFile: path) else {
                Log.error("Cannot read the provided wallpaper file as image. Check if the path is correct and if it is a valid image file")
                return nil
            }

            Log.debug("Loaded \(path) to be used as wallpaper image")
            return wallpaper
        }

        // Use our new function to get the original wallpaper directly from the file
        if let originalWallpaper = getOriginalWallpaper(for: screen) {
            originalWallpaper.adjustSize()
            return originalWallpaper
        }

        // Fallback to the old method if our new function fails
        guard let path = NSWorkspace.shared.desktopImageURL(for: screen), let wallpaper = NSImage(contentsOf: path) else {
            Log.error("Cannot read the currently set macOS wallpaper. Try providing a specific wallpaper as a parameter instead.")
            return nil
        }

        wallpaper.adjustSize()
        Log.debug("Using currently set macOS wallpaper \(path)")

        return wallpaper
    }

    private func setWallpaper(screen: NSScreen, wallpaper: Data) throws {
        guard let supportFiles = try? Folder.library?.subfolder(at: "Application Support"),
              let workingDirectory = try? supportFiles.createSubfolderIfNeeded(at: "ChangeMenuBarColor") else {
            throw WallpaperError.cannotAccessApplicationSupport
        }

        let generatedWallpaperFile = workingDirectory.url.appendingPathComponent("wallpaper-screen-adjusted-\(UUID().uuidString).jpg")
        try? FileManager.default.removeItem(at: generatedWallpaperFile)

        try wallpaper.write(to: generatedWallpaperFile, options: .atomic)
        Log.debug("Created new wallpaper for the main screen in \(generatedWallpaperFile.absoluteString)")

        try NSWorkspace.shared.setDesktopImageURL(generatedWallpaperFile, for: screen, options: [:])
        Log.info("Wallpaper set")

        // Clean up old wallpaper files
        let oldWallpaperFiles = workingDirectory.files.filter { $0.url != generatedWallpaperFile }
        guard !oldWallpaperFiles.isEmpty else {
            return
        }

        Log.info("Deleting old wallpaper files from previous runs")
        for file in oldWallpaperFiles {
            try? file.delete()
        }
    }
}

enum WallpaperError: Error, LocalizedError {
    case noScreensDetected
    case cannotAccessApplicationSupport
    case cannotReadWallpaper
    case invalidHexColor

    var errorDescription: String? {
        switch self {
        case .noScreensDetected:
            return "Could not detect any screens"
        case .cannotAccessApplicationSupport:
            return "Cannot access Application Support folder"
        case .cannotReadWallpaper:
            return "Cannot read the wallpaper file"
        case .invalidHexColor:
            return "Invalid HEX color provided. Make sure it includes the '#' symbol, e.g: #FF0000"
        }
    }
}
