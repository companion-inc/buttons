import Foundation
import Observation

@MainActor
@Observable
public final class LocalAgentStatusStore {
    public private(set) var statuses: [AIProvider: LocalAgentStatus] = [:]
    public private(set) var isRefreshing = false

    private let runner: LocalAgentRunner

    public init(runner: LocalAgentRunner = LocalAgentRunner()) {
        self.runner = runner
    }

    public static func production() -> LocalAgentStatusStore {
        LocalAgentStatusStore()
    }

    public func status(for provider: AIProvider) -> LocalAgentStatus? {
        statuses[provider]
    }

    public func refresh() async {
        isRefreshing = true
        defer {
            isRefreshing = false
        }

        var nextStatuses: [AIProvider: LocalAgentStatus] = [:]

        for provider in AIProvider.allCases {
            nextStatuses[provider] = await runner.status(for: provider)
        }

        statuses = nextStatuses
    }
}
