import QtQuick
import QtQuick.Layouts
import ".."

// Fila de slider estilo GNOME Quick Settings (icono + barra arrastrable).
Item {
    id: root
    property string icon: ""
    property real value: 0 // 0..1
    signal valueEdited(real v)

    implicitHeight: 32

    function setFromX(x, w) {
        var v = Math.max(0, Math.min(1, x / w))
        root.value = v
        root.valueEdited(v)
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        SymbolicIcon {
            name: root.icon
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 20

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: Theme.trackBg
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: Math.max(6, parent.width * Math.min(1, Math.max(0, root.value)))
                height: 6
                radius: 3
                color: Theme.accent
            }
            MouseArea {
                anchors.fill: parent
                onPressed: mouse => root.setFromX(mouse.x, track.width)
                onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x, track.width) }
            }
        }
    }
}
