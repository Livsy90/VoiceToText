import Foundation

protocol AudioFileImporting: Sendable {
    func importFile(from externalURL: URL) throws -> ImportedAudioFile
}
