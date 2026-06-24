import Foundation

public struct ButtonRunReceipt: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var buttonID: UUID
    public var buttonTitle: String
    public var startedAt: Date
    public var finishedAt: Date
    public var status: ButtonRunStatus
    public var summary: String
    public var output: String

    public init(
        id: UUID = UUID(),
        buttonID: UUID,
        buttonTitle: String,
        startedAt: Date = Date(),
        finishedAt: Date = Date(),
        status: ButtonRunStatus,
        summary: String,
        output: String = ""
    ) {
        self.id = id
        self.buttonID = buttonID
        self.buttonTitle = buttonTitle
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.status = status
        self.summary = summary
        self.output = output
    }
}
