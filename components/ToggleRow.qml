import QtQuick
import QtQuick.Layouts
import ".."

// Fila con icono + etiqueta + interruptor, para Wi-Fi / Bluetooth / No molestar.
Item {
    id: root
    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool checked: false
    signal toggled(bool value)

    implicitHeight: 40
    opacity: root.enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: 100 } }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        SymbolicIcon { name: root.icon; Layout.alignment: Qt.AlignVCenter }

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
