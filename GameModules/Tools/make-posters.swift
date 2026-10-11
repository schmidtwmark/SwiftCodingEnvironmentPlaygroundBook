//
//  make-posters.swift  (Mac tool, not shipped in the book)
//
//  Draws each Game Design page's poster (PrivateResources/poster.png), the picture Swift Playgrounds
//  shows in the live view until the student taps Run My Code.
//
//  Swift Playgrounds scales a poster to FILL the live view and cuts off whatever doesn't fit, and the
//  live view can be tall and narrow (iPad side by side or portrait), nearly square (the Mac) or wide
//  (iPad landscape). So every poster is a square 1024 x 1024 title card that survives any crop:
//    - the background is the Part's color, a top-to-bottom gradient, so it can be cut anywhere;
//    - everything that matters sits on a white card inside the central 512 x 512 square, which stays
//      whole in every center crop from 1:2 (tall) to 2:1 (wide): the Part's name, a big emoji for the
//      page, the page's number and title, and "▶ Run My Code to play".
//  It is deliberately not a picture of the level, so nobody mistakes it for the game.
//
//  Titles come from the page manifests (Name) and Part names from the chapter manifests, so after
//  renaming or adding a page just run this again. Every page whose manifest has a PosterReference
//  gets a poster (the README and Hints pages have none). A new page also needs an emoji in `pageEmoji`.
//  The tool refuses to write a poster whose words or emoji would leave the card.
//
//  Usage:  zsh GameModules/Tools/make-posters.sh [Chapters folder]
//

import Foundation
import AppKit
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

/// One emoji per page (by page folder) that says what the page is about.
let pageEmoji: [String: String] = [
    // Part 1: Moving
    "Walk": "🚶", "Fall": "🍎", "Jump": "🦘", "CoyoteTime": "🐺",
    // Part 2: Coins and Effects
    "Coins": "🪙", "ShowTheScore": "🏆", "Sounds": "🔊", "Sparkles": "✨",
    // Part 3: Enemies
    "CrabPatrol": "🦀", "BusyBees": "🐝", "GhostChase": "👻", "Stomp": "🥾",
    // Part 4: Looks
    "HeroMoves": "🏃", "Backgrounds": "🌄",
    // Part 5: Power-ups
    "Boing": "🍄", "StarPower": "⭐", "Fireballs": "🔥",
    // Part 6: Rules of the Game
    "Stopwatch": "⏱️", "DeathCounter": "💥", "LivesAndGameOver": "❤️", "LockedFlag": "🔒", "Level2": "2️⃣",
    // Part 7: Your Game
    "DesignYourOwnGame": "🎨",
]

/// Each Part's colors: the background gradient (top, bottom) and a darker accent for words on the card.
/// (No Chapter10 since v7: Coyote Time is in Part 1, and the later folders kept their names and colors.)
struct PartStyle { let top: UInt32; let bottom: UInt32; let accent: UInt32 }
let partStyles: [(chapter: String, style: PartStyle)] = [
    ("Chapter9", PartStyle(top: 0x6CB8FF, bottom: 0x2F6FD6, accent: 0x1F5FC4)),   // Part 1: Moving, blue
    ("Chapter11", PartStyle(top: 0xFFD35C, bottom: 0xF0861C, accent: 0xB45A00)),  // Part 2: Coins and Effects, gold
    ("Chapter12", PartStyle(top: 0xFF8A78, bottom: 0xD8383A, accent: 0xC42B2E)),  // Part 3: Enemies, red
    ("Chapter13", PartStyle(top: 0x5FDCCF, bottom: 0x14958C, accent: 0x0D7F77)),  // Part 4: Looks, teal
    ("Chapter14", PartStyle(top: 0xFF96CF, bottom: 0xD43C95, accent: 0xC02A83)),  // Part 5: Power-ups, pink
    ("Chapter15", PartStyle(top: 0x8BDD7A, bottom: 0x2E9A4C, accent: 0x23843F)),  // Part 6: Rules of the Game, green
    ("Chapter16", PartStyle(top: 0x6F7FD8, bottom: 0x2B2F7C, accent: 0x3A43A8)),  // Part 7: Your Game, indigo
]

// MARK: - Layout (top-down coordinates on the 1024 x 1024 poster)

let side: CGFloat = 1024
/// The square that stays visible in every center crop from 1:2 to 2:1.
let safeSquare = CGRect(x: 256, y: 256, width: 512, height: 512)
/// The white card, a little inside the safe square so its shadow stays inside too.
let card = safeSquare.insetBy(dx: 24, dy: 24)
/// Where the words and the emoji go; the tool fails if anything is drawn outside it.
let inner = card.insetBy(dx: 28, dy: 28)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func roundedFont(_ size: CGFloat, _ weight: NSFont.Weight) -> CTFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    let rounded = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
    return rounded as CTFont
}

