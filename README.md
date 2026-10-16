# Crashbar for Omarchy

[![Omarchy Plugin](https://img.shields.io/badge/Omarchy-Shell%20Plugin-blue.svg)](https://omarchy.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-0.1.2-green.svg)](https://github.com/Andrewx82/omarchy-crashbar)

**Crashbar** brings quiet, non-intrusive process crash alerting and interactive crash history directly to the Omarchy status bar.

Instead of disruptive desktop popup toasts in the corner of your screen, crash alerts are displayed **only in the left side of the bar**. Each alert stays displayed for 30 seconds, then collapses into an icon that pulls up a list of the last 5 undismissed crashes.

---

## Highlights & Features

- **In-Bar Alerts (Left Side Only)**: Disables generic desktop notification toasts for process crashes. Notifications appear cleanly on the left side of your Omarchy status bar (`󱚡 Process crashed: <process>`).
- **30-Second Notification**: Displays the process crash details prominently in the bar for 30 seconds before collapsing.
- **Interactive Icon & Crash History**: After 30 seconds, the banner collapses into a robot icon (`󱚡`). Clicking the icon pulls up an interactive panel listing the last 5 undismissed crashes.
- **AI Diagnosis Integration**: Each crash row features a 1-click **Diagnose with AI** button that immediately launches your default coding agent (`omarchy-agent-crash`) in a floating terminal to investigate the core dump and stack trace.
- **Dismissal & Auto-Hide**: Dismiss crashes individually or click **Dismiss All** to clear all pending crashes at once. When all crashes are dismissed, the widget hides completely from the bar.
- **Non-Destructive & Self-Healing**: Setup preserves any existing user service configurations (`.backup`). If uninstalled, stock `/usr/bin/omarchy-crash-watch` is automatically and cleanly restored with zero dangling symlinks or broken service overrides.
- **Zero Overhead**: Listens to systemd-coredump via a lightweight watcher and updates state via native Quickshell IPC.

---

## Installation

### Standard Omarchy Plugin Installation (Recommended)

Run the following command to add and enable the plugin:

```bash
omarchy plugin add https://github.com/Andrewx82/omarchy-crashbar.git --enable
```

Crashbar automatically initializes its background watcher service on first load. No secondary setup commands are required. Any existing custom unit files or CLI entries are safely preserved with `.backup` copies.

---

### Manual Installation

Alternatively, clone and run the installer directly:

```bash
git clone https://github.com/Andrewx82/omarchy-crashbar.git ~/.config/omarchy/plugins/omarchy-crashbar
~/.config/omarchy/plugins/omarchy-crashbar/install.sh
```

---

## Removal & Restoration

Crashbar is designed to leave zero lingering state when removed.

### Standard Plugin Removal

```bash
omarchy plugin remove omarchy-crashbar --yes
```

When the plugin is removed via `omarchy plugin remove`, the self-healing wrapper automatically detects that Crashbar has been removed:
- Restores any pre-existing user `omarchy-crash-watch.service` (or removes the Crashbar override).
- Restores or unlinks all entries in `~/.local/bin/`.
- Reloads the systemd user daemon and activates the stock Omarchy crash watcher (`/usr/bin/omarchy-crash-watch`).

### Manual Uninstallation Script

Alternatively, you can run the included uninstaller:

```bash
~/.config/omarchy/plugins/omarchy-crashbar/uninstall.sh
```

This cleans up services, restores stock Omarchy crash watching, and uninstalls the plugin in a single step.

---

## CLI Reference

The plugin includes the `crashbar` CLI utility (also aliased as `omarchy-crashbar`) for inspecting and managing crashes from the terminal or scripts:

| Command | Description |
|---|---|
| `crashbar list` | Output JSON of the last 5 undismissed crashes |
| `crashbar dismiss <id>` | Dismiss a crash by ID or PID |
| `crashbar dismiss-all` | Dismiss all recorded crashes |
| `crashbar test-crash` | Simulate a test crash to verify the in-bar alert |

---

## Requirements

- **Omarchy** with Hyprland and Omarchy Shell (Quickshell)
- **systemd-coredump**
- **Python 3.10+** (standard library only)

---

## License

This project is licensed under the [MIT License](LICENSE).
