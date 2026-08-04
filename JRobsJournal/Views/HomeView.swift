import SwiftUI

struct HomeView: View {
    @Binding var appearance: String
    @Binding var readerTextSize: Double
    @State private var searchText = ""

    private var normalizedSearch: String {
        searchText.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
    }

    private var matchingBooks: [BibleBook] {
        guard !normalizedSearch.isEmpty else { return [] }
        return BibleBook.all.filter {
            $0.name.localizedCaseInsensitiveContains(normalizedSearch)
        }
    }

    var body: some View {
        List {
            if !normalizedSearch.isEmpty {
                Section("Book Search") {
                    if matchingBooks.isEmpty {
                        Text("No Bible book found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(matchingBooks) { book in
                            NavigationLink(value: book) {
                                Label(book.name, systemImage: "book")
                            }
                        }
                    }
                }
            }

            Section("Bible") {
                NavigationLink {
                    BookListView(testament: .old)
                } label: {
                    Label("Old Testament", systemImage: "book.closed")
                }

                NavigationLink {
                    BookListView(testament: .new)
                } label: {
                    Label("New Testament", systemImage: "book.closed.fill")
                }
            }

            Section("Journal") {
                NavigationLink {
                    JournalListView()
                } label: {
                    Label("Freehand Journaling", systemImage: "square.and.pencil")
                }
            }

            Section("Reference") {
                NavigationLink {
                    MapsView()
                } label: {
                    Label("Bible Maps", systemImage: "map")
                }
            }

            Section("Display") {
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { option in
                        Text(option.rawValue).tag(option.rawValue)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Text Size: \(Int(readerTextSize))")
                    Slider(value: $readerTextSize, in: 14...32, step: 1)
                }
            }
        }
        .searchable(text: $searchText, prompt: "One-word book search")
        .navigationDestination(for: BibleBook.self) { book in
            BookWorkspaceView(book: book)
        }
    }
}
