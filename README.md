# Buttons

Buttons is a native macOS app for creating, running, customizing, and sharing one-click task buttons.

The app opens directly to a button board. Each button carries a face, task, inputs, permissions, approval policy, and run receipts. Shared buttons export as JSON recipes; the recipient connects the recipe to their own machine and accounts.

## Build

```sh
swift build
swift test
scripts/package-buttons-app.sh debug
open .build/debug/Buttons.app
```

## Button actions

- Open URL
- Copy text
- Run macOS Shortcut
- Run shell command
- Show message

Shell and Shortcut buttons require approval by default.
