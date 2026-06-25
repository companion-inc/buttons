# Buttons

Buttons is a native macOS app for creating, running, customizing, and sharing one-click AI workflow buttons.

The app opens directly to a button board. Every button is a background-agent workflow. The user can design the button face, set a category, write the saved run prompt, choose Codex or Claude Code, choose a model override, choose thinking level, choose permission level, and review every run log.

Buttons does not store OpenAI or Anthropic API keys. It runs the locally installed Codex or Claude Code CLI using the login already present on the Mac.

Buttons keeps its runtime state in `~/.buttons`. Each button gets its own editable slug workspace at `~/.buttons/buttons/<slug>/` with:

- `automation/` for internal acceleration artifacts the agent may maintain.
- `button.md` for the current button instructions and latest run prompt.
- `skills/` for button-specific reusable notes and helper instructions.
- `logs/` for per-run logs.
- `agent/` for agent scratch files.

Every click runs the selected local agent. The agent completes the task, reads the button workspace, and updates durable memory or automation so later clicks get cheaper. Buttons never turns a button into manual setup; the optimization layer belongs to the agent.

Clicking a button face runs it. The play mark inside the face is the run affordance, and the gear opens the button's internals. Buttons with no optimization memory yet, buttons set to always confirm, and risky buttons open an armed run screen first. Optimized safe buttons zoom into live run state and start immediately. While a run is active, another click does not start a duplicate; the live run exposes Stop and saves a stopped receipt when canceled.

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
- One saved run prompt per button; first or risky runs let the user review or edit that prompt before launch.
- Per-button workspace under `~/.buttons/buttons/<slug>/`
- Per-button optimization memory, skills folder, and logs
- The saved run prompt is the only user-provided run input for a button click.

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
