import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate-icon.swift <output.png>\n", stderr)
    exit(2)
}

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let background = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 228, yRadius: 228)
NSGradient(colors: [
    NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.12, alpha: 1),
    NSColor(calibratedRed: 0.17, green: 0.18, blue: 0.24, alpha: 1)
])!.draw(in: background, angle: -90)

let housingRect = NSRect(x: 312, y: 118, width: 400, height: 788)
let housing = NSBezierPath(roundedRect: housingRect, xRadius: 128, yRadius: 128)
NSColor(calibratedWhite: 0.04, alpha: 0.94).setFill()
housing.fill()
NSColor(calibratedWhite: 1, alpha: 0.12).setStroke()
housing.lineWidth = 18
housing.stroke()

let lights: [(CGFloat, NSColor)] = [
    (675, NSColor(calibratedRed: 0.94, green: 0.28, blue: 0.31, alpha: 1)),
    (421, NSColor(calibratedRed: 0.98, green: 0.69, blue: 0.20, alpha: 1)),
    (167, NSColor(calibratedRed: 0.25, green: 0.84, blue: 0.52, alpha: 1))
]

for (y, color) in lights {
    let shadow = NSShadow()
    shadow.shadowColor = color.withAlphaComponent(0.45)
    shadow.shadowBlurRadius = 46
    shadow.shadowOffset = .zero
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    let circle = NSBezierPath(ovalIn: NSRect(x: 392, y: y, width: 240, height: 240))
    color.setFill()
    circle.fill()
    NSGraphicsContext.restoreGraphicsState()
}

image.unlockFocus()
guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("failed to render icon\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
