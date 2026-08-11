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
    @State private var showingSecurity = false
    @State private var showingTools = false

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
                        NavigationLink { EntryAccessView(entry: entry) } label: { JournalEntryRow(entry: entry) }
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
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Button { showingSecurity = true } label: { Label("Journal Security", systemImage: "lock.shield") }
                    Button { showingTools = true } label: { Label("Backup & Restore", systemImage: "externaldrive") }
                } label: { Label("Journal Tools", systemImage: "ellipsis.circle") }
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink { EntryEditorView() } label: { Label("New Entry", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingCalendar) {
            JournalCalendarView(entries: store.entries, selectedDate: $selectedDate)
        }
        .sheet(isPresented: $showingSecurity) { JournalSecurityView() }
        .sheet(isPresented: $showingTools) { JournalToolsView() }
        .alert("Journal Storage Error", isPresented: Binding(
            get: { store.storageError != nil },
            set: { if !$0 { store.dismissStorageError() } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.storageError ?? "The journal could not be saved.")
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
            if !entry.isLocked, let data = entry.photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title).font(.headline).lineLimit(1)
                    Spacer()
                    if entry.isFavorite { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                    if entry.isLocked { Image(systemName: "lock.fill").foregroundStyle(.secondary) }
                    Text(entry.updatedAt, format: .dateTime.hour().minute()).font(.caption).foregroundStyle(.secondary)
                }
                if entry.isLocked {
                    Label("Locked entry", systemImage: "lock.shield")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    if !preview.isEmpty { Text(preview).font(.subheadline).foregroundStyle(.secondary).lineLimit(2) }
                    if !entry.scriptureReference.isEmpty { Label(entry.scriptureReference, systemImage: "book.closed").font(.caption).foregroundStyle(.tint) }
                    HStack(spacing: 6) {
                        Label(entry.folder.isEmpty ? "General" : entry.folder, systemImage: "folder")
                        ForEach(entry.tags.prefix(2), id: \.self) { Text("#\($0)") }
                    }.font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }.padding(.vertical, 6).contentShape(Rectangle())
    }
}

private struct EntryAccessView: View {
    @EnvironmentObject private var appLock: AppLockManager
    let entry: JournalEntry
    @State private var isAuthorized = false
    @State private var isAuthenticating = false

    var body: some View {
        Group {
            if !entry.isLocked || isAuthorized {
                EntryEditorView(entry: entry)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60)).foregroundStyle(.tint)
                    Text("Entry Locked").font(.title2.bold())
                    Text("Authenticate to view or edit this entry.")
                        .foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button { Task { await authenticate() } } label: {
                        Label("Unlock Entry", systemImage: "faceid")
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .disabled(isAuthenticating)
                    if let error = appLock.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                    }
                }
                .padding(32)
                .task { await authenticate() }
            }
        }
    }

    @MainActor
    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        isAuthorized = await appLock.authenticateEntry(title: entry.title)
        isAuthenticating = false
    }
}

