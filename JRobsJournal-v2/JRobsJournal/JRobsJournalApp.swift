import SwiftUI

@main
struct JRobsJournalApp: App {
    @StateObject private var journalStore = JournalStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(journalStore)
        }
    }
}
