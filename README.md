# Crashbar for Omarchy

[![Omarchy Plugin](https://img.shields.io/badge/Omarchy-Shell%20Plugin-blue.svg)](https://omarchy.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-0.1.0-green.svg)](https://github.com/Andrewx82/omarchy-crashbar)

**Crashbar** brings quiet, non-intrusive process crash alerting and interactive crash history directly to the Omarchy status bar.

Instead of disruptive desktop popup toasts in the corner of your screen, crash alerts are displayed **only in the left side of the bar**. Each alert stays displayed for 30 seconds, then collapses into an icon that pulls up a list of the last 5 undismissed crashes.

---

## Highlights & Features

- **In-Bar Alerts (Left Side Only)**: Disables generic desktop notification toasts for process crashes. Notifications appear cleanly on the left side of your Omarchy status bar (`󱚡 Process crashed: <process>`).
- **30-Second Notification**: Displays the process crash details prominently in the bar for 30 seconds before collapsing.
- **Interactive Icon & Crash History**: After 30 seconds, the banner collapses into a robot icon (`󱚡`). Clicking the icon pulls up an interactive panel listing the last 5 undismissed crashes.
- **AI Diagnosis Integration**: Each crash row features a 1-click **Diagnose with AI** button that immediately launches your default coding agent (`omarchy-agent-crash`) in a floating terminal to investigate the core dump and stack trace.
- **Dismissal & Auto-Hide**: Dismiss crashes individually or click **Dismiss All** to clear all pending crashes at once. When all crashes are dismissed, the widget hides completely from the bar.
- **Zero Overhead**: Listens to systemd-coredump via a lightweight systemd user watcher and updates state via native Quickshell IPC.

---

## Installation

### Standard Omarchy Plugin Installation (Recommended)

Run the following command to add and enable the plugin:

```bash
omarchy plugin add https://github.com/Andrewx82/omarchy-crashbar.git --enable
```

*Note: The plugin automatically configures the background watcher service upon first load.*

---

## Manual Installation

Alternatively, clone and run the installer directly:

```bash
git clone https://github.com/Andrewx82/omarchy-crashbar.git ~/.config/omarchy/plugins/omarchy-crashbar
~/.config/omarchy/plugins/omarchy-crashbar/install.sh
```

---

## Removal

To completely remove the plugin:

```bash
omarchy plugin remove omarchy-crashbar --yes
```

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
