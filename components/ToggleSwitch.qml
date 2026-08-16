import QtQuick
import ".."

// Interruptor deslizante estilo GNOME/libadwaita.
Rectangle {
    id: sw
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: sw.checked ? Theme.accent : Theme.trackBg
    border.width: sw.checked ? 0 : 1
    border.color: Theme.border

    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        width: parent.height - 4
        height: parent.height - 4
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: sw.checked ? parent.width - width - 2 : 2
        color: "#ffffff"
        Behavior on anchors.leftMargin { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        // No mutamos sw.checked aquí: es un componente "controlado", su valor
        // real llega desde afuera. Si lo pisamos localmente, se rompe el
        // binding con el estado real (Wi-Fi/Bluetooth/DND) y el switch queda
        // desincronizado después del primer click.
        onClicked: sw.toggled(!sw.checked)
    }
}
