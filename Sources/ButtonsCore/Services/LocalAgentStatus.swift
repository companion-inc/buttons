import Foundation

public struct LocalAgentStatus: Equatable, Sendable {
    public var provider: AIProvider
    public var isInstalled: Bool
    public var isAuthenticated: Bool
    public var executablePath: String?
    public var details: String

    public init(
        provider: AIProvider,
        isInstalled: Bool,
        isAuthenticated: Bool,
        executablePath: String?,
        details: String
    ) {
        self.provider = provider
        self.isInstalled = isInstalled
        self.isAuthenticated = isAuthenticated
        self.executablePath = executablePath
        self.details = details
    }
}
