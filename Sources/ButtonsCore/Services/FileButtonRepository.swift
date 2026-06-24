import Foundation

public actor FileButtonRepository {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func production() -> FileButtonRepository {
        let supportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let directoryURL = supportURL.appending(path: "Buttons", directoryHint: .isDirectory)
        return FileButtonRepository(fileURL: directoryURL.appending(path: "buttons.json"))
    }

    public func load() throws -> [ActionButton] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ButtonSeed.defaults
        }

        let data = try Data(contentsOf: fileURL)
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
