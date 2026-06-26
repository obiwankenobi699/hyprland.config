import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "."

Item {
    id: w
    implicitHeight: 56

    property string temp: "—"
    property string desc: "loading…"

    Process {
        id: proc
        command: ["/home/mukul/.config/hypr/scripts/weather.sh"]
        stdout: StdioCollector {
            id: c
            onStreamFinished: {
                try {
                    const d = JSON.parse(c.text);
                    w.temp = d.temp; w.desc = d.desc;
                } catch (e) {}
            }
        }
    }
    // refresh every 15 min (weather changes slowly)
    Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }

    function glyph(d) {
        d = (d || "").toLowerCase();
        if (d.indexOf("thunder") >= 0) return "󰖓";
        if (d.indexOf("rain") >= 0 || d.indexOf("drizzle") >= 0 || d.indexOf("shower") >= 0) return "󰖗";
        if (d.indexOf("snow") >= 0 || d.indexOf("sleet") >= 0 || d.indexOf("ice") >= 0) return "󰖘";
        if (d.indexOf("fog") >= 0 || d.indexOf("mist") >= 0 || d.indexOf("haze") >= 0) return "󰖑";
        if (d.indexOf("cloud") >= 0 || d.indexOf("overcast") >= 0) return "󰖐";
        if (d.indexOf("clear") >= 0 || d.indexOf("sunny") >= 0) return "󰖙";
        return "󰖐";
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.bg2
        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 12
            Text { text: w.glyph(w.desc); color: Theme.yellow; font.family: Theme.font; font.pixelSize: 28 }
            ColumnLayout {
                spacing: 0
                Text { text: w.temp; color: Theme.fg; font.family: Theme.font; font.pixelSize: 18; font.bold: true }
                Text { text: w.desc; color: Theme.gray; font.family: Theme.font; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            Text { text: "WEATHER"; color: Theme.bg4; font.family: Theme.font; font.pixelSize: 9; font.bold: true }
        }
    }
}
