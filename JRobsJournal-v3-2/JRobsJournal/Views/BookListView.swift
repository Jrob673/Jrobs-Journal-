import SwiftUI

struct BookListView: View {
    let testament: Testament
    @AppStorage("bibleTranslation") private var bibleTranslation = BibleTranslation.web.rawValue

    private var selectedTranslation: BibleTranslation {
        BibleTranslation(rawValue: bibleTranslation) ?? .web
    }

    var body: some View {
        List {
            Section {
                ForEach(BibleBook.books(in: testament)) { book in
                    NavigationLink(value: book) {
                        HStack {
                            Label(book.name, systemImage: "book")
                            Spacer()
                            Text(selectedTranslation.shortName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Selected Version: \(selectedTranslation.rawValue)")
            }
        }
        .navigationTitle("\(testament.rawValue) • \(selectedTranslation.shortName)")
        .navigationDestination(for: BibleBook.self) { book in
            BookWorkspaceView(book: book)
        }
    }
}

struct BookWorkspaceView: View {
    let book: BibleBook
    @AppStorage("bibleTranslation") private var bibleTranslation = BibleTranslation.web.rawValue

    private var selectedTranslation: BibleTranslation {
        BibleTranslation(rawValue: bibleTranslation) ?? .web
    }

    var body: some View {
        List {
            Section("Reading") {
                ContentUnavailableView(
                    "\(book.name) — \(selectedTranslation.shortName)",
                    systemImage: "doc.badge.plus",
                    description: Text("Selected version: \(selectedTranslation.rawValue)")
                )
            }

            Section("Notes") {
                NavigationLink {
                    EntryEditorView(bookName: book.name)
                } label: {
                    Label("New \(book.name) Note", systemImage: "square.and.pencil")
                }
            }
        }
        .navigationTitle("\(book.name) • \(selectedTranslation.shortName)")
    }
}
