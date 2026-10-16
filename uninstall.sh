#!/bin/bash
set -euo pipefail

TARGET_DIR="$HOME/.config/omarchy/plugins/omarchy-crashbar"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
DROPIN_DIR="$SYSTEMD_USER_DIR/omarchy-crash-watch.service.d"
DROPIN_FILE="$DROPIN_DIR/crashbar.conf"
LEGACY_SERVICE_FILE="$SYSTEMD_USER_DIR/omarchy-crash-watch.service"
BACKUP_SERVICE="$SYSTEMD_USER_DIR/omarchy-crash-watch.service.backup"
WRAPPER_BIN="$BIN_DIR/omarchy-crash-watch"

echo "Uninstalling Crashbar and restoring stock Omarchy crash watcher..."

# 1. Disable the plugin in omarchy-shell
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable omarchy-crashbar >/dev/null 2>&1 || true
fi

# 2. Restore systemd service configuration (remove drop-in and legacy unit)
rm -f "$DROPIN_FILE"
rmdir "$DROPIN_DIR" 2>/dev/null || true

if [[ -f "$LEGACY_SERVICE_FILE" ]]; then
  if grep -qE "Managed by Crashbar|on status bar|%h/\.local/bin/omarchy-crash-watch" "$LEGACY_SERVICE_FILE" 2>/dev/null; then
    if [[ -f "$BACKUP_SERVICE" ]] && ! grep -qE "Managed by Crashbar|on status bar|%h/\.local/bin/omarchy-crash-watch" "$BACKUP_SERVICE" 2>/dev/null; then
      echo "Restoring pre-existing omarchy-crash-watch.service from backup..."
      mv -f "$BACKUP_SERVICE" "$LEGACY_SERVICE_FILE"
    else
      echo "Removing Crashbar service override..."
      rm -f "$LEGACY_SERVICE_FILE"
    fi
  fi
fi
rm -f "$BACKUP_SERVICE" 2>/dev/null || true

# 3. Clean up CLI symlinks and restore genuine backups
for name in crashbar omarchy-crashbar; do
  target="$BIN_DIR/$name"
  if [[ -L "$target" ]] && [[ "$(readlink "$target" 2>/dev/null)" == *omarchy-crashbar* ]]; then
    rm -f "$target"
  fi
  if [[ -f "$BIN_DIR/$name.backup" ]]; then
    if grep -qE "Managed by Crashbar|crashbar|omarchy-crashbar" "$BIN_DIR/$name.backup" 2>/dev/null; then
      rm -f "$BIN_DIR/$name.backup"
    else
      echo "Restoring original $target from backup..."
      mv -f "$BIN_DIR/$name.backup" "$target"
    fi
  fi
done

# 4. Remove self-healing wrapper and restore original omarchy-crash-watch binary if genuine
rm -f "$WRAPPER_BIN"
if [[ -f "$WRAPPER_BIN.backup" ]]; then
  if grep -qE "Managed by Crashbar|crashbar|omarchy-crashbar" "$WRAPPER_BIN.backup" 2>/dev/null; then
    rm -f "$WRAPPER_BIN.backup"
  else
    echo "Restoring original $WRAPPER_BIN from backup..."
    mv -f "$WRAPPER_BIN.backup" "$WRAPPER_BIN"
  fi
fi

# 5. Reload systemd daemon and restart crash watch service to activate stock watcher
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user restart omarchy-crash-watch.service >/dev/null 2>&1 || true

# 6. Remove plugin directory if it exists
if [[ -d "$TARGET_DIR" ]]; then
  rm -rf "$TARGET_DIR"
fi

# 7. Rescan shell plugins
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
fi

echo "Crashbar uninstalled successfully."
echo "Stock Omarchy crash watcher (/usr/bin/omarchy-crash-watch) is restored and active."
