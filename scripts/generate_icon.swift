import Cocoa
import CoreGraphics

func createCGContext(width: Int, height: Int) -> CGContext? {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else { return nil }
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high
    return ctx
}

func saveContextToPNG(ctx: CGContext, url: URL) {
    guard let image = ctx.makeImage() else {
        print("Failed to make CGImage for \(url.path)")
        return
    }
    let rep = NSBitmapImageRep(cgImage: image)
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to convert to PNG for \(url.path)")
        return
    }
    try? pngData.write(to: url)
    print("Saved \(url.path) (\(ctx.width)x\(ctx.height))")
}

func drawSquircle(ctx: CGContext, rect: CGRect, cornerRadius: CGFloat) {
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
}

func drawSkyletMark(ctx: CGContext, center: CGPoint, radius: CGFloat, isTransparentBackdrop: Bool = false) {
    ctx.saveGState()
    
    // 1. Atmospheric Outer Celestial Halo (Sky Blue & Solar warmth blend)
    let haloRadius = radius * 1.55
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    
    // Ambient Solar Flare glow
    let flareColors = [
        NSColor(red: 0.98, green: 0.70, blue: 0.15, alpha: 0.35).cgColor,
        NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.15).cgColor,
        NSColor(red: 0.05, green: 0.15, blue: 0.35, alpha: 0.0).cgColor
    ] as CFArray
    let flareLocations: [CGFloat] = [0.0, 0.65, 1.0]
    if let flareGrad = CGGradient(colorsSpace: colorSpace, colors: flareColors, locations: flareLocations) {
        ctx.drawRadialGradient(flareGrad, startCenter: center, startRadius: radius * 0.2, endCenter: center, endRadius: haloRadius, options: .drawsAfterEndLocation)
    }
    
    // 2. Atmospheric Orbital Arc (Celestial Horizon / Sky Accent)
    // A sweeping, luminous sky-blue crescent/arc that cradles the solar core
    ctx.saveGState()
    let arcRadius = radius * 1.18
    let arcPath = CGMutablePath()
    arcPath.addArc(center: center, radius: arcRadius, startAngle: -.pi * 0.15, endAngle: .pi * 1.15, clockwise: false)
    ctx.setLineWidth(radius * 0.045)
    ctx.setLineCap(.round)
    
    // Stroke with gradient
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    
    let arcColors = [
        NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.0).cgColor,
        NSColor(red: 0.35, green: 0.85, blue: 1.00, alpha: 0.95).cgColor,
        NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.2).cgColor
    ] as CFArray
    let arcLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let arcGrad = CGGradient(colorsSpace: colorSpace, colors: arcColors, locations: arcLocations) {
        ctx.drawLinearGradient(arcGrad, start: CGPoint(x: center.x - arcRadius, y: center.y - arcRadius), end: CGPoint(x: center.x + arcRadius, y: center.y + arcRadius), options: [])
    }
    ctx.restoreGState()
    
    // 3. 12 Precision Solar Beams
    // Emanating radially, with primary cardinal rays slightly elongated
    let rayCount = 12
    let baseRayLength = radius * 0.36
    let baseRayThickness = radius * 0.062
    let innerGap = radius * 0.78
    
    for i in 0..<rayCount {
        let angle = CGFloat(i) * (.pi * 2.0 / CGFloat(rayCount))
        let isCardinal = (i % 3 == 0)
        let rayLength = isCardinal ? baseRayLength * 1.18 : baseRayLength
        let thickness = isCardinal ? baseRayThickness * 1.12 : baseRayThickness
        
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle)
        
        let rayRect = CGRect(x: -thickness / 2.0, y: innerGap, width: thickness, height: rayLength)
        let rayPath = CGPath(roundedRect: rayRect, cornerWidth: thickness / 2.0, cornerHeight: thickness / 2.0, transform: nil)
        
        // Add subtle shadow to ray
        ctx.setShadow(offset: .zero, blur: radius * 0.05, color: NSColor(red: 1.0, green: 0.72, blue: 0.10, alpha: 0.5).cgColor)
        
        ctx.addPath(rayPath)
        ctx.clip()
        
        let rayColors = [
            NSColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 0.95).cgColor,
            NSColor(red: 0.98, green: 0.55, blue: 0.05, alpha: 0.75).cgColor
        ] as CFArray
        let rayGrad = CGGradient(colorsSpace: colorSpace, colors: rayColors, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(rayGrad, start: CGPoint(x: 0, y: innerGap), end: CGPoint(x: 0, y: innerGap + rayLength), options: [])
        
        ctx.restoreGState()
    }
    
    // 4. Primary Solar Core (Warm amber glow with layered gradients)
    let coreRadius = radius * 0.65
    
    // Core Outer Bloom
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: radius * 0.22, color: NSColor(red: 1.0, green: 0.60, blue: 0.05, alpha: 0.7).cgColor)
    ctx.setFillColor(NSColor(red: 1.0, green: 0.70, blue: 0.15, alpha: 0.9).cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2))
    ctx.restoreGState()
    
    // Core Gradient (Top-to-bottom sunlight reflection)
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2))
    ctx.clip()
    
    let coreColors = [
        NSColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 1.0).cgColor,
        NSColor(red: 1.0, green: 0.72, blue: 0.12, alpha: 1.0).cgColor,
        NSColor(red: 0.92, green: 0.40, blue: 0.02, alpha: 1.0).cgColor
    ] as CFArray
    let coreGrad = CGGradient(colorsSpace: colorSpace, colors: coreColors, locations: [0.0, 0.45, 1.0])!
    ctx.drawLinearGradient(coreGrad,
                           start: CGPoint(x: center.x, y: center.y + coreRadius * 0.8),
                           end: CGPoint(x: center.x, y: center.y - coreRadius),
                           options: [])
    
    // Highlight reflection crescent on top rim
    let highlightRect = CGRect(x: center.x - coreRadius * 0.7, y: center.y + coreRadius * 0.2, width: coreRadius * 1.4, height: coreRadius * 0.6)
    let hlColors = [
        NSColor(white: 1.0, alpha: 0.45).cgColor,
        NSColor(white: 1.0, alpha: 0.0).cgColor
    ] as CFArray
    if let hlGrad = CGGradient(colorsSpace: colorSpace, colors: hlColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(hlGrad, start: CGPoint(x: center.x, y: highlightRect.maxY), end: CGPoint(x: center.x, y: highlightRect.minY), options: [])
    }
    ctx.restoreGState()
    
    // 5. Center Emblem: Refined Currency / Focus Horizon Ring
    // Subtle nested dual ring symbolizing circulation and time
    ctx.saveGState()
    let innerRingRadius = coreRadius * 0.52
    ctx.setLineWidth(radius * 0.035)
    ctx.setStrokeColor(NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.38).cgColor)
    ctx.strokeEllipse(in: CGRect(x: center.x - innerRingRadius, y: center.y - innerRingRadius, width: innerRingRadius * 2, height: innerRingRadius * 2))
    
    // Center point / compass star
    let centerDotRadius = radius * 0.065
    ctx.setFillColor(NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9).cgColor)
    ctx.setShadow(offset: .zero, blur: radius * 0.04, color: NSColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 0.8).cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - centerDotRadius, y: center.y - centerDotRadius, width: centerDotRadius * 2, height: centerDotRadius * 2))
    ctx.restoreGState()
    
    ctx.restoreGState()
}

