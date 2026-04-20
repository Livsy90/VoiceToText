import AVFoundation
import Foundation
import Speech

struct SpeechAnalyzerAudioTranscriber: AudioTranscribing {
    func fetchSupportedLanguages() async -> [TranscriptionLanguage] {
        let speechLocales = await SpeechTranscriber.supportedLocales
        let dictationLocales = await DictationTranscriber.supportedLocales
        let locales = Array(Set(speechLocales + dictationLocales))
            .sorted { lhs, rhs in
                lhs.localizedString(forIdentifier: lhs.identifier) ?? lhs.identifier
                    < rhs.localizedString(forIdentifier: rhs.identifier) ?? rhs.identifier
            }

        return locales.map { locale in
            TranscriptionLanguage(
                localeIdentifier: locale.identifier,
                displayName: locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
            )
        }
    }

    func transcribe(
        file: ImportedAudioFile,
        language: TranscriptionLanguage
    ) async throws -> TranscriptionResult {
        let locale = language.locale
        var errors: [Error] = []

        if await SpeechTranscriber.supportedLocale(equivalentTo: locale) != nil {
            do {
                return try await transcribeWithSpeechTranscriber(file: file, locale: locale)
            } catch {
                errors.append(error)
            }
        }

        if await DictationTranscriber.supportedLocale(equivalentTo: locale) != nil {
            do {
                return try await transcribeWithDictationTranscriber(file: file, locale: locale)
            } catch {
                errors.append(error)
            }
        }

        if let firstError = errors.first {
            throw mapError(firstError)
        }

        throw TranscriptionServiceError.unsupportedLocale
    }

    private func transcribeWithSpeechTranscriber(
        file: ImportedAudioFile,
        locale: Locale
    ) async throws -> TranscriptionResult {
        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
        return try await transcribe(file: file, module: transcriber)
    }

    private func transcribeWithDictationTranscriber(
        file: ImportedAudioFile,
        locale: Locale
    ) async throws -> TranscriptionResult {
        let transcriber = DictationTranscriber(locale: locale, preset: .longDictation)
        return try await transcribe(file: file, module: transcriber)
    }

    private func transcribe(
        file: ImportedAudioFile,
        module: SpeechTranscriber
    ) async throws -> TranscriptionResult {
        try await installAssetsIfNeeded(for: module)

        let audioFile = try AVAudioFile(forReading: file.localURL)
        let analyzer = SpeechAnalyzer(modules: [module])
        let collector = Task {
            try await collectText(from: module.results)
        }

        do {
            let lastSampleTime = try await analyzer.analyzeSequence(from: audioFile)

            if let lastSampleTime {
                try await analyzer.finalizeAndFinish(through: lastSampleTime)
            } else {
                await analyzer.cancelAndFinishNow()
            }

            let text = try await collector.value
            return TranscriptionResult(
                sourceFileName: file.fileName,
                text: text,
                createdAt: .now
            )
        } catch {
            collector.cancel()
            throw mapError(error)
        }
    }

    private func transcribe(
        file: ImportedAudioFile,
        module: DictationTranscriber
    ) async throws -> TranscriptionResult {
        try await installAssetsIfNeeded(for: module)

        let audioFile = try AVAudioFile(forReading: file.localURL)
        let analyzer = SpeechAnalyzer(modules: [module])
        let collector = Task {
            try await collectText(from: module.results)
        }

        do {
            let lastSampleTime = try await analyzer.analyzeSequence(from: audioFile)

            if let lastSampleTime {
                try await analyzer.finalizeAndFinish(through: lastSampleTime)
            } else {
                await analyzer.cancelAndFinishNow()
            }

            let text = try await collector.value
            return TranscriptionResult(
                sourceFileName: file.fileName,
                text: text,
                createdAt: .now
            )
        } catch {
            collector.cancel()
            throw mapError(error)
        }
    }

    private func installAssetsIfNeeded(for module: any SpeechModule) async throws {
        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            try await installationRequest.downloadAndInstall()
        }
    }

    private func collectText<ResultSequence: AsyncSequence>(
        from results: ResultSequence
    ) async throws -> String where ResultSequence.Element == SpeechTranscriber.Result {
        var fragments: [String] = []

        for try await result in results {
            let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            fragments.append(text)
        }

        let mergedText = fragments.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mergedText.isEmpty else {
            throw TranscriptionServiceError.emptyTranscription
        }

        return mergedText
    }

    private func collectText<ResultSequence: AsyncSequence>(
        from results: ResultSequence
    ) async throws -> String where ResultSequence.Element == DictationTranscriber.Result {
        var fragments: [String] = []

        for try await result in results {
            let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            fragments.append(text)
        }

        let mergedText = fragments.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mergedText.isEmpty else {
            throw TranscriptionServiceError.emptyTranscription
        }

        return mergedText
    }

    private func mapError(_ error: Error) -> Error {
        if error is CancellationError {
            return TranscriptionServiceError.transcriptionCancelled
        }

        let nsError = error as NSError
        let loweredDescription = nsError.localizedDescription.lowercased()

        if loweredDescription.contains("asset not found")
            || loweredDescription.contains("no model")
            || loweredDescription.contains("not available or downloadable") {
            return TranscriptionServiceError.languageModelUnavailable
        }

        return error
    }
}

enum TranscriptionServiceError: LocalizedError {
    case unsupportedLocale
    case emptyTranscription
    case transcriptionCancelled
    case languageModelUnavailable

    var errorDescription: String? {
        switch self {
        case .unsupportedLocale:
            return "На этом устройстве недоступна поддерживаемая локаль для распознавания речи."
        case .emptyTranscription:
            return "Не удалось распознать речь в выбранном аудиофайле."
        case .transcriptionCancelled:
            return "Транскрибация была прервана."
        case .languageModelUnavailable:
            return "Для выбранного языка на устройстве недоступна модель распознавания."
        }
    }
}
