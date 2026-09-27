import SwiftUI
import UIKit

/// Word display with the ORP letter pinned to the horizontal center,
/// replicating WordStage.svelte: monospaced font, red focus letter,
/// vertical focus markers, optional context words in multi-word mode.
struct WordStage: View {

    static let focusRed = Color(red: 1, green: 68 / 255, blue: 68 / 255)

    let frame: WordFrame
    let fadeToken: Int
    let fadeEnabled: Bool
    let fadeDurationMs: Int
    let multiWordEnabled: Bool
    let theme: ReaderThemeKind
    let wordFontSizePt: Int

    var body: some View {
        GeometryReader { geometry in
            let layout = WordLayout(
                frame: frame,
                multiWord: multiWordEnabled,
                preferredFontSize: CGFloat(wordFontSizePt),
                containerWidth: geometry.size.width,
                containerHeight: geometry.size.height
            )

            ZStack {
                focusMarker(atTop: true, container: geometry.size)
                focusMarker(atTop: false, container: geometry.size)

                if layout.parts == nil {
                    Text("Ready")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(theme.placeholderText)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                } else {
                    wordView(layout: layout)
                }
            }
        }
    }

    // MARK: - Word

    private func wordView(layout: WordLayout) -> some View {
        let built = buildSegments(layout: layout, theme: theme)
        let animation: Animation? = fadeEnabled
            ? .easeInOut(duration: Double(fadeDurationMs) / 1000)
            : nil

        return ZStack {
            segmentsView(built.segments)
                .position(
                    x: layout.positionX(charsBeforeOrpCenter: built.charsBeforeOrpCenter,
                                        totalChars: built.totalChars),
                    y: layout.containerHeight / 2
                )
        }
        .id(fadeToken)
        .transition(.opacity)
        .animation(animation, value: fadeToken)
    }

    private func segmentsView(_ segments: [Segment]) -> some View {
        HStack(spacing: 0) {
            ForEach(segments) { segment in
                Text(segment.text)
                    .font(Font(segment.font))
                    .foregroundColor(segment.color)
                    .fixedSize()
            }
        }
        // Segment order encodes the visual layout, so force LTR stacking
        // even for RTL words (each segment still shapes its own glyphs).
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - Focus markers

    private func focusMarker(atTop: Bool, container: CGSize) -> some View {
        let markerHeight = min(44, container.height / 4)
        let gradient = LinearGradient(
            colors: [Self.focusRed.opacity(0.9), .clear],
            startPoint: atTop ? .top : .bottom,
            endPoint: atTop ? .bottom : .top
        )
        return gradient
            .frame(width: 3, height: markerHeight)
            .position(
                x: container.width / 2,
                y: atTop ? markerHeight / 2 : container.height - markerHeight / 2
            )
    }
}

// MARK: - Layout model

private struct BuiltSegments {
    let segments: [Segment]
    let charsBeforeOrpCenter: Double
    let totalChars: Int
}

private struct Segment: Identifiable {
    let id: Int
    let text: String
    let font: UIFont
    let color: Color
}

/// Computes font size, monospace advance, and ORP centering for one frame.
private struct WordLayout {
    let parts: WordParts?
    let contextBefore: String
    let contextAfter: String
    let isRtl: Bool
    let font: UIFont
    let containerWidth: CGFloat
    let containerHeight: CGFloat

    init(
        frame: WordFrame,
        multiWord: Bool,
        preferredFontSize: CGFloat,
        containerWidth: CGFloat,
        containerHeight: CGFloat
    ) {
        self.containerWidth = containerWidth
        self.containerHeight = containerHeight

        guard frame.subset.indices.contains(frame.centerOffset),
              !frame.subset[frame.centerOffset].isEmpty else {
            self.parts = nil
            self.contextBefore = ""
            self.contextAfter = ""
            self.isRtl = false
            self.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
            return
        }

        let word = frame.subset[frame.centerOffset]
        let parts = ReadingUtils.splitWordForDisplay(word)
        self.parts = parts
        self.isRtl = ReadingUtils.isRightToLeft(word)

        let before = multiWord ? Array(frame.subset[0..<frame.centerOffset]) : []
        let after = multiWord ? Array(frame.subset[(frame.centerOffset + 1)...]) : []
        self.contextBefore = before.joined(separator: " ")
        self.contextAfter = after.joined(separator: " ")

        let totalChars = Self.totalCharCount(
            parts: parts, contextBefore: contextBefore, contextAfter: contextAfter
        )
        // Multi-word frames stay proportional to the chosen single-word size.
        let preferred = multiWord ? preferredFontSize * 0.48 : preferredFontSize
        self.font = Self.fittingFont(
            preferredSize: preferred,
            totalChars: totalChars,
            maxWidth: containerWidth * 0.94
        )
    }

