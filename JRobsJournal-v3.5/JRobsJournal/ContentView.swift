import SwiftUI

struct ContentView: View {
    @AppStorage("appearance")
    private var appearance = Appearance.system.rawValue

    @AppStorage("readerTextSize")
    private var readerTextSize = 19.0

    @AppStorage("accentColor")
    private var accentColor = AppAccent.blue.rawValue

    private var colorScheme: ColorScheme? {
        Appearance(rawValue: appearance)?.colorScheme
    }

    var body: some View {
        NavigationStack {
            HomeView(
                appearance: $appearance,
                readerTextSize: $readerTextSize
            )
        }
        .preferredColorScheme(colorScheme)
        .tint(
            AppAccent(rawValue: accentColor)?.color
                ?? AppAccent.blue.color
        )
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
