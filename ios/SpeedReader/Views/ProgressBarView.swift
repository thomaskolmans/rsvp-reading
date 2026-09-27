import SwiftUI

/// Clickable progress bar with word count / WPM / time-remaining stats
/// (ProgressBar.svelte parity; seek by tap or drag when not playing).
struct ProgressBarView: View {

    let progressPercent: Double
    let currentWord: Int
    let totalWords: Int
    let wpm: Int
    let timeRemaining: String
    let minimal: Bool
    let seekEnabled: Bool
    let theme: ReaderThemeKind
    let onSeek: (Double) -> Void

    private static let trackGray = Color(white: 0.13)

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Self.trackGray)
                    Capsule()
                        .fill(WordStage.focusRed)
                        .frame(width: fillWidth(total: geometry.size.width))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0).onChanged { value in
                        guard seekEnabled, geometry.size.width > 0 else { return }
                        let fraction = value.location.x / geometry.size.width
                        onSeek(min(100, max(0, fraction * 100)))
                    }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Reading progress"))
                .accessibilityValue("\(Int(progressPercent)) percent, \(timeRemaining) remaining")
            }
            .frame(height: seekEnabled ? 12 : 4)

            if !minimal {
                statsRow
            }
        }
    }

    private var statsRow: some View {
        HStack {
            Text("\(currentWord) / \(totalWords)")
            Spacer()
            Text("\(wpm) WPM")
                .foregroundColor(WordStage.focusRed)
                .monospacedDigit()
            Spacer()
            Text(timeRemaining).monospacedDigit()
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(theme.statsText)
    }

    private func fillWidth(total: CGFloat) -> CGFloat {
        max(0, min(total, total * progressPercent / 100))
    }
}
