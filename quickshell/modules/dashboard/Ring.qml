import QtQuick
import "."

Item {
    id: ring
    property real value: 0          // 0..1
    property string label: ""
    property string center: ""
    property color accent: Theme.green
    property int diameter: 92
    property int thickness: 7
    property int centerFontSize: 17
    implicitWidth: diameter
    implicitHeight: diameter + 12

    onValueChanged: canvas.requestPaint()
    onAccentChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: ring.diameter; height: ring.diameter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var cx = width / 2, cy = height / 2, r = width / 2 - ring.thickness;
            var v = Math.max(0, Math.min(1, ring.value));
            // track
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.lineWidth = ring.thickness;
            ctx.strokeStyle = "#3c3836";
            ctx.stroke();
            // value arc
            ctx.beginPath();
            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * v);
            ctx.lineWidth = ring.thickness;
            ctx.lineCap = "round";
            ctx.strokeStyle = ring.accent;
            ctx.stroke();
        }
        Text {
            anchors.centerIn: parent
            text: ring.center
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: ring.centerFontSize
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
