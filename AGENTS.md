# AGENTS.md — Buttons

Native macOS app for one-click AI workflow buttons. See `README.md` for the runtime layout.

## Product model — a button IS a prompt

- Every button is one user-authored prompt that a local agent (Codex or Claude Code) runs. There is no other kind of button. Do not add hardcoded action types ("Open URL", "Copy text", "Star repo") or special-cased built-in actions — those are prompts the user writes, not product features. When you find old action-typed buttons or decoders, migrate them into prompts and delete the action machinery; keep no parallel hardcoded-action path as the user-facing product.
- Clicking a button runs the selected local agent every time. Saved files or executables may exist only as internal automation/memory that the agent can improve; do not present the product as a manual script generator or make the user manage scripts.
- Never hardcode a repo URL, workspace path, account name, or default input value into a button, its run UI, or its sample/default board. The current dev repo (`companion-inc/buttons`) is your session context, not a product default — baking it in as a placeholder or default has been corrected more than once. Anything that varies per run lives in the user's prompt text, not in a separate field the app injects.
- Keep run configuration to what `README.md` already names: runner (Codex/Claude Code), model override, thinking level, permission mode, button face, category. Do not invent new required input fields beyond the prompt. The prompt is the content; everything else is a setting on how to run it.

When the user says "nothing hardcoded" or "every button is a prompt," it is the product spec, not a style note — reread this file before adding any non-prompt structure.
