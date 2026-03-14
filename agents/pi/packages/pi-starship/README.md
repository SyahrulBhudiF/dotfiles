# @elianiva/pi-starship

Starship-style prompt components for pi. This is a **library package**, not an auto-loading extension. [See why](#why-a-library-package)
This will NOT work outside of Pi's environment, which loads the files using [jiti](https://github.com/unjs/jiti).

## Installation

```bash
# or any other package manager of your choice
bun add @elianiva/pi-starship
```

## Usage

Create your own extension in `~/.pi/extensions/my-extension/`:

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  StarshipEditor,
  createStarshipWidget,
  setupStarshipEvents,
} from "@elianiva/pi-starship";

export default function myExtension(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;

    // Use the starship editor
    ctx.ui.setEditorComponent(
      (tui, theme, kb) => new StarshipEditor(tui, theme, kb, undefined, ctx)
    );

    // Add the info widget (shows cwd, git/jj branch, tokens, etc)
    createStarshipWidget(pi, ctx);
  });

  // Register event handlers for widget updates
  setupStarshipEvents(pi);
}
```

## API

### `StarshipEditor`

Custom editor class with a ❯ prompt prefix and suppressed borders.

```typescript
new StarshipEditor(
  tui: TUI,
  editorTheme: EditorTheme,
  keybindings: KeybindingsManager,
  options?: EditorOptions,
  context?: ExtensionContext
)
```

### `createStarshipWidget(pi, ctx)`

Initializes the info widget showing:
- Current directory
- Git/Jujutsu branch and commit
- Model name
- Thinking level
- Token usage (input/output/cache)
- Cost
- Context window usage

### `setupStarshipEvents(pi)`

Registers event handlers that update the widget:
- `session_switch` - Refresh VCS info
- `agent_start/agent_end` - Update stats
- `turn_end` - Update after each turn
- `model_select` - Update model display
- `user_bash` - Debounced VCS refresh (after shell commands)

### `refreshVcs(cwd, callback?)`

Manually refresh VCS info. Cached for 2 seconds.

### `getVcs()`

Get current VCS cache state:

```typescript
{
  info: {
    type: "git" | "jj",
    branch: string,
    commit: string,
    commitRest?: string,
    dirty: boolean
  } | null,
  time: number,
  cwd: string
}
```

## Why a Library Package?

**Extensibility**: This is intentionally designed as a library you compose, not a ready-to-use extension. You can pick and choose which part you want, you might just want the editor, you might just want the info widget, or both!

**No hard dependencies**: This extension was made alongside my other extension, [@elianiva/pi-ckers](https://github.com/elianiva/pi-ckers), which also overrides the editor, but I want to compose them and not have them have hard dependencies from one another.

**Overrides editor**: Since this wraps/replaces the editor component, it can't be an auto-loading extension because you may have other extension that already overrides the editor. The extension loading in Pi have no particular order, so you can't stack overriding editors. You can still use this extension without overriding the editor, you just won't get the minimal look that removes the borders and adds the ❯ prompt.

See how I use it [in my configuration](https://github.com/elianiva/dotfiles/blob/master/agents/pi/extensions/composed-editor).

## License

[MIT](./LICENSE)
