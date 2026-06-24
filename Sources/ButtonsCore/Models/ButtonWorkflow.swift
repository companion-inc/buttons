import Foundation

public struct ButtonWorkflow: Codable, Equatable, Sendable {
    public var inputs: [ButtonInputField]
    public var steps: [WorkflowStep]

    public init(inputs: [ButtonInputField] = [], steps: [WorkflowStep]) {
        self.inputs = inputs
        self.steps = steps
    }
}
