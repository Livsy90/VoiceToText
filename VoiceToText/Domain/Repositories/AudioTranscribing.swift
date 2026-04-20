import Foundation

protocol AudioTranscribing: Sendable {
    func fetchSupportedLanguages() async -> [TranscriptionLanguage]
    func transcribe(file: ImportedAudioFile, language: TranscriptionLanguage) async throws -> TranscriptionResult
}
