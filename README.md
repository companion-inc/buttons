# Buttons

Buttons is a native macOS app for creating, running, customizing, and sharing one-click AI workflow buttons.

The app opens directly to a button board. Every button is a background-agent workflow. The user can design the button face, set a category, set inputs, choose Codex or Claude Code, choose a model override, choose thinking level, choose permission level, and review every run log.

Buttons does not store OpenAI or Anthropic API keys. It runs the locally installed Codex or Claude Code CLI using the login already present on the Mac.

On first run, a button asks the selected local agent to extract the repetitive workflow into a reusable `run.zsh` script under Application Support. Later clicks run that script first so the button gets cheaper. If the script breaks, Buttons sends the failure and current script back to the agent, repairs it in place, and retries once.

## Build

```sh
swift build
swift test
scripts/package-buttons-app.sh debug
open .build/debug/Buttons.app
```

## Button runtime

- Button workflow
- Codex or Claude Code runner
- Optional model override
- Thinking level
- Permission mode
- Per-button reusable script
- Per-button run history and logs

Dangerous agent buttons require approval by default.

## Local agents

Authenticate the local CLIs before running agent buttons:

```sh
codex login
claude auth login
```

Agent permissions map directly to the CLI permission modes:

- Answer only: read-only Codex / plan-mode Claude.
- Workspace write: workspace-write Codex / auto Claude.
- Dangerous run: Codex `--dangerously-bypass-approvals-and-sandbox` or Claude `--dangerously-skip-permissions`.
