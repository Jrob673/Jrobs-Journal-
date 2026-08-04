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

                Link(destination: URL(string: "https://www.blueletterbible.org/")!) {
                    Label("Blue Letter Bible", systemImage: "text.book.closed")
                }

                Link(destination: URL(string: "https://biblehub.com/commentaries/")!) {
                    Label("Bible Hub Commentaries", systemImage: "books.vertical")
                }

                Link(destination: URL(string: "https://www.studylight.org/commentaries.html")!) {
                    Label("StudyLight Commentaries", systemImage: "book.pages")
                }

                Link(destination: URL(string: "https://www.freebiblecommentary.org/")!) {
                    Label("Free Bible Commentary", systemImage: "quote.bubble")
                }

                Link(destination: URL(string: "https://www.youtube.com/@bibleproject/videos")!) {
                    Label("BibleProject on YouTube", systemImage: "play.rectangle.fill")
                }
            }

            Section("Free Bibles") {
                Link(destination: URL(string: "https://worldenglish.bible/")!) {
                    Label("World English Bible", systemImage: "book.fill")
                }

                Link(destination: URL(string: "https://www.bible.com/")!) {
                    Label("YouVersion Bible", systemImage: "book.circle")
                }

                Link(destination: URL(string: "https://biblehub.com/")!) {
                    Label("Bible Hub Translations", systemImage: "character.book.closed")
                }
            }

            Section("Display") {
                NavigationLink {
                    DisplaySettingsView()
                } label: {
                    Label("Customize Reading Display", systemImage: "textformat.size")
                }
            }
        }
        .searchable(text: $searchText, prompt: "One-word book search")
        .navigationDestination(for: BibleBook.self) { book in
            BookWorkspaceView(book: book)
        }
    }
}
