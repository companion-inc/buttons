# Buttons Interaction Research

Status: active research, no implementation yet.
Understanding score: 76/100. The button/product model and primary affordance contract are corrected. The remaining gap is visual proof: dimensions, motion, and density need a prototype/screenshot pass before shipping code.

## Product Thesis

Buttons is a tactile prompt board for local AI agents.

It is not Apple Shortcuts with prettier cards, not Keyboard Maestro with fewer steps, and not a generic settings form. Each button is one saved prompt. The app's job is to let a person press a physical-feeling object and have Codex or Claude Code do the work in the background, while keeping editing, live state, history, sharing, and advanced execution settings attached to that same object.

## Corrected World Model

- A button is an object with affordance zones, not one overloaded click target.
- The primary press actuator runs the saved prompt or focuses the active run.
- Opening a button enters that button's internals through a zoom/morph transition.
- Editing the icon, color, title, category, and prompt happens inside the opened button, not in a separate Settings screen.
- Creating a button starts with the prompt. The app infers name, category, icon, and description where it can.
- Runner, model, thinking level, and permission mode are execution details. They exist, but they are not the product's main surface.
- Logs and current run state belong to the button, not a global admin console.
- A second press while running reveals live state and Stop; it does not launch a duplicate run.

## Current Buttons Failure

Observed in the current app:

- The board tile draws a gear and play mark inside one large run button, then overlays an invisible edit hit target over the gear.
- The opened button screen contains duplicate Save controls, a separate Settings card, Run controls, and Runs history all at the same visual level.
- The new-button flow drops the user into a form-like editor with a generic placeholder instead of making the physical button object feel editable.
- The visible model says "settings," "workflow," and "run" before the user has formed a simple mental model: this is a prompt button.

The result is calm-looking but conceptually crowded.

## Reference Notes

### Apple HIG / Platform Patterns

Source:

- Apple's button guidance describes buttons as simple, familiar ways to do tasks.
- Apple's context menu guidance says context menus give access to item-related functionality without cluttering the interface.
- Apple's layout guidance recommends progressive disclosure for hidden content.

Adopt:

- The primary action must remain visible and familiar.
- Secondary object-specific actions can live in context menus.
- Advanced configuration belongs behind progressive disclosure, close to the thing it controls.

Reject:

- Hiding Run in a context menu.
- Placing every advanced execution control at the same visual level as the prompt.
- Making a decorative mark clickable through an invisible overlay.

### HeyClicky

Local evidence:

- `/Applications/HeyClicky.app` is installed.
- Its app bundle includes a Codex runtime, a `ClickyComputerUseRuntime` helper, bundled skills, and a shipped agent behavior contract.
- Its shipped agent instructions separate the visible HeyClicky shell from child-agent capability. HeyClicky handles microphone, screenshots, onboarding, floating HUD, and summaries; the child agent handles reasoning and tools.
- It routes structured/local tools first and treats computer use as a capability behind the product surface.

Adopt:

- Hide runtime complexity behind a compact user-facing object.
- Keep computer-use and agent/tool capability as infrastructure, not primary UI.
- Make missing capability/auth state clear only when needed.

Reject:

- Exposing "Agents" or "Computer Use" as a top-level board concept.

### Stream Deck

Source:

- Elgato defines a profile as a layout of actions/functions, configurable with hotkeys, multi-action keys, text actions, plugin actions, folders, and page navigation.
- Stream Deck keys are visual action instances with title and image, activated by physical interaction.
- Action Sharing exports/imports keys, dials, folders, multi-actions, triggers, and wheels.

Adopt:

- The board is a set of pressable objects.
- The visual face communicates identity: color/icon/title/status.
- Sharing is object-level, not app-level.
- Organization can use folders/categories/pages without crowding each key.
- Failure/success feedback can live directly on the key/button face.

Reject:

- Drag-and-drop action building for v1. Buttons are prompts, not action blocks.

### Apple Shortcuts

Source:

- A shortcut is a quick way to get one or more tasks done with apps.
- A custom shortcut is created in a shortcut editor, then run for testing.
- In the main Shortcuts window, pointer-over reveals a run control; a shortcut can also be double-clicked to open the editor and run from there.
- Shortcuts asks for input or private-data permission only when an action needs it.

Adopt:

- Separate collection, editor, run, stop, and permission moments.
- Ask for run-time input only when the prompt explicitly needs it.
- Use object-level run feedback and a visible Stop affordance.

Reject:

- Exposing a step/action editor as the v1 default. The prompt is the action.

### Keyboard Maestro

Source:

- Keyboard Maestro separates Editor, Engine, Macro Groups, Macros, Triggers, and Actions.
- The editor is used only to make changes; the engine keeps running in the background.
- Macros can be edited by selecting or double-clicking them, and changes autosave.

Adopt:

- Separate editing from background execution conceptually.
- Keep the runner/engine always available behind the scenes.
- Avoid a prominent Save button as the dominant interaction; edits should feel retained without ceremony.

Reject:

- Making the user understand groups, triggers, actions, and engine state before using a button.

### Raycast Quicklinks

Local evidence:

- Raycast is installed as `/Applications/Raycast.app`.
- Its bundle is an `LSUIElement` utility app and declares AppleEvents access to control the Mac and run Shortcuts.
- It ships as a utility/launcher surface, not a heavy document editor.

