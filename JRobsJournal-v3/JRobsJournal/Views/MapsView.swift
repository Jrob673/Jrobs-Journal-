import SwiftUI

struct MapsView: View {
    var body: some View {
        List {
            ContentUnavailableView(
                "Bible Maps",
                systemImage: "map.fill",
                description: Text("Map packages can be added when a licensed source is selected.")
            )
        }
        .navigationTitle("Maps")
    }
}
