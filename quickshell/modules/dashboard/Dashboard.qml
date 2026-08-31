import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "."

Scope {
    id: dashScope
    property bool dashOpen: false
    property string page: "home"
    property string displayMode: "standard"

    Process {
        id: displayModeRead
        command: ["bash", "-lc", "state=\"${XDG_STATE_HOME:-$HOME/.local/state}/hypr/display-mode\"; cat \"$state\" 2>/dev/null || printf standard"]
        stdout: StdioCollector {
            id: displayModeOutput
            onStreamFinished: {
                const value = displayModeOutput.text.trim();
                dashScope.displayMode = value || "standard";
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: displayModeRead.running = true
    }

    // A normal floating window (xdg toplevel) so it can be dragged/positioned
    // by the WM, appears in screenshots, and doesn't grab all input.
    FloatingWindow {
        id: win
        visible: dashScope.dashOpen
        title: "quickshell-dashboard"
        color: "transparent"
        implicitWidth: 1000
        implicitHeight: panel.implicitHeight
        minimumSize: Qt.size(implicitWidth, panel.implicitHeight)

        SystemClock { id: clock; precision: SystemClock.Seconds }

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 22
            color: Theme.bg
            border.color: Theme.bg3
            border.width: 1
            implicitHeight: 650

            // Esc closes
            focus: dashScope.dashOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    dashScope.dashOpen = false;
                    event.accepted = true;
                }
            }

            RowLayout {
                id: mainRow
                visible: dashScope.page === "home"
                anchors { fill: parent; margins: 28 }
                spacing: 28

                // ── LEFT: clock + date + stats ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 18

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            implicitWidth: 64
                            implicitHeight: 64
                            radius: 32
                            color: Theme.bg2
                            border.color: Theme.orange
                            border.width: 2
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file:///home/mukul/Pictures/face/wolf.jpg"
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: "MUKUL"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 18
                                font.bold: true
                            }
                            Text {
                                text: "SYSTEM DASHBOARD"
                                color: Theme.orange
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.2
                            }
                            Text {
                                text: dashScope.displayMode === "bw"
                                    ? "Ghost Mode · grayscale display active"
                                    : "Standard display mode · " + statsPanel.insight
                                color: Theme.gray
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 62
                            implicitHeight: 24
                            radius: 12
                            color: Theme.bg2
                            border.color: Theme.bg3
                            Text {
                                anchors.centerIn: parent
                                text: dashScope.displayMode === "bw" ? "● GHOST" : "● LIVE"
                                color: dashScope.displayMode === "bw" ? Theme.orange : Theme.green
                                font.family: Theme.font
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text {
                            readonly property int h: clock.date.getHours()
                            text: (h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening") + ", mukul"
                            color: Theme.orange
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            text: Qt.formatDateTime(clock.date, "hh:mm")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 80
                            font.bold: true
                        }
                        Text {
                            text: Qt.formatDateTime(clock.date, "dddd, dd MMMM").toUpperCase()
                            color: Theme.gray
                            font.family: Theme.font
                            font.pixelSize: 14
                        }
                    }

                    Weather { Layout.fillWidth: true }
                    NowPlaying { Layout.fillWidth: true }
                    StatsPanel {
                        id: statsPanel
                        Layout.fillWidth: true
                        onRequestDiagnostics: dashScope.page = "diagnostics"
                    }
                }

                // vertical divider
                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.bg3 }

                // ── RIGHT: quick toggles + sliders ──
                ColumnLayout {
                    Layout.preferredWidth: 230
                    Layout.minimumWidth: 230
                    Layout.maximumWidth: 230
                    Layout.alignment: Qt.AlignTop
                    spacing: 16
                    Text {
                        text: "QUICK CONTROLS"
                        color: Theme.gray
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.bold: true
                    }
                    ControlsPanel {
                        Layout.fillWidth: true
                        onRequestClose: dashScope.dashOpen = false
                    }
                    Calendar { Layout.fillWidth: true }
                }
            }

            DiagnosticsPage {
                anchors.fill: parent
                visible: dashScope.page === "diagnostics"
                onRequestBack: dashScope.page = "home"
            }
        }
    }

    IpcHandler {
        target: "dashboard"
        function toggle(): void {
            if (dashScope.dashOpen) {
                dashScope.dashOpen = false;
                dashScope.page = "home";
            } else {
                dashScope.dashOpen = true;
            }
        }
        function open(): void { dashScope.dashOpen = true; }
        function close(): void { dashScope.dashOpen = false; dashScope.page = "home"; }
    }
}
