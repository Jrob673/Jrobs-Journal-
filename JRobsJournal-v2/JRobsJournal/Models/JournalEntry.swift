import SwiftUI

struct JournalEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var bookName: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

@MainActor
final class JournalStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []

    private let defaults: UserDefaults
    private let storageKey = "journalEntries.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func save(_ entry: JournalEntry) {
        var updated = entry
        updated.updatedAt = Date()

        if let index = entries.firstIndex(where: { $0.id == updated.id }) {
            entries[index] = updated
        } else {
            entries.insert(updated, at: 0)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        entries = (try? JSONDecoder().decode([JournalEntry].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
