import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class TranscriptionViewModel {
    enum ViewState: Equatable {
        case idle
        case processing(fileName: String)
        case loaded(TranscriptionResult)
        case failed(message: String, lastResult: TranscriptionResult?)

        var result: TranscriptionResult? {
            switch self {
            case .loaded(let result):
                return result
            case .failed(_, let lastResult):
                return lastResult
            case .idle, .processing:
                return nil
            }
        }
    }

    var state: ViewState = .idle
    var isFileImporterPresented = false
    var supportedLanguages: [TranscriptionLanguage] = []
    var selectedLanguageIdentifier = ""
    var isLoadingLanguages = false

    private let importAudioFileUseCase: ImportAudioFileUseCase
    private let getSupportedTranscriptionLanguagesUseCase: GetSupportedTranscriptionLanguagesUseCase
    private let transcribeAudioFileUseCase: TranscribeAudioFileUseCase

    init(
        importAudioFileUseCase: ImportAudioFileUseCase,
        getSupportedTranscriptionLanguagesUseCase: GetSupportedTranscriptionLanguagesUseCase,
        transcribeAudioFileUseCase: TranscribeAudioFileUseCase
    ) {
        self.importAudioFileUseCase = importAudioFileUseCase
        self.getSupportedTranscriptionLanguagesUseCase = getSupportedTranscriptionLanguagesUseCase
        self.transcribeAudioFileUseCase = transcribeAudioFileUseCase
    }

    var transcriptionText: String? {
        state.result?.text
    }

    var shareText: String {
        transcriptionText ?? ""
    }

    var canShareOrCopy: Bool {
        transcriptionText?.isEmpty == false
    }

    var canImportAudio: Bool {
        !selectedLanguageIdentifier.isEmpty && !isLoadingLanguages
    }

    var selectedLanguage: TranscriptionLanguage? {
        supportedLanguages.first { $0.id == selectedLanguageIdentifier }
    }

    func loadSupportedLanguagesIfNeeded() {
        guard supportedLanguages.isEmpty, !isLoadingLanguages else { return }

        Task {
            isLoadingLanguages = true
            let languages = await getSupportedTranscriptionLanguagesUseCase.execute()
            supportedLanguages = languages
            if selectedLanguageIdentifier.isEmpty {
                selectedLanguageIdentifier = preferredLanguageIdentifier(from: languages)
            }
            isLoadingLanguages = false
        }
    }

    func openImporter() {
        guard canImportAudio else { return }
        isFileImporterPresented = true
    }

    func handleImportedFile(_ result: Result<URL, any Error>) {
        Task {
            await importAndTranscribe(result)
        }
    }

    func copyText() {
        guard let transcriptionText else { return }
        UIPasteboard.general.string = transcriptionText
    }

    private func importAndTranscribe(_ result: Result<URL, any Error>) async {
        let previousResult = state.result

        do {
            let externalURL = try result.get()
            let importedFile = try importAudioFileUseCase.execute(from: externalURL)
            state = .processing(fileName: importedFile.fileName)

            guard let selectedLanguage else {
                throw TranscriptionServiceError.unsupportedLocale
            }

            let transcription = try await transcribeAudioFileUseCase.execute(
                file: importedFile,
                language: selectedLanguage
            )
            state = .loaded(transcription)
        } catch {
            state = .failed(
                message: error.localizedDescription,
                lastResult: previousResult
            )
        }
    }

    private func preferredLanguageIdentifier(from languages: [TranscriptionLanguage]) -> String {
        if let matchedLanguage = languages.first(where: { $0.locale.language.languageCode?.identifier == Locale.current.language.languageCode?.identifier }) {
            return matchedLanguage.id
        }

        return languages.first?.id ?? ""
    }
}
