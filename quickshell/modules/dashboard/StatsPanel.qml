import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "."

Item {
    id: sp
    implicitHeight: col.implicitHeight

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
            id: col2
            onStreamFinished: {
                try {
                    const d = JSON.parse(col2.text);
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

    component MiniStat: RowLayout {
        property string icon: ""
        property string value: ""
        property color accent: Theme.green
        spacing: 6
        Text { text: icon; color: accent; font.family: Theme.font; font.pixelSize: 14 }
        Text { text: value; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 14

        // ── Progress rings ──
        RowLayout {
            Layout.fillWidth: true
            Ring { Layout.fillWidth: true; value: sp.cpu / 100;  center: sp.cpu + "%";  label: "CPU";  accent: Theme.green }
            Ring { Layout.fillWidth: true; value: sp.ram / 100;  center: sp.ram + "%";  label: "RAM";  accent: Theme.aqua }
            Ring { Layout.fillWidth: true; value: sp.disk / 100; center: sp.disk + "%"; label: "DISK"; accent: Theme.orange }
        }

        // ── Compact text row ──
        RowLayout {
            Layout.fillWidth: true
            MiniStat { icon: "󰔏"; value: sp.temp + "°C"; accent: Theme.orange }
            Item { Layout.fillWidth: true }
            MiniStat { icon: "󰁹"; value: sp.batt + "%"; accent: Theme.yellow }
            Item { Layout.fillWidth: true }
            MiniStat { icon: "󰅐"; value: sp.up;         accent: Theme.green }
        }
    }
}
