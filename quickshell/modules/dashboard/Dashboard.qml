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

    // A normal floating window (xdg toplevel) so it can be dragged/positioned
    // by the WM, appears in screenshots, and doesn't grab all input.
    FloatingWindow {
        id: win
        visible: dashScope.dashOpen
        title: "quickshell-dashboard"
        color: "transparent"
        implicitWidth: 880
        implicitHeight: panel.implicitHeight
        minimumSize: Qt.size(880, panel.implicitHeight)

        SystemClock { id: clock; precision: SystemClock.Seconds }

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 22
            color: Theme.bg
            border.color: Theme.bg3
            border.width: 1
            implicitHeight: mainRow.implicitHeight + 56

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
                anchors { fill: parent; margins: 28 }
                spacing: 28

                // ── LEFT: clock + date + stats ──
                ColumnLayout {
                    Layout.preferredWidth: 380
                    Layout.alignment: Qt.AlignTop
                    spacing: 22

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

                    NowPlaying { Layout.fillWidth: true }
                    StatsPanel { Layout.fillWidth: true }
                }

                // vertical divider
                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.bg3 }

                // ── RIGHT: quick toggles + sliders ──
                ColumnLayout {
                    Layout.fillWidth: true
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
                }
            }
        }
    }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { dashScope.dashOpen = !dashScope.dashOpen; }
        function open(): void { dashScope.dashOpen = true; }
        function close(): void { dashScope.dashOpen = false; }
    }
}
