import SwiftUI

@main
struct JRobsJournalApp: App {
    @StateObject private var journalStore = JournalStore()
    @StateObject private var appLock = AppLockManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(journalStore)
                .environmentObject(appLock)
        }
    }
}