func generateMasterIcon() {
    let size = 1024
    guard let ctx = createCGContext(width: size, height: size) else { return }
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    
    // Squircle Bounds (macOS App Icon squircle standard)
    let margin: CGFloat = 82
    let iconRect = CGRect(x: margin, y: margin, width: CGFloat(size) - margin * 2, height: CGFloat(size) - margin * 2)
    let cornerRadius: CGFloat = (CGFloat(size) - margin * 2) * 0.2237 // Apple continuous squircle standard ~192pt
    
    // 1. Outer App Drop Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 32, color: NSColor(white: 0.0, alpha: 0.55).cgColor)
    let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()
    
    // 2. Icon Base Squircle Background
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    
    // Midnight to Twilight Deep Background Gradient
    let bgColors = [
        NSColor(red: 0.05, green: 0.08, blue: 0.16, alpha: 1.0).cgColor, // Top: deep celestial navy
        NSColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 1.0).cgColor  // Bottom: dark midnight obsidian
    ] as CFArray
    let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 512, y: iconRect.maxY), end: CGPoint(x: 512, y: iconRect.minY), options: [])
    
    // Ambient upper atmosphere glow
    let glowColors = [
        NSColor(red: 0.14, green: 0.35, blue: 0.65, alpha: 0.25).cgColor,
        NSColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 0.0).cgColor
    ] as CFArray
    if let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(glowGrad, startCenter: CGPoint(x: 512, y: 720), startRadius: 20, endCenter: CGPoint(x: 512, y: 512), endRadius: 460, options: .drawsAfterEndLocation)
    }
    
    // Subtle Inner Rim Bevel / Border
    ctx.setLineWidth(2.5)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.12).cgColor)
    ctx.addPath(squirclePath)
    ctx.strokePath()
    
    // Draw Mark inside icon
    drawSkyletMark(ctx: ctx, center: CGPoint(x: 512, y: 512), radius: 240)
    
    ctx.restoreGState()
    
    let masterUrl = URL(fileURLWithPath: "shots/icon_master_1024.png")
    saveContextToPNG(ctx: ctx, url: masterUrl)
}

func generateDropletMark() {
    let size = 1024
    guard let ctx = createCGContext(width: size, height: size) else { return }
    
    // Author inside 820x820 safe zone on transparent 1024x1024 canvas
    drawSkyletMark(ctx: ctx, center: CGPoint(x: 512, y: 512), radius: 250, isTransparentBackdrop: true)
    
    let markUrl = URL(fileURLWithPath: "Skylet.icon/Assets/mark.png")
    saveContextToPNG(ctx: ctx, url: markUrl)
}

func generateScalePreviews() {
    guard let masterImage = NSImage(contentsOfFile: "shots/icon_master_1024.png"),
          let cgImage = masterImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Failed to load master icon")
        return
    }
    
    let scales = [512, 256, 128, 64, 32, 16]
    for s in scales {
        guard let ctx = createCGContext(width: s, height: s) else { continue }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: s, height: s))
        let url = URL(fileURLWithPath: "shots/icon_\(s).png")
        saveContextToPNG(ctx: ctx, url: url)
    }
}

print("==> Generating Master Icon & Mark...")
generateMasterIcon()
generateDropletMark()
generateScalePreviews()
print("==> Done.")
