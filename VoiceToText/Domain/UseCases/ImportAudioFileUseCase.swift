import Foundation

struct ImportAudioFileUseCase: Sendable {
    private let audioFileImporting: any AudioFileImporting

    init(audioFileImporting: any AudioFileImporting) {
        self.audioFileImporting = audioFileImporting
    }

    func execute(from externalURL: URL) throws -> ImportedAudioFile {
        try audioFileImporting.importFile(from: externalURL)
    }
}
