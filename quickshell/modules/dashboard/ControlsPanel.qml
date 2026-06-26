import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: cp
    implicitHeight: col.implicitHeight
    signal requestClose()

    function act(cmd) { Quickshell.execDetached(["bash", "-lc", cmd]); }

    // toggle button (icon + label in a rounded square)
    component ToggleBtn: Rectangle {
        property string icon: ""
        property string label: ""
        property color accent: Theme.aqua
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 72
        radius: 12
        color: ma.containsMouse ? Theme.bg3 : Theme.bg2
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: icon
                color: accent
                font.family: Theme.font
                font.pixelSize: 26
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: label
                color: Theme.gray
                font.family: Theme.font
                font.pixelSize: 10
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 12

        // ── Quick toggles ──
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 10
            rowSpacing: 10
            ToggleBtn { icon: "󰖩"; label: "Wifi";  accent: Theme.aqua;   onClicked: cp.act('[ "$(nmcli radio wifi)" = enabled ] && nmcli radio wifi off || nmcli radio wifi on') }
            ToggleBtn { icon: "󰂯"; label: "BT";    accent: Theme.aqua;   onClicked: cp.act('bluetoothctl show | grep -q "Powered: yes" && bluetoothctl power off || bluetoothctl power on') }
            ToggleBtn { icon: "󰓅"; label: "Perf";  accent: Theme.orange; onClicked: cp.act("~/.config/hypr/scripts/toggle-profile.sh") }
            ToggleBtn { icon: "󰈐"; label: "Fan";   accent: Theme.red;    onClicked: cp.act("~/.config/hypr/scripts/fan-max.sh") }
            ToggleBtn { icon: "󰌾"; label: "Lock";  accent: Theme.green;  onClicked: { cp.act("hyprlock"); cp.requestClose(); } }
            ToggleBtn { icon: "󰍃"; label: "Exit";  accent: Theme.yellow; onClicked: { cp.act("wlogout"); cp.requestClose(); } }
        }

        // ── Volume slider ──
        SliderRow {
            id: volRow
            Layout.fillWidth: true
            icon: "󰕾"
            accent: Theme.green
            onUserSet: v => cp.act("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + v.toFixed(2))
        }
        Process {
            id: volRead
            command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'"]
            stdout: StdioCollector { id: volCol; onStreamFinished: volRow.setExternal(parseFloat(volCol.text)) }
        }

        // ── Brightness slider ──
        SliderRow {
            id: brightRow
            Layout.fillWidth: true
            icon: "󰃠"
            accent: Theme.yellow
            onUserSet: v => cp.act("brightnessctl set " + Math.round(v * 100) + "%")
        }
        Process {
            id: brightRead
            command: ["bash", "-lc", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
            stdout: StdioCollector { id: brightCol; onStreamFinished: brightRow.setExternal(parseFloat(brightCol.text) / 100) }
        }

        Timer {
            interval: 1500
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: { volRead.running = true; brightRead.running = true; }
        }
    }

    // slider with an icon; emits userSet(value 0..1) only on user drag
    component SliderRow: RowLayout {
        property string icon: ""
        property color accent: Theme.green
        signal userSet(real value)
        function setExternal(v) { if (!isNaN(v) && !slider.pressed) slider.value = v; }
        spacing: 10
        Text { text: icon; color: accent; font.family: Theme.font; font.pixelSize: 18 }
        Slider {
            id: slider
            Layout.fillWidth: true
            from: 0; to: 1
            onMoved: userSet(value)
            background: Rectangle {
                x: slider.leftPadding; y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth; height: 6; radius: 3
                color: Theme.bg3
                Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 3; color: accent }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 14; height: 14; radius: 7
                color: accent
            }
        }
    }
}
