import Foundation

struct TranscribeAudioFileUseCase: Sendable {
    private let audioTranscribing: any AudioTranscribing

    init(audioTranscribing: any AudioTranscribing) {
        self.audioTranscribing = audioTranscribing
    }

    func execute(
        file: ImportedAudioFile,
        language: TranscriptionLanguage
    ) async throws -> TranscriptionResult {
        try await audioTranscribing.transcribe(file: file, language: language)
    }
}
