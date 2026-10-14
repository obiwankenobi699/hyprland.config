import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
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
        running: dashScope.dashOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: displayModeRead.running = true
    }

    FloatingWindow {
        id: win
        visible: dashScope.dashOpen
        title: "quickshell-dashboard"
        color: "transparent"
        implicitWidth: 1480
        implicitHeight: 820
        minimumSize: Qt.size(1280, 720)

        SystemClock { id: clock; precision: SystemClock.Seconds }

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            onActivated: {
                dashScope.dashOpen = false;
                dashScope.page = "home";
            }
        }
        Shortcut {
            sequence: "Ctrl+K"
            context: Qt.WindowShortcut
            onActivated: appLauncher.focusSearch()
        }

        RowLayout {
            visible: dashScope.page === "home"
            anchors.fill: parent
            spacing: 16

            Rectangle {
                Layout.preferredWidth: 360
                Layout.fillHeight: true
                radius: 18
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            implicitWidth: 52
                            implicitHeight: 52
                            radius: 14
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
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "MUKUL // COMMAND CENTER"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                text: dashScope.displayMode === "bw"
                                    ? "GHOST MODE · grayscale active"
                                    : "SYSTEM ONLINE · " + statsPanel.insight
                                color: dashScope.displayMode === "bw" ? Theme.orange : Theme.green
                                font.family: Theme.font
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.bg3 }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                readonly property int h: clock.date.getHours()
                                text: (h < 12 ? "GOOD MORNING" : h < 18 ? "GOOD AFTERNOON" : "GOOD EVENING")
                                color: Theme.orange
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1
                            }
                            Text {
                                text: Qt.formatDateTime(clock.date, "hh:mm")
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 54
                                font.bold: true
                            }
                            Text {
                                text: Qt.formatDateTime(clock.date, "dddd, dd MMMM").toUpperCase()
                                color: Theme.aqua
                                font.family: Theme.font
                                font.pixelSize: 12
                            }
                        }
                        Text {
                            text: Qt.formatDateTime(clock.date, "ss")
                            color: Theme.gray
                            font.family: Theme.font
                            font.pixelSize: 22
                        }
                    }

                    Weather {
                        Layout.fillWidth: true
                        active: dashScope.dashOpen && dashScope.page === "home"
                    }
                    NowPlaying {
                        Layout.fillWidth: true
                        active: dashScope.dashOpen && dashScope.page === "home"
                    }
                    StatsPanel {
                        id: statsPanel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: dashScope.dashOpen && dashScope.page === "home"
                        onRequestDiagnostics: dashScope.page = "diagnostics"
                    }
                }
            }

            AppLauncher {
                id: appLauncher
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: dashScope.dashOpen && dashScope.page === "home"
                onRequestClose: {
                    dashScope.dashOpen = false;
                    dashScope.page = "home";
                }
            }

            Rectangle {
                Layout.preferredWidth: 330
                Layout.fillHeight: true
                radius: 18
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "CONTROL CENTER"
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.bold: true
                            font.letterSpacing: 1
                        }
                        Text {
                            text: "󰂚"
                            color: Theme.orange
                            font.family: Theme.font
                            font.pixelSize: 18
                        }
                    }

                    Button {
                        id: notificationsButton
                        Layout.fillWidth: true
                        implicitHeight: 58
                        text: "Open notifications"
                        focusPolicy: Qt.StrongFocus
                        onClicked: {
                            Quickshell.execDetached(["swaync-client", "-t"]);
                            dashScope.dashOpen = false;
                        }
                        background: Rectangle {
                            radius: 12
                            color: notificationsButton.down || notificationsButton.hovered ? Theme.bg3 : Theme.bg2
                            border.width: notificationsButton.activeFocus ? 2 : 1
                            border.color: notificationsButton.activeFocus ? Theme.focus : Theme.bg3
                        }
                        contentItem: RowLayout {
                            spacing: 10
                            Text {
                                text: "󰂞"
                                color: Theme.orange
                                font.family: Theme.font
                                font.pixelSize: 21
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: "NOTIFICATIONS"
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                Text {
                                    text: "View history and media alerts"
                                    color: Theme.gray
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                }
                            }
                            Text { text: "›"; color: Theme.gray; font.pixelSize: 20 }
                        }
                    }

                    ControlsPanel {
                        Layout.fillWidth: true
                        active: dashScope.dashOpen && dashScope.page === "home"
                        onRequestClose: dashScope.dashOpen = false
                    }

                    Calendar { Layout.fillWidth: true }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "QUICK LAUNCH"
                        color: Theme.gray
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.bold: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        component DockButton: Button {
                            property string glyph: ""
                            property string command: ""
                            property string hint: ""
                            Layout.fillWidth: true
                            implicitHeight: 46
                            text: hint
                            focusPolicy: Qt.StrongFocus
                            onClicked: {
                                Quickshell.execDetached(["bash", "-lc", command]);
                                dashScope.dashOpen = false;
                            }
                            ToolTip.visible: hovered
                            ToolTip.text: hint
                            background: Rectangle {
                                radius: 10
                                color: parent.down || parent.hovered ? Theme.bg3 : Theme.bg2
                                border.width: parent.activeFocus ? 2 : 0
                                border.color: Theme.focus
                            }
                            contentItem: Text {
                                text: parent.glyph
                                color: Theme.fg
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: Theme.font
                                font.pixelSize: 20
                            }
                        }

                        DockButton { glyph: "󰆍"; hint: "Terminal"; command: "kitty" }
                        DockButton { glyph: "󰖟"; hint: "Browser"; command: "zen-browser" }
                        DockButton { glyph: "󰉋"; hint: "Files"; command: "dolphin" }
                        DockButton { glyph: "󰨞"; hint: "Code"; command: "code" }
                        DockButton { glyph: "󰚰"; hint: "Update"; command: "kitty --class system-maintenance -e ~/.config/hypr/scripts/system-update.sh" }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: dashScope.page === "diagnostics"
            radius: 18
            color: Theme.surface
            border.color: Theme.border
            border.width: 1

            DiagnosticsPage {
                anchors.fill: parent
                onRequestBack: {
                    dashScope.page = "home";
                    Qt.callLater(() => appLauncher.focusSearch());
                }
            }
        }

        onVisibleChanged: {
            if (visible && dashScope.page === "home")
                Qt.callLater(() => appLauncher.focusSearch());
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
                Qt.callLater(() => appLauncher.focusSearch());
            }
        }
        function open(): void {
            dashScope.dashOpen = true;
            Qt.callLater(() => appLauncher.focusSearch());
        }
        function close(): void {
            dashScope.dashOpen = false;
            dashScope.page = "home";
        }
    }
}
