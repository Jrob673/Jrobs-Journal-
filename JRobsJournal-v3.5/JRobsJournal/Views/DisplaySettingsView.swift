import SwiftUI
import Security

enum APIBibleKeyStore {
    private static let service = Bundle.main.bundleIdentifier ?? "JRobsJournal"
    private static let account = "API_BIBLE_KEY"

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else { return nil }
        return key
    }

    static func save(_ key: String) throws {
        let value = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, let data = value.data(using: .utf8) else {
            throw APIBibleKeyStoreError.emptyKey
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            attributes.forEach { item[$0.key] = $0.value }
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
                throw APIBibleKeyStoreError.couldNotSave
            }
        } else if status != errSecSuccess {
            throw APIBibleKeyStoreError.couldNotSave
        }
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

private enum APIBibleKeyStoreError: LocalizedError {
    case emptyKey
    case couldNotSave

    var errorDescription: String? {
        switch self {
        case .emptyKey: "Enter your API.Bible key."
        case .couldNotSave: "The key could not be saved securely. Try again."
        }
    }
}

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

struct DisplaySettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    @AppStorage("readerTextSize") private var readerTextSize = 19.0
    @AppStorage("accentColor") private var accentColor = AppAccent.blue.rawValue
    @AppStorage("readerBackground") private var readerBackground = ReaderBackground.automatic.rawValue
    @AppStorage("bibleTranslation") private var bibleTranslation = BibleTranslation.web.rawValue
    @State private var apiBibleKey = ""
    @State private var apiKeyIsSaved = false
    @State private var apiKeyMessage: String?

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

            Section("Online Bible Versions") {
                SecureField("API.Bible key", text: $apiBibleKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .privacySensitive()

                Button(apiKeyIsSaved ? "Update API Key" : "Save API Key") {
                    do {
                        try APIBibleKeyStore.save(apiBibleKey)
                        apiBibleKey = ""
                        apiKeyIsSaved = true
                        apiKeyMessage = "API key saved securely on this device."
                    } catch {
                        apiKeyMessage = error.localizedDescription
                    }
                }
                .disabled(apiBibleKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if apiKeyIsSaved {
                    Label("API key configured", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)

                    Button("Remove API Key", role: .destructive) {
                        APIBibleKeyStore.delete()
                        apiBibleKey = ""
                        apiKeyIsSaved = false
                        apiKeyMessage = "API key removed from this device."
                    }
                }

                if let apiKeyMessage {
                    Text(apiKeyMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("Used only for NIV, NKJV, and NLT. The key is stored in this device's Keychain and is not added to GitHub.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
        .onAppear {
            apiKeyIsSaved = APIBibleKeyStore.load() != nil
        }
    }
}