func line(_ text: String, font: CTFont, color: CGColor, kern: CGFloat = 0) -> CTLine {
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        NSAttributedString.Key(kCTKernAttributeName as String): kern,
    ]
    return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
}

func width(_ l: CTLine) -> CGFloat { CGFloat(CTLineGetTypographicBounds(l, nil, nil, nil)) }

func newContext(opaque: Bool = false) -> CGContext {
    CGContext(data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8, bytesPerRow: Int(side) * 4,
              space: CGColorSpace(name: CGColorSpace.sRGB)!,
              bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast).rawValue)!
}

/// The smallest rectangle (top-down) holding every pixel of `image` that isn't fully transparent.
func drawnBounds(_ image: CGImage) -> CGRect? {
    let w = image.width, h = image.height
    var pixels = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    var minX = w, minY = h, maxX = -1, maxY = -1
    for y in 0..<h {   // row 0 of the buffer is the top of the image
        for x in 0..<w where pixels[(y * w + x) * 4 + 3] > 0 {
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
    }
    return maxX < 0 ? nil : CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}

/// The emoji drawn big, trimmed to the pixels it really covers (so it can be centered by eye).
func emojiImage(_ text: String) -> CGImage {
    let n = 320
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let l = line(text, font: CTFontCreateWithName("AppleColorEmoji" as CFString, 200, nil), color: color(0))
    ctx.textPosition = CGPoint(x: (CGFloat(n) - width(l)) / 2, y: 80)
    CTLineDraw(l, ctx)
    let image = ctx.makeImage()!
    guard let box = drawnBounds(image) else { fatalError("the emoji \(text) draws nothing") }
    return image.cropping(to: box)!
}

/// The title in one line, or in two balanced lines if one line would have to get too small.
func titleLines(_ title: String, maxWidth: CGFloat) -> (lines: [String], size: CGFloat) {
    let biggest: CGFloat = 58, smallestOneLine: CGFloat = 46
    let measure = { (s: String) in width(line(s, font: roundedFont(biggest, .heavy), color: color(0))) }
    let one = measure(title)
    if biggest * min(1, maxWidth / one) >= smallestOneLine { return ([title], biggest * min(1, maxWidth / one)) }
    let words = title.split(separator: " ").map(String.init)
    var best: (lines: [String], widest: CGFloat) = ([title], one)
    for i in 1..<max(words.count, 2) where words.count >= 2 {
        let lines = [words[..<i].joined(separator: " "), words[i...].joined(separator: " ")]
        let widest = lines.map(measure).max()!
        if widest < best.widest { best = (lines, widest) }
    }
    return (best.lines, biggest * min(1, maxWidth / best.widest))
}

func poster(title: String, part: String, emoji: String, style: PartStyle) -> CGImage {
    // The words and the emoji go on their own transparent layer first, so the tool can check that
    // everything drawn stays inside the card.
    let fg = newContext()
    let flip = { (yTopDown: CGFloat) in side - yTopDown }   // CoreGraphics' y goes up

    let labelFont = roundedFont(24, .bold)
    var label = line(part.uppercased(), font: labelFont, color: color(style.accent), kern: 2)
    if width(label) > inner.width {
        label = line(part.uppercased(), font: roundedFont(24 * inner.width / width(label), .bold), color: color(style.accent), kern: 1)
    }
    let labelH = CTFontGetCapHeight(labelFont)
    let (titleText, titleSize) = titleLines(title, maxWidth: inner.width)
    let titleFont = roundedFont(titleSize, .heavy)
    let titleCap = CTFontGetCapHeight(titleFont), lineGap = titleSize * 1.12
    let titleH = titleCap + lineGap * CGFloat(titleText.count - 1) + CTFontGetDescent(titleFont) * 0.6
    let runFont = roundedFont(27, .semibold)
    let runH = CTFontGetCapHeight(runFont)
    let runDrop = CTFontGetDescent(runFont)   // the "p" and "y" of "play" hang below the line
    let gaps: [CGFloat] = [30, 30, 34]
    // The emoji gets the room the words leave (bigger when the title fits on one line).
    let picture = emojiImage(emoji)
    let emojiBox = min(205, max(150, inner.height - (labelH + titleH + runH + runDrop + gaps.reduce(0, +))))
    let scale = emojiBox / CGFloat(max(picture.width, picture.height))
    let emojiW = CGFloat(picture.width) * scale, emojiH = CGFloat(picture.height) * scale
    let total = labelH + gaps[0] + emojiH + gaps[1] + titleH + gaps[2] + runH + runDrop
    var y = inner.midY - total / 2   // top of the stack, top-down

    // The Part's name, small, in the Part's color.
    fg.textPosition = CGPoint(x: inner.midX - width(label) / 2, y: flip(y + labelH))
    CTLineDraw(label, fg)
    y += labelH + gaps[0]
    // The page's emoji.
    fg.draw(picture, in: CGRect(x: inner.midX - emojiW / 2, y: flip(y + emojiH), width: emojiW, height: emojiH))
    y += emojiH + gaps[1]
    // "20. Lives and Game Over", big.
    for (i, text) in titleText.enumerated() {
        let l = line(text, font: titleFont, color: color(0x1D1D1F))
        fg.textPosition = CGPoint(x: inner.midX - width(l) / 2, y: flip(y + titleCap + lineGap * CGFloat(i)))
        CTLineDraw(l, fg)
    }
    y += titleH + gaps[2]
    // "▶ Run My Code to play" (the ▶ is drawn, so it never turns into the colored ▶️ emoji).
    let run = line("Run My Code to play", font: runFont, color: color(0x5E5E66))
    let tri = runH * 1.05, space = runH * 0.55
    let runX = inner.midX - (tri * 0.9 + space + width(run)) / 2
    let base = flip(y + runH)
    fg.setFillColor(color(style.accent))
    fg.move(to: CGPoint(x: runX, y: base - (tri - runH) / 2))
    fg.addLine(to: CGPoint(x: runX, y: base + runH + (tri - runH) / 2))
    fg.addLine(to: CGPoint(x: runX + tri * 0.9, y: base + runH / 2))
    fg.closePath()
    fg.fillPath()
    fg.textPosition = CGPoint(x: runX + tri * 0.9 + space, y: base)
    CTLineDraw(run, fg)
    let content = fg.makeImage()!

    guard let drawn = drawnBounds(content), inner.insetBy(dx: -4, dy: -4).contains(drawn) else {
        print("error: \"\(title)\": the words or the emoji don't fit on the card (drawn \(String(describing: drawnBounds(content))), card \(card))")
        exit(1)
    }

    // The poster: the Part's gradient, the card with a soft shadow, then the words and the emoji.
    let ctx = newContext(opaque: true)   // no alpha channel: a smaller PNG
    // One solid color per row (CoreGraphics' own gradients dither, which makes the PNG 2-3 times bigger).
    let channels = { (hex: UInt32) in [hex >> 16 & 0xFF, hex >> 8 & 0xFF, hex & 0xFF].map { CGFloat($0) / 255 } }
    let top = channels(style.top), bottom = channels(style.bottom)
    for row in 0..<Int(side) {
        let t = CGFloat(row) / (side - 1), c = (0..<3).map { top[$0] + (bottom[$0] - top[$0]) * t }
        ctx.setFillColor(CGColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: 1))
        ctx.fill(CGRect(x: 0, y: flip(CGFloat(row + 1)), width: side, height: 1))
    }
    let cardPath = CGPath(roundedRect: CGRect(x: card.minX, y: flip(card.maxY), width: card.width, height: card.height),
                          cornerWidth: 56, cornerHeight: 56, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 24, color: CGColor(gray: 0, alpha: 0.28))
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.addPath(cardPath)
    ctx.fillPath()
    ctx.restoreGState()
    ctx.draw(content, in: CGRect(x: 0, y: 0, width: side, height: side))
    return ctx.makeImage()!
}

