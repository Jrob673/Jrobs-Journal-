import CryptoKit
import Security
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
    var isLocked: Bool = false
    var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    private enum CodingKeys: String, CodingKey {
        case id, title, body, bookName, scriptureReference, tags, folder
        case isFavorite, isLocked, photoData, createdAt, updatedAt
    }

    init(id: UUID = UUID(), title: String, body: String, bookName: String? = nil,
         scriptureReference: String = "", tags: [String] = [], folder: String = "General",
         isFavorite: Bool = false, isLocked: Bool = false, photoData: Data? = nil,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.title = title; self.body = body; self.bookName = bookName
        self.scriptureReference = scriptureReference; self.tags = tags; self.folder = folder
        self.isFavorite = isFavorite; self.isLocked = isLocked; self.photoData = photoData
        self.createdAt = createdAt; self.updatedAt = updatedAt
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
        isLocked = try values.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        photoData = try values.decodeIfPresent(Data.self, forKey: .photoData)
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

private struct SecureJournalStorage {
    private let service = "com.jrob673.JRobsJournal.secure-storage"
    private let account = "journal-encryption-key.v1"
    let fileURL: URL

    init(directory overrideDirectory: URL? = nil, fileManager: FileManager = .default) {
        let base = (try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? fileManager.temporaryDirectory
        let directory = overrideDirectory ?? base.appendingPathComponent("JRobsJournal", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("journalEntries.v2.encrypted")
    }

    func load() throws -> [JournalEntry]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let sealedData = try Data(contentsOf: fileURL)
        let box = try AES.GCM.SealedBox(combined: sealedData)
        let clearData = try AES.GCM.open(box, using: try encryptionKey())
        return try JSONDecoder().decode([JournalEntry].self, from: clearData)
    }

    func save(_ entries: [JournalEntry]) throws {
        let clearData = try JSONEncoder().encode(entries)
        let sealedBox = try AES.GCM.seal(clearData, using: try encryptionKey())
        guard let combined = sealedBox.combined else { throw StorageError.invalidEncryptedData }
        try combined.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    private func encryptionKey() throws -> SymmetricKey {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data { return SymmetricKey(data: data) }
        guard status == errSecItemNotFound else { throw StorageError.keychain(status) }

        let keyData = Data(SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) })
        let add: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                  kSecAttrService as String: service,
                                  kSecAttrAccount as String: account,
                                  kSecValueData as String: keyData,
                                  kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw StorageError.keychain(addStatus) }
        return SymmetricKey(data: keyData)
    }

    private enum StorageError: LocalizedError {
        case keychain(OSStatus), invalidEncryptedData
        var errorDescription: String? {
            switch self {
            case .keychain(let status): "Apple Keychain error (\(status))."
            case .invalidEncryptedData: "Encrypted journal data could not be created."
            }
        }
    }
}

@MainActor
final class JournalStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []
    @Published private(set) var storageError: String?

    private let defaults: UserDefaults
    private let legacyStorageKey = "journalEntries.v1"
    private let secureStorage: SecureJournalStorage

    init(defaults: UserDefaults = .standard, storageDirectory: URL? = nil) {
        self.defaults = defaults
        secureStorage = SecureJournalStorage(directory: storageDirectory)
        load()
    }

    func save(_ entry: JournalEntry) {
        var updated = entry; updated.updatedAt = Date()
        if let index = entries.firstIndex(where: { $0.id == updated.id }) { entries[index] = updated }
        else { entries.append(updated) }
        sortEntries(); persist()
    }

    func delete(at offsets: IndexSet) { entries.remove(atOffsets: offsets); persist() }
    func delete(_ entry: JournalEntry) { entries.removeAll { $0.id == entry.id }; persist() }
    func toggleFavorite(_ entry: JournalEntry) {
        guard var updated = entries.first(where: { $0.id == entry.id }) else { return }
        updated.isFavorite.toggle(); save(updated)
    }

    func dismissStorageError() { storageError = nil }

    private func load() {
        do {
            if let encryptedEntries = try secureStorage.load() {
                entries = encryptedEntries; sortEntries(); return
            }
            let legacyEntries = try defaults.data(forKey: legacyStorageKey).map { try JSONDecoder().decode([JournalEntry].self, from: $0) } ?? []
            entries = legacyEntries; sortEntries()
            try secureStorage.save(entries)
            defaults.removeObject(forKey: legacyStorageKey)
        } catch {
            entries = []; storageError = "Journal storage could not be opened: \(error.localizedDescription)"
        }
    }

    private func sortEntries() { entries.sort { $0.updatedAt > $1.updatedAt } }
    private func persist() {
        do { try secureStorage.save(entries); storageError = nil }
        catch { storageError = "Journal changes could not be saved: \(error.localizedDescription)" }
    }
}
