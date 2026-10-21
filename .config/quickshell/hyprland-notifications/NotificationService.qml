import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    property var history: []
    property var popups: []
    property var deadlines: ({})
    property bool dnd: false
    property bool panelOpen: false
    readonly property int historyLimit: 80
    readonly property int popupLimit: 4
    readonly property int defaultTimeout: 6500

    function receive(notification) {
        notification.tracked = true;
        const entry = {
            id: notification.id,
            app: notification.appName || "System",
            icon: notification.appIcon || "",
            summary: notification.summary || "Notification",
            body: notification.body || "",
            urgency: notification.urgency,
            time: new Date(),
            live: notification
        };

        const previousHistory = history.filter(item => item.id !== entry.id);
        for (const evicted of previousHistory.slice(historyLimit - 1))
            if (evicted.live)
                evicted.live.dismiss();
        history = [entry].concat(previousHistory).slice(0, historyLimit);
        if (!dnd || entry.urgency === NotificationUrgency.Critical)
            popups = [entry].concat(popups.filter(item => item.id !== entry.id))
                .slice(0, popupLimit);

        const timeout = notification.expireTimeout < 0
            ? defaultTimeout : notification.expireTimeout;
        const nextDeadlines = Object.assign({}, deadlines);
        if (timeout > 0 && entry.urgency !== NotificationUrgency.Critical)
            nextDeadlines[entry.id] = Date.now() + timeout;
        else
            delete nextDeadlines[entry.id];
        deadlines = nextDeadlines;

        notification.closed.connect(() => root.onClosed(entry.id));
    }

    function onClosed(id) {
        popups = popups.filter(item => item.id !== id);
        history = history.map(item => item.id === id
            ? Object.assign({}, item, { live: null }) : item);
        const nextDeadlines = Object.assign({}, deadlines);
        delete nextDeadlines[id];
        deadlines = nextDeadlines;
    }

    function dismiss(id) {
        const entry = history.find(item => item.id === id);
        popups = popups.filter(item => item.id !== id);
        history = history.filter(item => item.id !== id);
        const nextDeadlines = Object.assign({}, deadlines);
        delete nextDeadlines[id];
        deadlines = nextDeadlines;
        if (entry && entry.live)
            entry.live.dismiss();
    }

    function clear() {
        const previous = history;
        history = [];
        popups = [];
        deadlines = ({});
        for (const entry of previous)
            if (entry.live)
                entry.live.dismiss();
    }

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: notification => root.receive(notification)
    }

    Timer {
        interval: 250
        repeat: true
        running: Object.keys(root.deadlines).length > 0
        onTriggered: {
            const now = Date.now();
            for (const id of Object.keys(root.deadlines)) {
                if (root.deadlines[id] > now)
                    continue;
                const entry = root.history.find(item => item.id === Number(id));
                if (entry && entry.live)
                    entry.live.expire();
                else
                    root.onClosed(Number(id));
            }
        }
    }
}
