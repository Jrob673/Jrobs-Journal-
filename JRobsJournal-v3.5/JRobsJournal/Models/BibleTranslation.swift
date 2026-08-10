import Foundation

enum BibleTranslation: String, CaseIterable, Identifiable {
    case web = "World English Bible (WEB)"
    case kjv = "King James Version (KJV)"
    case asv = "American Standard Version (ASV)"
    case niv = "New International Version (NIV 2011)"
    case nkjv = "New King James Version (NKJV)"
    case nlt = "New Living Translation (NLT)"

    var id: String { rawValue }

    var apiBibleID: String? {
        switch self {
        case .niv: "78a9f6124f344018-01"
        case .nkjv: "63097d2a0a2f7db3-01"
        case .nlt: "d6e14a625393b4da-01"
        case .web, .kjv, .asv: nil
        }
    }

    var requiresInternet: Bool {
        apiBibleID != nil
    }
}
