import QtQuick
import ".."

// Abre el selector de fondo de pantalla (awww).
BarButton {
    id: btn
    active: PopupManager.current === "wallpapers"
    SymbolicIcon { name: "preferences-desktop-wallpaper-symbolic" }
    onClicked: PopupManager.open("wallpapers")
}
