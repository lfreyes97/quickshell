import QtQuick
import ".."

// Botón chico tipo "chip": para selectores de layout, números de workspace
// y flechas del asistente de tiling en WindowControlPopup.
Rectangle {
    id: chip
    property string text: ""
    property string icon: ""
    property bool selected: false
    signal clicked

    implicitWidth: Math.max(28, label.implicitWidth + 16)
    implicitHeight: 26
    radius: Theme.radius - 6
    color: chip.selected ? Theme.activeBg : (mouse.containsMouse ? Theme.hoverBg : "transparent")
    border.width: 1
    border.color: chip.selected ? Theme.accent : Theme.border
    opacity: chip.enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: 100 } }
    Behavior on opacity { NumberAnimation { duration: 100 } }

    SymbolicIcon {
        visible: chip.icon.length > 0
        name: chip.icon
        size: 13
        tint: chip.selected ? Theme.accent : Theme.fg
        anchors.centerIn: parent
    }
    Text {
        id: label
        visible: chip.icon.length === 0
        anchors.centerIn: parent
        text: chip.text
        color: chip.selected ? Theme.accent : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: chip.selected ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: chip.clicked()
    }
}
