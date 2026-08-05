import SwiftUI

struct HomeView: View {
    @Binding var appearance: String
    @Binding var readerTextSize: Double

    @AppStorage("bibleTranslation")
    private var bibleTranslation = BibleTranslation.web.rawValue

    @State private var searchText = ""
    @State private var bibleExpanded = false
    @State private var bibleVersionsExpanded = false
    @State private var onlineVersionsExpanded = false
    @State private var journalExpanded = false
    @State private var referenceExpanded = false
    @State private var customizationExpanded = false

    private var normalizedSearch: String {
        searchText
            .split(whereSeparator: { $0.isWhitespace })
            .first
            .map(String.init) ?? ""
    }

    private var matchingBooks: [BibleBook] {
        guard !normalizedSearch.isEmpty else {
            return []
        }

        return BibleBook.all.filter { book in
            book.name.localizedCaseInsensitiveContains(normalizedSearch)
        }
    }

    var body: some View {
        ZStack {
            Image("MainBackground")
                .resizable()
                .scaledToFill()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .clipped()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.70)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                Text("JRobs Journal")
                    .font(.largeTitle.bold())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                if !normalizedSearch.isEmpty {
                    Section("Book Search") {
                        if matchingBooks.isEmpty {
                            Text("No Bible book found")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(matchingBooks) { book in
                                NavigationLink(value: book) {
                                    Label(
                                        book.name,
                                        systemImage: "book"
                                    )
                                }
                            }
                        }
                    }
                    .listRowBackground(
                        Color.black.opacity(0.60)
                    )
                }

                Button {
                    withAnimation {
                        bibleExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Label("Bible", systemImage: "book.fill")
                            .font(.headline)

                        Spacer()

                        Image(
                            systemName: bibleExpanded
                                ? "chevron.down"
                                : "chevron.right"
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    Color.black.opacity(0.60)
                )

                if bibleExpanded {
                    DisclosureGroup(
                        isExpanded: $bibleVersionsExpanded
                    ) {
                        ForEach(
                            BibleTranslation.allCases
                        ) { translation in
                            Button {
                                bibleTranslation =
                                    translation.rawValue
                            } label: {
                                HStack {
                                    Text(translation.rawValue)

                                    Spacer()

                                    if bibleTranslation ==
                                        translation.rawValue {
                                        Image(
                                            systemName:
                                                "checkmark.circle.fill"
                                        )
                                        .foregroundStyle(
                                            Color.accentColor
                                        )
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        Label(
                            "Bible Versions",
                            systemImage: "books.vertical"
                        )
                        .font(
                            .subheadline.weight(.semibold)
                        )
                    }

                    NavigationLink {
                        BookListView(testament: .old)
                    } label: {
                        Label(
                            "Old Testament",
                            systemImage: "book.closed"
                        )
                    }

                    NavigationLink {
                        BookListView(testament: .new)
                    } label: {
                        Label(
                            "New Testament",
                            systemImage: "book.closed.fill"
                        )
                    }

                    DisclosureGroup(
                        isExpanded: $onlineVersionsExpanded
                    ) {
                        Link(
                            destination: URL(
                                string:
                                    "https://worldenglish.bible/"
                            )!
                        ) {
                            Label(
                                "World English Bible",
                                systemImage: "book.fill"
                            )
                        }

                        Link(
                            destination: URL(
                                string: "https://www.bible.com/"
                            )!
                        ) {
                            Label(
                                "YouVersion",
                                systemImage: "book.circle"
                            )
                        }

                        Link(
                            destination: URL(
                                string: "https://biblehub.com/"
                            )!
                        ) {
                            Label(
                                "Bible Hub",
                                systemImage:
                                    "character.book.closed"
                            )
                        }
                    } label: {
                        Label(
                            "Online Bible Versions",
                            systemImage: "network"
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                }

                Button {
                    withAnimation {
                        journalExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Label(
                            "Journal",
                            systemImage: "pencil.and.list.clipboard"
                        )
                        .font(.headline)

                        Spacer()

                        Image(
                            systemName: journalExpanded
                                ? "chevron.down"
                                : "chevron.right"
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if journalExpanded {
                    NavigationLink {
                        JournalListView()
                    } label: {
                        Label(
                            "Freehand Journaling",
                            systemImage: "square.and.pencil"
                        )
                    }
                }

                HStack {
                    Label(
                        "Reference",
                        systemImage: "books.vertical.fill"
                    )
                    .font(.headline)

                    Spacer()

                    Image(
                        systemName: referenceExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    referenceExpanded.toggle()
                }

                if referenceExpanded {
                    NavigationLink {
                        MapsView()
                    } label: {
                        Label(
                            "Bible Maps",
                            systemImage: "map"
                        )
                    }

                    Link(
                        destination: URL(
                            string:
                                "https://www.blueletterbible.org/"
                        )!
                    ) {
                        Label(
                            "Blue Letter Bible",
                            systemImage: "text.book.closed"
                        )
                    }

                    Link(
                        destination: URL(
                            string:
                                "https://biblehub.com/commentaries/"
                        )!
                    ) {
                        Label(
                            "Bible Hub Commentaries",
                            systemImage: "books.vertical"
                        )
                    }

                    Link(
                        destination: URL(
                            string:
                                "https://www.studylight.org/commentaries.html"
                        )!
                    ) {
                        Label(
                            "StudyLight Commentaries",
                            systemImage: "book.pages"
                        )
                    }

                    Link(
                        destination: URL(
                            string:
                                "https://www.freebiblecommentary.org/"
                        )!
                    ) {
                        Label(
                            "Free Bible Commentary",
                            systemImage: "quote.bubble"
                        )
                    }

                    Link(
                        destination: URL(
                            string:
                                "https://www.youtube.com/playlist?list=PLH0Szn1yYNeeVFodkI9J_WEATHQCwRZ0u"
                        )!
                    ) {
                        Label(
                            "BibleProject: Old Testament Books",
                            systemImage:
                                "play.rectangle.fill"
                        )
                    }

                    Link(
                        destination: URL(
                            string:
                                "https://www.youtube.com/playlist?list=PLH0Szn1yYNecanpQqdixWAm3zHdhY2kPR"
                        )!
                    ) {
                        Label(
                            "BibleProject: New Testament Books",
                            systemImage:
                                "play.rectangle.fill"
                        )
                    }
                }

                HStack {
                    Label(
                        "Customization",
                        systemImage: "paintpalette.fill"
                    )
                    .font(.headline)

                    Spacer()

                    Image(
                        systemName: customizationExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    customizationExpanded.toggle()
                }

                if customizationExpanded {
                    NavigationLink {
                        DisplaySettingsView()
                    } label: {
                        Label(
                            "Customize Reading Display",
                            systemImage: "textformat.size"
                        )
                    }
                }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .foregroundStyle(.white)
        }
        .searchable(
            text: $searchText,
            prompt: "One-word book search"
        )
        .navigationDestination(
            for: BibleBook.self
        ) { book in
            BookWorkspaceView(book: book)
        }
    }
}
