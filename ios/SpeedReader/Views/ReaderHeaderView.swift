import SwiftUI

/// Top bar with the app title and the action buttons (library, jump to
/// position, save progress, load content, settings). Colored by the
/// active reading theme.
struct ReaderHeaderView: View {

    let theme: ReaderThemeKind
    let libraryActive: Bool
    let jumpActive: Bool
    let textActive: Bool
    let settingsActive: Bool
    let saveDisabled: Bool
    let onLibrary: () -> Void
    let onJump: () -> Void
    let onSave: () -> Void
    let onText: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack {
            Text("Speed Reader")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(theme.chromeText)
            Spacer()
            HStack(spacing: 8) {
                headerButton("books.vertical", isActive: libraryActive) { onLibrary() }
                    .accessibilityLabel(Text("Library"))

                headerButton("chevron.left.forwardslash.chevron.right", isActive: jumpActive) { onJump() }
                    .accessibilityLabel(Text("Jump to position"))

                headerButton("square.and.arrow.down", isActive: false) { onSave() }
                    .disabled(saveDisabled)
                    .accessibilityLabel(Text("Save progress"))

                headerButton("doc", isActive: textActive) { onText() }
                    .accessibilityLabel(Text("Load content"))

                headerButton("gearshape", isActive: settingsActive) { onSettings() }
                    .accessibilityLabel(Text("Settings"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func headerButton(_ systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 38, height: 38)
                .background(theme.chipFill)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.chipBorder, lineWidth: 1))
                .foregroundColor(isActive ? WordStage.focusRed : theme.chromeText)
        }
        .buttonStyle(.plain)
    }
}