Source:

- Quicklinks save repeated URLs, file paths, folders, deeplinks, or search URLs by name.
- Quicklinks appear directly in Root Search alongside commands/apps.
- They support dynamic placeholders and can be searched, edited, duplicated, pinned, hidden, and shared with a team.

Adopt:

- Fast repeated tasks should be available from the main surface without opening a heavy editor.
- Management actions should be discoverable through an object action menu or opened-object surface.
- Categories/tags organize the library, but should not dominate the button face.
- Placeholders belong inside the prompt model, not as separate hardcoded fields.

Reject:

- Text-command-first launcher UI. Buttons needs physical/tactile objects.

## Local App Inventory

Relevant apps installed on this Mac:

- HeyClicky: closest local AI/computer-use runtime reference.
- Raycast: repeated-action launcher and quicklink management reference.
- Shortcuts: Apple-native shortcut collection/editor/run reference.
- Automator: older Mac automation reference; likely a cautionary example for complexity.
- Figma and Paper: object/canvas editing references if a visual design pass is needed.
- Codex and Claude: provider surfaces; runtime dependencies should stay behind Buttons.

Not found locally:

- Stream Deck app.
- Keyboard Maestro.
- BetterTouchTool.
- Alfred.

Stream Deck and Keyboard Maestro are still useful as documented references because they define the physical-action board and Mac automation/editor split respectively.

## Affordance Contract Draft

Board button face:

- The tile is a physical object with a base and a raised press actuator. The entire card is not one `Button`.
- Main raised actuator: press to run when idle; press to focus live state when running.
- Small visible enter/edit affordance on the base: opens the button's internals. It is visible and named by hover/accessibility. It is not an invisible hit area.
- Status mark: idle, running, failed, succeeded, needs input, needs auth. Status is on the button face.
- Category chip: lightweight grouping/filter signal. It is not a settings entry point.
- Context menu: duplicate, share, delete, reveal logs, export. Destructive actions confirm.

Opened button:

- Entered through a shared-element zoom/morph from the board button.
- Header is the editable button face: click icon/color/title/category directly to edit them.
- Primary content is the prompt.
- Run state and recent logs sit beside/below the prompt according to window size.
- Execution details are collapsed by default: runner, model, thinking, permission.
- Save should not be the hero. Autosave or a quiet Done/Back pattern is better for this object.

Create flow:

- New button begins as a blank tactile object.
- The first focused field is the prompt.
- Name/category/icon/color are inferred after the prompt is written, then editable on the face.
- Advanced execution settings are available but not required.

Run flow:

- Idle press starts run when permission policy allows it.
- Risky run opens an armed state, not a generic modal.
- Running press opens live state with Stop.
- Failed/succeeded state remains attached to the button.

## Open Questions Before Implementation

- Which icon best communicates "enter button" without reading as generic Settings.
- Exact dimensions of the raised actuator versus the base after visual testing.
- Whether the opened button should be full-window zoom or centered room with board fading behind.
- How much live run output belongs on the board face before opening the button.
- Which local agent availability/auth errors belong on first run vs global setup.

## Interaction Decisions

### Board

- The board is the home screen. It should not say "Buttons" in huge redundant text once the app/window already identifies itself.
- Each button tile is a tactile object with two obvious zones:
  - Press actuator: the satisfying physical control. Pressing it runs the saved prompt.
  - Base/enter control: the quieter affordance for opening internals.
- Hover can reveal stronger edit/share/history controls, but Run must never depend on hover.
- The face shows only: icon, title, category/color, status, and possibly a compact last-run state.
- No provider badges on the button by default. Codex/Claude Code are execution details.
- No "script," "optimized," or "self-healing" language in v1.

### Create

- New creates a draft button object on the board, then zooms into it.
- The draft starts with a blank prompt field and an editable physical face preview.
- The app autosaves the draft. The primary exit control is Done/Back, not Save.
- Title, category, icon, color, and short caption are inferred after the first meaningful prompt, then editable directly on the face.
- Empty prompt means the actuator is disabled and visually says the button is not armed yet.

### Open / Edit

- Opening uses a matched-geometry zoom/morph from the board object into a button room.
- The opened button is not called Settings.
- The header is the button face itself. Clicking the icon edits the icon. Clicking the color/skin edits color. Clicking title/category edits those values.
- Prompt is the primary editable content.
- Execution details live in a collapsed section called Execution, not Settings:
  - Runner
  - Permission
  - Thinking
  - Model override
- Share, Duplicate, Export, and Delete live in an overflow/context area, not as a horizontal row of loud buttons.

### Run

- Press actuator on idle button starts the prompt.
- If the permission mode is risky, the button enters an in-place armed state instead of opening a dialog. The second explicit press starts the run.
- While running, the actuator changes to live-state/Stop behavior:
  - Press reveals the live run room.
  - Stop is visible inside live state.
  - A duplicate run cannot start until the active run resolves.
- Completion/failure stays attached to the button face, like Stream Deck's per-key OK/error feedback.

### Logs

- The board shows only a compact status.
- The opened button shows current state and recent run history.
- Full logs are available from the button room or context menu.