struct EntryEditorView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var entry: JournalEntry
    @State private var tagText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoError: String?
    @StateObject private var voiceRecorder = VoiceNoteRecorder()
    @State private var reminderEnabled = false
    @State private var reminderDate = Date().addingTimeInterval(3600)
    @State private var featureError: String?
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
                Toggle(isOn: $entry.isLocked) {
                    Label("Lock This Entry", systemImage: entry.isLocked ? "lock.fill" : "lock.open")
                }

                TextField("Folder (for example: Faith)", text: $entry.folder)
                TextField("Tags separated by commas", text: $tagText)
                    .onChange(of: tagText) { _, value in entry.tags = normalizedTags(value) }
                TextField("Scripture (for example: John 3:16)", text: $entry.scriptureReference)
                    .textInputAutocapitalization(.words)
            }

            Section("Reminder") {
                Toggle("Remind Me", isOn: $reminderEnabled)
                if reminderEnabled {
                    DatePicker("Date and Time", selection: $reminderDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }
            }

            Section("Voice Note") {
                if voiceRecorder.isRecording {
                    Button(role: .destructive) {
                        if let data = voiceRecorder.stop() { entry.audioData = data }
                    } label: { Label("Stop Recording", systemImage: "stop.circle.fill") }
                } else {
                    Button { Task { await voiceRecorder.start() } } label: {
                        Label(entry.audioData == nil ? "Record Voice Note" : "Replace Voice Note", systemImage: "mic.circle")
                    }
                }
                if let audio = entry.audioData {
                    Button { voiceRecorder.togglePlayback(data: audio) } label: {
                        Label(voiceRecorder.isPlaying ? "Stop Playback" : "Play Voice Note", systemImage: voiceRecorder.isPlaying ? "stop.fill" : "play.fill")
                    }
                    Button("Remove Voice Note", role: .destructive) { entry.audioData = nil }
                }
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
            ToolbarItem(placement: .confirmationAction) { Button("Save") { saveEntry() }.fontWeight(.semibold).disabled(!hasContent || voiceRecorder.isRecording) }
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focusedField = nil } }
        }
        .onAppear {
            tagText = entry.tags.joined(separator: ", ")
            reminderEnabled = entry.reminderDate != nil
            reminderDate = max(entry.reminderDate ?? .distantPast, Date().addingTimeInterval(3600))
            if entry.title.isEmpty && entry.body.isEmpty { focusedField = .title }
        }
        .onChange(of: selectedPhoto) { _, item in Task { await loadPhoto(item) } }
        .onChange(of: voiceRecorder.errorMessage) { _, value in featureError = value }
        .alert("Journal Feature Error", isPresented: Binding(get: { featureError != nil }, set: { if !$0 { featureError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(featureError ?? "The requested action could not be completed.") }
    }

    private var cleanedFolder: String { entry.folder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "General" : entry.folder.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func saveEntry() {
        entry.folder = cleanedFolder
        entry.tags = normalizedTags(tagText)
        entry.reminderDate = reminderEnabled ? reminderDate : nil
        store.save(entry)
        if reminderEnabled {
            Task {
                do { try await JournalReminderManager.schedule(for: entry); dismiss() }
                catch { featureError = error.localizedDescription }
            }
        } else {
            JournalReminderManager.cancel(entryID: entry.id)
            dismiss()
        }
    }
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

private struct JournalToolsView: View {
    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var exportDocument = JournalBackupDocument()
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingRestoreData: Data?
    @State private var confirmingRestore = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Backup") {
                    Button { exportBackup() } label: { Label("Export Journal Backup", systemImage: "square.and.arrow.up") }
                    Text("The exported backup contains your entries, photos, and voice notes. Store it securely because the portable file is not encrypted.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Restore") {
                    Button { showingImporter = true } label: { Label("Restore from Backup", systemImage: "square.and.arrow.down") }
                    Text("Restore replaces every journal entry currently stored on this device.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Backup & Restore").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .jrobsJournalBackup,
                          defaultFilename: "JRobs-Journal-Backup-\(Date().formatted(.iso8601.year().month().day()))") { result in
                if case .failure(let error) = result { message = error.localizedDescription }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.jrobsJournalBackup, .json]) { result in
                do {
                    let url = try result.get()
                    guard url.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
                    defer { url.stopAccessingSecurityScopedResource() }
                    pendingRestoreData = try Data(contentsOf: url)
                    confirmingRestore = true
                } catch { message = error.localizedDescription }
            }
            .confirmationDialog("Replace Current Journal?", isPresented: $confirmingRestore, titleVisibility: .visible) {
                Button("Replace and Restore", role: .destructive) { restoreBackup() }
                Button("Cancel", role: .cancel) { pendingRestoreData = nil }
            } message: { Text("This cannot be undone unless you export a backup first.") }
            .alert("Backup & Restore", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(message ?? "") }
        }
    }

    private func exportBackup() {
        do { exportDocument = JournalBackupDocument(data: try store.exportData()); showingExporter = true }
        catch { message = error.localizedDescription }
    }
    private func restoreBackup() {
        guard let data = pendingRestoreData else { return }
        do { try store.restore(from: data); message = "Journal backup restored successfully." }
        catch { message = "This backup could not be restored: \(error.localizedDescription)" }
        pendingRestoreData = nil
    }
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
