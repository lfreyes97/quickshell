import QtQuick
import ".."

// Botón genérico de la barra: fondo redondeado que se resalta en hover
// o cuando su popup asociado está abierto. El contenido (icono, texto,
// o ambos) se pasa como hijos.
Rectangle {
    id: btn
    default property alias content: row.data
    property bool active: false
    property alias spacing: row.spacing
    property alias containsMouse: mouse.containsMouse

    signal clicked
    signal rightClicked

    implicitHeight: Theme.barHeight - 10
    implicitWidth: row.implicitWidth + 16
    radius: Theme.radius - 4
    color: btn.active ? Theme.activeBg : (mouse.containsMouse ? Theme.hoverBg : "transparent")

    Behavior on color { ColorAnimation { duration: 100 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouseEvent => {
            if (mouseEvent.button === Qt.RightButton)
                btn.rightClicked()
            else
                btn.clicked()
        }
    }
}
