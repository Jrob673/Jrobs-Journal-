import SwiftUI

struct JournalView: View {
    @State private var title = ""
    @State private var bodyText = ""
    var body: some View {
        Form {
            TextField("Entry title", text: $title)
            TextEditor(text: $bodyText).frame(minHeight: 320)
        }
        .navigationTitle("Free Hand Journal")
        .toolbar { Button("Save") {}.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
    }
}
