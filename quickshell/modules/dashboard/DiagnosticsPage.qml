import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

Item {
    id: root
    signal requestBack()

    property string selectedCategory: "storage"
    property var healthData: ({"categories": {}, "metrics": {}, "missing_dependencies": [], "last_updated": null})
    property var findings: []
    property string apiError: ""
    readonly property var categories: ["overview", "cpu", "gpu", "ram", "storage", "battery", "thermal", "network", "kernel"]

    function severityColor(severity) {
        if (severity === "CRITICAL") return Theme.red;
        if (severity === "WARNING") return Theme.orange;
        if (severity === "OK") return Theme.green;
        return Theme.gray;
    }

    function severitySymbol(severity) {
        if (severity === "CRITICAL") return "✕";
        if (severity === "WARNING") return "⚠";
        if (severity === "OK") return "✓";
        return "?";
    }

    function categoryState(category) {
        return healthData.categories[category] || "UNKNOWN";
    }

    function metricRows() {
        const rows = [];
        for (const key in healthData.metrics) {
            if (selectedCategory === "overview" || key.indexOf(selectedCategory + ".") === 0) {
                const metric = healthData.metrics[key];
                rows.push({
                    "key": key,
                    "label": key.split(".")[1].replace(/_/g, " ").toUpperCase(),
                    "value": metric.value === null ? "—" : metric.value + metric.unit,
                    "severity": metric.severity,
                    "expected": metric.expected,
                    "detail": metric.detail
                });
            }
        }
        return rows;
    }

    function refreshEndpoint(path, callback) {
        const request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) return;
            if (request.status === 200) {
                try {
                    callback(JSON.parse(request.responseText));
                    root.apiError = "";
                } catch (error) {
                    root.apiError = "Invalid diagnostics response";
                }
            } else {
                root.apiError = "diagnosticsd is offline";
            }
        };
        request.open("GET", "http://127.0.0.1:17373" + path);
        request.send();
    }

    function refresh() {
        refreshEndpoint("/health", data => root.healthData = data);
        refreshEndpoint("/findings", data => root.findings = data.findings || []);
    }

    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    ColumnLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "‹ BACK"
                color: Theme.orange
                font.family: Theme.font
                font.pixelSize: 12
                font.bold: true
                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.requestBack() }
            }
            Item { Layout.fillWidth: true }
            Text { text: "DIAGNOSTICS"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.bold: true }
            Item { Layout.fillWidth: true }
            Text {
                text: root.healthData.last_updated ? "⟳ " + Qt.formatTime(new Date(root.healthData.last_updated * 1000), "hh:mm:ss") : "⟳ WAITING"
                color: Theme.gray
                font.family: Theme.font
                font.pixelSize: 10
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.bg3 }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            ColumnLayout {
                Layout.preferredWidth: 138
                Layout.fillHeight: true
                spacing: 4
                Repeater {
                    model: root.categories
                    delegate: Rectangle {
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: root.selectedCategory === modelData ? Theme.bg3 : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                            Text {
                                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                color: root.selectedCategory === modelData ? Theme.fg : Theme.gray
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                visible: modelData !== "overview"
                                text: root.severitySymbol(root.categoryState(modelData))
                                color: root.severityColor(root.categoryState(modelData))
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedCategory = modelData }
                    }
                }
                Item { Layout.fillHeight: true }
            }

            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.bg3 }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: details.implicitHeight
                clip: true
                ScrollBar.vertical: ScrollBar {}

                ColumnLayout {
                    id: details
                    width: parent.width - 12
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.selectedCategory.toUpperCase()
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            readonly property string state: root.selectedCategory === "overview"
                                ? (root.healthData.complete ? "OK" : "UNKNOWN") : root.categoryState(root.selectedCategory)
                            text: root.severitySymbol(state) + " " + state
                            color: root.severityColor(state)
                            font.family: Theme.font
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        visible: root.selectedCategory === "storage"
                        text: "Usage and hardware health are evaluated separately. Phase 1 reports filesystem space; SMART wear arrives in Phase 2."
                        color: Theme.gray
                        font.family: Theme.font
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: root.metricRows()
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: metricContent.implicitHeight + 24
                            radius: 12
                            color: Theme.bg2
                            border.color: Theme.bg3
                            ColumnLayout {
                                id: metricContent
                                anchors { fill: parent; margins: 12 }
                                spacing: 5
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: modelData.label; color: Theme.gray; font.family: Theme.font; font.pixelSize: 10 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: modelData.value; color: Theme.fg; font.family: Theme.font; font.pixelSize: 15; font.bold: true }
                                    Text {
                                        text: root.severitySymbol(modelData.severity) + " " + modelData.severity
                                        color: root.severityColor(modelData.severity)
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                                Text {
                                    text: modelData.detail !== "" ? modelData.detail : "Expected: " + modelData.expected
                                    color: Theme.gray
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.metricRows().length === 0
                        text: "? UNKNOWN — no Phase 1 collector is available for this category."
                        color: Theme.gray
                        font.family: Theme.font
                        font.pixelSize: 11
                    }

                    Text {
                        text: "ACTIVE FINDINGS"
                        color: Theme.gray
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.bold: true
                        Layout.topMargin: 6
                    }

                    Repeater {
                        model: root.findings.filter(finding => root.selectedCategory === "overview" || finding.category === root.selectedCategory)
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: findingContent.implicitHeight + 24
                            radius: 12
                            color: Theme.bg2
                            border.color: root.severityColor(modelData.severity)
                            ColumnLayout {
                                id: findingContent
                                anchors { fill: parent; margins: 12 }
                                spacing: 5
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: root.severitySymbol(modelData.severity) + " " + modelData.severity
                                        color: root.severityColor(modelData.severity)
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text { text: modelData.id; color: Theme.gray; font.family: Theme.font; font.pixelSize: 9 }
                                }
                                Text { text: modelData.reason; color: Theme.fg; font.family: Theme.font; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                Text {
                                    text: "Current: " + modelData.value + modelData.unit + "  ·  Expected: " + modelData.expected
                                    color: Theme.gray; font.family: Theme.font; font.pixelSize: 9
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.findings.filter(finding => root.selectedCategory === "overview" || finding.category === root.selectedCategory).length === 0
                        text: "No active findings for this view."
                        color: Theme.gray
                        font.family: Theme.font
                        font.pixelSize: 10
                    }

                    Text {
                        visible: root.healthData.missing_dependencies && root.healthData.missing_dependencies.length > 0
                        text: "? Missing optional dependencies: " + root.healthData.missing_dependencies.join(", ")
                        color: Theme.gray
                        font.family: Theme.font
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.apiError !== ""
                        text: "? UNKNOWN — " + root.apiError
                        color: Theme.orange
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
