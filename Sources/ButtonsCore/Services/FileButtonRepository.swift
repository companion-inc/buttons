import Foundation

public actor FileButtonRepository {
    private let fileURL: URL
    private let legacyReadURL: URL?

    public init(fileURL: URL, legacyReadURL: URL? = nil) {
        self.fileURL = fileURL
        self.legacyReadURL = legacyReadURL
    }

    public static func production() -> FileButtonRepository {
        let legacySupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
            .appending(path: "Buttons", directoryHint: .isDirectory)

        return FileButtonRepository(
            fileURL: ButtonAutomationWorkspace.homeURL.appending(path: "buttons.json"),
            legacyReadURL: legacySupportURL.appending(path: "buttons.json")
        )
    }

    public func load() throws -> [ActionButton] {
        let readURL: URL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            readURL = fileURL
        } else if let legacyReadURL, FileManager.default.fileExists(atPath: legacyReadURL.path) {
            readURL = legacyReadURL
        } else {
            return ButtonSeed.defaults
        }

        let data = try Data(contentsOf: readURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ActionButton].self, from: data)
    }

    public func save(_ buttons: [ActionButton]) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(buttons)
        try data.write(to: fileURL, options: [.atomic])
    }
}
