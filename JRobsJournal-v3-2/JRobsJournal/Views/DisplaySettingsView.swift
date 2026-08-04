import SwiftUI

enum AppAccent: String, CaseIterable, Identifiable {
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
    case red = "Red"
    case orange = "Orange"
    case teal = "Teal"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: .blue
        case .purple: .purple
        case .green: .green
        case .red: .red
        case .orange: .orange
        case .teal: .teal
        }
    }
}

enum ReaderBackground: String, CaseIterable, Identifiable {
    case automatic = "Automatic"
    case white = "White"
    case cream = "Cream"
    case gray = "Soft Gray"
    case black = "Black"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .automatic: Color(uiColor: .systemBackground)
        case .white: .white
        case .cream: Color(red: 0.98, green: 0.95, blue: 0.86)
        case .gray: Color(red: 0.92, green: 0.92, blue: 0.94)
        case .black: .black
        }
    }

    var textColor: Color {
        self == .black ? .white : .black
    }
}

enum BibleTranslation: String, CaseIterable, Identifiable {
    case kjv = "King James Version (KJV)"
    case nkjv = "New King James Version (NKJV)"
    case niv = "New International Version (NIV)"
    case esv = "English Standard Version (ESV)"
    case nlt = "New Living Translation (NLT)"
    case csb = "Christian Standard Bible (CSB)"
    case nasb = "New American Standard Bible (NASB)"
    case web = "World English Bible (WEB)"
    case asv = "American Standard Version (ASV)"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .kjv: "KJV"
        case .nkjv: "NKJV"
        case .niv: "NIV"
        case .esv: "ESV"
        case .nlt: "NLT"
        case .csb: "CSB"
        case .nasb: "NASB"
        case .web: "WEB"
        case .asv: "ASV"
        }
    }
}

struct DisplaySettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    @AppStorage("readerTextSize") private var readerTextSize = 19.0
    @AppStorage("accentColor") private var accentColor = AppAccent.blue.rawValue
    @AppStorage("readerBackground") private var readerBackground = ReaderBackground.automatic.rawValue
    @AppStorage("bibleTranslation") private var bibleTranslation = BibleTranslation.web.rawValue

    private var selectedBackground: ReaderBackground {
        ReaderBackground(rawValue: readerBackground) ?? .automatic
    }

    var body: some View {
        Form {
            Section("Preview") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("John 3:16")
                        .font(.headline)
                    Text("For God so loved the world, that he gave his one and only Son...")
                        .font(.system(size: readerTextSize))
                }
                .foregroundStyle(selectedBackground.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(selectedBackground.color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Section("Text") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Size: \(Int(readerTextSize)) pt")
                    Slider(value: $readerTextSize, in: 14...34, step: 1)
                }

                Picker("Bible Version", selection: $bibleTranslation) {
                    ForEach(BibleTranslation.allCases) { translation in
                        Text(translation.rawValue).tag(translation.rawValue)
                    }
                }
            }

            Section("Appearance") {
                Picker("App Theme", selection: $appearance) {
                    ForEach(Appearance.allCases) { option in
                        Text(option.rawValue).tag(option.rawValue)
                    }
                }

                Picker("Reading Background", selection: $readerBackground) {
                    ForEach(ReaderBackground.allCases) { option in
                        Text(option.rawValue).tag(option.rawValue)
                    }
                }
            }

            Section("Accent Color") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 14) {
                    ForEach(AppAccent.allCases) { option in
                        Button {
                            accentColor = option.rawValue
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if accentColor == option.rawValue {
                                            Image(systemName: "checkmark")
                                                .font(.headline.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                Text(option.rawValue)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Use \(option.rawValue) accent color")
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Display Settings")
    }
}
