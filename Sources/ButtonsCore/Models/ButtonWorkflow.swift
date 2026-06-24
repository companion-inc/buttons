import Foundation

public struct ButtonWorkflow: Codable, Equatable, Sendable {
    public var steps: [WorkflowStep]

    public init(steps: [WorkflowStep]) {
        self.steps = steps
    }

    enum CodingKeys: String, CodingKey {
        case inputs
        case steps
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyInputs = try container.decodeIfPresent([LegacyButtonInputField].self, forKey: .inputs) ?? []
        let decodedSteps = try container.decode([WorkflowStep].self, forKey: .steps)

        guard !legacyInputs.isEmpty else {
            steps = decodedSteps
            return
        }

        let legacyValues = Dictionary(uniqueKeysWithValues: legacyInputs.map { ($0.key, $0.defaultValue) })
        steps = decodedSteps.map { step in
            var copy = step
            copy.value = LegacyTemplateRenderer.render(copy.value, values: legacyValues)
            return copy
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(steps, forKey: .steps)
    }
}
