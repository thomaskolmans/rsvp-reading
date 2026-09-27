import SwiftUI

/// Settings panel — Settings.svelte parity: speed, display, effects, pauses.
struct SettingsSheet: View {

    @Binding var settings: ReaderSettings
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                speedSection
                displaySection
                effectsSection
                pausesSection
                languageSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Speed

    private var speedSection: some View {
        Section("Speed") {
            VStack(spacing: 6) {
                Text("\(settings.wordsPerMinute)")
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("words/min")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.45))
                Slider(
                    value: Binding(
                        get: { Double(settings.wordsPerMinute) },
                        set: { settings.wordsPerMinute = Int($0 / Double(ReaderSettings.wpmStep)) * ReaderSettings.wpmStep }
                    ),
                    in: Double(ReaderSettings.wpmRange.lowerBound)...Double(ReaderSettings.wpmRange.upperBound),
                    step: Double(ReaderSettings.wpmStep)
                )
                .tint(WordStage.focusRed)
                HStack(spacing: 8) {
                    ForEach(ReaderSettings.wpmPresets, id: \.self) { preset in
                        presetButton(preset)
                    }
                }
            }
            .listRowBackground(Color(white: 0.07))

            stepperRow(
                title: "Lower WPM for longer words",
                value: $settings.wordLengthWPMMultiplier,
                range: 0...50,
                step: 1,
                suffix: "%",
                hint: "Percentage points each extra letter adds to the pause"
            )
        }
    }

    private func presetButton(_ preset: Int) -> some View {
        Button(String(preset)) {
            settings.wordsPerMinute = preset
        }
        .font(.system(size: 15, weight: .medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            settings.wordsPerMinute == preset
                ? WordStage.focusRed
                : Color(white: 0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .foregroundColor(.white)
    }

    // MARK: - Display

    private var displaySection: some View {
        Section("Display") {
            sliderRow(
                title: String(localized: "Word size"),
                value: Binding(
                    get: { Double(settings.wordFontSizePt) },
                    set: { settings.wordFontSizePt = Int($0) }
                ),
                range: Double(ReaderSettings.fontSizeRange.lowerBound)...Double(ReaderSettings.fontSizeRange.upperBound),
                step: 2,
                suffix: " pt"
            )

            themePicker

            Picker(String(localized: "Reading orientation"), selection: $settings.orientation) {
                Text("Auto").tag(ReadingOrientation.auto)
                Text("Portrait").tag(ReadingOrientation.portrait)
                Text("Landscape").tag(ReadingOrientation.landscape)
            }
            .pickerStyle(.segmented)

            Picker("Words shown simultaneously", selection: $settings.frameWordCount) {
                ForEach([1, 3, 5, 7], id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .pickerStyle(.segmented)
            Text("Odd numbers (1, 3, 5, 7) center the highlight best")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Background")
            HStack(spacing: 12) {
                ForEach(ReaderThemeKind.allCases, id: \.self) { kind in
                    Button {
                        settings.theme = kind
                    } label: {
                        Circle()
                            .fill(kind.background)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle().stroke(
                                    kind == settings.theme
                                        ? WordStage.focusRed
                                        : Color.white.opacity(0.25),
                                    lineWidth: kind == settings.theme ? 3 : 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(kind.localizedName)
                }
            }
        }
    }

    // MARK: - Effects

    private var effectsSection: some View {
        Section("Effects") {
            Toggle("Word fade", isOn: $settings.fadeEnabled)
                .tint(WordStage.focusRed)
            if settings.fadeEnabled {
                sliderRow(
                    title: "Duration",
                    value: Binding(
                        get: { Double(settings.fadeDurationMs) },
                        set: { settings.fadeDurationMs = Int($0) }
                    ),
                    range: 50...300,
                    step: 25,
                    suffix: "ms"
                )
            }
        }
    }

    // MARK: - Pauses

    private var pausesSection: some View {
        Section("Pauses") {
            Toggle("Pause on punctuation", isOn: $settings.pauseOnPunctuation)
                .tint(WordStage.focusRed)
            if settings.pauseOnPunctuation {
                sliderRow(
                    title: "Pause multiplier",
                    value: $settings.punctuationPauseMultiplier,
                    range: 1...4,
                    step: 0.5,
                    suffix: "x",
                    format: "%.1f"
                )
            }
            stepperRow(
                title: "Pause every N words",
                value: $settings.pauseAfterWords,
                range: 0...50,
                step: 5,
                suffix: settings.pauseAfterWords == 0 ? " Off" : ""
            )
            if settings.pauseAfterWords > 0 {
                sliderRow(
                    title: "Pause duration",
                    value: Binding(
                        get: { Double(settings.pauseDurationMs) },
                        set: { settings.pauseDurationMs = Int($0) }
                    ),
                    range: 100...2000,
                    step: 100,
                    suffix: "ms"
                )
            }
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        Section("Language") {
            Picker("Language", selection: $settings.appLanguage) {
                Text("System").tag(AppLanguage.system)
                Text("English").tag(AppLanguage.english)
                Text("Русский").tag(AppLanguage.russian)
            }
            .pickerStyle(.menu)
            .onAppear {
                // The picker mirrors the applied override, which lives in
                // UserDefaults (the session copy may not match yet).
                settings.appLanguage = LanguageOverride.current()
            }
            .onChange(of: settings.appLanguage) { _, newValue in
                LanguageOverride.set(newValue)
            }
            Text("Restart the app for the language to apply")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Row builders

    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String,
        format: String = "%.0f"
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue) + suffix)
                    .foregroundColor(WordStage.focusRed)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
                .tint(WordStage.focusRed)
        }
    }

    private func stepperRow(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int,
        suffix: String,
        hint: String? = nil
    ) -> some View {
        VStack(spacing: 4) {
            Stepper(
                value: value,
                in: range,
                step: step
            ) {
                HStack {
                    Text(title)
                    Spacer()
                    Text(value.wrappedValue == 0 && title.contains("N words") ? "Off" : "\(value.wrappedValue)\(suffix)")
                        .foregroundColor(WordStage.focusRed)
                        .monospacedDigit()
                }
            }
            if let hint {
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
