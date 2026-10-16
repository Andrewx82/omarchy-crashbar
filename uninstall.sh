#!/bin/bash
set -euo pipefail

TARGET_DIR="$HOME/.config/omarchy/plugins/omarchy-crashbar"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
DROPIN_DIR="$SYSTEMD_USER_DIR/omarchy-crash-watch.service.d"
DROPIN_FILE="$DROPIN_DIR/crashbar.conf"
DROPIN_BACKUP="$DROPIN_FILE.omarchy-crashbar-backup"
LEGACY_SERVICE_FILE="$SYSTEMD_USER_DIR/omarchy-crash-watch.service"
LEGACY_SERVICE_BACKUP="$LEGACY_SERVICE_FILE.omarchy-crashbar-backup"
WRAPPER_BIN="$BIN_DIR/omarchy-crash-watch"
WRAPPER_BACKUP="$WRAPPER_BIN.omarchy-crashbar-backup"

readonly CRASHBAR_SIGNATURE="OMARCHY_CRASHBAR_MANAGED_FILE_v1"

DEACTIVATE_ONLY=0
if [[ "${1:-}" == "--deactivate" || "${1:-}" == "--keep-plugin" ]]; then
  DEACTIVATE_ONLY=1
fi

echo "Uninstalling Crashbar and restoring stock Omarchy crash watcher..."

# 1. Disable the plugin in omarchy-shell (unless deactivating from UI)
if (( ! DEACTIVATE_ONLY )) && command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable omarchy-crashbar >/dev/null 2>&1 || true
fi

# 2. Restore systemd service configuration
if [[ -e "$DROPIN_FILE" || -L "$DROPIN_FILE" ]]; then
  if grep -qF "$CRASHBAR_SIGNATURE" "$DROPIN_FILE" 2>/dev/null; then
    rm -f "$DROPIN_FILE"
  fi
fi

if [[ -e "$DROPIN_BACKUP" || -L "$DROPIN_BACKUP" ]]; then
  echo "Restoring original $DROPIN_FILE from backup..."
  rm -f "$DROPIN_FILE"
  mv -f "$DROPIN_BACKUP" "$DROPIN_FILE"
fi
rmdir "$DROPIN_DIR" 2>/dev/null || true

if [[ -e "$LEGACY_SERVICE_BACKUP" || -L "$LEGACY_SERVICE_BACKUP" ]]; then
  echo "Restoring original $LEGACY_SERVICE_FILE from backup..."
  rm -f "$LEGACY_SERVICE_FILE"
  mv -f "$LEGACY_SERVICE_BACKUP" "$LEGACY_SERVICE_FILE"
elif [[ -e "$LEGACY_SERVICE_FILE" || -L "$LEGACY_SERVICE_FILE" ]] && grep -qF "$CRASHBAR_SIGNATURE" "$LEGACY_SERVICE_FILE" 2>/dev/null; then
  echo "Removing Crashbar legacy service file..."
  rm -f "$LEGACY_SERVICE_FILE"
fi

# 3. Clean up CLI symlinks and restore user backups if present
for name in crashbar omarchy-crashbar; do
  target="$BIN_DIR/$name"
  target_backup="$target.omarchy-crashbar-backup"
  if [[ -L "$target" ]] && [[ "$(readlink "$target" 2>/dev/null)" == *omarchy-crashbar* ]]; then
    rm -f "$target"
  fi
  if [[ -e "$target_backup" || -L "$target_backup" ]]; then
    echo "Restoring original $target from backup..."
    rm -f "$target"
    mv -f "$target_backup" "$target"
  fi
done

# 4. Remove self-healing wrapper and restore original omarchy-crash-watch binary if backed up
if [[ -e "$WRAPPER_BIN" || -L "$WRAPPER_BIN" ]]; then
  if grep -qF "$CRASHBAR_SIGNATURE" "$WRAPPER_BIN" 2>/dev/null; then
    rm -f "$WRAPPER_BIN"
  fi
fi
if [[ -e "$WRAPPER_BACKUP" || -L "$WRAPPER_BACKUP" ]]; then
  echo "Restoring original $WRAPPER_BIN from backup..."
  rm -f "$WRAPPER_BIN"
  mv -f "$WRAPPER_BACKUP" "$WRAPPER_BIN"
fi

# 5. Reload systemd daemon and restart crash watch service to activate stock watcher
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user restart omarchy-crash-watch.service >/dev/null 2>&1 || true

# 6. Remove plugin directory if called externally (and not deactivating from UI)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if (( ! DEACTIVATE_ONLY )) && [[ "$SCRIPT_DIR" != "$TARGET_DIR" && -d "$TARGET_DIR" ]]; then
  rm -rf "$TARGET_DIR"
fi

# 7. Rescan shell plugins
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
fi

echo "Crashbar uninstalled successfully."
echo "Stock Omarchy crash watcher (/usr/bin/omarchy-crash-watch) is restored and active."
