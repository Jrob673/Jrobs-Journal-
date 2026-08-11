import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appLock: AppLockManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    @AppStorage("readerTextSize") private var readerTextSize = 19.0
    @AppStorage("accentColor") private var accentColor = AppAccent.blue.rawValue

    private var colorScheme: ColorScheme? { Appearance(rawValue: appearance)?.colorScheme }

    var body: some View {
        Group {
            if appLock.isEnabled && !appLock.isUnlocked {
                JournalLockView()
            } else {
                NavigationStack { HomeView(appearance: $appearance, readerTextSize: $readerTextSize) }
            }
        }
        .preferredColorScheme(colorScheme)
        .tint(AppAccent(rawValue: accentColor)?.color ?? AppAccent.blue.color)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { appLock.lock() }
            else if appLock.isEnabled && !appLock.isUnlocked { Task { await appLock.unlock() } }
        }
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}
