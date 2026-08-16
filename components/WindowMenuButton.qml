import QtQuick
import ".."

// Abre el gestor de la ventana activa: flotante/monocle/fullscreen/cerrar,
// asistente de tiling dwindle (bsp) y mover de workspace.
BarButton {
    id: btn
    active: PopupManager.current === "windowctl"
    SymbolicIcon { name: "view-paged-symbolic" }
    onClicked: PopupManager.open("windowctl")
}
