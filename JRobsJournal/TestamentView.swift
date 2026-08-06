import SwiftUI

struct TestamentView: View {
    let title: String
    let books: [BibleBook]
    var body: some View {
        List(books) { book in
            NavigationLink { ChapterGridView(book: book) } label: {
                HStack { Text(book.name); Spacer(); Text("\(book.chapterCount)").foregroundStyle(.secondary) }
            }
        }.navigationTitle(title)
    }
}

struct ChapterGridView: View {
    let book: BibleBook
    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...book.chapterCount, id: \.self) { chapter in
                    NavigationLink { ReaderPlaceholderView(book: book.name, chapter: chapter) } label: {
                        Text("\(chapter)").frame(maxWidth: .infinity, minHeight: 48).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.navigationTitle(book.name)
    }
}

struct ReaderPlaceholderView: View {
    let book: String
    let chapter: Int
    var body: some View {
        ContentUnavailableView("\(book) \(chapter)", systemImage: "book.pages", description: Text("Scripture database connection is the next implementation step."))
            .navigationTitle("\(book) \(chapter)")
    }
}
