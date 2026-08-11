import SwiftUI

struct HomeView: View {
    @Binding var appearance: String
    @Binding var readerTextSize: Double

    @AppStorage("bibleTranslation")
    private var bibleTranslation = BibleTranslation.web.rawValue

    @AppStorage("accentColor")
    private var accentColor = AppAccent.blue.rawValue

    @AppStorage("homeTextColorHex")
    private var homeTextColorHex = ""

    @State private var searchText = ""
    @State private var bibleVersionsExpanded = false
    @State private var onlineVersionsExpanded = false
    @State private var journalExpanded = false
    @State private var referenceExpanded = false
    @State private var customizationExpanded = false
    @State private var bibleTapCount = 0

    private var bibleExpanded: Bool {
        !bibleTapCount.isMultiple(of: 2)
    }

    private let mainHeaderFont = Font.system(size: 28, weight: .bold)
    private let subHeaderFont = Font.system(size: 20, weight: .bold)

    private var homeAccentColor: Color {
        if let customColor = Color(hex: homeTextColorHex) {
            return customColor
        }
        return (AppAccent(rawValue: accentColor) ?? .blue).color
    }

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
                VStack(alignment: .leading, spacing: 18) {
                        Text("JRobs Journal")
                        .font(.largeTitle.bold())
                        .foregroundStyle(homeAccentColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField(
                            "One-word book search",
                            text: $searchText
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear search")
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .fill(Color.black.opacity(0.42))
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    }

                    Text("Bible tap count: \(bibleTapCount) | Bible open: \(bibleExpanded ? "YES" : "NO")")
                        .font(.caption2)
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        .accessibilityHidden(true)

                    if !normalizedSearch.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Book Search")
                                .font(.headline)
                                .foregroundStyle(homeAccentColor)

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
                                        .submenuStyle(
                                            font: subHeaderFont,
                                            color: homeAccentColor
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        withAnimation {
                            bibleTapCount += 1
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Label(
                                "Bible",
                                systemImage: "book.fill"
                            )
                            .font(mainHeaderFont)
                            .foregroundStyle(homeAccentColor)

                            Spacer()

                            Image(
                                systemName: bibleExpanded
                                    ? "chevron.down"
                                    : "chevron.right"
                            )
                            .font(.headline.weight(.bold))
                            .foregroundStyle(homeAccentColor)
                        }
                        .mainHeaderCard()
                    }
                    .buttonStyle(.plain)

                    if bibleExpanded {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(
                                    "Version",
                                    systemImage: "books.vertical"
                                )
                                .font(.headline)
                                .foregroundStyle(homeAccentColor)

                                LazyVGrid(
                                    columns: [
                                        GridItem(
                                            .adaptive(minimum: 64),
                                            spacing: 8
                                        )
                                    ],
                                    alignment: .leading,
                                    spacing: 8
                                ) {
                                    ForEach(
                                        BibleTranslation.allCases
                                    ) { translation in
                                        let isSelected =
                                            bibleTranslation ==
                                            translation.rawValue

                                        Button {
                                            bibleTranslation =
                                                translation.rawValue
                                        } label: {
                                            Text(translation.abbreviation)
                                                .font(
                                                    .system(
                                                        size: 14,
                                                        weight: .bold
                                                    )
                                                )
                                                .foregroundStyle(
                                                        isSelected
                                                            ? Color.black
                                                            : Color.white
                                                )
                                                .frame(
                                                    maxWidth: .infinity,
                                                    minHeight: 36
                                                )
                                                .background(
                                                    RoundedRectangle(
                                                        cornerRadius: 9,
                                                        style: .continuous
                                                    )
                                                    .fill(
                                                        isSelected
                                                            ? homeAccentColor
                                                            : Color.black
                                                                .opacity(0.42)
                                                    )
                                                )
                                                .overlay {
                                                    RoundedRectangle(
                                                        cornerRadius: 9,
                                                        style: .continuous
                                                    )
                                                    .stroke(
                                                        isSelected
                                                            ? homeAccentColor
                                                            : Color.white
                                                                .opacity(0.24),
                                                        lineWidth: 1
                                                    )
                                                }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(
                                            translation.rawValue
                                        )
                                        .accessibilityAddTraits(
                                            isSelected
                                                ? .isSelected
                                                : []
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                                .fill(Color.black.opacity(0.30))
                            )

                            NavigationLink {
                                BookListView(testament: .old)
                            } label: {
                                Label(
                                    "Old Testament",
                                    systemImage: "book.closed"
                                )
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
                                )
                            }

                            NavigationLink {
                                BookListView(testament: .new)
                            } label: {
                                Label(
                                    "New Testament",
                                    systemImage: "book.closed.fill"
                                )
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
                                )
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
                                        .submenuStyle(
                                            font: subHeaderFont,
                                            color: homeAccentColor
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
                                        .submenuStyle(
                                            font: subHeaderFont,
                                            color: homeAccentColor
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
                                        .submenuStyle(
                                            font: subHeaderFont,
                                            color: homeAccentColor
                                        )
                                    }
                                }
                                .padding(.top, 8)
                            } label: {
                                Label(
                                    "Online Bible Versions",
                                    systemImage: "network"
                                )
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
                                )
                            }
                        }
                    }

                    Button {
                        withAnimation {
                            journalExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Label(
                                "Journal",
                                systemImage: "pencil.and.list.clipboard"
                            )
                            .font(mainHeaderFont)
                            .foregroundStyle(homeAccentColor)

                            Spacer()

                            Image(
                                systemName: journalExpanded
                                    ? "chevron.down"
                                    : "chevron.right"
                            )
                            .font(.headline.weight(.bold))
                            .foregroundStyle(homeAccentColor)
                        }
                        .mainHeaderCard()
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
                            .submenuStyle(
                                font: subHeaderFont,
                                color: homeAccentColor
                            )
                        }
                    }

