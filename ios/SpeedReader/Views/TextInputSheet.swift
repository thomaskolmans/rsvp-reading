import SwiftUI

/// Text input + file import panel — TextInput.svelte parity.
struct TextInputSheet: View {

    @Binding var text: String
    @State private var draft: String
    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var importError: String?

    /// Receives the text to load plus an optional document title (file name).
    let onApply: (String, String?) -> Void
    let onClose: () -> Void

    init(text: Binding<String>, onApply: @escaping (String, String?) -> Void, onClose: @escaping () -> Void) {
        _draft = State(initialValue: text.wrappedValue)
        self.onApply = onApply
        self.onClose = onClose
        _text = text
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Paste or type your text") {
                    TextEditor(text: $draft)
                        .frame(minHeight: 220)
                        .font(.system(size: 15))
                        .scrollContentBackground(.hidden)
                        .background(Color(white: 0.06))
                }

                Section("Import a document") {
                    Button {
                        isImporting = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.arrow.up")
                            Text("Upload PDF, EPUB, TXT, FB2 or DOCX")
                        }
                    }

                    if isImporting {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(importMessage ?? "Loading…")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    if let importError {
                        Text(importError)
                            .font(.system(size: 13))
                            .foregroundColor(WordStage.focusRed)
                    }
                    Text("Extracted text replaces the editor content.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Load Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Load Text") {
                        text = draft
                        onApply(draft, nil)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: FileImportService.supportedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importMessage = String(format: String(localized: "Loading %@…"), url.lastPathComponent)
            importError = nil
            do {
                let extracted = try FileImportService.importText(from: url)
                // On mobile the import is the goal itself: load and dismiss
                // instead of making the user press "Load Text" afterwards.
                importMessage = nil
                onApply(extracted, url.deletingPathExtension().lastPathComponent)
                onClose()
            } catch {
                importMessage = nil
                importError = error.localizedDescription
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}
