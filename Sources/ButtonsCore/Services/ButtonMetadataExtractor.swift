import Foundation

/// What a quick model pass pulls out of a button's prompt so the user never has
/// to fill anything but the prompt itself. Every field is best-effort; callers
/// apply only the ones that are still at their defaults.
public struct ButtonMetadata: Sendable, Equatable {
    public var name: String
    public var category: String
    public var goal: String
    public var colorRawValue: String?
    public var symbolName: String?

    public init(
        name: String,
        category: String = "",
        goal: String = "",
        colorRawValue: String? = nil,
        symbolName: String? = nil
    ) {
        self.name = name
        self.category = category
        self.goal = goal
        self.colorRawValue = colorRawValue
        self.symbolName = symbolName
    }
}

/// Reads a button's run prompt and asks a small, read-only local model to label
/// it — name, category, goal, color, icon. Runs through the same Codex / Claude
/// Code CLI the buttons themselves use, so it needs no extra credentials.
public actor ButtonMetadataExtractor {
    private let runner: LocalAgentRunner

    public init(runner: LocalAgentRunner = LocalAgentRunner()) {
        self.runner = runner
    }

    /// Hard cap on a single labeling pass. A rate-limited CLI can retry for
    /// minutes before failing, so we bound it and let the other provider win.
    static let timeout: Duration = .seconds(30)

    /// Returns nil when the prompt is too thin to label or no local model is
    /// available — callers keep their existing values in that case.
    public func metadata(forPrompt prompt: String, provider: AIProvider) async -> ButtonMetadata? {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return nil }

        // Labeling is provider-independent, so race the button's own runner
        // against the other local CLI and take the first that answers. If the
        // primary is rate limited or signed out, the fallback still wins fast
        // instead of waiting out the primary's internal retry loop.
        let candidates = [provider] + AIProvider.allCases.filter { $0 != provider }

        return await withTaskGroup(of: ButtonMetadata?.self) { group in
            for candidate in candidates {
                group.addTask { await self.label(prompt: trimmed, provider: candidate) }
            }
            for await result in group {
                if let result {
                    group.cancelAll()
                    return result
                }
            }
            return nil
        }
    }

    /// One labeling attempt against one provider, bounded by `timeout`. Returns
    /// nil on failure or timeout; a timeout cancels and tears down the CLI process.
    private func label(prompt: String, provider: AIProvider) async -> ButtonMetadata? {
        let configuration = AIConfiguration(
            provider: provider,
            model: Self.smallModel(for: provider),
            systemPrompt: Self.systemPrompt,
            executionMode: .replyOnly,
            thinkingLevel: .low
        )

        return await withTaskGroup(of: ButtonMetadata?.self) { group in
            group.addTask {
                do {
                    return Self.parse(try await self.runner.run(configuration: configuration, prompt: prompt))
                } catch {
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(for: Self.timeout)
                return nil
            }

            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    /// Empty means "let the CLI pick its default" — low effort on a tiny prompt
    /// keeps the pass quick without pinning a model slug that can go stale.
    static func smallModel(for provider: AIProvider) -> String {
        switch provider {
        case .claudeCode, .codex:
            return ""
        }
    }

    static let systemPrompt = """
    You label one-click automation buttons. Read the button's run prompt and reply with ONLY a single-line minified JSON object — no prose, no markdown, no code fences.
    Keys:
      "name": a 2-4 word Title Case label someone would tap, e.g. "Brex Vendor Card". No surrounding quotes, no trailing punctuation.
      "category": a one or two word bucket, e.g. "Finance", "GitHub", "Email".
      "goal": one short imperative sentence describing the outcome.
      "color": exactly one of poppy, cobalt, mint, graphite, lemon, rose, ocean, paper that suits the theme.
      "symbol": a valid SF Symbol name that fits the task, e.g. "creditcard.fill".
    Output only the JSON object.
    """

    static func parse(_ raw: String) -> ButtonMetadata? {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}"),
              start < end
        else { return nil }

        let slice = String(raw[start...end])
        guard let data = slice.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        func string(_ key: String) -> String? {
            guard let value = object[key] as? String else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        guard let name = string("name") else { return nil }

        return ButtonMetadata(
            name: name,
            category: string("category") ?? "",
            goal: string("goal") ?? "",
            colorRawValue: string("color")?.lowercased(),
            symbolName: string("symbol")
        )
    }
}
