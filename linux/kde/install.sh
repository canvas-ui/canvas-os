#!/usr/bin/env bash
# Install the Canvas KDE integration for the current user.
#
#   ./install.sh               install or update
#   ./install.sh --uninstall   remove everything except the config file
#
# Needs the canvas CLI, logged in to a remote (`canvas remote add` / `login`).
set -euo pipefail
cd "$(dirname "$0")"

DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN="$HOME/.local/bin"
MENU="$DATA/kio/servicemenus"
APPS="$DATA/applications"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/canvas/kde.conf"
SEND="$BIN/canvas-send"
LAUNCHERS=(canvas-save-selection.desktop canvas-save-clipboard.desktop)

rebuild_menus() {
  for b in kbuildsycoca6 kbuildsycoca5; do
    command -v "$b" >/dev/null 2>&1 && { "$b" >/dev/null 2>&1 || true; return; }
  done
}

if [[ "${1:-}" == --uninstall ]]; then
  rm -f "$SEND" "$MENU/canvas-send.desktop"
  for l in "${LAUNCHERS[@]}"; do rm -f "$APPS/$l"; done
  rebuild_menus
  echo "Removed. $CONF was kept."
  exit 0
fi

canvas_bin=$(command -v canvas || true)
if [[ -z "$canvas_bin" ]]; then
  echo "The canvas CLI is not on PATH. Install it first:" >&2
  echo "  https://github.com/canvas-ui/canvas-cli#install" >&2
  exit 1
fi

render() { # template destination mode
  sed "s|@CANVAS_SEND@|$SEND|g" "$1" > "$2"
  chmod "$3" "$2"
}

mkdir -p "$BIN" "$MENU" "$APPS" "$(dirname "$CONF")"
install -m 755 canvas-send "$SEND"
# Dolphin only runs service menus that are executable (KF 5.85 and later).
render canvas-send.desktop "$MENU/canvas-send.desktop" 755
for l in "${LAUNCHERS[@]}"; do render "$l" "$APPS/$l" 644; done
rebuild_menus

if [[ ! -f "$CONF" ]]; then
  cat > "$CONF" <<CONF
# Canvas KDE integration (canvas-send). Sourced as bash.
# The server, account and token come from the canvas CLI's default remote.

# Absolute path: Dolphin and KGlobalAccel may run without ~/.local/bin on PATH.
CANVAS_BIN="$canvas_bin"

# Where items land. Either a workspace ("ws <name>") plus a tree path, or a
# context ("ctx <name>"), which already is a path (CANVAS_PATH is ignored).
CANVAS_SCOPE="ws universe"
CANVAS_PATH="/inbox"
CONF
  echo "Wrote $CONF"
fi

echo "Installed:"
echo "  $SEND"
echo "  $MENU/canvas-send.desktop   (Dolphin: right-click > Send to Canvas)"
for l in "${LAUNCHERS[@]}"; do echo "  $APPS/$l"; done
echo

# shellcheck source=/dev/null
. "$CONF"
read -r -a scope <<<"$CANVAS_SCOPE"
if "$CANVAS_BIN" "${scope[@]}" >/dev/null 2>&1; then
  echo "canvas CLI can reach '$CANVAS_SCOPE'."
else
  echo "Warning: '$CANVAS_BIN $CANVAS_SCOPE' failed. Check 'canvas remote list'"
  echo "and that the workspace exists and is started, or edit $CONF."
fi

missing=()
command -v notify-send >/dev/null 2>&1 || missing+=(libnotify-bin)
command -v kdialog >/dev/null 2>&1 || missing+=(kdialog)
if [[ "${XDG_SESSION_TYPE:-}" == wayland ]]; then
  command -v wl-paste >/dev/null 2>&1 || missing+=(wl-clipboard)
else
  command -v xclip >/dev/null 2>&1 || missing+=(xclip)
fi
((${#missing[@]})) && echo "Optional packages missing: sudo apt install ${missing[*]}"

echo
echo "Restart Dolphin to see the menu entry. Shortcut setup: see README.md."
