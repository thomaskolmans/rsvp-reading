import SwiftUI

/// Jump-to-position panel — word number or "50%", with quick presets
/// (jump-to panel from App.svelte).
struct JumpToSheet: View {

    let totalWords: Int
    let onJump: (String) -> Void
    let onClose: () -> Void

    @State private var value = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter word number (e.g., 150) or percentage (e.g., 50%)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Word # or %", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit(apply)

                Button("Go", action: apply)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(WordStage.focusRed)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.white)

                Divider().overlay(Color.white.opacity(0.12))

                HStack(spacing: 8) {
                    quickButton("Start", value: "0")
                    quickButton("25%", value: "25%")
                    quickButton("50%", value: "50%")
                    quickButton("75%", value: "75%")
                }

                Spacer()
            }
            .padding(20)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Jump to position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onClose)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func apply() {
        onJump(value)
        onClose()
    }

    private func quickButton(_ title: String, value: String) -> some View {
        Button(title) {
            onJump(value)
            onClose()
        }
        .font(.system(size: 14, weight: .medium))
        .frame(maxWidth: .infinity, minHeight: 42)
        .background(Color(white: 0.12))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.22), lineWidth: 1))
        .foregroundColor(.white.opacity(0.8))
    }
}
