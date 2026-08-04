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

    var body: some View {
        List {
            Section("Reading") {
                ContentUnavailableView(
                    "Import \(book.name)",
                    systemImage: "doc.badge.plus",
                    description: Text("Licensed Bible text can be added without changing the journal structure.")
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
}
