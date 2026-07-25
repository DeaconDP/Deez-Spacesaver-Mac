#!/usr/bin/env swift
import AppKit
import Foundation

let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()

let defaultOutput = repoRoot
    .appendingPathComponent("DeezSpacesaver/Assets.xcassets/AppIcon.appiconset")

let outputDir = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
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

// Matches CyberpunkColors in the app.
enum Palette {
    static let bgTop = CGColor(red: 10 / 255, green: 14 / 255, blue: 24 / 255, alpha: 1)
    static let bgBottom = CGColor(red: 4 / 255, green: 6 / 255, blue: 12 / 255, alpha: 1)
    static let accent = CGColor(red: 0, green: 229 / 255, blue: 1, alpha: 1)
    static let accentSoft = CGColor(red: 0, green: 229 / 255, blue: 1, alpha: 0.18)
    static let accentSecondary = CGColor(red: 228 / 255, green: 0, blue: 143 / 255, alpha: 0.35)
}

func drawDatabase(in context: CGContext, canvas: CGFloat) {
    let cx = canvas * 0.5
    let diskWidth = canvas * 0.56
    let diskHeight = canvas * 0.13
    let gap = canvas * 0.055
    let totalHeight = diskHeight * 3 + gap * 2
    var y = (canvas - totalHeight) / 2 + diskHeight * 0.35

    func drawDisk(topY: CGFloat) {
        let rect = CGRect(
            x: cx - diskWidth / 2,
            y: topY,
            width: diskWidth,
            height: diskHeight
        )
        let ellipseHeight = diskHeight * 0.72
        let topEllipse = CGRect(
            x: rect.minX,
            y: rect.maxY - ellipseHeight,
            width: rect.width,
            height: ellipseHeight
        )
        let bottomEllipse = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: ellipseHeight
        )

        context.setFillColor(Palette.accent)
        context.fillEllipse(in: bottomEllipse)
        context.fill(rect)
        context.setFillColor(Palette.accent.copy(alpha: 0.82)!)
        context.fillEllipse(in: topEllipse)
    }

    drawDisk(topY: y)
    y += diskHeight + gap
    drawDisk(topY: y)
    y += diskHeight + gap
    drawDisk(topY: y)
}

func drawIcon(pixels: Int) throws -> Data {
    let canvas = CGFloat(pixels)

    guard let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: pixels * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "IconGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap context"])
    }

    if let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [Palette.bgTop, Palette.bgBottom] as CFArray,
        locations: [0, 1]
    ) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: canvas * 0.5, y: canvas),
            end: CGPoint(x: canvas * 0.5, y: 0),
            options: []
        )
    }

    context.saveGState()
    context.setFillColor(Palette.accentSoft)
    context.fillEllipse(in: CGRect(x: canvas * 0.1, y: canvas * 0.08, width: canvas * 0.8, height: canvas * 0.62))
    context.setFillColor(Palette.accentSecondary)
    context.fillEllipse(in: CGRect(x: canvas * 0.22, y: canvas * 0.02, width: canvas * 0.56, height: canvas * 0.38))
    context.restoreGState()

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -canvas * 0.01),
        blur: canvas * 0.05,
        color: Palette.accent.copy(alpha: 0.45)
    )
    drawDatabase(in: context, canvas: canvas)
    context.restoreGState()

    guard let outputImage = context.makeImage(),
          let png = NSBitmapImageRep(cgImage: outputImage).representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    return png
}

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

for entry in sizes {
    let fileURL = outputDir.appendingPathComponent(entry.name)
    let png = try drawIcon(pixels: entry.pixels)
    try png.write(to: fileURL)
    print("Wrote \(fileURL.path)")
}

print("Done.")
