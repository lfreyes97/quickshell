import QtQuick
import ".."

// Abre el Overview: mosaico de todos los workspaces y sus ventanas,
// al estilo GNOME Activities / Mission Control.
BarButton {
    id: btn
    active: PopupManager.current === "overview"
    SymbolicIcon { name: "focus-windows-symbolic" }
    onClicked: PopupManager.open("overview")
}
