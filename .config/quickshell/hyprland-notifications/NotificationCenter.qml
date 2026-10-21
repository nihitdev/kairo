import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "."

PanelWindow {
    id: root
    required property var service

    function activeScreen() {
        try {
            const name = Hyprland.focusedMonitor.name;
            const match = Quickshell.screens.find(screen => screen.name === name);
            if (match)
                return match;
        } catch (error) {}
        return Quickshell.cursorScreen || Quickshell.screens[0] || null;
    }

    screen: activeScreen()
    visible: service.panelOpen
    implicitWidth: 410
    implicitHeight: Math.min(620, Math.max(280, (screen ? screen.height : 768) - 88))
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: 43; right: 10 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "archnemesis-hypr-notifications"

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 22
        color: Theme.panel
        border.width: 1
        border.color: Qt.rgba(0.8, 0.65, 0.97, 0.32)
        focus: root.visible
        Keys.onEscapePressed: root.service.panelOpen = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 17
            spacing: 13

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Notifications"; color: Theme.text; font.family: Theme.font; font.pixelSize: 18; font.weight: Font.DemiBold }
                    Text { text: root.service.history.length === 0 ? "All caught up" : root.service.history.length + " recent"; color: Theme.subtext; font.family: Theme.mono; font.pixelSize: 9 }
                }
                ToolButton {
                    label: root.service.dnd ? "DND on" : "DND"
                    active: root.service.dnd
                    onClicked: root.service.dnd = !root.service.dnd
                }
                ToolButton {
                    label: "Clear"
                    onClicked: root.service.clear()
                }
                ToolButton {
                    label: "×"
                    onClicked: root.service.panelOpen = false
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1; opacity: 0.65 }

            ListView {
                id: history
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 9
                model: root.service.history
                delegate: NotificationCard {
                    required property var modelData
                    width: ListView.view.width
                    entry: modelData
                    service: root.service
                }

                Text {
                    anchors.centerIn: parent
                    visible: history.count === 0
                    text: "Nothing new. Enjoy the quiet."
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }
        }
    }

    component ToolButton: Rectangle {
        required property string label
        property bool active: false
        signal clicked()
        implicitWidth: label.length > 4 ? 52 : 34
        implicitHeight: 30
        radius: 10
        color: mouse.containsMouse || active ? Theme.surface : "transparent"
        border.width: active ? 1 : 0
        border.color: Theme.mauve
        Text { anchors.centerIn: parent; text: parent.label; color: parent.active ? Theme.mauve : Theme.text; font.family: Theme.font; font.pixelSize: 10 }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
