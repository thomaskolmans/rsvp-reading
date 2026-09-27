import SwiftUI

/// Play / Pause / Resume / Stop / Restart plus the touch row
/// (back 5 words, -WPM, WPM, +WPM, forward 5 words) — Controls.svelte parity.
struct PlaybackControlsView: View {

    let isPlaying: Bool
    let isPaused: Bool
    let canPlay: Bool
    let minimal: Bool
    let wpm: Int
    let theme: ReaderThemeKind
    let onPlay: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onRestart: () -> Void
    let onSkip: (Int) -> Void
    let onAdjustWpm: (Int) -> Void
    let onRepeatSentence: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            transportRow
            // While paused (even in focus mode) speed/word controls are the whole
            // point of pausing, so keep them available.
            if !minimal || isPaused {
                touchRow
            }
        }
    }

    private var transportRow: some View {
        HStack(spacing: 16) {
            primaryButton
            controlButton(
                title: "Stop",
                systemImage: "stop.fill",
                disabled: !isPlaying && !isPaused,
                action: onStop
            )
            controlButton(
                title: "Restart",
                systemImage: "arrow.counterclockwise",
                disabled: false,
                action: onRestart
            )
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        if isPlaying {
            controlButton(title: "Pause", systemImage: "pause.fill", disabled: false, action: onPause)
                .tint(WordStage.focusRed)
        } else if isPaused {
            controlButton(title: "Resume", systemImage: "play.fill", disabled: false, action: onResume)
                .tint(WordStage.focusRed)
        } else {
            controlButton(title: "Play", systemImage: "play.fill", disabled: !canPlay, action: onPlay)
                .tint(WordStage.focusRed)
        }
    }

    private var touchRow: some View {
        HStack(spacing: 8) {
            touchButton("arrow.uturn.backward", label: "Repeat sentence") { onRepeatSentence() }
            touchButton("chevron.left.2", label: "Back 5 words") { onSkip(-5) }
            touchButton(nil, label: "−WPM") { onAdjustWpm(-50) }
            Text("\(wpm)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(WordStage.focusRed)
                .frame(minWidth: 44)
            touchButton(nil, label: "+WPM") { onAdjustWpm(50) }
            touchButton("chevron.right.2", label: "Forward 5 words") { onSkip(5) }
        }
    }

    private func touchButton(
        _ systemImage: String?,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 14, weight: .semibold))
                } else {
                    Text(label).font(.system(size: 13, weight: .medium))
                }
            }
            .frame(minWidth: 44, minHeight: 40)
            .background(theme.chipFill)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.chipBorder, lineWidth: 1))
            .foregroundColor(theme.controlLabel.opacity(0.85))
        }
        .accessibilityLabel(String(localized: String.LocalizationValue(label)))
    }

    private func controlButton(
        title: String,
        systemImage: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                if !minimal { Text(title).font(.system(size: 14, weight: .medium)) }
            }
            .frame(minWidth: minimal ? 48 : 72, minHeight: 44)
            .background(theme.chipFill)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.chipBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundColor(theme.controlLabel)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
        .accessibilityLabel(String(localized: String.LocalizationValue(title)))
    }
}
