import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import ".."

// Icono simbólico de Adwaita (mono, recoloreable) usando el tema de iconos
// del sistema a través de Quickshell.iconPath().
Item {
    id: root
    property string name: ""
    property color tint: Theme.fg
    property real size: Theme.iconSize

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: img
        anchors.fill: parent
        implicitSize: root.size
        source: root.name ? Quickshell.iconPath(root.name, true) : ""
        visible: false
    }

    MultiEffect {
        anchors.fill: img
        source: img
        colorization: 1.0
        colorizationColor: root.tint
        brightness: 0
    }
}
