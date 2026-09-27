// Renders the Speed Reader app icon (1024x1024 PNG) with AppKit.
// Design: black square, white monospaced "speed" with the ORP letter "e" in red
// pinned to the horizontal center, red focus markers above and below.
import AppKit

let focusRed = NSColor(red: 1, green: 68 / 255, blue: 68 / 255, alpha: 1)
let size: CGFloat = 1024
let word = "speed"
let orpIndex = 1 // ORP of a 5-letter word — the "e"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { fatalError("no context") }

// Background: near-black with a subtle vertical gradient
let colors = [NSColor(white: 0.10, alpha: 1).cgColor, NSColor.black.cgColor] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// Word: draw fully white, then overdraw the ORP letter in red.
let fontSize: CGFloat = 300
let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
let whiteAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
let redAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: focusRed]

let whole = NSAttributedString(string: word, attributes: whiteAttrs)
let advance = ("0" as NSString).size(withAttributes: whiteAttrs).width
let totalWidth = CGFloat(word.count) * advance
let firstLetterX = (size - totalWidth) / 2
let baselineY = (size - fontSize * 0.72) / 2 // optically center the x-height block

let prefix = NSAttributedString(string: String(word.prefix(orpIndex)), attributes: whiteAttrs)
let orpLetter = NSAttributedString(string: String(Array(word)[orpIndex]), attributes: redAttrs)

whole.draw(at: NSPoint(x: firstLetterX, y: baselineY))
// Redraw the ORP letter slightly left so ITS center (not its advance box) sits mid-icon,
// matching the in-app ORP display.
orpLetter.draw(at: NSPoint(x: firstLetterX + CGFloat(orpIndex) * advance, y: baselineY))

// Focus markers: vertical red capsules above and below the word, centered on the ORP letter
let orpCenterX = firstLetterX + CGFloat(orpIndex) * advance + advance / 2
let markerWidth: CGFloat = 22
let markerHeight: CGFloat = 150
let markerMargin: CGFloat = 96
for positionY in [size - markerMargin - markerHeight, markerMargin] {
    let rect = CGRect(
        x: orpCenterX - markerWidth / 2,
        y: positionY,
        width: markerWidth,
        height: markerHeight
    )
    let path = NSBezierPath(roundedRect: rect, xRadius: markerWidth / 2, yRadius: markerWidth / 2)
    focusRed.withAlphaComponent(0.85).setFill()
    path.fill()
}
_ = prefix

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG encoding failed")
}
let output = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon1024.png"
try! png.write(to: URL(fileURLWithPath: output))
print("wrote \(output) (\(png.count) bytes)")
