import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "."

Item {
    id: sp
    implicitHeight: grid.implicitHeight

    property int cpu: 0
    property int ram: 0
    property int temp: 0
    property int batt: 0
    property int disk: 0
    property string up: "—"

    Process {
        id: proc
        command: ["/home/mukul/.config/hypr/scripts/sysinfo.sh"]
        stdout: StdioCollector {
            id: col
            onStreamFinished: {
                try {
                    const d = JSON.parse(col.text);
                    sp.cpu = d.cpu; sp.ram = d.ram; sp.temp = d.temp;
                    sp.batt = d.batt; sp.disk = d.disk; sp.up = d.up;
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    component StatTile: Rectangle {
        property string icon: ""
        property string label: ""
        property string value: ""
        property color accent: Theme.green
        Layout.fillWidth: true
        implicitHeight: 56
        radius: 10
        color: Theme.bg2
        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 10
            Text { text: icon; color: accent; font.family: Theme.font; font.pixelSize: 20 }
            ColumnLayout {
                spacing: 0
                Text { text: value; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.bold: true }
                Text { text: label; color: Theme.gray; font.family: Theme.font; font.pixelSize: 10 }
            }
            Item { Layout.fillWidth: true }
        }
    }

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: 2
        rowSpacing: 8
        columnSpacing: 8
        StatTile { icon: "󰻠";  label: "CPU";    value: sp.cpu + "%";   accent: Theme.green }
        StatTile { icon: "󰍛";  label: "RAM";    value: sp.ram + "%";   accent: Theme.aqua }
        StatTile { icon: "󰔏";  label: "TEMP";   value: sp.temp + "°C"; accent: Theme.orange }
        StatTile { icon: "󰁹";  label: "BATT";   value: sp.batt + "%";  accent: Theme.yellow }
        StatTile { icon: "󰋊";  label: "DISK";   value: sp.disk + "%";  accent: Theme.aqua }
        StatTile { icon: "󰅐";  label: "UPTIME"; value: sp.up;          accent: Theme.green }
    }
}
