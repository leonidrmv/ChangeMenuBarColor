//
//  ChangeMenuBarColor+ImageManipulation.swift
//  ChangeMenuBarColor
//
//  Created by Igor Kulman on 19.11.2020.
//

#if canImport(Accessibility)
    import Accessibility
#endif
import Foundation
import Cocoa

@MainActor
func createGradientImage(startColor: NSColor, endColor: NSColor, width: CGFloat, height: CGFloat) -> NSImage? {
    guard let context = createContext(width: width, height: height) else {
        Log.error("Could not create graphical context for gradient image")
        return nil
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [startColor.cgColor, endColor.cgColor] as CFArray
    let locations: [CGFloat] = [0.0, 1.0]

    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
        Log.error("Could not create gradient")
        return nil
    }

    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: width, y: 0),
        options: []
    )

    guard let composedImage = context.makeImage() else {
        Log.error("Could not create composed image for gradient image")
        return nil
    }

    return NSImage(cgImage: composedImage, size: CGSize(width: width, height: height))
}

@MainActor
func createSolidImage(color: NSColor, width: CGFloat, height: CGFloat) -> NSImage? {
    guard let context = createContext(width: width, height: height) else {
        Log.error("Could not create graphical context for solid color image")
        return nil
    }

    context.setFillColor(color.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    guard let composedImage = context.makeImage() else {
        Log.error("Could not create composed image for solid color image")
        return nil
    }

    return NSImage(cgImage: composedImage, size: CGSize(width: width, height: height))
}

@MainActor
func combineImages(baseImage: NSImage, addedImage: NSImage) -> NSImage? {
    let width = baseImage.size.width
    let height = baseImage.size.height

    // Create bitmap representation with high-quality settings
    guard let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(width),
        pixelsHigh: Int(height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        Log.error("Could not create bitmap representation when merging images")
        return nil
    }

    bitmapRep.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
        Log.error("Could not create graphics context when merging images")
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = context

    // Draw the base image (wallpaper) at full quality
    let baseRect = NSRect(x: 0, y: 0, width: width, height: height)
    baseImage.draw(in: baseRect, from: .zero, operation: .copy, fraction: 1.0)

    // Use the actual menu bar height from the added image
    // The added image was created with the correct menu bar height for the screen
    let menuBarHeight = addedImage.size.height

    Log.debug("Combining images - Menu bar overlay height: \(menuBarHeight)px")

    // Draw the menu bar portion at the top of the image
    let menuBarRect = NSRect(x: 0, y: height - menuBarHeight, width: width, height: menuBarHeight)
    let sourceRect = NSRect(x: 0, y: 0, width: addedImage.size.width, height: menuBarHeight)
    addedImage.draw(in: menuBarRect, from: sourceRect, operation: .sourceOver, fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    // Create final image from the bitmap representation
    let finalImage = NSImage(size: NSSize(width: width, height: height))
    finalImage.addRepresentation(bitmapRep)

    return finalImage
}

func createContext(width: CGFloat, height: CGFloat) -> CGContext? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue

    return CGContext(
        data: nil,
        width: Int(width),
        height: Int(height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )
}

@MainActor
func colorName(_ color: NSColor) -> String {
    #if canImport(Accessibility)
    if #available(macOS 11.0, *) {
        return AXNameFromColor(color.cgColor)
    }
    #endif
    return color.description
}

@MainActor
func getOriginalWallpaper(for screen: NSScreen) -> NSImage? {
    guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else {
        Log.error("Could not get desktop image URL")
        return nil
    }

    do {
        let imageData = try Data(contentsOf: url)
        guard let image = NSImage(data: imageData) else {
            Log.error("Failed to convert data to NSImage")
            return nil
        }

        Log.debug("Successfully loaded original wallpaper from \(url.path)")
        return image
    } catch {
        Log.error("Failed to load original wallpaper: \(error.localizedDescription)")
        return nil
    }
}
