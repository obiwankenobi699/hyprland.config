import QtQuick
import "."

Item {
    id: ring
    property real value: 0          // 0..1
    property string label: ""
    property string center: ""
    property color accent: Theme.green
    implicitWidth: 92
    implicitHeight: 104

    onValueChanged: canvas.requestPaint()
    onAccentChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: 92; height: 92
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var cx = width / 2, cy = height / 2, r = width / 2 - 7;
            var v = Math.max(0, Math.min(1, ring.value));
            // track
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.lineWidth = 7;
            ctx.strokeStyle = "#3c3836";
            ctx.stroke();
            // value arc
            ctx.beginPath();
            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * v);
            ctx.lineWidth = 7;
            ctx.lineCap = "round";
            ctx.strokeStyle = ring.accent;
            ctx.stroke();
        }
        Text {
            anchors.centerIn: parent
            text: ring.center
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 17
            font.bold: true
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: ring.label
        color: Theme.gray
        font.family: Theme.font
        font.pixelSize: 10
    }
}
