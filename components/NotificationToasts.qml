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

    // Separación respecto a la barra. Ojo: forma parte del alto total de la
    // superficie, así que debe sumarse al implicitHeight o la tarjeta
    // (colocada con este margen) queda recortada por el borde inferior.
    readonly property int toastTopMargin: 40

    implicitWidth: 300
    implicitHeight: column.implicitHeight + toastTopMargin

    Column {
        id: column
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: toasts.toastTopMargin
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
                elevated: true
                onDismissRequested: {
                    if (toast.modelData && toast.modelData.dismiss) toast.modelData.dismiss()
                }

                // Mientras el puntero está encima se pausa el auto-cierre,
                // para poder leer la notificación con calma.
                HoverHandler { id: toastHover }

                Timer {
                    interval: 6000
                    running: !toastHover.hovered
                    onTriggered: {
                        if (toast.modelData && toast.modelData.dismiss) toast.modelData.dismiss()
                    }
                }
            }
        }
    }
}
