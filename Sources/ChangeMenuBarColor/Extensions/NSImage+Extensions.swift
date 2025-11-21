//
//  NSImage+Extensions.swift
//  ChangeMenuBarColor
//
//  Created by Igor Kulman on 16.11.2020.
//

import Foundation
import Cocoa

extension NSImage {
    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: self.size)
        return self.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    var jpgData: Data? {
        guard let cgImage = self.cgImage else {
            Log.error("Cannot create CGImage from NSImage")
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = self.size

        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 1.0]) else {
            Log.error("Cannot create JPEG data from bitmap image")
            return nil
        }

        return jpegData
    }

    func copy(size: NSSize) -> NSImage? {
        let frame = NSRect(x: 0, y: 0, width: size.width, height: size.height)

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        bitmapRep.size = size

        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        NSGraphicsContext.current = context

        self.draw(in: frame)

        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: size)
        result.addRepresentation(bitmapRep)
        return result
    }
    
    func resizeWhileMaintainingAspectRatioToSize(size: NSSize) -> NSImage? {
        let newSize: NSSize
        
        let widthRatio  = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.size.width * widthRatio), height: floor(self.size.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.size.width * heightRatio), height: floor(self.size.height * heightRatio))
        }
        
        return self.copy(size: newSize)
    }
    
    func crop(size: NSSize) -> NSImage? {
        // only resize when the size actually differs
        guard size != self.size else {
            return self
        }

        // Resize the current image, while preserving the aspect ratio.
        guard let resized = self.resizeWhileMaintainingAspectRatioToSize(size: size) else {
            return nil
        }

        // the image centering is needed only when the resized image does not exactly match the screen size
        guard resized.size != size else {
            return resized
        }

        // Get some points to center the cropping area.
        let x = floor((resized.size.width - size.width) / 2)
        let y = floor((resized.size.height - size.height) / 2)

        // Create the cropping frame.
        let cropRect = NSRect(x: x, y: y, width: size.width, height: size.height)

        // Create bitmap representation for high-quality cropping
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        bitmapRep.size = size

        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        NSGraphicsContext.current = context

        let destRect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        resized.draw(in: destRect, from: cropRect, operation: .copy, fraction: 1.0)

        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: size)
        result.addRepresentation(bitmapRep)
        return result
    }

    // Images loaded from file sometimes do not report the size correctly, see https://stackoverflow.com/questions/9264051/nsimage-size-not-real-size-with-some-pictures
    // This can lead to artifacts produced by resizing operations
    func adjustSize() {
        // use the biggest sizes from all the representations https://stackoverflow.com/a/38523158/581164
        size = representations.reduce(size) { size, representation in
            return CGSize(width: max(size.width, CGFloat(representation.pixelsWide)), height: max(size.height, CGFloat(representation.pixelsHigh)))
        }
    }
}
