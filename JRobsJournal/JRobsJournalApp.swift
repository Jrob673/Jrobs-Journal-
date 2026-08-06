import SwiftUI

@main
struct JRobsJournalApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = 0
    var body: some Scene {
        WindowGroup { HomeView().preferredColorScheme(colorScheme) }
    }
    private var colorScheme: ColorScheme? {
        appearanceMode == 1 ? .light : appearanceMode == 2 ? .dark : nil
    }
}
