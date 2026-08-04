import SwiftUI

struct HomeView: View {
    @Binding var appearance: String
    @Binding var readerTextSize: Double
    @AppStorage("bibleTranslation") private var bibleTranslation = BibleTranslation.web.rawValue
    @State private var searchText = ""
    @State private var bibleExpanded = true
    @State private var bibleVersionsExpanded = false
    @State private var onlineVersionsExpanded = false
    @State private var journalExpanded = false
    @State private var referenceExpanded = false
    @State private var customizationExpanded = false

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

            DisclosureGroup(isExpanded: $bibleExpanded) {
                DisclosureGroup(isExpanded: $bibleVersionsExpanded) {
                    ForEach(BibleTranslation.allCases) { translation in
                        Button {
                            bibleTranslation = translation.rawValue
                        } label: {
                            HStack {
                                Text(translation.rawValue)
                                Spacer()
                                if bibleTranslation == translation.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    Label("Bible Versions", systemImage: "books.vertical")
                        .font(.subheadline.weight(.semibold))
                }

                DisclosureGroup(isExpanded: $onlineVersionsExpanded) {
                    Link(destination: URL(string: "https://worldenglish.bible/")!) {
                        Label("World English Bible Online", systemImage: "book.fill")
                    }

                    Link(destination: URL(string: "https://www.bible.com/")!) {
                        Label("YouVersion", systemImage: "book.circle")
                    }

                    Link(destination: URL(string: "https://biblehub.com/")!) {
                        Label("Bible Hub", systemImage: "character.book.closed")
                    }
                } label: {
                    Label("Online Versions", systemImage: "network")
                        .font(.subheadline.weight(.semibold))
                }

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
            } label: {
                Label("Bible", systemImage: "book.fill")
                    .font(.headline)
            }

            DisclosureGroup(isExpanded: $journalExpanded) {
                NavigationLink {
                    JournalListView()
                } label: {
                    Label("Freehand Journaling", systemImage: "square.and.pencil")
                }
            } label: {
                Label("Journal", systemImage: "pencil.and.list.clipboard")
                    .font(.headline)
            }

            DisclosureGroup(isExpanded: $referenceExpanded) {
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

                Link(destination: URL(string: "https://www.youtube.com/playlist?list=PLH0Szn1yYNeeVFodkI9J_WEATHQCwRZ0u")!) {
                    Label("BibleProject: Old Testament Books", systemImage: "play.rectangle.fill")
                }

                Link(destination: URL(string: "https://www.youtube.com/playlist?list=PLH0Szn1yYNecanpQqdixWAm3zHdhY2kPR")!) {
                    Label("BibleProject: New Testament Books", systemImage: "play.rectangle.fill")
                }
            } label: {
                Label("Reference", systemImage: "books.vertical.fill")
                    .font(.headline)
            }

            DisclosureGroup(isExpanded: $customizationExpanded) {
                NavigationLink {
                    DisplaySettingsView()
                } label: {
                    Label("Customize Reading Display", systemImage: "textformat.size")
                }
            } label: {
                Label("Customization", systemImage: "paintpalette.fill")
                    .font(.headline)
            }
        }
        .searchable(text: $searchText, prompt: "One-word book search")
        .navigationDestination(for: BibleBook.self) { book in
            BookWorkspaceView(book: book)
        }
    }
}
