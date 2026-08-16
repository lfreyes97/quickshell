import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

// Banners de notificación emergentes, centrados bajo la barra como en GNOME.
PanelWindow {
    id: toasts
    WlrLayershell.namespace: "quickshell:toast"
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Notifications.server.trackedNotifications.values.length > 0
    anchors { top: true }
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"

    implicitWidth: 300
    implicitHeight: column.implicitHeight

    Column {
        id: column
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 40
        spacing: 8
        width: 300

        Repeater {
            model: Notifications.server.trackedNotifications.values
            delegate: NotificationRow {
                id: toast
                required property var modelData
                width: column.width
                appName: modelData.appName
                summary: modelData.summary
                body: modelData.body || ""
                appIcon: modelData.appIcon || ""
                time: null
                onDismissRequested: {
                    if (toast.modelData && toast.modelData.dismiss) toast.modelData.dismiss()
                }

                Timer {
                    interval: 6000
                    running: true
                    onTriggered: {
                        if (toast.modelData && toast.modelData.dismiss) toast.modelData.dismiss()
                    }
                }
            }
        }
    }
}