func plist(_ url: URL) -> [String: Any]? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
}

@main
struct MakePosters {
    static func main() {
        let args = CommandLine.arguments
        guard args.count == 2 else {
            print("usage: make-posters <the book's Chapters folder (the one with Chapter9.playgroundchapter)>")
            exit(2)
        }
        let chapters = URL(fileURLWithPath: args[1])
        for (chapter, style) in partStyles {
            let chapterDir = chapters.appendingPathComponent("\(chapter).playgroundchapter")
            guard let manifest = plist(chapterDir.appendingPathComponent("Manifest.plist")),
                  let part = manifest["Name"] as? String, let pages = manifest["Pages"] as? [String] else {
                print("skipped \(chapter): no chapter manifest")
                continue
            }
            for page in pages {
                let pageDir = chapterDir.appendingPathComponent("Pages/\(page)")
                guard let pageManifest = plist(pageDir.appendingPathComponent("Manifest.plist")) else {
                    print("error: \(chapter)/\(page) has no manifest")
                    exit(1)
                }
                guard let posterName = pageManifest["PosterReference"] as? String else { continue }   // README, Hints
                let folder = page.replacingOccurrences(of: ".playgroundpage", with: "")
                guard let title = pageManifest["Name"] as? String, let emoji = pageEmoji[folder] else {
                    print("error: \(chapter)/\(page) needs a Name in its manifest and an emoji in make-posters.swift's pageEmoji")
                    exit(1)
                }
                let dir = pageDir.appendingPathComponent("PrivateResources")
                try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let url = dir.appendingPathComponent(posterName)
                let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
                CGImageDestinationAddImage(dest, poster(title: title, part: part.replacingOccurrences(of: ":", with: " ·"),
                                                        emoji: emoji, style: style), nil)
                guard CGImageDestinationFinalize(dest) else { print("could not write \(url.path)"); exit(1) }
                print("wrote \(chapter)/\(page)/PrivateResources/\(posterName)")
            }
        }
    }
}
