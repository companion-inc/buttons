import Foundation

public struct AIConfiguration: Codable, Equatable, Sendable {
    public var provider: AIProvider
    public var model: String
    public var systemPrompt: String
    public var executionMode: AIExecutionMode
    public var workingDirectory: String
    public var thinkingLevel: AgentThinkingLevel

    public init(
        provider: AIProvider = .codex,
        model: String = "",
        systemPrompt: String = "",
        executionMode: AIExecutionMode = .workspaceWrite,
        workingDirectory: String = AIConfiguration.defaultWorkingDirectory,
        thinkingLevel: AgentThinkingLevel = .high
    ) {
        self.provider = provider
        self.model = model
        self.systemPrompt = systemPrompt
        self.executionMode = executionMode
        self.workingDirectory = workingDirectory
        self.thinkingLevel = thinkingLevel
    }

    public static var defaultWorkingDirectory: String {
        FileManager.default.homeDirectoryForCurrentUser.path
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case model
        case systemPrompt
        case executionMode
        case workingDirectory
        case thinkingLevel
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        provider = try container.decodeIfPresent(AIProvider.self, forKey: .provider) ?? .codex
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? ""
        systemPrompt = try container.decodeIfPresent(String.self, forKey: .systemPrompt) ?? ""
        executionMode = try container.decodeIfPresent(AIExecutionMode.self, forKey: .executionMode) ?? .workspaceWrite
        workingDirectory = try container.decodeIfPresent(String.self, forKey: .workingDirectory) ?? AIConfiguration.defaultWorkingDirectory
        thinkingLevel = try container.decodeIfPresent(AgentThinkingLevel.self, forKey: .thinkingLevel) ?? .high
    }
}
