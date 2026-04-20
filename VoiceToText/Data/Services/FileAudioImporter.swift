import Foundation

struct FileAudioImporter: AudioFileImporting {
    func importFile(from externalURL: URL) throws -> ImportedAudioFile {
        let startedAccessing = externalURL.startAccessingSecurityScopedResource()
        defer {
            if startedAccessing {
                externalURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileManager = FileManager.default
        let importsDirectory = try makeImportsDirectory(using: fileManager)
        let destinationURL = importsDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(externalURL.pathExtension)

        if fileManager.fileExists(atPath: destinationURL.path()) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: externalURL, to: destinationURL)

        return ImportedAudioFile(
            id: UUID(),
            fileName: externalURL.lastPathComponent,
            localURL: destinationURL
        )
    }

    private func makeImportsDirectory(using fileManager: FileManager) throws -> URL {
        let applicationSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let importsDirectory = applicationSupportURL
            .appendingPathComponent("ImportedAudio", isDirectory: true)

        try fileManager.createDirectory(
            at: importsDirectory,
            withIntermediateDirectories: true
        )

        return importsDirectory
    }
}
