import AppKit

// Draws the 1024x1024 app icon: blue gradient, white card with five day columns and coloured events.
// Usage (macOS): swift tools/make_icon.swift App/Assets.xcassets/AppIcon.appiconset/icon-1024.png
let size: CGFloat = 1024
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor { CGColor(red: r/255, green: g/255, blue: b/255, alpha: 1) }

let grad = CGGradient(colorsSpace: cs, colors: [c(64, 120, 245), c(38, 72, 190)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

let card = CGRect(x: 120, y: 250, width: 784, height: 524)
ctx.addPath(CGPath(roundedRect: card, cornerWidth: 70, cornerHeight: 70, transform: nil))
ctx.setFillColor(c(255, 255, 255)); ctx.fillPath()

let cols = 5
let pad: CGFloat = 44, gap: CGFloat = 22
let colW = (card.width - pad*2 - gap*CGFloat(cols-1)) / CGFloat(cols)
let top = card.maxY - pad
let headerH: CGFloat = 46
let palette = [c(255, 149, 0), c(52, 199, 89), c(255, 59, 48), c(175, 82, 222), c(90, 200, 250)]
// Events per day: (start from top, height) as fractions of the column body, palette index.
let events: [[(CGFloat, CGFloat, Int)]] = [
    [(0.05, 0.30, 0), (0.45, 0.25, 4)],
    [(0.15, 0.45, 1)],
    [(0.00, 0.20, 2), (0.30, 0.20, 3), (0.62, 0.30, 0)],
    [(0.25, 0.35, 4)],
    [(0.05, 0.25, 3), (0.50, 0.40, 1)],
]
let bodyTop = top - headerH - 26
let bodyH = bodyTop - (card.minY + pad)
for i in 0..<cols {
    let x = card.minX + pad + CGFloat(i) * (colW + gap)
    let h = CGRect(x: x, y: top - headerH, width: colW, height: headerH)
    ctx.addPath(CGPath(roundedRect: h, cornerWidth: 14, cornerHeight: 14, transform: nil))
    ctx.setFillColor(i == 0 ? c(64, 120, 245) : c(222, 228, 240)); ctx.fillPath()
    for (s, len, p) in events[i] {
        let r = CGRect(x: x, y: bodyTop - (s + len) * bodyH, width: colW, height: len * bodyH - 6)
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 16, cornerHeight: 16, transform: nil))
        ctx.setFillColor(palette[p]); ctx.fillPath()
    }
}

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("wrote \(CommandLine.arguments[1])")
