import QtQuick
import QtQuick.Layouts
import ".."

// Fila con icono + etiqueta + interruptor, para Wi-Fi / Bluetooth / No molestar.
Item {
    id: root
    property string icon: ""
    property url iconSource: ""
    property string label: ""
    property string sublabel: ""
    property bool checked: false
    signal toggled(bool value)

    implicitHeight: 40
    opacity: root.enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: 100 } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius - 6
        color: hover.hovered ? Theme.hoverBg : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    // HoverHandler en vez de MouseArea: sigue marcando hover aunque el
    // puntero esté sobre el switch (que tiene su propio MouseArea).
    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled(!root.checked)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        SymbolicIcon { name: root.icon; source: root.iconSource; Layout.alignment: Qt.AlignVCenter }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                text: root.label
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Text {
                visible: root.sublabel.length > 0
                text: root.sublabel
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        ToggleSwitch {
            checked: root.checked
            onToggled: value => root.toggled(value)
        }
    }
}
