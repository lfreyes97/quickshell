//@ pragma IconTheme Phosphor
import Quickshell
import QtQuick
import "components"

Scope {
    id: root

    // Restaura el fondo de pantalla guardado al iniciar la shell.
    Component.onCompleted: Wallpaper.restore()

    Variants {
        model: Quickshell.screens

        Bar {
            property var modelData
            screen: modelData
        }
    }
}
