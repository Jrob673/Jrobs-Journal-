import XCTest
@testable import JRobsJournal

@MainActor
final class JournalStoreTests: XCTestCase {
    func testSavePersistsEntry() throws {
        let suiteName = "JournalStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = JournalStore(defaults: defaults)
        store.save(JournalEntry(title: "Test", body: "Saved entry"))

        let restored = JournalStore(defaults: defaults)
        XCTAssertEqual(restored.entries.count, 1)
        XCTAssertEqual(restored.entries.first?.title, "Test")
    }

    func testStageTwoFieldsPersist() throws {
        let suiteName = "JournalStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = JournalStore(defaults: defaults)
        store.save(JournalEntry(title: "Sunday", body: "Notes", scriptureReference: "John 3:16", tags: ["Faith"], folder: "Church", isFavorite: true))

        let restored = JournalStore(defaults: defaults)
        let entry = try XCTUnwrap(restored.entries.first)
        XCTAssertEqual(entry.scriptureReference, "John 3:16")
        XCTAssertEqual(entry.tags, ["Faith"])
        XCTAssertEqual(entry.folder, "Church")
        XCTAssertTrue(entry.isFavorite)
    }
}
