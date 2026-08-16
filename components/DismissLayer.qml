import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

// Capa invisible de pantalla completa: cierra cualquier popup abierto
// al hacer click fuera de él, como en GNOME Shell.
PanelWindow {
    id: dismiss
    WlrLayershell.namespace: "quickshell:dismiss"
    visible: PopupManager.current !== ""
    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: PopupManager.close()
    }
}
