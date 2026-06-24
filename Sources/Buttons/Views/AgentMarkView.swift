import ButtonsCore
import SwiftUI

struct AgentMarkView: View {
    let provider: AIProvider

    var body: some View {
        switch provider {
        case .codex:
            CodexMark()
        case .claudeCode:
            ClaudeCodeMark()
        }
    }
}
