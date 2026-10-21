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
    visible: service.popups.length > 0 && !service.panelOpen
    anchors { top: true; right: true }
    margins { top: 50; right: 12 }
    implicitWidth: 370
    implicitHeight: Math.min(560, stack.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "archnemesis-hypr-notification-popups"

    ColumnLayout {
        id: stack
        anchors.fill: parent
        spacing: 8
        Repeater {
            model: root.visible ? root.service.popups : []
            NotificationCard {
                required property var modelData
                Layout.fillWidth: true
                entry: modelData
                service: root.service
                compact: true
            }
        }
    }
}
