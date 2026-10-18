import QtQuick
import ".."

// Botón chico tipo "chip": números de workspace y flechas del asistente de
// tiling en WindowControlPopup. `dot` marca con un punto debajo del texto
// (p. ej. workspace con ventanas).
Rectangle {
    id: chip
    property string text: ""
    property string icon: ""
    property bool selected: false
    property bool dot: false
    signal clicked

    implicitWidth: Math.max(32, label.implicitWidth + 16)
    implicitHeight: 32
    radius: Theme.radius - 6
    color: chip.selected ? Theme.accent : (mouse.containsMouse ? Theme.cardHoverBg : Theme.cardBg)
    opacity: chip.enabled || chip.selected ? 1 : 0.4
    scale: mouse.pressed ? 0.94 : 1

    Behavior on color { ColorAnimation { duration: 100 } }
    Behavior on opacity { NumberAnimation { duration: 100 } }
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    readonly property color contentColor: chip.selected ? Theme.accentFg : Theme.fg

    SymbolicIcon {
        visible: chip.icon.length > 0
        name: chip.icon
        size: 14
        tint: chip.contentColor
        anchors.centerIn: parent
    }
    Text {
        id: label
        visible: chip.icon.length === 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: chip.dot ? -2 : 0
        text: chip.text
        color: chip.contentColor
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: chip.selected ? Font.Bold : Font.Normal
    }
    Rectangle {
        visible: chip.dot
        width: 4
        height: 4
        radius: 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        color: chip.contentColor
        opacity: 0.7
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
