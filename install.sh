#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/omarchy/plugins/omarchy-crashbar"

if [[ "$REPO_DIR" != "$TARGET_DIR" ]]; then
  mkdir -p "$HOME/.config/omarchy/plugins"
  rm -rf "$TARGET_DIR"
  cp -r "$REPO_DIR" "$TARGET_DIR"
fi

chmod +x "$TARGET_DIR/setup" "$TARGET_DIR/crashbar" "$TARGET_DIR/omarchy-crash-watch"
"$TARGET_DIR/setup"

# Rescan and enable plugin if omarchy-shell is running
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
fi

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin enable omarchy-crashbar --section left >/dev/null 2>&1 || true
fi

echo "Crashbar installed and enabled successfully."
