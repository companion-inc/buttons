import Foundation

public actor ButtonRunReceiptRepository {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func production() -> ButtonRunReceiptRepository {
        let supportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let directoryURL = supportURL.appending(path: "Buttons", directoryHint: .isDirectory)
        return ButtonRunReceiptRepository(fileURL: directoryURL.appending(path: "runs.json"))
    }

    public func load() throws -> [ButtonRunReceipt] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ButtonRunReceipt].self, from: data)
    }

    public func save(_ receipts: [ButtonRunReceipt]) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(receipts)
        try data.write(to: fileURL, options: [.atomic])
    }
}
