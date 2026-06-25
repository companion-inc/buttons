@testable import ButtonsCore
import Foundation
import Testing

@Suite("Button metadata extraction")
struct ButtonMetadataExtractorTests {
    @Test("Parses the clean minified JSON a small model returns")
    func parsesCleanJSON() throws {
        let raw = #"{"name":"Brex Vendor Card","category":"Finance","goal":"Find or create a Brex vendor card for the current provider and autofill its details.","color":"cobalt","symbol":"creditcard.fill"}"#

        let metadata = try #require(ButtonMetadataExtractor.parse(raw))

        #expect(metadata.name == "Brex Vendor Card")
        #expect(metadata.category == "Finance")
        #expect(metadata.goal.hasPrefix("Find or create"))
        #expect(metadata.colorRawValue == "cobalt")
        #expect(metadata.symbolName == "creditcard.fill")
    }

    @Test("Recovers JSON wrapped in prose or code fences")
    func recoversJSONFromNoisyOutput() throws {
        let raw = """
        Sure — here's the label:
        ```json
        {"name":"Star Repo","category":"GitHub","goal":"Star the repository."}
        ```
        """

        let metadata = try #require(ButtonMetadataExtractor.parse(raw))

        #expect(metadata.name == "Star Repo")
        #expect(metadata.category == "GitHub")
        #expect(metadata.colorRawValue == nil)
        #expect(metadata.symbolName == nil)
    }

    @Test("Lowercases the color so it maps onto the ButtonColor enum")
    func normalizesColor() throws {
        let raw = #"{"name":"Ocean Thing","color":"Ocean"}"#

        let metadata = try #require(ButtonMetadataExtractor.parse(raw))

        let color = try #require(ButtonColor(rawValue: metadata.colorRawValue ?? ""))
        #expect(color == .ocean)
    }

    @Test("Returns nil when there is no usable name")
    func rejectsOutputWithoutName() {
        #expect(ButtonMetadataExtractor.parse("no json here at all") == nil)
        #expect(ButtonMetadataExtractor.parse(#"{"category":"Finance"}"#) == nil)
        #expect(ButtonMetadataExtractor.parse(#"{"name":"   "}"#) == nil)
    }

    @Test("Metadata labels use CLI defaults instead of pinned model slugs")
    func omitsModelPins() {
        #expect(ButtonMetadataExtractor.smallModel(for: .claudeCode) == "")
        #expect(ButtonMetadataExtractor.smallModel(for: .codex) == "")
    }
}
