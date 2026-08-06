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

    private let mainHeaderFont = Font.system(size: 28, weight: .bold)
    private let subHeaderFont = Font.system(size: 20, weight: .semibold)

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
                LazyVStack(alignment: .leading, spacing: 28) {
                    Text("JRobs Journal")
                        .font(.system(size: 34, weight: .heavy))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)

                    if !normalizedSearch.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Book Search")
                                .font(.headline)
                                .foregroundStyle(.white)

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
                                        .font(subHeaderFont)
                                        .foregroundStyle(.yellow)
                                    }
                                }
                            }
                        }
                    }

                    bibleSection
                    journalSection
                    referenceSection
                    customizationSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
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

    private var bibleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    bibleExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(
                        "Bible",
                        systemImage: "book.fill"
                    )
                    .font(mainHeaderFont)
                    .foregroundStyle(.white)

                    Spacer()

                    Image(
                        systemName: bibleExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if bibleExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    DisclosureGroup(
                        isExpanded: $bibleVersionsExpanded
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(
                                BibleTranslation.allCases
                            ) { translation in
                                Button {
                                    bibleTranslation =
                                        translation.rawValue
                                } label: {
                                    HStack {
                                        Text(translation.rawValue)
                                            .font(subHeaderFont)
                                            .foregroundStyle(.yellow)

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
                        }
                        .padding(.top, 8)
                    } label: {
                        Label(
                            "Bible Versions",
                            systemImage: "books.vertical"
                        )
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
                    }

                    NavigationLink {
                        BookListView(testament: .old)
                    } label: {
                        Label(
                            "Old Testament",
                            systemImage: "book.closed"
                        )
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
                    }

                    NavigationLink {
                        BookListView(testament: .new)
                    } label: {
                        Label(
                            "New Testament",
                            systemImage: "book.closed.fill"
                        )
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
                    }

                    DisclosureGroup(
                        isExpanded: $onlineVersionsExpanded
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
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
                                .font(subHeaderFont)
                                .foregroundStyle(.yellow)
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
                                .font(subHeaderFont)
                                .foregroundStyle(.yellow)
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
                                .font(subHeaderFont)
                                .foregroundStyle(.yellow)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Label(
                            "Online Bible Versions",
                            systemImage: "network"
                        )
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
                    }
                }
                .padding(.leading, 10)
            }
        }
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    journalExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(
                        "Journal",
                        systemImage: "pencil.and.list.clipboard"
                    )
                    .font(mainHeaderFont)
                    .foregroundStyle(.white)

                    Spacer()

                    Image(
                        systemName: journalExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                    .font(subHeaderFont)
                    .foregroundStyle(.yellow)
                }
                .padding(.leading, 10)
            }
        }
    }

    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    referenceExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(
                        "Reference",
                        systemImage: "books.vertical.fill"
                    )
                    .font(mainHeaderFont)
                    .foregroundStyle(.white)

                    Spacer()

                    Image(
                        systemName: referenceExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if referenceExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    NavigationLink {
                        MapsView()
                    } label: {
                        Label(
                            "Bible Maps",
                            systemImage: "map"
                        )
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
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
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
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
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
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
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
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
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
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
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
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
                        .font(subHeaderFont)
                        .foregroundStyle(.yellow)
                    }
                }
                .padding(.leading, 10)
            }
        }
    }

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    customizationExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(
                        "Customization",
                        systemImage: "paintpalette.fill"
                    )
                    .font(mainHeaderFont)
                    .foregroundStyle(.white)

                    Spacer()

                    Image(
                        systemName: customizationExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if customizationExpanded {
                NavigationLink {
                    DisplaySettingsView()
                } label: {
                    Label(
                        "Customize Reading Display",
                        systemImage: "textformat.size"
                    )
                    .font(subHeaderFont)
                    .foregroundStyle(.yellow)
                }
                .padding(.leading, 10)
            }
        }
    }
}
