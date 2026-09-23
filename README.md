# macwindow

A small CLI that snaps windows to the left half, the right half, or full screen
using the macOS built-in accessibility API.
One LaunchAgent, no config file, no menu bar icon.

| Shortcut | Action |
| --- | --- |
| `⌃⌥←` | Left half |
| `⌃⌥→` | Right half |
| `⌃⌥↑` | Maximize |

## Walking across displays

Press the same shortcut again and the window moves to the opposite half of the next display.
With two displays (B to the right of A), repeating `⌃⌥→` walks one half-slot to the right each time.

```
A right → B left → B right → A left → A right → …     (⌃⌥← walks the other way)
One display: A right → A right → A right → …
```

A press counts as a repeat only when it's the same action, on the same window,
and the window is still where it was last put.
Moving a window by hand starts over.

Repeating `⌃⌥↑` cycles through the displays.

## Usage

```
swift build -c release
install -D -t ~/.local/bin .build/release/macwindow

macwindow install     # register a login agent that listens for the shortcuts
macwindow status      # show permission and agent state
macwindow uninstall   # remove the agent

macwindow left        # move a window directly, without a shortcut
macwindow right
macwindow maximize
```

A one-off run like `macwindow left` doesn't remember where it last put a window,
since the process exits each time. It always behaves as a first press,
so walking across displays only happens inside `macwindow watch` (the resident agent).

## Accessibility permission

Moving another app's windows **requires accessibility permission**.
Permission is tied to the process that's responsible for the run. When you type `macwindow left`
in a terminal, the terminal is responsible, and its permission is borrowed. A process started by the
LaunchAgent is responsible for itself, so `~/.local/bin/macwindow` has to be granted permission
directly — otherwise the hotkeys fire but no window moves.

The resident process asks for permission on startup. If no dialog appears (you declined before),
add the binary under System Settings → Privacy & Security → Accessibility and restart it.

```
launchctl kickstart -k gui/$(id -u)/com.github.tubo28.macwindow
```

`macwindow status` reports the terminal's permission and the agent's permission separately.
Warnings from the resident process go to `~/Library/Logs/com.github.tubo28.macwindow.log`.

TCC identifies a binary by path and code signature. Every `swift build` produces a new ad-hoc
signature, so the binary has to be granted permission again after each rebuild.
