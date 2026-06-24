# Buttons

Buttons is a native macOS app for creating, running, customizing, and sharing one-click AI workflow buttons.

The app opens directly to a button board. Every button is a background-agent workflow. The user can design the button face, set a category, write the saved run prompt, choose Codex or Claude Code, choose a model override, choose thinking level, choose permission level, and review every run log.

Buttons does not store OpenAI or Anthropic API keys. It runs the locally installed Codex or Claude Code CLI using the login already present on the Mac.

Buttons keeps its runtime state in `~/.buttons`. Each button gets its own editable slug workspace at `~/.buttons/buttons/<slug>/` with:

- `scripts/run.zsh` for the self-healing reusable workflow.
- `button.md` for the current button instructions and latest run prompt.
- `skills/` for button-specific reusable notes and helper instructions.
- `logs/` for per-run logs.
- `agent/` for agent scratch files.

On first run, a button asks the selected local agent to extract the repetitive workflow into its own reusable script. Later clicks run that script first so the button gets cheaper. If the script breaks, Buttons sends the failure and current script back to the agent, repairs it in place, and retries once.

Clicking a button face runs it. The play mark inside the face is the run affordance, and the gear opens the button's internals. Buttons with no reusable script yet, buttons set to always confirm, and risky buttons open an armed run screen first. Cached safe buttons zoom into live run state and start immediately.

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
- Per-button reusable script, skills folder, and logs
- `BUTTON_RUN_PROMPT` is the only user-provided run input exposed to generated scripts.

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
