#!/usr/bin/env swift
import AppKit
import Foundation

let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()

let defaultSource = repoRoot
    .appendingPathComponent("scripts/icon-source-1024.png")
let iconBundle = repoRoot
    .appendingPathComponent("DeezSpacesaver/AppIcon.icon")
let legacyIconset = repoRoot
    .appendingPathComponent("DeezSpacesaver/Assets.xcassets/AppIcon.appiconset")

let sourceURL = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : defaultSource

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

func makeBitmap(pixels: Int) throws -> NSBitmapImageRep {
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
    return bitmap
}

/// White glyph on transparent — Tahoe Icon Composer foreground layer.
func makeGlyphPNG(pixels: Int = 1024) throws -> Data {
    let bitmap = try makeBitmap(pixels: pixels)
    let canvas = NSRect(x: 0, y: 0, width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSBezierPath(rect: canvas).fill()
    sourceImage.draw(
        in: canvas,
        from: NSRect(x: 0, y: 0, width: sourceRep.pixelsWide, height: sourceRep.pixelsHigh),
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    // Knock out the black plate; keep the white database mark (and its AA fringe).
    guard let data = bitmap.bitmapData else {
        throw NSError(domain: "IconGen", code: 3, userInfo: [NSLocalizedDescriptionKey: "No bitmap data"])
    }
    let rowBytes = bitmap.bytesPerRow
    for y in 0..<pixels {
        let row = data.advanced(by: y * rowBytes)
        for x in 0..<pixels {
            let p = row.advanced(by: x * 4)
            let r = Int(p[0]), g = Int(p[1]), b = Int(p[2])
            let luma = (r + g + b) / 3
            if luma < 40 {
                p[0] = 0; p[1] = 0; p[2] = 0; p[3] = 0
            } else {
                p[0] = 255; p[1] = 255; p[2] = 255; p[3] = UInt8(luma)
            }
        }
    }

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    return png
}

// Remove classic appiconset — Tahoe needs AppIcon.icon; both named AppIcon conflict.
if FileManager.default.fileExists(atPath: legacyIconset.path) {
    try FileManager.default.removeItem(at: legacyIconset)
    print("Removed \(legacyIconset.path)")
}

let assetsDir = iconBundle.appendingPathComponent("Assets")
try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)

let glyphURL = assetsDir.appendingPathComponent("glyph.png")
try makeGlyphPNG().write(to: glyphURL)
print("Wrote \(glyphURL.path)")

let iconJSON = """
{
  "fill" : {
    "solid" : "display-p3:0.00000,0.00000,0.00000,1.00000"
  },
  "groups" : [
    {
      "layers" : [
        {
          "glass" : false,
          "image-name" : "glyph.png",
          "name" : "Glyph",
          "position" : {
            "scale" : 1,
            "translation-in-points" : [
              0,
              0
            ]
          }
        }
      ],
      "shadow" : {
        "kind" : "neutral",
        "opacity" : 0.25
      },
      "translucency" : {
        "enabled" : false,
        "value" : 0.5
      }
    }
  ],
  "supported-platforms" : {
    "squares" : "shared"
  }
}
"""
let jsonURL = iconBundle.appendingPathComponent("icon.json")
try iconJSON.write(to: jsonURL, atomically: true, encoding: .utf8)
print("Wrote \(jsonURL.path)")

print("Done.")
