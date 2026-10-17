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
    // Ruta directa a un SVG propio (assets/), opcional, cuando el icono no
    // existe en el tema del sistema.
    property url source: ""
    property color tint: Theme.fg
    property real size: Theme.iconSize

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: img
        anchors.fill: parent
        implicitSize: root.size
        source: root.source != "" ? root.source
            : root.name ? Quickshell.iconPath(root.name, true) : ""
        visible: false
    }

    MultiEffect {
        anchors.fill: img
        source: img
        // Los SVG simbólicos usan fill="currentColor" y Qt los rasteriza
        // en negro; primero se blanquean con brightness y recién ahí la
        // colorization aplica el tinte. Sin el brightness el icono queda
        // negro (invisible sobre la barra oscura).
        brightness: 1.0
        colorization: 1.0
        colorizationColor: root.tint
    }
}
