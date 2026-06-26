# Buttons

Buttons is a native macOS app for creating, running, customizing, and sharing one-click AI workflow buttons.

The app opens directly to a button board. Every button is a saved workflow with a physical button face. The user can design the face, set a category, write an agent instruction for prompt buttons, choose Codex or Claude Code for agent buttons, choose a model override, choose thinking level, choose permission level, and review every run log.

Buttons does not store OpenAI or Anthropic API keys. It runs the locally installed Codex or Claude Code CLI using the login already present on the Mac.

Buttons keeps its runtime state in `~/.buttons`. Each button gets its own editable slug workspace at `~/.buttons/buttons/<slug>/` with:

- `button.md` for the current button instructions and latest run prompt.
- `logs/` for per-run logs.

Every click runs the saved workflow. Buttons v1 keeps the loop direct: click the button, run the task, show live state, save the run log.

Clicking a button face runs it. The play mark inside the face is the run affordance, and the gear opens the button's internals. Buttons set to always confirm, or buttons whose permission mode requires confirmation, open an armed run screen first. Safe buttons zoom into live run state and start immediately. While a run is active, another click does not start a duplicate; the live run exposes Stop and saves a stopped receipt when canceled.

## Build

```sh
swift build
swift test
scripts/package-buttons-app.sh debug
open .build/debug/Buttons.app
```

## Button runtime

- Button workflow
- Codex or Claude Code runner for prompt buttons
- Optional model override
- Thinking level
- Permission mode
- One saved run instruction per prompt button; risky runs let the user review before launch.
- Per-button workspace under `~/.buttons/buttons/<slug>/`
- Per-button run logs
- The saved run instruction is the only user-provided run input for a prompt button click.

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
