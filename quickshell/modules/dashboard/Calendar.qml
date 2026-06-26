import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

Rectangle {
    id: cal
    radius: 12
    color: Theme.bg2
    implicitHeight: col.implicitHeight + 24

    SystemClock { id: clk; precision: SystemClock.Hours }

    function buildDays() {
        var d = clk.date;
        var year = d.getFullYear(), month = d.getMonth(), today = d.getDate();
        var startDow = (new Date(year, month, 1).getDay() + 6) % 7; // Mon=0
        var daysInMonth = new Date(year, month + 1, 0).getDate();
        var cells = [];
        for (var i = 0; i < startDow; i++) cells.push({ day: 0, today: false });
        for (var n = 1; n <= daysInMonth; n++) cells.push({ day: n, today: n === today });
        return cells;
    }
    property var cells: buildDays()
    Connections { target: clk; function onDateChanged() { cal.cells = cal.buildDays(); } }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clk.date, "MMMM yyyy")
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 14; font.bold: true
        }

        GridLayout {
            columns: 7
            Layout.fillWidth: true
            rowSpacing: 3
            columnSpacing: 3

            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData; color: Theme.gray
                    font.family: Theme.font; font.pixelSize: 10; font.bold: true
                }
            }
            Repeater {
                model: cal.cells
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 22
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22; height: 22; radius: 11
                        color: modelData.today ? Theme.orange : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData.day > 0 ? modelData.day : ""
                            color: modelData.today ? Theme.bg : Theme.fg
                            font.family: Theme.font; font.pixelSize: 11
                            font.bold: modelData.today
                        }
                    }
                }
            }
        }
    }
}
