import SwiftUI

struct JournalListView: View {
    @EnvironmentObject private var store: JournalStore

    var body: some View {
        List {
            ForEach(store.entries) { entry in
                NavigationLink {
                    EntryEditorView(entry: entry)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title.isEmpty ? "Untitled" : entry.title)
                            .font(.headline)
                        Text(entry.updatedAt, format: .dateTime.month().day().year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: store.delete)
        }
        .navigationTitle("Journal")
        .toolbar {
            NavigationLink {
                EntryEditorView()
            } label: {
                Label("New Entry", systemImage: "plus")
            }
        }
        .overlay {
            if store.entries.isEmpty {
                ContentUnavailableView(
                    "No Journal Entries",
                    systemImage: "square.and.pencil",
                    description: Text("Tap + to create your first entry.")
                )
            }
        }
    }
}

struct EntryEditorView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var entry: JournalEntry

    init(entry: JournalEntry? = nil, bookName: String? = nil) {
        _entry = State(initialValue: entry ?? JournalEntry(
            title: bookName.map { "\($0) Notes" } ?? "",
            body: "",
            bookName: bookName
        ))
    }

    var body: some View {
        Form {
            TextField("Title", text: $entry.title)
                .font(.headline)
            TextEditor(text: $entry.body)
                .frame(minHeight: 320)
                .accessibilityLabel("Journal entry")
        }
        .navigationTitle(entry.title.isEmpty ? "New Entry" : entry.title)
        .toolbar {
            Button("Save") {
                store.save(entry)
                dismiss()
            }
            .disabled(entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}
