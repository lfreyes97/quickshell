import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

// Selector de workspaces estilo Super+Tab: aparece mientras se mantiene
// SUPER (hypr/modules/binds.lua), en orden numérico; confirma al soltar
// SUPER. Estado en Switcher.qml.
PanelWindow {
    id: root
    WlrLayershell.namespace: "quickshell:popup:supertab"
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Switcher.wsActive
    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"

    Rectangle {
        anchors.centerIn: parent
        radius: Theme.radius
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.border
        width: row.implicitWidth + 24
        height: row.implicitHeight + 24

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: Switcher.wsList
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    width: 52
                    height: 52
                    radius: Theme.radius - 8
                    color: index === Switcher.wsIndex ? Theme.activeBg : "transparent"
                    border.width: index === Switcher.wsIndex ? 2 : 1
                    border.color: index === Switcher.wsIndex ? Theme.accent : Theme.border

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: tile.modelData.name
                        color: index === Switcher.wsIndex ? Theme.accent : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
