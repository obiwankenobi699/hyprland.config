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
    readonly property string insight: {
        if (cpu === 0 && ram === 0 && disk === 0)
            return "Collecting live system data...";
        if (disk >= 95)
            return "Action needed: disk space is critically low";
        if (temp >= 85)
            return "Watch thermal load: system temperature is high";
        if (ram >= 90)
            return "Memory pressure is high: close unused applications";
        if (cpu >= 90)
            return "Heavy CPU load detected: check active applications";
        if (batt > 0 && batt <= 20)
            return "Battery is low: connect the charger soon";
        return "System stable · CPU " + cpu + "% · RAM " + ram + "% · " + temp + "°C";
    }
    signal requestDiagnostics()

    Process {
        id: proc
        command: ["/home/mukul/.config/hypr/scripts/sysinfo.sh"]
        stdout: StdioCollector {
            id: output
            onStreamFinished: {
                try {
                    const data = JSON.parse(output.text);
                    sp.cpu = data.cpu || 0;
                    sp.ram = data.ram || 0;
                    sp.temp = data.temp || 0;
                    sp.batt = data.batt || 0;
                    sp.disk = data.disk || 0;
                    sp.up = data.up || "—";
                } catch (error) {
                    // Keep the last valid values when a sample is interrupted.
                }
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

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Ring { Layout.fillWidth: true; value: sp.cpu / 100; center: sp.cpu + "%"; label: "CPU"; accent: Theme.green }
            Ring { Layout.fillWidth: true; value: sp.ram / 100; center: sp.ram + "%"; label: "RAM"; accent: Theme.aqua }
            Ring { Layout.fillWidth: true; value: sp.disk / 100; center: sp.disk + "%"; label: "DISK"; accent: Theme.orange }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MiniStat { icon: "󰔏"; value: sp.temp + "°C"; accent: Theme.orange }
            MiniStat { icon: "󰁹"; value: sp.batt + "%"; accent: Theme.yellow }
            Item { Layout.fillWidth: true }
            MiniStat { icon: "󰅐"; value: sp.up; accent: Theme.green }
            Text {
                text: "HEALTH  ›"
                color: Theme.orange
                font.family: Theme.font
                font.pixelSize: 9
                font.bold: true
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sp.requestDiagnostics()
                }
            }
        }
    }

    component MiniStat: RowLayout {
        property string icon: ""
        property string value: ""
        property color accent: Theme.green
        spacing: 6
        Text { text: icon; color: accent; font.family: Theme.font; font.pixelSize: 14 }
        Text { text: value; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
    }
}
