import Foundation

enum BibleTranslation: String, CaseIterable, Identifiable {
    case web = "World English Bible (WEB)"
    case kjv = "King James Version (KJV)"
    case asv = "American Standard Version (ASV)"

    var id: String { rawValue }
}
