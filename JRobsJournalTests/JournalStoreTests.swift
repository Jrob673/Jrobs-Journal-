import XCTest
@testable import JRobsJournal

@MainActor
final class JournalStoreTests: XCTestCase {
    func testSavePersistsEntry() throws {
        let suiteName = "JournalStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = JournalStore(defaults: defaults, storageDirectory: directory)
        store.save(JournalEntry(title: "Test", body: "Saved entry"))

        let restored = JournalStore(defaults: defaults, storageDirectory: directory)
        XCTAssertEqual(restored.entries.count, 1)
        XCTAssertEqual(restored.entries.first?.title, "Test")
    }

    func testStageTwoFieldsPersist() throws {
        let suiteName = "JournalStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = JournalStore(defaults: defaults, storageDirectory: directory)
        store.save(JournalEntry(title: "Sunday", body: "Notes", scriptureReference: "John 3:16", tags: ["Faith"], folder: "Church", isFavorite: true))

        let restored = JournalStore(defaults: defaults, storageDirectory: directory)
        let entry = try XCTUnwrap(restored.entries.first)
        XCTAssertEqual(entry.scriptureReference, "John 3:16")
        XCTAssertEqual(entry.tags, ["Faith"])
        XCTAssertEqual(entry.folder, "Church")
        XCTAssertTrue(entry.isFavorite)
    }

    func testPerEntryLockPersists() throws {
        let suiteName = "JournalStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = JournalStore(defaults: defaults, storageDirectory: directory)
        store.save(JournalEntry(title: "Private", body: "Locked content", isLocked: true))

        let restored = JournalStore(defaults: defaults, storageDirectory: directory)
        XCTAssertTrue(try XCTUnwrap(restored.entries.first).isLocked)
    }

    func testOlderEntryWithoutLockFieldDefaultsToUnlocked() throws {
        let json = #"{"title":"Existing entry","body":"Existing content"}"#.data(using: .utf8)!
        let entry = try JSONDecoder().decode(JournalEntry.self, from: json)
        XCTAssertFalse(entry.isLocked)
        XCTAssertNil(entry.audioData)
        XCTAssertNil(entry.reminderDate)
    }

    func testStageThreePartTwoFieldsPersist() throws {
        let suiteName = "JournalStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defer { try? FileManager.default.removeItem(at: directory) }
        let reminder = Date(timeIntervalSince1970: 1_900_000_000)
        let audio = Data([0x01, 0x02, 0x03])

        let store = JournalStore(defaults: defaults, storageDirectory: directory)
        store.save(JournalEntry(title: "Reminder", body: "Voice note", audioData: audio, reminderDate: reminder))

        let restored = try XCTUnwrap(JournalStore(defaults: defaults, storageDirectory: directory).entries.first)
        XCTAssertEqual(restored.audioData, audio)
        XCTAssertEqual(restored.reminderDate, reminder)
    }

    func testBackupRoundTripRestoresEntries() throws {
        let sourceName = "JournalStoreTests.source.\(UUID().uuidString)"
        let targetName = "JournalStoreTests.target.\(UUID().uuidString)"
        let sourceDefaults = try XCTUnwrap(UserDefaults(suiteName: sourceName))
        let targetDefaults = try XCTUnwrap(UserDefaults(suiteName: targetName))
        let sourceDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(sourceName)
        let targetDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(targetName)
        defer { sourceDefaults.removePersistentDomain(forName: sourceName); targetDefaults.removePersistentDomain(forName: targetName) }
        defer { try? FileManager.default.removeItem(at: sourceDirectory); try? FileManager.default.removeItem(at: targetDirectory) }

        let source = JournalStore(defaults: sourceDefaults, storageDirectory: sourceDirectory)
        source.save(JournalEntry(title: "Backup", body: "Restored", isLocked: true, audioData: Data([0x0A])))
        let backup = try source.exportData()
        let target = JournalStore(defaults: targetDefaults, storageDirectory: targetDirectory)
        try target.restore(from: backup)

        XCTAssertEqual(target.entries, source.entries)
    }

    func testLegacyEntriesMigrateToEncryptedStorage() throws {
        let suiteName = "JournalStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defer { try? FileManager.default.removeItem(at: directory) }

        let legacy = [JournalEntry(title: "Private title", body: "Private body")]
        defaults.set(try JSONEncoder().encode(legacy), forKey: "journalEntries.v1")

        let store = JournalStore(defaults: defaults, storageDirectory: directory)

        XCTAssertEqual(store.entries, legacy)
        XCTAssertNil(defaults.data(forKey: "journalEntries.v1"))
        let encryptedURL = directory.appendingPathComponent("journalEntries.v2.encrypted")
        let encryptedData = try Data(contentsOf: encryptedURL)
        XCTAssertFalse(String(data: encryptedData, encoding: .utf8)?.contains("Private body") ?? false)
    }
}
