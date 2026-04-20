import Foundation

struct ImportedAudioFile: Equatable, Sendable {
    let id: UUID
    let fileName: String
    let localURL: URL
}
