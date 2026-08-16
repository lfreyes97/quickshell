import QtQuick
import ".."

// Puro indicador: icono + etiqueta + puntitos de workspace. Ya no abre
// rofi al hacer click (el lanzador vive en SUPER+R) — la gestión de
// ventanas y el overview de workspaces tienen sus propios botones
// (WindowMenuButton, OverviewButton).
BarButton {
    id: activities
    spacing: 8

    SymbolicIcon { name: "view-app-grid-symbolic" }
    Text {
        text: "Actividades"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 12
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }
    Workspaces {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }
}
