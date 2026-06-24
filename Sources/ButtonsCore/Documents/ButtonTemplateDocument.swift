import Foundation
import SwiftUI
import UniformTypeIdentifiers

public struct ButtonTemplateDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.buttonsTemplate, .json] }
    public static var writableContentTypes: [UTType] { [.buttonsTemplate, .json] }

    public var button: ActionButton

    public init(button: ActionButton) {
        self.button = button
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        button = try ButtonTemplateCodec.decode(data)
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try ButtonTemplateCodec.encode(button)
        return FileWrapper(regularFileWithContents: data)
    }
}
