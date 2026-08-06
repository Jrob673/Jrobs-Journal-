import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { TestamentView(title: "Old Testament", books: BibleData.oldTestament) } label: { Label("Old Testament", systemImage: "book.closed") }
                NavigationLink { TestamentView(title: "New Testament", books: BibleData.newTestament) } label: { Label("New Testament", systemImage: "cross") }
                NavigationLink { JournalView() } label: { Label("Free Hand Journal", systemImage: "square.and.pencil") }
            }
            .navigationTitle("JRobs Journal")
            .searchable(text: $searchText, prompt: "One-word search")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") } } }
        }
    }
}
