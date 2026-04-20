import Foundation

struct GetSupportedTranscriptionLanguagesUseCase: Sendable {
    private let audioTranscribing: any AudioTranscribing

    init(audioTranscribing: any AudioTranscribing) {
        self.audioTranscribing = audioTranscribing
    }

    func execute() async -> [TranscriptionLanguage] {
        await audioTranscribing.fetchSupportedLanguages()
    }
}
