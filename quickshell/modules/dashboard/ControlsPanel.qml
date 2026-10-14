import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: cp
    implicitHeight: col.implicitHeight
    property bool active: true
    signal requestClose()

    function act(cmd) { Quickshell.execDetached(["bash", "-lc", cmd]); }

    // toggle button (icon + label in a rounded square)
    component ToggleBtn: Button {
        id: toggleButton
        property string glyph: ""
        property string label: ""
        property color accent: Theme.aqua
        text: label
        Layout.fillWidth: true
        implicitHeight: 72
        focusPolicy: Qt.StrongFocus
        background: Rectangle {
            radius: 12
            color: parent.down || parent.hovered ? Theme.bg3 : Theme.bg2
            border.width: parent.activeFocus ? 2 : 0
            border.color: Theme.orange
        }
        contentItem: ColumnLayout {
            spacing: 5
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: toggleButton.glyph
                color: toggleButton.accent
                font.family: Theme.font
                font.pixelSize: 26
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: toggleButton.label
                color: Theme.gray
                font.family: Theme.font
                font.pixelSize: 10
            }
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 12

        // ── Quick toggles ──
        GridLayout {
            Layout.fillWidth: true
            columns: cp.width < 330 ? 2 : 3
            columnSpacing: 10
            rowSpacing: 10
            ToggleBtn { glyph: "󰖩"; label: "Wifi";  accent: Theme.aqua;   onClicked: cp.act('[ "$(nmcli radio wifi)" = enabled ] && nmcli radio wifi off || nmcli radio wifi on') }
            ToggleBtn { glyph: "󰂯"; label: "Bluetooth"; accent: Theme.aqua; onClicked: cp.act('bluetoothctl show | grep -q "Powered: yes" && bluetoothctl power off || bluetoothctl power on') }
            ToggleBtn { glyph: "󰓅"; label: "Performance"; accent: Theme.orange; onClicked: cp.act("~/.config/hypr/scripts/toggle-profile.sh") }
            ToggleBtn { glyph: "󰈐"; label: "Fan";   accent: Theme.red;    onClicked: cp.act("~/.config/hypr/scripts/fan-max.sh") }
            ToggleBtn { glyph: "󰌾"; label: "Lock";  accent: Theme.green;  onClicked: { cp.act("hyprlock"); cp.requestClose(); } }
            ToggleBtn { glyph: "󰍃"; label: "Session"; accent: Theme.yellow; onClicked: { cp.act("wlogout"); cp.requestClose(); } }
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
            running: cp.active
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
