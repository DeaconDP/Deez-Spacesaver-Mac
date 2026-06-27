#!/usr/bin/env swift
import AppKit
import Foundation

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "DeezSpacesaver/Assets.xcassets/AppIcon.appiconset"

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


func drawUnicodeSymbol(in context: CGContext, size: CGFloat) {
    // U+25A4 ▤ — stacked reads as database / storage layers
    let symbol = String(repeating: "\u{25A4}\n", count: 3).trimmingCharacters(in: .newlines)
    let fontSize = size * 0.22
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineSpacing = size * 0.02
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph,
    ]
    let text = NSAttributedString(string: symbol, attributes: attributes)
    let textSize = text.size()
    let point = CGPoint(
        x: (size - textSize.width) / 2,
        y: (size - textSize.height) / 2
    )
    let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsContext
    text.draw(at: point)
    NSGraphicsContext.restoreGraphicsState()
}

func renderIcon(pixels: Int, to url: URL) throws {
    let size = CGFloat(pixels)
    guard let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "IconGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create context"])
    }

    context.setFillColor(NSColor.black.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))

    drawUnicodeSymbol(in: context, size: size)

    guard let image = context.makeImage() else {
        throw NSError(domain: "IconGen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to make image"])
    }

    let rep = NSBitmapImageRep(cgImage: image)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    try png.write(to: url)
}

let outURL = URL(fileURLWithPath: outputDir, isDirectory: true)
try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)

for entry in sizes {
    let fileURL = outURL.appendingPathComponent(entry.name)
    try renderIcon(pixels: entry.pixels, to: fileURL)
    print("Wrote \(fileURL.path)")
}

print("Done.")
