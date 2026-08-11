import SwiftUI

struct JournalEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var bookName: String?
    var scriptureReference: String = ""
    var tags: [String] = []
    var folder: String = "General"
    var isFavorite: Bool = false
    var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    private enum CodingKeys: String, CodingKey {
        case id, title, body, bookName, scriptureReference, tags, folder
        case isFavorite, photoData, createdAt, updatedAt
    }

    init(
        id: UUID = UUID(), title: String, body: String, bookName: String? = nil,
        scriptureReference: String = "", tags: [String] = [], folder: String = "General",
        isFavorite: Bool = false, photoData: Data? = nil,
        createdAt: Date = Date(), updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.bookName = bookName
        self.scriptureReference = scriptureReference
        self.tags = tags
        self.folder = folder
        self.isFavorite = isFavorite
        self.photoData = photoData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try values.decodeIfPresent(String.self, forKey: .body) ?? ""
        bookName = try values.decodeIfPresent(String.self, forKey: .bookName)
        scriptureReference = try values.decodeIfPresent(String.self, forKey: .scriptureReference) ?? ""
        tags = try values.decodeIfPresent([String].self, forKey: .tags) ?? []
        folder = try values.decodeIfPresent(String.self, forKey: .folder) ?? "General"
        isFavorite = try values.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        photoData = try values.decodeIfPresent(Data.self, forKey: .photoData)
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
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

    func toggleFavorite(_ entry: JournalEntry) {
        guard var updated = entries.first(where: { $0.id == entry.id }) else { return }
        updated.isFavorite.toggle()
        save(updated)
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
