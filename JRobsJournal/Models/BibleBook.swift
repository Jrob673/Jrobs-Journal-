import Foundation

enum Testament: String, CaseIterable, Identifiable {
    case old = "Old Testament"
    case new = "New Testament"

    var id: String { rawValue }
}

struct BibleBook: Identifiable, Hashable {
    let name: String
    let testament: Testament
    var id: String { name }

    static let oldTestamentNames = [
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
        "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings",
        "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah",
        "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes",
        "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations", "Ezekiel",
        "Daniel", "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah",
        "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi"
    ]

    static let newTestamentNames = [
        "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
        "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
        "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
        "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
        "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"
    ]

    static let all: [BibleBook] =
        oldTestamentNames.map { BibleBook(name: $0, testament: .old) } +
        newTestamentNames.map { BibleBook(name: $0, testament: .new) }

    static func books(in testament: Testament) -> [BibleBook] {
        all.filter { $0.testament == testament }
    }
}
