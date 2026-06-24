import Foundation

public enum ButtonTemplateCodec {
    public static func encode(_ button: ActionButton) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(button)
    }

    public static func decode(_ data: Data) throws -> ActionButton {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var button = try decoder.decode(ActionButton.self, from: data)
        button.id = UUID()
        button.createdAt = Date()
        button.updatedAt = Date()
        return button
    }
}
