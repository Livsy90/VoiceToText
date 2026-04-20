import Foundation

struct TranscriptionLanguage: Equatable, Identifiable, Sendable {
    let localeIdentifier: String
    let displayName: String

    var id: String {
        localeIdentifier
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }
}
