# Canvas for KDE Plasma

Right-click menu and shortcuts that send files and text from a KDE desktop to
Canvas. Tested against Plasma 6 (KDE Frameworks 6); Plasma 5.27 works the same
way, the installer picks `kbuildsycoca5` when that is what is installed.

Everything goes through the [canvas CLI](https://github.com/canvas-ui/canvas-cli),
so the server, account and API token are the ones `canvas remote list` shows.
This folder holds no credentials of its own.

## Install

```bash
canvas remote add me@canvas https://canvas.example.org --token canvas-…   # once
./install.sh
```

Then restart Dolphin. `./install.sh --uninstall` removes it again.

The installer writes `~/.config/canvas/kde.conf`:

| Key | Default | Meaning |
|---|---|---|
| `CANVAS_BIN` | path found at install time | the canvas CLI; absolute, because Dolphin and the shortcut daemon may not have `~/.local/bin` on PATH |
| `CANVAS_SCOPE` | `ws universe` | `ws <workspace>` or `ctx <context>` |
| `CANVAS_PATH` | `/inbox` | tree path inside a workspace scope (`/inbox`, or `tree:/path` for another tree); ignored for a context |

## What it adds

Dolphin: right-click files or folders, then **Send to Canvas**. The bytes are
uploaded to the workspace (`canvas … file add`) and a notification reports the
result. Folders are uploaded recursively.

Text: `canvas-send --selection` saves the highlighted text (the PRIMARY
selection, no Ctrl+C needed) as a note titled with its first line. A selection
that is a single URL becomes a tab instead. `canvas-send --ask --clipboard`
does the same for the clipboard and asks for a title first.

Scripts: `canvas-send FILE…` and `… | canvas-send --text -`.

## Shortcuts for selected text

There is no system-wide hook for adding entries to every application's text
right-click menu on Linux; each toolkit and app draws its own. The closest
equivalents:

1. Global shortcut: System Settings > Keyboard > Shortcuts > Add New >
   Application, pick *Canvas: Save Selection as Note*, assign e.g.
   `Meta+Shift+N`. Select text anywhere, press the shortcut.

2. Clipboard action popup: This gives a menu at the cursor, which is the
   nearest thing to a right-click entry. Right-click the clipboard icon in the
   panel > Configure Clipboard > Actions Menu > Add Action:
   - Regular expression: `.+`
   - Add command: `canvas-send --ask --clipboard`, description *Save as Canvas note*
   - Leave "Automatic" off so it does not pop up on every copy.

   Copy text, press `Ctrl+Alt+R` (*Manually invoke action on current
   clipboard*), pick *Save as Canvas note*. Do not use Klipper's `%s`
   placeholder: it pastes the copied text into a shell command line.

3. Browser: For web pages, the Canvas browser extension is where a real
   "save selection" right-click entry belongs.

## Requirements

`notify-send` (libnotify-bin) for notifications, `kdialog` for `--ask`, and
`wl-clipboard` on Wayland or `xclip` on X11 for reading the selection. The
installer lists whichever are missing.

## Why not the Share menu

Dolphin's *Share* submenu is the KDE Purpose framework. Installed PWAs do not
register there on Linux (a PWA `share_target` only reaches Android and
ChromeOS share sheets), and a Purpose plugin has to be built as a C++/QML
plugin. The service menu covers the same need without a build step.
