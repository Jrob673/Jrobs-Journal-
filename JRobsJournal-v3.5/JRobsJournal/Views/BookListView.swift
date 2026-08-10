import SwiftUI

struct BookListView: View {
    let testament: Testament

    @AppStorage("bibleDarkMode") private var bibleDarkMode = false

    var body: some View {
        List {
            Section {
                Toggle("Dark", isOn: $bibleDarkMode)
            }

            Section {
                ForEach(BibleBook.books(in: testament)) { book in
                    NavigationLink {
                        BookWorkspaceView(book: book)
                    } label: {
                        Label(book.name, systemImage: "book")
                            .foregroundStyle(bibleDarkMode ? Color.white : Color.primary)
                    }
                }
            }
        }
        .navigationTitle(testament.rawValue)
        .environment(\.colorScheme, bibleDarkMode ? ColorScheme.dark : ColorScheme.light)
    }
}

struct BookWorkspaceView: View {
    let book: BibleBook

    @AppStorage("bibleTranslation") private var bibleTranslation = BibleTranslation.web.rawValue
    @AppStorage("readerTextSize") private var readerTextSize = 19.0
    @AppStorage("readerBackground") private var readerBackground = ReaderBackground.automatic.rawValue
    @AppStorage("bibleDarkMode") private var bibleDarkMode = false

    @State private var selectedChapter = 1
    @State private var verses: [BibleVerse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isDownloadingOldTestament = false
    @State private var downloadedChapterCount = 0
    @State private var scriptureCopyright: String?

    private var selectedTranslation: BibleTranslation {
        BibleTranslation(rawValue: bibleTranslation) ?? .web
    }

    private var selectedReaderBackground: ReaderBackground {
        ReaderBackground(rawValue: readerBackground) ?? .automatic
    }

    private var readerTextColor: Color {
        switch selectedReaderBackground {
        case .automatic:
            bibleDarkMode ? .white : .black
        case .black:
            .white
        case .white, .cream, .gray:
            .black
        }
    }

    private var loadRequest: ScriptureRequest {
        ScriptureRequest(
            bookName: book.name,
            chapter: selectedChapter,
            translation: selectedTranslation.apiIdentifier
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            chapterControls
            Divider()
            readingContent
        }
        .background(selectedReaderBackground.color.ignoresSafeArea())
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, bibleDarkMode ? ColorScheme.dark : ColorScheme.light)
        .task(id: loadRequest) {
            await loadScripture(for: loadRequest)
        }
    }

