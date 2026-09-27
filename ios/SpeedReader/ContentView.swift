import SwiftUI
import UIKit

/// Main reader screen — App.svelte parity plus mobile-native UX:
/// tap the word to play/pause, vertical swipe for speed, screen stays awake
/// while reading, haptic feedback on pause and completion.
struct ContentView: View {

    @StateObject private var engine = ReaderEngine()
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSettings = false
    @State private var showTextInput = false
    @State private var showJumpTo = false
    @State private var showLibrary = false
    @State private var savedSession: SavedSession?
    @State private var importError: String?

    private let toggleHaptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 0) {
            if !engine.isFocusMode {
                ReaderHeaderView(
                    theme: engine.settings.theme,
                    libraryActive: showLibrary,
                    jumpActive: showJumpTo,
                    textActive: showTextInput,
                    settingsActive: showSettings,
                    saveDisabled: engine.words.isEmpty,
                    onLibrary: { showLibrary.toggle() },
                    onJump: { showJumpTo.toggle() },
                    onSave: { _ = engine.saveSession() },
                    onText: { showTextInput.toggle() },
                    onSettings: { showSettings.toggle() }
                )
            }

            WordStage(
                frame: engine.currentFrame,
                fadeToken: engine.currentIndex,
                fadeEnabled: engine.settings.fadeEnabled,
                fadeDurationMs: engine.settings.fadeDurationMs,
                multiWordEnabled: engine.settings.frameWordCount > 1,
                theme: engine.settings.theme,
                wordFontSizePt: engine.settings.wordFontSizePt
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture(perform: handleDisplayTap)
            .onLongPressGesture(minimumDuration: 0.35) {
                engine.repeatSentence()
            }
            .gesture(wpmSwipeGesture)
            .accessibilityLabel(Text(String(format: String(localized: "Current word: %@"), engine.currentWord)))
            .accessibilityHint(Text("Double tap to play or pause"))

            bottomBar
        }
        .background(engine.settings.theme.background.ignoresSafeArea())
        .preferredColorScheme(engine.settings.theme.isLight ? .light : .dark)
        .onAppear {
            checkForSavedSession()
            importPendingSharedText()
            OrientationLock.apply(engine.settings.orientation)
        }
        .onChange(of: engine.settings.orientation) { _, orientation in
            OrientationLock.apply(orientation)
        }
        // Mobile replacement for the web's Ctrl+S: never lose the position
        // if the app is killed in the background.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                persistProgress()
            }
            if phase == .active {
                importPendingSharedText()
            }
        }
        // A speed reader must not have the screen dim mid-sentence.
        .onChange(of: engine.isPlaying) { _, playing in
            UIApplication.shared.isIdleTimerDisabled = playing
        }
        .onChange(of: engine.completionCount) { _, _ in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            StatsStore.flush()
        }
        .onOpenURL(perform: handleOpenURL)
        .sheet(isPresented: $showLibrary) {
            LibrarySheet(
                onOpen: { entry in
                    engine.load(text: entry.text)
                    engine.seek(toIndex: entry.currentIndex)
                    showLibrary = false
                },
                onClose: { showLibrary = false }
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(settings: $engine.settings) { showSettings = false }
        }
        .sheet(isPresented: $showTextInput) {
            TextInputSheet(
                text: .constant(engine.sourceText),
                onApply: { newText, title in
                    loadDocument(text: newText, title: title)
                    showTextInput = false
                },
                onClose: { showTextInput = false }
            )
        }
        .sheet(isPresented: $showJumpTo) {
            JumpToSheet(
                totalWords: engine.words.count,
                onJump: { engine.jump(to: $0) },
                onClose: { showJumpTo = false }
            )
        }
        .alert("Resume reading?", isPresented: Binding(
            get: { savedSession != nil },
            set: { if !$0 { savedSession = nil } }
        )) {
            Button("Start Fresh", role: .destructive) {
                SessionStore.clear()
                savedSession = nil
            }
            Button("Resume") {
                if let session = savedSession { engine.restore(session: session) }
                savedSession = nil
            }
        } message: {
            if let session = savedSession {
                Text(String(
                    format: String(localized: "You have a saved session at word %d of %d.\nSaved %@"),
                    session.currentWordIndex,
                    session.totalWords,
                    session.savedAt.formatted(date: .abbreviated, time: .shortened)
                ))
            }
        }
        .alert("Could not open file", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
    }

    // MARK: - Display gestures

    private func handleDisplayTap() {
        toggleHaptic.impactOccurred()
        engine.togglePlayPause()
    }

    /// Vertical swipe over the word: up = faster, down = slower (±25 WPM).
    private var wpmSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let isVertical = abs(value.translation.height) > abs(value.translation.width)
                guard isVertical else { return }
                if value.translation.height < 0 {
                    engine.adjustWpm(by: ReaderSettings.wpmStep)
                } else {
                    engine.adjustWpm(by: -ReaderSettings.wpmStep)
                }
            }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            ProgressBarView(
                progressPercent: engine.progressPercent,
                currentWord: engine.currentIndex,
                totalWords: engine.words.count,
                wpm: engine.settings.wordsPerMinute,
                timeRemaining: engine.timeRemaining,
                minimal: engine.isPlaying,
                seekEnabled: !engine.isPlaying,
                theme: engine.settings.theme
            ) { percentage in
                engine.seek(toPercent: percentage)
            }

            PlaybackControlsView(
                isPlaying: engine.isPlaying,
                isPaused: engine.isPaused,
                canPlay: engine.canPlay,
                minimal: engine.isFocusMode,
                wpm: engine.settings.wordsPerMinute,
                theme: engine.settings.theme,
                onPlay: engine.start,
                onPause: engine.pause,
                onResume: engine.resume,
                onStop: engine.stop,
                onRestart: engine.restart,
                onSkip: engine.skip(byWords:),
                onAdjustWpm: engine.adjustWpm(by:),
                onRepeatSentence: engine.repeatSentence
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Session / files

    /// Persists the active reading position everywhere it belongs:
    /// resume session, library entry and (batched) reading stats.
    private func persistProgress() {
        guard !engine.words.isEmpty else { return }
        _ = engine.saveSession()
        LibraryStore.upsert(
            text: engine.sourceText,
            title: nil,
            currentIndex: engine.currentIndex,
            totalWords: engine.words.count
        )
        StatsStore.flush()
    }

    /// Loads a new document into the engine and registers it in the library.
    private func loadDocument(text: String, title: String?) {
        engine.load(text: text)
        LibraryStore.upsert(text: text, title: title, currentIndex: 0, totalWords: engine.words.count)
    }

    /// A word-0 session carries no useful position — prompting "Resume" for it
    /// would be noise on every launch.
    private func checkForSavedSession() {
        guard let session = SessionStore.load(), session.currentWordIndex > 0 else { return }
        savedSession = session
    }

    private func handleOpenURL(url: URL) {
        if url.isFileURL {
            do {
                let text = try FileImportService.importText(from: url)
                loadDocument(text: text, title: url.deletingPathExtension().lastPathComponent)
            } catch {
                importError = error.localizedDescription
            }
        } else {
            // speedreader:// — the Share Extension's best-effort open.
            importPendingSharedText()
        }
    }

    /// Consumes text handed over by the Share Extension via the App Group.
    private func importPendingSharedText() {
        guard let share = AppGroupStore.takePendingText() else { return }
        loadDocument(text: share.text, title: share.title)
    }
}
