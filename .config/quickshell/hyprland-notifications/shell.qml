import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    NotificationService { id: notifications }
    NotificationCenter { service: notifications }
    NotificationPopups { service: notifications }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            notifications.panelOpen = !notifications.panelOpen;
        }
        function close(): void {
            notifications.panelOpen = false;
        }
        function toggleDnd(): void {
            notifications.dnd = !notifications.dnd;
        }
        function clear(): void {
            notifications.clear();
        }
        function status(): string {
            return JSON.stringify({
                count: notifications.history.length,
                dnd: notifications.dnd,
                panelOpen: notifications.panelOpen
            });
        }
    }
}
