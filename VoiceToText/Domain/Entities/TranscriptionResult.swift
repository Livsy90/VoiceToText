import Foundation

struct TranscriptionResult: Equatable, Sendable {
    let sourceFileName: String
    let text: String
    let createdAt: Date
}
