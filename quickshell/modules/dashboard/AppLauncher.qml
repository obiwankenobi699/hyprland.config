import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "."

Rectangle {
    id: launcher
    property bool active: false
    signal requestClose()

    radius: 18
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    function focusSearch() {
        searchField.forceActiveFocus();
        searchField.selectAll();
    }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        launcher.requestClose();
    }

    function appRank(entry) {
        const name = entry.name.toLowerCase();
        const preferred = ["zen browser", "code - oss", "dolphin", "kitty", "obsidian", "vesktop", "spotify", "figma", "neovim"];
        for (let index = 0; index < preferred.length; index++) {
            if (name === preferred[index] || name.startsWith(preferred[index] + " "))
                return index;
        }
        return preferred.length;
    }

    function hasUsableIcon(entry) {
        const knownMissing = ["preferences-system-network", "preferences-system", "hwloc", "network-wired"];
        return entry.icon && !knownMissing.includes(entry.icon);
    }

    ScriptModel {
        id: appsModel
        values: {
            const query = searchField.text.trim().toLowerCase();
            return DesktopEntries.applications.values
                .filter(entry => {
                    if (entry.noDisplay)
                        return false;
                    if (!query)
                        return true;
                    const haystack = [entry.name, entry.genericName, entry.comment, entry.id]
                        .join(" ").toLowerCase();
                    return haystack.includes(query);
                })
                .sort((a, b) => {
                    const rankDifference = launcher.appRank(a) - launcher.appRank(b);
                    return rankDifference || a.name.localeCompare(b.name);
                });
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "󰀻"
                color: Theme.orange
                font.family: Theme.font
                font.pixelSize: 22
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: "APPLICATIONS"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: searchField.text.trim()
                        ? appsModel.values.length + " matches"
                        : appsModel.values.length + " installed · type to filter"
                    color: Theme.gray
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }
            Text {
                text: "CTRL K"
                color: Theme.gray
                font.family: Theme.font
                font.pixelSize: 9
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.bg3 }

        TextField {
            id: searchField
            Layout.fillWidth: true
            implicitHeight: 46
            leftPadding: 42
            rightPadding: 14
            placeholderText: "Search applications…"
            color: Theme.fg
            placeholderTextColor: Theme.gray
            selectionColor: Theme.orange
            selectedTextColor: Theme.bg
            font.family: Theme.font
            font.pixelSize: 13
            focus: launcher.active

            onTextChanged: Qt.callLater(() => {
                appsGrid.currentIndex = -1;
                appsGrid.positionViewAtBeginning();
            })

            background: Rectangle {
                radius: 12
                color: Theme.bg2
                border.width: searchField.activeFocus ? 2 : 1
                border.color: searchField.activeFocus ? Theme.focus : Theme.bg3
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    color: searchField.activeFocus ? Theme.orange : Theme.gray
                    font.family: Theme.font
                    font.pixelSize: 16
                }
            }

            Keys.onDownPressed: {
                if (appsGrid.count > 0) {
                    appsGrid.currentIndex = 0;
                    appsGrid.forceActiveFocus();
                }
            }
            Keys.onReturnPressed: launcher.launch(appsModel.values[0])
            Keys.onEnterPressed: launcher.launch(appsModel.values[0])
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: appsGrid
                anchors.fill: parent
                clip: true
                model: appsModel
                cellWidth: width / 4
                cellHeight: 112
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationWraps: true
                highlightMoveDuration: 100
                currentIndex: -1

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.bg4
                    }
                }

                delegate: Button {
                    id: appButton
                    required property var modelData
                    width: appsGrid.cellWidth - 8
                    height: appsGrid.cellHeight - 8
                    x: 4
                    y: 4
                    text: modelData.name
                    focusPolicy: Qt.StrongFocus
                    onClicked: launcher.launch(modelData)

                    background: Rectangle {
                        radius: 12
                        color: appButton.down ? Theme.bg4
                            : appButton.hovered || appButton.activeFocus ? Theme.surfaceRaised
                            : "transparent"
                        border.width: appButton.activeFocus ? 2 : 0
                        border.color: Theme.focus
                    }

                    contentItem: ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 7

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46

                            Text {
                                anchors.centerIn: parent
                                text: "󰀻"
                                color: Theme.aqua
                                font.family: Theme.font
                                font.pixelSize: 30
                            }
                            Image {
                                id: appIcon
                                anchors.fill: parent
                                visible: source.toString().length > 0 && status === Image.Ready
                                source: launcher.hasUsableIcon(appButton.modelData)
                                    ? Quickshell.iconPath(appButton.modelData.icon)
                                    : ""
                                sourceSize.width: 46
                                sourceSize.height: 46
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: appButton.modelData.name
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 10
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                        }
                    }
                }

                Keys.onReturnPressed: launcher.launch(appsModel.values[currentIndex])
                Keys.onEnterPressed: launcher.launch(appsModel.values[currentIndex])
            }

            Column {
                anchors.centerIn: parent
                visible: appsModel.values.length === 0
                spacing: 8
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰅙"
                    color: Theme.gray
                    font.family: Theme.font
                    font.pixelSize: 30
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No applications match “" + searchField.text + "”"
                    color: Theme.gray
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "↑↓←→ navigate   ·   ENTER launch   ·   ESC close"
            color: Theme.gray
            font.family: Theme.font
            font.pixelSize: 9
        }
    }
}
