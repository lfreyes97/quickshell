import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

// Base para los popups flotantes de la barra (calendario, quick settings):
// tarjeta redondeada y translúcida, anclada bajo la barra.
PanelWindow {
    id: popup
    property string popupName: ""
    // "left" (bajo Actividades), "right" (bajo el status pill) o "center" (bajo el reloj)
    property string align: "right"
    property int cardWidth: 300
    default property alias content: column.data

    WlrLayershell.namespace: "quickshell:popup:" + popup.popupName
    // Por encima de la capa que cierra los popups: si no, ambas superficies
    // quedan al mismo nivel y los clicks pueden ir a la de abajo en vez de
    // llegar a los controles del popup.
    WlrLayershell.layer: WlrLayer.Overlay
    visible: PopupManager.current === popup.popupName
    color: "transparent"
    anchors {
        top: true
        left: popup.align === "left"
        right: popup.align === "right"
    }
    margins {
        top: 6
        left: popup.align === "left" ? 8 : 0
        right: popup.align === "right" ? 8 : 0
    }
    exclusiveZone: 0
    aboveWindows: true
    focusable: false

    implicitWidth: popup.cardWidth
    implicitHeight: column.implicitHeight + 24

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.border

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
        }
    }
}
