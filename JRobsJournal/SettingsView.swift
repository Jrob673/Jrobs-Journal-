import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = 0
    @AppStorage("readerFontSize") private var readerFontSize = 18.0
    var body: some View {
        Form {
            Section("Appearance") { Picker("Theme", selection: $appearanceMode) { Text("System").tag(0); Text("Light").tag(1); Text("Dark").tag(2) } }
            Section("Reading") { Slider(value: $readerFontSize, in: 14...34, step: 1); Text("Preview text — \(Int(readerFontSize)) pt").font(.system(size: readerFontSize)) }
        }.navigationTitle("Settings")
    }
}
