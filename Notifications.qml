pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

// Servidor de notificaciones + historial, al estilo GNOME (el mismo panel
// que aparece al abrir el calendario). Los banners emergentes se manejan
// aparte en components/NotificationToasts.qml usando server.trackedNotifications.
QtObject {
    id: notifications

    property bool dnd: false
    property var history: []
    readonly property int unreadCount: notifications.history.length

    function clear() { notifications.history = [] }

    property NotificationServer server: NotificationServer {
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: function (n) {
            var entry = {
                id: n.id,
                appName: n.appName || "Notificación",
                appIcon: n.appIcon,
                summary: n.summary,
                body: n.body,
                urgency: n.urgency,
                image: n.image,
                time: new Date()
            }
            notifications.history = [entry].concat(notifications.history).slice(0, 50)

            // "tracked" mantiene la notificación viva para poder mostrarla como
            // banner; el servidor la retira solo de trackedNotifications cuando
            // se cierra (dismiss/expire), sin que tengamos que tocar "tracked".
            if (!notifications.dnd) n.tracked = true
        }
    }
}
