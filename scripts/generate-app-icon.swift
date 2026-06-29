#!/usr/bin/env swift
import AppKit
import Foundation

let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()

let defaultSource = repoRoot
    .appendingPathComponent("scripts/icon-source-1024.png")
let defaultOutput = repoRoot
    .appendingPathComponent("DeezSpacesaver/Assets.xcassets/AppIcon.appiconset")

let sourceURL = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : defaultSource
let outputDir = CommandLine.arguments.count > 2
    ? URL(fileURLWithPath: CommandLine.arguments[2])
    : defaultOutput

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

// macOS icon grid on a 1024 master (matches system app geometry on Tahoe+).
private let masterCanvas: CGFloat = 1024
private let masterBodyInset: CGFloat = 100 // (1024 - 824) / 2
private let masterCornerRadius: CGFloat = 185.4

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("error: could not load source icon at \(sourceURL.path)\n", stderr)
    exit(1)
}

guard let sourceRep = sourceImage.representations.max(by: {
    ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
}) else {
    fputs("error: source icon has no bitmap representations\n", stderr)
    exit(1)
}

func macOSIconBodyRect(forCanvas size: CGFloat) -> (body: NSRect, cornerRadius: CGFloat) {
    let scale = size / masterCanvas
    let inset = masterBodyInset * scale
    let bodySize = size - inset * 2
    let cornerRadius = masterCornerRadius * scale
    return (NSRect(x: inset, y: inset, width: bodySize, height: bodySize), cornerRadius)
}

func resizeIcon(pixels: Int) throws -> Data {
    let size = CGFloat(pixels)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap"])
    }

    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    let geometry = macOSIconBodyRect(forCanvas: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    NSColor.clear.setFill()
    NSBezierPath(rect: canvas).fill()

    // Soft system shadow so the icon matches native apps on the Dock/Launchpad grid.
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
    shadow.shadowOffset = NSSize(width: 0, height: -12 * (size / masterCanvas))
    shadow.shadowBlurRadius = 28 * (size / masterCanvas)
    shadow.set()

    let bodyPath = NSBezierPath(roundedRect: geometry.body, xRadius: geometry.cornerRadius, yRadius: geometry.cornerRadius)
    NSColor.black.setFill()
    bodyPath.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.current?.saveGraphicsState()
    bodyPath.addClip()
    sourceImage.draw(
        in: canvas,
        from: NSRect(x: 0, y: 0, width: sourceRep.pixelsWide, height: sourceRep.pixelsHigh),
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    return png
}

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

for entry in sizes {
    let fileURL = outputDir.appendingPathComponent(entry.name)
    let png = try resizeIcon(pixels: entry.pixels)
    try png.write(to: fileURL)
    print("Wrote \(fileURL.path)")
}

print("Done.")
