pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property int count: server.trackedNotifications.values.length

    // Expose the ObjectModel directly, usable as a Repeater/ListView model
    readonly property var notifications: server.trackedNotifications

    function clearAll() {
        for (var i = 0; i < server.trackedNotifications.values.length; i++) {
            server.trackedNotifications.values[i].dismiss();
        }
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
        }
    }
}
