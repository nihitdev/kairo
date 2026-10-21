import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "."

Rectangle {
    id: root
    required property var entry
    required property var service
    property bool compact: false

    implicitHeight: content.implicitHeight + 24
    radius: 16
    color: Theme.panel
    border.width: 1
    border.color: entry.urgency === NotificationUrgency.Critical
        ? Qt.rgba(0.95, 0.55, 0.66, 0.82) : Qt.rgba(0.8, 0.65, 0.97, 0.24)

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 13
        spacing: 7

        RowLayout {
            spacing: 9
            Image {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                source: {
                    const icon = root.entry.icon || "";
                    if (icon.startsWith("file://") || icon.startsWith("/"))
                        return icon;
                    return icon ? Quickshell.iconPath(icon, true) : "";
                }
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
            Text {
                Layout.fillWidth: true
                text: root.entry.app
                color: Theme.mauve
                font.family: Theme.mono
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            Text {
                text: Qt.formatTime(root.entry.time, "HH:mm")
                color: Theme.subtext
                font.family: Theme.mono
                font.pixelSize: 9
            }
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: dismissMouse.containsMouse ? Theme.surface1 : "transparent"
                Text { anchors.centerIn: parent; text: "×"; color: Theme.text; font.pixelSize: 17 }
                MouseArea {
                    id: dismissMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.service.dismiss(root.entry.id)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.entry.summary
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.entry.body.replace(/<[^>]*>/g, "")
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: 11
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 4 : 7
            elide: Text.ElideRight
        }

        RowLayout {
            visible: root.entry.live && root.entry.live.actions.length > 0
            Repeater {
                model: root.entry.live ? root.entry.live.actions : []
                Rectangle {
                    required property var modelData
                    implicitWidth: actionText.implicitWidth + 18
                    implicitHeight: 27
                    radius: 9
                    color: actionMouse.containsMouse ? Theme.surface1 : Theme.surface
                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