    private var chapterControls: some View {
        VStack(spacing: 8) {
            HStack {
                Text(selectedTranslation.shortName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Picker("Chapter", selection: $selectedChapter) {
                    ForEach(1...book.chapterCount, id: \.self) { chapter in
                        Text("Chapter \(chapter)").tag(chapter)
                    }
                }
                .pickerStyle(.menu)
            }

            if selectedTranslation == .web {
                Label("World English Bible is available offline", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if selectedTranslation.requiresInternet {
                Label("Internet required", systemImage: "network")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if book.testament == .old {
                Button {
                    Task { await downloadOldTestament() }
                } label: {
                    if isDownloadingOldTestament {
                        Label(
                            "Saving chapter \(downloadedChapterCount) of \(BibleBook.oldTestamentChapterCount)",
                            systemImage: "arrow.down.circle"
                        )
                    } else {
                        Label("Download \(selectedTranslation.shortName) for Offline Use", systemImage: "arrow.down.circle")
                    }
                }
                .font(.caption.weight(.semibold))
                .disabled(isDownloadingOldTestament)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(readerTextColor)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(selectedReaderBackground.color)
    }

    @ViewBuilder
    private var readingContent: some View {
        if isLoading && verses.isEmpty {
            ProgressView("Loading \(book.name) \(selectedChapter)…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage, verses.isEmpty {
            ContentUnavailableView {
                Label("Unable to Load Scripture", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try Again") {
                    Task { await loadScripture(for: loadRequest) }
                }
                .buttonStyle(.borderedProminent)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text("\(book.name) \(selectedChapter)")
                        .font(.title2.bold())
                        .padding(.bottom, 4)

                    ForEach(verses) { verse in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(verse.verse)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 24, alignment: .trailing)

                            Text(verse.text.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.system(size: readerTextSize))
                                .textSelection(.enabled)
                        }
                    }

                    if let scriptureCopyright, !scriptureCopyright.isEmpty {
                        Text(scriptureCopyright)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                    }

                    NavigationLink {
                        EntryEditorView(bookName: book.name)
                    } label: {
                        Label("New \(book.name) Note", systemImage: "square.and.pencil")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 12)
                }
                .foregroundStyle(readerTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .refreshable {
                await loadScripture(for: loadRequest)
            }
        }
    }

    @MainActor
    private func loadScripture(for request: ScriptureRequest) async {
        isLoading = true
        errorMessage = nil
        verses = []
        scriptureCopyright = nil

        do {
            let loadedVerses = try await BibleAPI.load(request)
            try Task.checkCancellation()
            verses = loadedVerses
            scriptureCopyright = selectedTranslation.requiresInternet
                ? selectedTranslation.copyrightNotice
                : nil
        } catch is CancellationError {
            isLoading = false
            return
        } catch {
            guard !Task.isCancelled else { return }
            verses = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func downloadOldTestament() async {
        isDownloadingOldTestament = true
        downloadedChapterCount = 0

        for offlineBook in BibleBook.books(in: .old) {
            for chapter in 1...offlineBook.chapterCount {
                let request = ScriptureRequest(
                    bookName: offlineBook.name,
                    chapter: chapter,
                    translation: selectedTranslation.apiIdentifier
                )

                do {
                    _ = try await BibleAPI.load(request)
                    downloadedChapterCount += 1
                } catch {
                    errorMessage = "Offline download stopped at \(offlineBook.name) \(chapter). Check your internet connection and try again. Already saved chapters remain available."
                    isDownloadingOldTestament = false
                    return
                }
            }
        }

        isDownloadingOldTestament = false
    }
}

private struct ScriptureRequest: Hashable {
    let bookName: String
    let chapter: Int
    let translation: String
}

private struct BibleAPIResponse: Decodable {
    let verses: [BibleVerse]
}

private struct APIBibleResponse: Decodable {
    let data: APIBiblePassage
}

private struct APIBiblePassage: Decodable {
    let content: String
    let copyright: String?
}

private struct BibleVerse: Codable, Identifiable {
    let bookID: String
    let chapter: Int
    let verse: Int
    let text: String

    var id: String { "\(bookID)-\(chapter)-\(verse)" }

    private enum CodingKeys: String, CodingKey {
        case bookID = "book_id"
        case chapter
        case verse
        case text
    }
}

private enum BibleAPI {
    static func load(_ request: ScriptureRequest) async throws -> [BibleVerse] {
        if request.translation == "web",
           let bundled = try BundledScripture.load(request) {
            return bundled
        }

        if let cached = ScriptureCache.load(request) {
            return cached
        }

        if let translation = BibleTranslation.allCases.first(where: {
            $0.apiIdentifier == request.translation
        }), let bibleID = translation.apiBibleID {
            let verses = try await loadFromAPIBible(
                request,
                bibleID: bibleID
            )
            ScriptureCache.save(verses, for: request)
            return verses
        }

        let reference = "\(request.bookName) \(request.chapter)"
        guard let encodedReference = reference.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ),
        var components = URLComponents(
            string: "https://bible-api.com/\(encodedReference)"
        ) else {
            throw BibleAPIError.invalidRequest
        }

        components.queryItems = [
            URLQueryItem(name: "translation", value: request.translation)
        ]

        guard let url = components.url else {
            throw BibleAPIError.invalidRequest
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 30
        urlRequest.cachePolicy = .reloadRevalidatingCacheData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("JRobsJournal/3.8.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BibleAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw BibleAPIError.httpStatus(httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(BibleAPIResponse.self, from: data)
            guard !decoded.verses.isEmpty else {
                throw BibleAPIError.noScripture
            }
            ScriptureCache.save(decoded.verses, for: request)
            return decoded.verses
        } catch let error as BibleAPIError {
            throw error
        } catch {
            throw BibleAPIError.invalidData
        }
    }

    private static func loadFromAPIBible(
        _ request: ScriptureRequest,
        bibleID: String
    ) async throws -> [BibleVerse] {
        guard let apiKey = apiBibleKey, !apiKey.isEmpty else {
            throw BibleAPIError.missingAPIBibleKey
        }
        guard let bookID = apiBibleBookID(for: request.bookName) else {
            throw BibleAPIError.invalidRequest
        }

        let passageID = "\(bookID).\(request.chapter)"
        guard let url = URL(
            string: "https://api.scripture.api.bible/v1/bibles/\(bibleID)/passages/\(passageID)?content-type=html&include-notes=false&include-titles=false&include-chapter-numbers=false&include-verse-numbers=true"
        ) else {
            throw BibleAPIError.invalidRequest
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 30
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BibleAPIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BibleAPIError.httpStatus(httpResponse.statusCode)
        }

        let decoded: APIBibleResponse
        do {
            decoded = try JSONDecoder().decode(APIBibleResponse.self, from: data)
        } catch {
            throw BibleAPIError.invalidData
        }
        let verses = parseAPIBibleHTML(
            decoded.data.content,
            bookID: bookID,
            chapter: request.chapter
        )
        guard !verses.isEmpty else {
            throw BibleAPIError.noScripture
        }
        return verses
    }

    private static var apiBibleKey: String? {
        let bundleKeys = ["API_BIBLE_KEY", "API_BIBLE_API_KEY", "APIBibleKey"]
        for key in bundleKeys {
            if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !value.contains("$(") {
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ProcessInfo.processInfo.environment["API_BIBLE_KEY"]
    }

    private static func parseAPIBibleHTML(
        _ html: String,
        bookID: String,
        chapter: Int
    ) -> [BibleVerse] {
        // API.Bible does not guarantee HTML attribute order. First find each
        // verse marker, then use the text between consecutive markers.
        let markerPattern = #"<span\b(?=[^>]*\bclass\s*=\s*['\"][^'\"]*\bv\b[^'\"]*['\"])(?=[^>]*\bdata-number\s*=\s*['\"](\d+)['\"])[^>]*>.*?</span>"#
        guard let markerRegex = try? NSRegularExpression(
            pattern: markerPattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return [] }

        let fullRange = NSRange(html.startIndex..., in: html)
        let markers = markerRegex.matches(in: html, range: fullRange)

        return markers.enumerated().compactMap { index, marker in
            guard marker.numberOfRanges >= 2,
                  marker.range.location != NSNotFound,
                  let numberRange = Range(marker.range(at: 1), in: html),
                  let verseNumber = Int(html[numberRange]) else {
                return nil
            }

            let textStart = marker.range.location + marker.range.length
            let textEnd = index + 1 < markers.count
                ? markers[index + 1].range.location
                : fullRange.location + fullRange.length
            guard textEnd >= textStart,
                  let textRange = Range(
                    NSRange(location: textStart, length: textEnd - textStart),
                    in: html
                  ) else { return nil }

            let text = String(html[textRange])
                .replacingOccurrences(
                    of: "<[^>]+>",
                    with: " ",
                    options: .regularExpression
                )
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&#x27;", with: "'")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(
                    of: "\\s+",
                    with: " ",
                    options: .regularExpression
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else { return nil }
            return BibleVerse(
                bookID: bookID,
                chapter: chapter,
                verse: verseNumber,
                text: text
            )
        }
    }

    private static func apiBibleBookID(for name: String) -> String? {
        let ids = [
            "Genesis": "GEN", "Exodus": "EXO", "Leviticus": "LEV",
            "Numbers": "NUM", "Deuteronomy": "DEU", "Joshua": "JOS",
            "Judges": "JDG", "Ruth": "RUT", "1 Samuel": "1SA",
            "2 Samuel": "2SA", "1 Kings": "1KI", "2 Kings": "2KI",
            "1 Chronicles": "1CH", "2 Chronicles": "2CH", "Ezra": "EZR",
            "Nehemiah": "NEH", "Esther": "EST", "Job": "JOB",
            "Psalms": "PSA", "Proverbs": "PRO", "Ecclesiastes": "ECC",
            "Song of Solomon": "SNG", "Isaiah": "ISA", "Jeremiah": "JER",
            "Lamentations": "LAM", "Ezekiel": "EZK", "Daniel": "DAN",
            "Hosea": "HOS", "Joel": "JOL", "Amos": "AMO",
            "Obadiah": "OBA", "Jonah": "JON", "Micah": "MIC",
            "Nahum": "NAM", "Habakkuk": "HAB", "Zephaniah": "ZEP",
            "Haggai": "HAG", "Zechariah": "ZEC", "Malachi": "MAL",
            "Matthew": "MAT", "Mark": "MRK", "Luke": "LUK",
            "John": "JHN", "Acts": "ACT", "Romans": "ROM",
            "1 Corinthians": "1CO", "2 Corinthians": "2CO",
            "Galatians": "GAL", "Ephesians": "EPH", "Philippians": "PHP",
            "Colossians": "COL", "1 Thessalonians": "1TH",
            "2 Thessalonians": "2TH", "1 Timothy": "1TI",
            "2 Timothy": "2TI", "Titus": "TIT", "Philemon": "PHM",
            "Hebrews": "HEB", "James": "JAS", "1 Peter": "1PE",
            "2 Peter": "2PE", "1 John": "1JN", "2 John": "2JN",
            "3 John": "3JN", "Jude": "JUD", "Revelation": "REV"
        ]
        return ids[name]
    }
}

private struct BundledVerse: Decodable {
    let chapter: Int
    let verse: Int
    let text: String
}

private enum BundledScripture {
    static func load(_ request: ScriptureRequest) throws -> [BibleVerse]? {
        let resourceName = request.bookName
            .lowercased()
            .replacingOccurrences(of: " ", with: "")

        let resourceURL = Bundle.main.url(
            forResource: resourceName,
            withExtension: "json",
            subdirectory: "Scripture/WEB"
        ) ?? Bundle.main.url(forResource: resourceName, withExtension: "json")

        guard let resourceURL else { return nil }

        let data = try Data(contentsOf: resourceURL)
        let bookVerses = try JSONDecoder().decode([BundledVerse].self, from: data)
        let chapterVerses = bookVerses
            .filter { $0.chapter == request.chapter }
            .map {
                BibleVerse(
                    bookID: resourceName,
                    chapter: $0.chapter,
                    verse: $0.verse,
                    text: $0.text
                )
            }

        guard !chapterVerses.isEmpty else {
            throw BibleAPIError.noScripture
        }
        return chapterVerses
    }
}

private enum ScriptureCache {
    static func load(_ request: ScriptureRequest) -> [BibleVerse]? {
        guard let data = try? Data(contentsOf: fileURL(for: request)),
              let verses = try? JSONDecoder().decode([BibleVerse].self, from: data),
              !verses.isEmpty else {
            return nil
        }
        return verses
    }

    static func save(_ verses: [BibleVerse], for request: ScriptureRequest) {
        guard let data = try? JSONEncoder().encode(verses) else { return }
        let url = fileURL(for: request)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }

    private static func fileURL(for request: ScriptureRequest) -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let safeBookName = request.bookName.replacingOccurrences(of: " ", with: "-")
        return baseURL
            .appendingPathComponent("OfflineScripture", isDirectory: true)
            .appendingPathComponent(request.translation, isDirectory: true)
            .appendingPathComponent("\(safeBookName)-\(request.chapter).json")
    }
}

private enum BibleAPIError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case httpStatus(Int)
    case invalidData
    case noScripture
    case missingAPIBibleKey

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            "The selected book or chapter could not be requested."
        case .invalidResponse:
            "The Bible service returned an invalid response. Check your connection and try again."
        case .httpStatus(let statusCode):
            "The Bible service returned error \(statusCode). Check your connection and try again."
        case .invalidData:
            "The Bible service returned unreadable scripture data. Try again."
        case .noScripture:
            "No scripture text was returned for this chapter and translation."
        case .missingAPIBibleKey:
            "API.Bible key not found. Add API_BIBLE_KEY to the app target's Info settings, then rebuild."
        }
    }
}

private extension BibleTranslation {
    var shortName: String {
        switch self {
        case .web: "WEB"
        case .kjv: "KJV"
        case .asv: "ASV"
        case .niv: "NIV"
        case .nkjv: "NKJV"
        case .nlt: "NLT"
        }
    }

    var apiIdentifier: String {
        switch self {
        case .web: "web"
        case .kjv: "kjv"
        case .asv: "asv"
        case .niv: "api-bible-niv"
        case .nkjv: "api-bible-nkjv"
        case .nlt: "api-bible-nlt"
        }
    }

    var copyrightNotice: String? {
        switch self {
        case .niv:
            "Scripture quotations taken from The Holy Bible, New International Version® NIV®. Copyright © Biblica, Inc. Used by permission. All rights reserved worldwide."
        case .nkjv:
            "Scripture taken from the New King James Version®. Copyright © Thomas Nelson. Used by permission. All rights reserved."
        case .nlt:
            "Scripture quotations marked NLT are taken from the Holy Bible, New Living Translation. Copyright © Tyndale House Foundation. Used by permission."
        case .web, .kjv, .asv:
            nil
        }
    }
}

private extension BibleBook {
    static var oldTestamentChapterCount: Int {
        books(in: .old).reduce(0) { $0 + $1.chapterCount }
    }

    var chapterCount: Int {
        let counts = [
            "Genesis": 50, "Exodus": 40, "Leviticus": 27, "Numbers": 36,
            "Deuteronomy": 34, "Joshua": 24, "Judges": 21, "Ruth": 4,
            "1 Samuel": 31, "2 Samuel": 24, "1 Kings": 22, "2 Kings": 25,
            "1 Chronicles": 29, "2 Chronicles": 36, "Ezra": 10, "Nehemiah": 13,
            "Esther": 10, "Job": 42, "Psalms": 150, "Proverbs": 31,
            "Ecclesiastes": 12, "Song of Solomon": 8, "Isaiah": 66,
            "Jeremiah": 52, "Lamentations": 5, "Ezekiel": 48, "Daniel": 12,
            "Hosea": 14, "Joel": 3, "Amos": 9, "Obadiah": 1, "Jonah": 4,
            "Micah": 7, "Nahum": 3, "Habakkuk": 3, "Zephaniah": 3,
            "Haggai": 2, "Zechariah": 14, "Malachi": 4,
            "Matthew": 28, "Mark": 16, "Luke": 24, "John": 21, "Acts": 28,
            "Romans": 16, "1 Corinthians": 16, "2 Corinthians": 13,
            "Galatians": 6, "Ephesians": 6, "Philippians": 4, "Colossians": 4,
            "1 Thessalonians": 5, "2 Thessalonians": 3, "1 Timothy": 6,
            "2 Timothy": 4, "Titus": 3, "Philemon": 1, "Hebrews": 13,
            "James": 5, "1 Peter": 5, "2 Peter": 3, "1 John": 5,
            "2 John": 1, "3 John": 1, "Jude": 1, "Revelation": 22
        ]
        return counts[name] ?? 1
    }
}
