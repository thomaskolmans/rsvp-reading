import SwiftUI

/// Color mapping for the reading-screen themes. Light themes flip every piece of
/// reading-screen chrome (word text, stats, button labels) so contrast is preserved.
extension ReaderThemeKind {

    var background: Color {
        switch self {
        case .black: return Color.black
        case .charcoal: return Color(red: 0.11, green: 0.11, blue: 0.13)
        case .navy: return Color(red: 0.05, green: 0.10, blue: 0.18)
        case .sepia: return Color(red: 0.96, green: 0.92, blue: 0.84)
        case .white: return Color.white
        }
    }

    var isLight: Bool {
        self == .sepia || self == .white
    }

    /// Main word glyphs (before/after the ORP letter).
    var wordText: Color {
        isLight ? Color(red: 0.16, green: 0.12, blue: 0.07) : .white
    }

    /// Dimmed context words in multi-word mode.
    var contextText: Color {
        isLight ? Color(white: 0.42) : Color(white: 0.4)
    }

    /// Header title and icon glyphs.
    var chromeText: Color {
        isLight ? Color.black.opacity(0.55) : .white.opacity(0.5)
    }

    /// Stats row (word count / WPM / time).
    var statsText: Color {
        isLight ? Color.black.opacity(0.7) : .white.opacity(0.7)
    }

    /// Control-chip fill (Play/Stop/touch buttons, header buttons).
    var chipFill: Color {
        isLight ? Color.black.opacity(0.07) : Color(white: 0.12)
    }

    var chipBorder: Color {
        isLight ? Color.black.opacity(0.18) : Color(white: 0.22)
    }

    var controlLabel: Color {
        isLight ? Color.black.opacity(0.8) : .white
    }

    /// "Ready" placeholder.
    var placeholderText: Color {
        isLight ? Color.black.opacity(0.25) : Color(white: 0.2)
    }

    var localizedName: String {
        let key: String.LocalizationValue
        switch self {
        case .black: key = "Black"
        case .charcoal: key = "Charcoal"
        case .navy: key = "Navy"
        case .sepia: key = "Sepia"
        case .white: key = "White"
        }
        return String(localized: key)
    }
}
