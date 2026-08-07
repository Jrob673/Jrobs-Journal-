import SwiftUI

struct BookListView: View {
    let testament: Testament

    var body: some View {
        NavigationStack {
            List(BibleBook.books(in: testament)) { book in
                NavigationLink {
                    BookWorkspaceView(book: book)
                } label: {
                    Label(book.name, systemImage: "book")
                }
            }
            .navigationTitle(testament.rawValue)
        }
    }
}

struct BookWorkspaceView: View {
    let book: BibleBook

    @AppStorage("bibleTranslation") private var bibleTranslation = BibleTranslation.web.rawValue
    @AppStorage("readerTextSize") private var readerTextSize = 19.0
    @AppStorage("readerBackground") private var readerBackground = ReaderBackground.automatic.rawValue

    @State private var selectedChapter = 1
    @State private var verses: [BibleVerse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isDownloadingOldTestament = false
    @State private var downloadedChapterCount = 0

    private var selectedTranslation: BibleTranslation {
        BibleTranslation(rawValue: bibleTranslation) ?? .web
    }

    private var selectedReaderBackground: ReaderBackground {
        ReaderBackground(rawValue: readerBackground) ?? .automatic
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

            if book.testament == .old {
                Button {
                    Task { await downloadOldTestament() }
                } label: {
                    if isDownloadingOldTestament {
                        Label(
                            "Saving chapter \(downloadedChapterCount) of \(BibleBook.oldTestamentChapterCount)",
                            systemImage: "arrow.down.circle"
                        )
                    } else {
                        Label("Download Old Testament for Offline Use", systemImage: "arrow.down.circle")
                    }
                }
                .font(.caption.weight(.semibold))
                .disabled(isDownloadingOldTestament)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(selectedReaderBackground.textColor)
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

                    NavigationLink {
                        EntryEditorView(bookName: book.name)
                    } label: {
                        Label("New \(book.name) Note", systemImage: "square.and.pencil")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 12)
                }
                .foregroundStyle(selectedReaderBackground.textColor)
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

        do {
            let loadedVerses = try await BibleAPI.load(request)
            guard !Task.isCancelled else { return }
            verses = loadedVerses
        } catch is CancellationError {
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
        if let cached = ScriptureCache.load(request) {
            return cached
        }

        var components = URLComponents(string: "https://bible-api.com")!
        components.path = "/\(request.bookName) \(request.chapter)"
        components.queryItems = [URLQueryItem(name: "translation", value: request.translation)]

        guard let url = components.url else {
            throw BibleAPIError.invalidRequest
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BibleAPIError.serverUnavailable
        }

        let decoded = try JSONDecoder().decode(BibleAPIResponse.self, from: data)
        guard !decoded.verses.isEmpty else {
            throw BibleAPIError.noScripture
        }
        ScriptureCache.save(decoded.verses, for: request)
        return decoded.verses
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
    case serverUnavailable
    case noScripture

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            "The selected book or chapter is invalid."
        case .serverUnavailable:
            "The Bible service is unavailable. Check your internet connection and try again."
        case .noScripture:
            "No scripture text was returned for this chapter and translation."
        }
    }
}

private extension BibleTranslation {
    var shortName: String {
        switch self {
        case .web: "WEB"
        case .kjv: "KJV"
        case .asv: "ASV"
        }
    }

    var apiIdentifier: String {
        switch self {
        case .web: "web"
        case .kjv: "kjv"
        case .asv: "asv"
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
