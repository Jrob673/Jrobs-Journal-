import SwiftUI

struct BookListView: View {
    let testament: Testament

    var body: some View {
        List(BibleBook.books(in: testament)) { book in
            NavigationLink(value: book) {
                Label(book.name, systemImage: "book")
            }
        }
        .navigationTitle(testament.rawValue)
        .navigationDestination(for: BibleBook.self) { book in
            BookWorkspaceView(book: book)
        }
    }
}

struct BookWorkspaceView: View {
    let book: BibleBook
    @AppStorage("bibleTranslation") private var bibleTranslation = BibleTranslation.web.rawValue

    var body: some View {
        List {
            Section("Reading") {
                ContentUnavailableView(
                    "\(book.name) — \(shortTranslationName)",
                    systemImage: "doc.badge.plus",
                    description: Text("Your selected Bible version will be used when scripture text is added.")
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
        .navigationTitle(book.name)
    }

    private var shortTranslationName: String {
        switch BibleTranslation(rawValue: bibleTranslation) ?? .web {
        case .web: "WEB"
        case .kjv: "KJV"
        case .asv: "ASV"
        }
    }
}
