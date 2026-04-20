import Foundation

struct AppContainer {
    let importAudioFileUseCase: ImportAudioFileUseCase
    let getSupportedTranscriptionLanguagesUseCase: GetSupportedTranscriptionLanguagesUseCase
    let transcribeAudioFileUseCase: TranscribeAudioFileUseCase

    @MainActor
    func makeTranscriptionViewModel() -> TranscriptionViewModel {
        TranscriptionViewModel(
            importAudioFileUseCase: importAudioFileUseCase,
            getSupportedTranscriptionLanguagesUseCase: getSupportedTranscriptionLanguagesUseCase,
            transcribeAudioFileUseCase: transcribeAudioFileUseCase
        )
    }
}

extension AppContainer {
    static let live: AppContainer = {
        let importer = FileAudioImporter()
        let transcriber = SpeechAnalyzerAudioTranscriber()

        return AppContainer(
            importAudioFileUseCase: ImportAudioFileUseCase(audioFileImporting: importer),
            getSupportedTranscriptionLanguagesUseCase: GetSupportedTranscriptionLanguagesUseCase(audioTranscribing: transcriber),
            transcribeAudioFileUseCase: TranscribeAudioFileUseCase(audioTranscribing: transcriber)
        )
    }()
}
