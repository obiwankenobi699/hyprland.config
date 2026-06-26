import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

Item {
    id: np
    implicitHeight: 60

    property string status: ""
    property string artist: ""
    property string title: ""
    property string artUrl: ""
    readonly property bool hasPlayer: np.title.length > 0

    Process {
        id: proc
        command: ["bash", "-lc", "playerctl metadata --format '{{status}}|{{artist}}|{{title}}|{{mpris:artUrl}}' 2>/dev/null"]
        stdout: StdioCollector {
            id: c
            onStreamFinished: {
                const t = c.text.trim();
                if (t.length === 0) { np.status = ""; np.artist = ""; np.title = ""; np.artUrl = ""; }
                else {
                    const p = t.split("|");
                    np.status = p[0] || ""; np.artist = p[1] || "";
                    np.title = p[2] || ""; np.artUrl = p[3] || "";
                }
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }

    function ctl(cmd) { Quickshell.execDetached(["bash", "-lc", "playerctl " + cmd]); }

    // ── Active player ──
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.bg2
        visible: np.hasPlayer
        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
            spacing: 12
            // album art (with glyph fallback)
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 8
                color: Theme.bg3
                clip: true
                Image {
                    anchors.fill: parent
                    source: np.artUrl
                    visible: np.artUrl.length > 0 && status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: np.artUrl.length === 0 || parent.children[0].status !== Image.Ready
                    text: "󰝙"; color: Theme.orange; font.family: Theme.font; font.pixelSize: 22
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: np.title; color: Theme.fg; font.family: Theme.font
                    font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true
                }
                Text {
                    text: np.artist; color: Theme.gray; font.family: Theme.font
                    font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
            MediaBtn { icon: "󰒮"; onClicked: np.ctl("previous") }
            MediaBtn { icon: np.status === "Playing" ? "󰏤" : "󰐊"; onClicked: np.ctl("play-pause") }
            MediaBtn { icon: "󰒭"; onClicked: np.ctl("next") }
        }
    }

    // ── Nothing playing ──
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.bg2
        visible: !np.hasPlayer
        Text {
            anchors.centerIn: parent
            text: "󰝛   Nothing playing"
            color: Theme.gray; font.family: Theme.font; font.pixelSize: 12
        }
    }

    component MediaBtn: Rectangle {
        property string icon: ""
        signal clicked()
        implicitWidth: 34; implicitHeight: 34; radius: 17
        color: mma.containsMouse ? Theme.bg3 : "transparent"
        Text { anchors.centerIn: parent; text: icon; color: Theme.fg; font.family: Theme.font; font.pixelSize: 17 }
        MouseArea {
            id: mma; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked()
        }
    }
}
