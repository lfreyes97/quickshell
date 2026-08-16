import Quickshell.Hyprland
import QtQuick
import ".."

// Puntitos de workspace de Hyprland, junto al botón de Actividades.
// GNOME no los muestra por defecto, pero Hyprland no tiene "Overview"
// nativo, así que esto sustituye esa función.
Row {
    id: root
    spacing: 6
    property var wsList: Hyprland.workspaces.values

    Repeater {
        model: root.wsList
        delegate: Rectangle {
            id: dot
            required property var modelData
            width: modelData.active ? 16 : 8
            height: 8
            radius: 4
            color: modelData.active ? Theme.accent : Theme.fgDim
            opacity: modelData.active ? 1.0 : 0.6
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Behavior on width { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 120 } }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                // Este Hyprland usa config en Lua: el socket de "dispatch"
                // evalúa el string como código Lua (hl.dispatch(<string>)),
                // no como el clásico "dispatcher arg" — por eso hl.dsp.focus
                // en vez de simplemente "workspace <id>".
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + dot.modelData.id + " })")
            }
        }
    }
}
