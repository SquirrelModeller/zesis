pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property int count: server.trackedNotifications.values.length
    property int unreadCount: 0

    readonly property var notifications: server.trackedNotifications
    readonly property ListModel history: historyModel

    function clearHistory() {
        historyModel.clear();
        unreadCount = 0;
    }

    function markRead() {
        unreadCount = 0;
    }

    ListModel {
        id: historyModel
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: false

        onNotification: n => {
            n.tracked = true;
            historyModel.insert(0, {
                appName: n.appName ?? "",
                summary: n.summary ?? "",
                body: n.body ?? "",
                time: Qt.formatTime(new Date(), "hh:mm")
            });
            if (historyModel.count > 50)
                historyModel.remove(historyModel.count - 1);
            root.unreadCount++;
        }
    }
}
