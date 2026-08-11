import AVFoundation
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

enum JournalReminderManager {
    private static func identifier(for id: UUID) -> String { "journal-entry-\(id.uuidString)" }

    static func schedule(for entry: JournalEntry) async throws {
        guard let date = entry.reminderDate, date > Date() else { cancel(entryID: entry.id); return }
        let center = UNUserNotificationCenter.current()
        guard try await center.requestAuthorization(options: [.alert, .badge, .sound]) else { throw ReminderError.permissionDenied }
        let content = UNMutableNotificationContent()
        content.title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Journal Reminder" : entry.title
        content.body = "You scheduled time for this journal entry."
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(identifier: identifier(for: entry.id), content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: entry.id)])
        try await center.add(request)
    }

    static func cancel(entryID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: entryID)])
    }

    enum ReminderError: LocalizedError {
        case permissionDenied
        var errorDescription: String? { "Notifications are disabled. Enable them in Settings to use journal reminders." }
    }
}

@MainActor
final class VoiceNoteRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var isPlaying = false
    @Published var errorMessage: String?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent("JRobsJournalVoiceNote.m4a")

    func start() async {
        let allowed = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
        }
        guard allowed else { errorMessage = "Microphone access is required to record a voice note."; return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try session.setActive(true)
            recorder = try AVAudioRecorder(url: temporaryURL, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1, AVEncoderBitRateKey: 96_000,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            errorMessage = nil
        } catch { errorMessage = "Recording could not start: \(error.localizedDescription)" }
    }

    func stop() -> Data? {
        recorder?.stop(); recorder = nil; isRecording = false
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        guard let data = try? Data(contentsOf: temporaryURL), data.count <= 25_000_000 else {
            errorMessage = "The voice note is too large. Keep recordings under about 30 minutes."
            return nil
        }
        return data
    }

    func togglePlayback(data: Data) {
        if isPlaying { player?.stop(); player = nil; isPlaying = false; return }
        do { player = try AVAudioPlayer(data: data); player?.delegate = self; player?.play(); isPlaying = true }
        catch { errorMessage = "The voice note could not be played." }
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { isPlaying = false }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) { isRecording = false }
}

extension UTType { static let jrobsJournalBackup = UTType(exportedAs: "com.jrob673.jrobsjournal.backup", conformingTo: .json) }

struct JournalBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.jrobsJournalBackup, .json] }
    var data = Data()
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
