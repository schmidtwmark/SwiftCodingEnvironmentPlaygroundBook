// Draws the book icon (902 x 678, like turtleicon.png). Usage: swift make-icon.swift out.png
import AppKit
let size = NSSize(width: 902, height: 678)
let image = NSImage(size: size)
image.lockFocus()
NSColor(red: 0.75, green: 0.89, blue: 1, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()
NSColor(red: 0.42, green: 0.29, blue: 0.17, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: 902, height: 170).fill()
NSColor(red: 0.36, green: 0.72, blue: 0.27, alpha: 1).setFill()
NSRect(x: 0, y: 150, width: 902, height: 30).fill()
NSColor(red: 0.42, green: 0.29, blue: 0.17, alpha: 1).setFill()
NSRect(x: 520, y: 330, width: 260, height: 60).fill()
NSColor(red: 0.36, green: 0.72, blue: 0.27, alpha: 1).setFill()
NSRect(x: 520, y: 380, width: 260, height: 14).fill()
func emoji(_ s: String, _ x: CGFloat, _ y: CGFloat, _ pt: CGFloat) {
    NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: pt)]).draw(at: NSPoint(x: x, y: y))
}
emoji("☁️", 90, 520, 90); emoji("☁️", 640, 560, 70)
emoji("🙂", 120, 300, 130)
emoji("🦀", 330, 175, 110)
emoji("🪙", 560, 400, 70); emoji("🪙", 660, 400, 70)
emoji("🚩", 740, 175, 120)
image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
