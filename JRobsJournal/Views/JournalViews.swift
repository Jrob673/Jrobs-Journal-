import SwiftUI

struct JournalListView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var searchText = ""

    private var filteredEntries: [JournalEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.entries }

        return store.entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query) ||
            entry.body.localizedCaseInsensitiveContains(query) ||
            (entry.bookName?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var daySections: [(date: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) {
            calendar.startOfDay(for: $0.updatedAt)
        }

        return grouped.keys
            .sorted(by: >)
            .map { date in
                (
                    date: date,
                    entries: grouped[date, default: []].sorted {
                        $0.updatedAt > $1.updatedAt
                    }
                )
            }
    }

    var body: some View {
        List {
            ForEach(daySections, id: \.date) { section in
                Section {
                    ForEach(section.entries) { entry in
                        NavigationLink {
                            EntryEditorView(entry: entry)
                        } label: {
                            JournalEntryRow(entry: entry)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    store.delete(entry)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(section.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Journal")
        .searchable(text: $searchText, prompt: "Search entries")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    EntryEditorView()
                } label: {
                    Label("New Entry", systemImage: "plus")
                }
            }
        }
        .overlay {
            if store.entries.isEmpty {
                ContentUnavailableView(
                    "No Journal Entries",
                    systemImage: "square.and.pencil",
                    description: Text("Tap + to create your first entry.")
                )
            } else if filteredEntries.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different word or phrase.")
                )
            }
        }
    }
}

private struct JournalEntryRow: View {
    let entry: JournalEntry

    private var displayTitle: String {
        let trimmed = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    private var preview: String {
        entry.body
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(entry.updatedAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !preview.isEmpty {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if let bookName = entry.bookName, !bookName.isEmpty {
                Label(bookName, systemImage: "book.closed")
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

struct EntryEditorView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var entry: JournalEntry
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case body
    }

    init(entry: JournalEntry? = nil, bookName: String? = nil) {
        _entry = State(initialValue: entry ?? JournalEntry(
            title: bookName.map { "\($0) Notes" } ?? "",
            body: "",
            bookName: bookName
        ))
    }

    private var hasContent: Bool {
        !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.createdAt.formatted(.dateTime.weekday(.wide).month(.wide).day().year().hour().minute()))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 12)

            TextField("Title", text: $entry.title, axis: .vertical)
                .font(.title2.bold())
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .title)
                .padding(.horizontal)
                .padding(.top, 14)

            Divider()
                .padding(.horizontal)
                .padding(.top, 12)

            TextEditor(text: $entry.body)
                .font(.body)
                .focused($focusedField, equals: .body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 11)
                .padding(.top, 6)
                .accessibilityLabel("Journal entry")
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(entry.title.isEmpty ? "New Entry" : "Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.save(entry)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(!hasContent)
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .onAppear {
            if entry.title.isEmpty && entry.body.isEmpty {
                focusedField = .title
            }
        }
    }
}