    var advance: CGFloat {
        ("0" as NSString).size(withAttributes: [.font: font]).width
    }

    /// X position (center) of the whole HStack so the ORP letter sits mid-screen.
    func positionX(charsBeforeOrpCenter: Double, totalChars: Int) -> CGFloat {
        let containerCenter = containerWidth / 2
        let orpCenterInStack = CGFloat(charsBeforeOrpCenter) * advance
        let stackHalf = CGFloat(totalChars) * advance / 2
        return containerCenter - orpCenterInStack + stackHalf
    }

    static func fittingFont(preferredSize: CGFloat, totalChars: Int, maxWidth: CGFloat) -> UIFont {
        var size = preferredSize
        while size > 12 {
            let font = UIFont.monospacedSystemFont(ofSize: size, weight: .medium)
            let advance = ("0" as NSString).size(withAttributes: [.font: font]).width
            if CGFloat(totalChars) * advance <= maxWidth { return font }
            size -= 2
        }
        return UIFont.monospacedSystemFont(ofSize: max(12, size), weight: .medium)
    }

    static func totalCharCount(parts: WordParts, contextBefore: String, contextAfter: String) -> Int {
        var count = parts.before.count + parts.orp.count + parts.after.count
        if !contextBefore.isEmpty { count += contextBefore.count + 1 }
        if !contextAfter.isEmpty { count += contextAfter.count + 1 }
        return count
    }
}

/// Builds the visual segments left→right around the ORP letter.
/// For RTL words the order is mirrored (web-app parity).
private func buildSegments(layout: WordLayout, theme: ReaderThemeKind) -> BuiltSegments {
    guard let parts = layout.parts else {
        return BuiltSegments(segments: [], charsBeforeOrpCenter: 0, totalChars: 0)
    }

    let wordFont = layout.font
    let orpFont = UIFont.monospacedSystemFont(ofSize: wordFont.pointSize, weight: .bold)
    let contextFont = UIFont.monospacedSystemFont(ofSize: wordFont.pointSize, weight: .regular)
    let contextColor = theme.contextText

    var segments: [Segment] = []
    var charsBeforeOrp = 0

    func append(_ text: String, _ font: UIFont, _ color: Color) {
        guard !text.isEmpty else { return }
        segments.append(Segment(id: segments.count, text: text, font: font, color: color))
        charsBeforeOrp += text.count
    }

    let leadingContext = layout.isRtl ? layout.contextAfter : layout.contextBefore
    let leadingWordPart = layout.isRtl ? parts.after : parts.before
    if !leadingContext.isEmpty { append("\(leadingContext) ", contextFont, contextColor) }
    append(leadingWordPart, wordFont, theme.wordText)

    segments.append(Segment(id: segments.count, text: parts.orp, font: orpFont, color: WordStage.focusRed))
    let charsBeforeOrpCenter = Double(charsBeforeOrp) + 0.5

    let trailingWordPart = layout.isRtl ? parts.before : parts.after
    let trailingContext = layout.isRtl ? layout.contextBefore : layout.contextAfter
    append(trailingWordPart, wordFont, theme.wordText)
    if !trailingContext.isEmpty { append(" \(trailingContext)", contextFont, contextColor) }

    return BuiltSegments(
        segments: segments,
        charsBeforeOrpCenter: charsBeforeOrpCenter,
        totalChars: WordLayout.totalCharCount(
            parts: parts, contextBefore: layout.contextBefore, contextAfter: layout.contextAfter
        )
    )
}
