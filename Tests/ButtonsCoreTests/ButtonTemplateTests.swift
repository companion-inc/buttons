import ButtonsCore
import Foundation
import Testing

@Suite("Button templates")
struct ButtonTemplateTests {
    @Test("Template export and import keeps recipe while minting a new id")
    func exportImportKeepsRecipeWithNewID() throws {
        let button = ButtonSeed.defaults[1]

        let data = try ButtonTemplateCodec.encode(button)
        let decoded = try ButtonTemplateCodec.decode(data)

        #expect(decoded.id != button.id)
        #expect(decoded.title == button.title)
        #expect(decoded.workflow.steps == button.workflow.steps)
    }

    @Test("Template rendering replaces input tokens")
    func templateRenderingReplacesTokens() {
        let rendered = TemplateRenderer.render(
            "Open {{repo}} for {{person}}",
            values: ["repo": "Buttons", "person": "Advait"]
        )

        #expect(rendered == "Open Buttons for Advait")
    }
}