                    Button {
                        withAnimation {
                            referenceExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Label(
                                "Reference",
                                systemImage: "books.vertical.fill"
                            )
                            .font(mainHeaderFont)
                            .foregroundStyle(homeAccentColor)

                            Spacer()

                            Image(
                                systemName: referenceExpanded
                                    ? "chevron.down"
                                    : "chevron.right"
                            )
                            .font(.headline.weight(.bold))
                            .foregroundStyle(homeAccentColor)
                        }
                        .mainHeaderCard()
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
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
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
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
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
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
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
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
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
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
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
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
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
                                .submenuStyle(
                                    font: subHeaderFont,
                                    color: homeAccentColor
                                )
                            }
                        }
                    }

                    Button {
                        withAnimation {
                            customizationExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Label(
                                "Customization",
                                systemImage: "paintpalette.fill"
                            )
                            .font(mainHeaderFont)
                            .foregroundStyle(homeAccentColor)

                            Spacer()

                            Image(
                                systemName: customizationExpanded
                                    ? "chevron.down"
                                    : "chevron.right"
                            )
                            .font(.headline.weight(.bold))
                            .foregroundStyle(homeAccentColor)
                        }
                        .mainHeaderCard()
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
                            .submenuStyle(
                                font: subHeaderFont,
                                color: homeAccentColor
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .defaultScrollAnchor(.top)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .foregroundStyle(.white)
        }
        .navigationDestination(
            for: BibleBook.self
        ) { book in
            BookWorkspaceView(book: book)
        }
    }

}

private extension View {
    func mainHeaderCard() -> some View {
        self
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(Color.gray.opacity(0.24))
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.16),
                    lineWidth: 1
                )
            }
            .shadow(
                color: Color.black.opacity(0.20),
                radius: 8,
                x: 0,
                y: 4
            )
    }

    func submenuStyle(font: Font, color: Color) -> some View {
        self
            .font(font)
            .foregroundStyle(color)
            .padding(.leading, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }
}
