import SwiftUI
import PhotosUI
import UIKit

struct JournalListView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var searchText = ""
    @State private var selectedFolder = "All"
    @State private var selectedTag = "All"
    @State private var favoritesOnly = false
    @State private var selectedDate: Date?
    @State private var showingCalendar = false
    @State private var showingFolderPicker = false
    @State private var showingTagPicker = false

    private var folders: [String] {
        ["All"] + Set(store.entries.map { $0.folder.isEmpty ? "General" : $0.folder }).sorted()
    }

    private var tags: [String] {
        ["All"] + Set(store.entries.flatMap(\.tags)).sorted()
    }

    private var filteredEntries: [JournalEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.entries.filter { entry in
            let matchesSearch = query.isEmpty || entry.title.localizedCaseInsensitiveContains(query) ||
                entry.body.localizedCaseInsensitiveContains(query) ||
                entry.scriptureReference.localizedCaseInsensitiveContains(query) ||
                entry.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            let matchesFolder = selectedFolder == "All" || entry.folder == selectedFolder
            let matchesTag = selectedTag == "All" || entry.tags.contains(selectedTag)
            let matchesFavorite = !favoritesOnly || entry.isFavorite
            let matchesDate = selectedDate.map { Calendar.current.isDate(entry.createdAt, inSameDayAs: $0) } ?? true
            return matchesSearch && matchesFolder && matchesTag && matchesFavorite && matchesDate
        }
    }

    private var daySections: [(date: Date, entries: [JournalEntry])] {
        let grouped = Dictionary(grouping: filteredEntries) { Calendar.current.startOfDay(for: $0.createdAt) }
        return grouped.keys.sorted(by: >).map { date in
            (date, grouped[date, default: []].sorted { $0.updatedAt > $1.updatedAt })
        }
    }

    var body: some View {
        List {
            Section {
                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Button { showingFolderPicker = true } label: {
                            FilterChip(title: selectedFolder == "All" ? "Folders" : selectedFolder, icon: "folder", active: selectedFolder != "All")
                                .frame(maxWidth: .infinity)
                        }

                        Button { showingTagPicker = true } label: {
                            FilterChip(title: selectedTag == "All" ? "Tags" : selectedTag, icon: "tag", active: selectedTag != "All")
                                .frame(maxWidth: .infinity)
                        }
                    }

                    GridRow {
                        Button { favoritesOnly.toggle() } label: {
                            FilterChip(title: "Favorites", icon: favoritesOnly ? "star.fill" : "star", active: favoritesOnly)
                                .frame(maxWidth: .infinity)
                        }

                        Button { showingCalendar = true } label: {
                            FilterChip(title: selectedDate?.formatted(date: .abbreviated, time: .omitted) ?? "Calendar", icon: "calendar", active: selectedDate != nil)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)

                if selectedFolder != "All" || selectedTag != "All" || favoritesOnly || selectedDate != nil {
                    Button {
                        selectedFolder = "All"
                        selectedTag = "All"
                        favoritesOnly = false
                        selectedDate = nil
                    } label: {
                        Label("Clear Filters", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }

            ForEach(daySections, id: \.date) { section in
                Section {
                    ForEach(section.entries) { entry in
                        NavigationLink { EntryEditorView(entry: entry) } label: { JournalEntryRow(entry: entry) }
                            .swipeActions(edge: .leading) {
                                Button { store.toggleFavorite(entry) } label: {
                                    Label(entry.isFavorite ? "Unfavorite" : "Favorite", systemImage: entry.isFavorite ? "star.slash" : "star")
                                }.tint(.yellow)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { withAnimation { store.delete(entry) } } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                } header: {
                    Text(section.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(.subheadline.weight(.semibold)).textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Journal")
        .searchable(text: $searchText, prompt: "Search entries, tags, or scripture")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink { EntryEditorView() } label: { Label("New Entry", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingCalendar) {
            JournalCalendarView(entries: store.entries, selectedDate: $selectedDate)
        }
        .confirmationDialog("Choose Folder", isPresented: $showingFolderPicker, titleVisibility: .visible) {
            ForEach(folders, id: \.self) { folder in
                Button(folder == "All" ? "All Folders" : folder) { selectedFolder = folder }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Choose Tag", isPresented: $showingTagPicker, titleVisibility: .visible) {
            ForEach(tags, id: \.self) { tag in
                Button(tag == "All" ? "All Tags" : tag) { selectedTag = tag }
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay {
            if store.entries.isEmpty {
                ContentUnavailableView("No Journal Entries", systemImage: "square.and.pencil", description: Text("Tap + to create your first entry."))
            } else if filteredEntries.isEmpty {
                ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Clear a filter or try another search."))
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let icon: String
    var active = false
    var body: some View {
        Label(title, systemImage: icon).font(.subheadline.weight(.semibold)).lineLimit(1)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(active ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.12), in: Capsule())
    }
}

private struct JournalEntryRow: View {
    let entry: JournalEntry
    private var title: String { entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : entry.title }
    private var preview: String { entry.body.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ") }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let data = entry.photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title).font(.headline).lineLimit(1)
                    Spacer()
                    if entry.isFavorite { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                    Text(entry.updatedAt, format: .dateTime.hour().minute()).font(.caption).foregroundStyle(.secondary)
                }
                if !preview.isEmpty { Text(preview).font(.subheadline).foregroundStyle(.secondary).lineLimit(2) }
                if !entry.scriptureReference.isEmpty { Label(entry.scriptureReference, systemImage: "book.closed").font(.caption).foregroundStyle(.tint) }
                HStack(spacing: 6) {
                    Label(entry.folder.isEmpty ? "General" : entry.folder, systemImage: "folder")
                    ForEach(entry.tags.prefix(2), id: \.self) { Text("#\($0)") }
                }.font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }.padding(.vertical, 6).contentShape(Rectangle())
    }
}

struct EntryEditorView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var entry: JournalEntry
    @State private var tagText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoError: String?
    @FocusState private var focusedField: Field?
    private enum Field { case title, body }

    init(entry: JournalEntry? = nil, bookName: String? = nil) {
        _entry = State(initialValue: entry ?? JournalEntry(title: bookName.map { "\($0) Notes" } ?? "", body: "", bookName: bookName, scriptureReference: bookName ?? ""))
    }

    private var hasContent: Bool {
        !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entry.photoData != nil
    }

    var body: some View {
        Form {
            Section {
                Text(entry.createdAt.formatted(.dateTime.weekday(.wide).month(.wide).day().year().hour().minute())).font(.caption).foregroundStyle(.secondary)
                TextField("Title", text: $entry.title, axis: .vertical).font(.title2.bold()).focused($focusedField, equals: .title)
            }

            Section("Entry Details") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(entry.photoData == nil ? "Add Photo" : "Replace Photo", systemImage: "photo")
                }
                Toggle(isOn: $entry.isFavorite) {
                    Label("Favorite", systemImage: entry.isFavorite ? "star.fill" : "star")
                }

                TextField("Folder (for example: Faith)", text: $entry.folder)
                TextField("Tags separated by commas", text: $tagText)
                    .onChange(of: tagText) { _, value in entry.tags = normalizedTags(value) }
                TextField("Scripture (for example: John 3:16)", text: $entry.scriptureReference)
                    .textInputAutocapitalization(.words)
            }

            if entry.photoData != nil || photoError != nil {
                Section("Photo") {
                    if let data = entry.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 300).clipShape(RoundedRectangle(cornerRadius: 12))
                        Button("Remove Photo", role: .destructive) { entry.photoData = nil }
                    }
                    if let photoError { Text(photoError).font(.caption).foregroundStyle(.red) }
                }
            }

            Section("Journal Entry") {
                TextEditor(text: $entry.body)
                    .font(.body)
                    .focused($focusedField, equals: .body)
                    .frame(minHeight: 240)
                    .accessibilityLabel("Journal entry")
            }
        }
        .navigationTitle(entry.title.isEmpty ? "New Entry" : "Edit Entry").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save") { entry.folder = cleanedFolder; entry.tags = normalizedTags(tagText); store.save(entry); dismiss() }.fontWeight(.semibold).disabled(!hasContent) }
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focusedField = nil } }
        }
        .onAppear { tagText = entry.tags.joined(separator: ", "); if entry.title.isEmpty && entry.body.isEmpty { focusedField = .title } }
        .onChange(of: selectedPhoto) { _, item in Task { await loadPhoto(item) } }
    }

    private var cleanedFolder: String { entry.folder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "General" : entry.folder.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func normalizedTags(_ text: String) -> [String] {
        var seen = Set<String>()
        return text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }.filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }
    @MainActor private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), data.count <= 15_000_000, UIImage(data: data) != nil else { throw PhotoError.invalid }
            entry.photoData = data; photoError = nil
        } catch { photoError = "Photo could not be added. Choose an image smaller than 15 MB." }
    }
    private enum PhotoError: Error { case invalid }
}

private struct JournalCalendarView: View {
    let entries: [JournalEntry]
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    private var count: Int { entries.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }.count }
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                DatePicker("Journal date", selection: $date, displayedComponents: .date).datePickerStyle(.graphical).padding()
                Label(count == 1 ? "1 entry on this day" : "\(count) entries on this day", systemImage: count > 0 ? "checkmark.circle.fill" : "calendar")
                    .foregroundStyle(count > 0 ? Color.accentColor : Color.secondary)
                Spacer()
            }
            .navigationTitle("Calendar").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Clear") { selectedDate = nil; dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Show Day") { selectedDate = date; dismiss() } }
            }
            .onAppear { date = selectedDate ?? Date() }
        }
    }
}
