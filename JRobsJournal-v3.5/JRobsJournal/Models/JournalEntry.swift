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
            entries.append(updated)
        }

        sortEntries()
        persist()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        persist()
    }

    func delete(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else {
            entries = []
            return
        }

        do {
            entries = try JSONDecoder().decode([JournalEntry].self, from: data)
            sortEntries()
        } catch {
            entries = []
        }
    }

    private func sortEntries() {
        entries.sort { $0.updatedAt > $1.updatedAt }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(entries)
            defaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Unable to save journal entries: \(error.localizedDescription)")
        }
    }
}
