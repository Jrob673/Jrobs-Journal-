import LocalAuthentication
import SwiftUI

@MainActor
final class AppLockManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var isUnlocked = true
    @Published var errorMessage: String?

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: "journalSecurity.appLockEnabled")
        isUnlocked = !isEnabled
    }

    func enable() async -> Bool {
        guard await authenticate(reason: "Enable protection for your journal") else { return false }
        isEnabled = true
        UserDefaults.standard.set(true, forKey: "journalSecurity.appLockEnabled")
        isUnlocked = true
        return true
    }

    func disable() {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: "journalSecurity.appLockEnabled")
        isUnlocked = true
        errorMessage = nil
    }

    func lock() {
        guard isEnabled else { return }
        isUnlocked = false
        errorMessage = nil
    }

    func unlock() async {
        guard isEnabled, !isUnlocked else { return }
        _ = await authenticate(reason: "Unlock JRobs Journal")
    }

    func authenticateEntry(title: String) async -> Bool {
        await authenticate(reason: "Unlock \(title.isEmpty ? "this journal entry" : title)")
    }

    private func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"

        var evaluationError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evaluationError) else {
            errorMessage = evaluationError?.localizedDescription ?? "Set a device passcode before enabling Journal Lock."
            return false
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                isUnlocked = true
                errorMessage = nil
            }
            return success
        } catch {
            isUnlocked = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}

struct JournalLockView: View {
    @EnvironmentObject private var appLock: AppLockManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("JRobs Journal is Locked")
                .font(.title2.bold())
            Text("Authenticate with Face ID, Touch ID, or your device passcode.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                Task { await appLock.unlock() }
            } label: {
                Label("Unlock Journal", systemImage: "faceid")
                    .frame(maxWidth: 280)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let errorMessage = appLock.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .task { await appLock.unlock() }
    }
}

struct JournalSecurityView: View {
    @EnvironmentObject private var appLock: AppLockManager
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Journal Protection") {
                    LabeledContent("Encrypted Storage", value: "On")
                    LabeledContent("App Lock", value: appLock.isEnabled ? "On" : "Off")

                    Button(appLock.isEnabled ? "Turn Off App Lock" : "Turn On App Lock") {
                        Task {
                            isWorking = true
                            if appLock.isEnabled {
                                appLock.disable()
                            } else {
                                _ = await appLock.enable()
                            }
                            isWorking = false
                        }
                    }
                    .disabled(isWorking)
                }

                Section {
                    Text("Journal entries are encrypted with AES-256-GCM. The encryption key is stored in the Apple Keychain and is restricted to this device.")
                }

                if let errorMessage = appLock.errorMessage {
                    Section("Security Status") {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Journal Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
