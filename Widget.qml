import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "omarchy-crashbar"
  ipcTarget: "omarchy-crashbar"
  manageIpc: false

  property bool notificationActive: false
  property string notificationComm: ""
  property int notificationRemainingSec: 30
  property int undismissedCount: 0
  property var crashesList: []
  property bool isConfigured: true

  readonly property string crashManagerBin: decodeURIComponent(Qt.resolvedUrl("crashbar").toString().replace(/^file:\/\//, ""))
  readonly property string setupBin: decodeURIComponent(Qt.resolvedUrl("setup").toString().replace(/^file:\/\//, ""))
  readonly property string uninstallBin: decodeURIComponent(Qt.resolvedUrl("uninstall.sh").toString().replace(/^file:\/\//, ""))

  Process {
    id: setupActionProc
    onExited: function(exitCode) {
      root.refresh()
    }
  }

  Process {
    id: deactivateActionProc
    onExited: function(exitCode) {
      root.refresh()
    }
  }

  function refresh() {
    if (!statusProc.running) {
      statusProc.running = true
    }
  }

  function broadcast(method) {
    var items = bar && typeof bar.moduleWidgets === "function"
      ? bar.moduleWidgets(moduleName) : [root]
    for (var i = 0; i < items.length; i++) {
      if (items[i] && typeof items[i][method] === "function") items[i][method]()
    }
  }

  function triggerCrashNotification(comm) {
    notificationComm = comm || "Process"
    notificationActive = true
    notificationRemainingSec = 30
    notificationTimer.restart()
    refresh()
  }

  function cancelNotification() {
    notificationActive = false
    notificationTimer.stop()
    if (root.undismissedCount === 0 && root.opened) {
      root.close()
    }
  }

  function dismiss(id) {
    cancelNotification()
    dismissProc.command = [root.crashManagerBin, "dismiss", id]
    dismissProc.running = true
  }

  function dismissAll() {
    cancelNotification()
    dismissProc.command = [root.crashManagerBin, "dismiss-all"]
    dismissProc.running = true
    root.close()
  }

  function shellQuote(str) {
    return "'" + String(str || "").replace(/'/g, "'\\''") + "'"
  }

  function diagnose(pid, comm, exe, signal) {
    var argv = [
      "omarchy-agent-crash",
      String(pid || ""),
      String(comm || "unknown"),
      String(exe || "unknown"),
      String(signal || "unknown")
    ]
    var cmd = argv.map(root.shellQuote).join(" ")
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run(cmd)
    } else if (typeof Quickshell.execDetached === "function") {
      Quickshell.execDetached(["bash", "-lc", 'exec "$@"', "bash"].concat(argv))
    } else {
      diagnoseProc.command = ["/bin/sh", "-c", cmd]
      diagnoseProc.running = true
    }
  }

  Component.onCompleted: {
    root.refresh()
  }

  IpcHandler {
    target: "omarchy-crashbar"

    function notifyCrash(comm: string, pid: string, exe: string, signal: string): void {
      var items = root.bar && typeof root.bar.moduleWidgets === "function"
        ? root.bar.moduleWidgets(root.moduleName) : [root]
      for (var i = 0; i < items.length; i++) {
        if (items[i] && typeof items[i].triggerCrashNotification === "function") {
          items[i].triggerCrashNotification(comm)
        }
      }
    }

    function refresh(): void {
      root.broadcast("refresh")
    }

    function open(): void {
      root.open()
    }

    function close(): void {
      root.close()
    }

    function toggle(): void {
      root.toggle()
    }
  }

  Process {
    id: statusProc
    command: [root.crashManagerBin, "list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.undismissedCount = data.count || 0
          root.crashesList = data.crashes || []
          if (data.configured !== undefined) {
            root.isConfigured = data.configured
          }
          if (root.undismissedCount === 0) {
            root.cancelNotification()
          }
          if (root.isConfigured && root.undismissedCount === 0 && !root.notificationActive && root.opened) {
            root.close()
          }
        } catch (e) {
          console.log("Error parsing crash status:", e)
        }
      }
    }
  }

  Process {
    id: dismissProc
    onExited: function(exitCode) {
      root.refresh()
    }
  }

  Process {
    id: diagnoseProc
  }

  // 30-second notification timer
  Timer {
    id: notificationTimer
    interval: 30000
    repeat: false
    running: false
    onTriggered: {
      root.cancelNotification()
    }
  }

  // Periodic refresh to keep relative times updated
  Timer {
    interval: 30000
    repeat: true
    running: root.visible || root.opened
    onTriggered: root.refresh()
  }

  visible: !root.isConfigured || root.notificationActive || root.undismissedCount > 0
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    fontSize: Style.bar.iconFont
    fixedWidth: root.notificationActive ? -1 : (bar && bar.vertical ? -1 : Style.bar.iconSlot)
    active: root.notificationActive || root.opened || !root.isConfigured
    activeColor: !root.isConfigured ? (bar ? bar.accent : Color.accent) : (bar ? bar.urgent : Color.urgent)
    useActiveColor: true

    text: {
      if (root.notificationActive) {
        return "󱚡  Process crashed: " + root.notificationComm
      }
      return "󱚡"
    }

    tooltipText: {
      if (!root.isConfigured) {
        return "Crashbar (Setup Required)\nClick to complete setup"
      }
      if (root.notificationActive) {
        return "Process crashed: " + root.notificationComm + "\nClick to view list/diagnose"
      }
      return root.undismissedCount + " undismissed crash" + (root.undismissedCount > 1 ? "es" : "") + "\nClick for Crashbar"
    }

    onPressed: function(b) {
      root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    Column {
      id: contentColumn
      width: parent.width
      spacing: Style.space(12)

      // Header row
      RowLayout {
        width: parent.width
        spacing: Style.space(8)

        Text {
          text: "󱚡"
          color: root.bar ? root.bar.urgent : Color.urgent
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
        }

        Text {
          text: !root.isConfigured ? "Crashbar Setup" : ("Crashbar (" + root.undismissedCount + ")")
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        Item {
          Layout.fillWidth: true
        }

        Button {
          visible: root.isConfigured && root.undismissedCount > 0
          text: "Dismiss All"
          iconText: "✕"
          fontSize: Style.font.caption
          horizontalPadding: Style.space(8)
          verticalPadding: Style.space(4)
          bordered: true
          onClicked: root.dismissAll()
        }
      }

      // Setup Card (shown if setup has not been run yet)
      BorderSurface {
        visible: !root.isConfigured
        width: parent.width
        implicitHeight: setupCol.implicitHeight + Style.space(20)
        radius: Style.cornerRadius
        color: Style.hoverFillFor(root.barForeground, root.barForeground)
        borderSpec: Border.flat(Color.accent, 1)

        Column {
          id: setupCol
          anchors.fill: parent
          anchors.margins: Style.space(10)
          spacing: Style.space(8)

          Text {
            text: "Activate Crashbar"
            color: root.barForeground
            font.bold: true
            font.pixelSize: Style.font.subtitle
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Replaces intrusive desktop notification popups with quiet in-bar alerts and 1-click AI diagnosis. Click below to safely configure the watcher service and CLI tools (all existing configurations are backed up)."
            color: root.barForeground
            opacity: 0.85
            font.pixelSize: Style.font.caption
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            Button {
              text: setupActionProc.running ? "Activating..." : "Finish Setup & Activate"
              iconText: "󰑓"
              accent: Color.accent
              bordered: true
              fontSize: Style.font.caption
              horizontalPadding: Style.space(12)
              verticalPadding: Style.space(6)
              enabled: !setupActionProc.running
              onClicked: {
                setupActionProc.command = [root.setupBin]
                setupActionProc.running = true
              }
            }
          }
        }
      }

      // Empty state
      Item {
        visible: root.isConfigured && root.crashesList.length === 0
        width: parent.width
        implicitHeight: Style.space(40)

        Text {
          anchors.centerIn: parent
          text: "No undismissed crashes"
          color: root.barForeground
          opacity: 0.5
          font.pixelSize: Style.font.body
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
        }
      }

      // List of crashes
      Column {
        width: parent.width
        spacing: Style.space(8)
        visible: root.crashesList.length > 0

        Repeater {
          model: root.crashesList

          BorderSurface {
            required property var modelData
            required property int index

            width: parent.width
            implicitHeight: cardLayout.implicitHeight + Style.space(16)
            radius: Style.cornerRadius
            color: Style.hoverFillFor(root.barForeground, root.barForeground)
            borderSpec: Border.flat(Color.popups.border, 1)

            Column {
              id: cardLayout
              anchors.fill: parent
              anchors.margins: Style.space(8)
              spacing: Style.space(6)

              // Header: App name + relative time
              RowLayout {
                width: parent.width

                Text {
                  text: modelData.comm || "Process"
                  color: root.barForeground
                  font.bold: true
                  font.pixelSize: Style.font.body
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: modelData.timeAgo || ""
                  color: root.barForeground
                  opacity: 0.6
                  font.pixelSize: Style.font.caption
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                }
              }

              // Details: Signal badge + PID & Path
              RowLayout {
                width: parent.width
                spacing: Style.space(6)

                BorderSurface {
                  color: Style.normalFillFor(root.barForeground, Color.urgent)
                  radius: Style.cornerRadius * 0.5
                  implicitHeight: Style.space(18)
                  implicitWidth: sigText.implicitWidth + Style.space(10)

                  Text {
                    id: sigText
                    anchors.centerIn: parent
                    text: modelData.signal || "CRASH"
                    color: Color.urgent
                    font.bold: true
                    font.pixelSize: Style.font.caption
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  }
                }

                Text {
                  text: "PID " + modelData.pid + (modelData.exe ? " • " + modelData.exe : "")
                  color: root.barForeground
                  opacity: 0.75
                  font.pixelSize: Style.font.caption
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  elide: Text.ElideMiddle
                  Layout.fillWidth: true
                }
              }

              // Action buttons
              RowLayout {
                width: parent.width
                spacing: Style.space(8)

                Button {
                  text: "Diagnose with AI"
                  iconText: "󱚡"
                  accent: Color.accent
                  bordered: true
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(8)
                  verticalPadding: Style.space(4)
                  onClicked: {
                    root.diagnose(modelData.pid, modelData.comm, modelData.exe, modelData.signal)
                  }
                }

                Item { Layout.fillWidth: true }

                Button {
                  text: "Dismiss"
                  iconText: "✕"
                  bordered: true
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(8)
                  verticalPadding: Style.space(4)
                  onClicked: {
                    root.dismiss(modelData.id)
                  }
                }
              }
            }
          }
        }
      }

      // Footer status & deactivation row
      RowLayout {
        width: parent.width
        visible: root.isConfigured
        spacing: Style.space(8)

        Text {
          text: "● Watcher Active"
          color: Color.active
          font.pixelSize: Style.font.caption
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
        }

        Item { Layout.fillWidth: true }

        Button {
          text: deactivateActionProc.running ? "Restoring..." : "Deactivate Watcher"
          fontSize: Style.font.caption
          opacity: 0.7
          bordered: false
          enabled: !deactivateActionProc.running
          onClicked: {
            deactivateActionProc.command = [root.uninstallBin, "--deactivate"]
            deactivateActionProc.running = true
          }
        }
      }
    }
  }
}
