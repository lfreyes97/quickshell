import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."

// Panel de captura de pantalla al estilo GNOME: abajo al centro, con el
// modo (región, pantalla o ventana), retardo, puntero y el botón de
// disparo. Se abre desde Quick Settings o por IPC
// (`qs ipc call screenshot toggle`, p. ej. con la tecla Print).
//
// La captura en sí la hace un script (slurp + grim): se guarda en
// Imágenes/Capturas, se copia al portapapeles y avisa con una
// notificación. Enter captura, Esc cierra, ←/→ cambian de modo.
PanelWindow {
    id: root
    WlrLayershell.namespace: "quickshell:popup:screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: PopupManager.current === "screenshot"
    anchors.bottom: true
    margins.bottom: 40
    exclusiveZone: 0
    color: "transparent"
    implicitWidth: 420
    implicitHeight: card.implicitHeight

    // Preferencias: se mantienen mientras corre la shell.
    property string mode: "region" // region | screen | window
    property int delay: 0
    property bool showPointer: false

    readonly property var modes: [
        { value: "region", label: "Región", icon: "edit-select-all-symbolic" },
        { value: "screen", label: "Pantalla", icon: "video-display-symbolic" },
        { value: "window", label: "Ventana", icon: "focus-windows-symbolic" }
    ]
    readonly property string hint: root.mode === "region" ? "Arrastrá para elegir el área, o hacé clic para el monitor entero"
        : root.mode === "window" ? "Después vas a hacer clic en la ventana"
        : "Captura el monitor " + (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "actual")

    function cycleMode(delta) {
        var i = root.modes.findIndex(m => m.value === root.mode)
        root.mode = root.modes[(i + delta + root.modes.length) % root.modes.length].value
    }

    // $1 modo, $2 retardo (s), $3 puntero (0/1), $4 monitor, $5 acento (rrggbb)
    readonly property string script:
        "mode=$1; delay=$2; cursor=$3; mon=$4; acc=$5; " +
        // Deja que el panel desaparezca antes de seleccionar/capturar.
        "sleep 0.3; " +
        "sl() { slurp -c \"${acc}ff\" -s \"${acc}33\" -b 00000055 -w 2 \"$@\"; }; " +
        "case \"$mode\" in " +
        // -o: un clic sin arrastrar toma el monitor entero en vez de un punto.
        "  region) g=$(sl -d -o) || exit 0 ;; " +
        "  window) ws=$(hyprctl monitors -j | jq -c '[.[].activeWorkspace.id]'); " +
        "    g=$(hyprctl clients -j | jq -r --argjson ws \"$ws\" " +
        "      '.[] | select(.hidden | not) | select(.workspace.id as $w | $ws | index($w)) " +
        "       | \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"' | sl -r) || exit 0 ;; " +
        "esac; " +
        "[ \"$delay\" -gt 0 ] && sleep \"$delay\"; " +
        ". \"${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs\" 2>/dev/null; " +
        "d=\"${XDG_PICTURES_DIR:-$HOME/Pictures}/Capturas\"; mkdir -p \"$d\"; " +
        "f=\"$d/Captura_$(date +%Y-%m-%d_%H-%M-%S).png\"; " +
        "c=; [ \"$cursor\" = 1 ] && c=-c; " +
        "if [ \"$mode\" = screen ]; then grim $c -o \"$mon\" \"$f\"; else grim $c -g \"$g\" \"$f\"; fi && " +
        "wl-copy < \"$f\" && " +
        "notify-send -a 'Captura de pantalla' -i \"$f\" 'Captura guardada' 'También se copió al portapapeles'"

    function capture() {
        var mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        var acc = String(Theme.accent).replace("#", "").slice(-6)
        PopupManager.close()
        Quickshell.execDetached(["sh", "-c", root.script, "sh",
            root.mode, String(root.delay), root.showPointer ? "1" : "0", mon, acc])
    }

    onVisibleChanged: if (visible) { card.opacity = 0; card.y = 6; openAnim.restart(); keys.forceActiveFocus() }
    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: card; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "y"; to: 0; duration: 180; easing.type: Easing.OutCubic }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape: PopupManager.close(); break
            case Qt.Key_Return:
            case Qt.Key_Enter: root.capture(); break
            case Qt.Key_Left: root.cycleMode(-1); break
            case Qt.Key_Right: root.cycleMode(1); break
            default: return
            }
            event.accepted = true
        }
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 24
        height: implicitHeight
        radius: Theme.radius
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.border

        Column {
            id: col
            anchors { fill: parent; margins: 12 }
            spacing: 10

            // ---- Cabecera ----
            RowLayout {
                width: parent.width
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    text: "Captura de pantalla"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
                IconButton {
                    icon: "window-close-symbolic"
                    flat: true
                    onClicked: PopupManager.close()
                }
            }

            // ---- Modo ----
            Row {
                width: parent.width
                spacing: 8
                Repeater {
                    model: root.modes
                    delegate: TileButton {
                        required property var modelData
                        width: (col.width - 2 * 8) / 3
                        implicitHeight: 72
                        icon: modelData.icon
                        label: modelData.label
                        checked: root.mode === modelData.value
                        onClicked: root.mode = modelData.value
                    }
                }
            }
            Text {
                width: parent.width
                leftPadding: 4
                text: root.hint
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            // ---- Opciones ----
            SectionLabel { text: "Retardo" }
            RowLayout {
                width: parent.width
                spacing: 8
                SegmentedControl {
                    Layout.fillWidth: true
                    model: [
                        { label: "No", value: "0" },
                        { label: "3 s", value: "3" },
                        { label: "5 s", value: "5" },
                        { label: "10 s", value: "10" }
                    ]
                    current: String(root.delay)
                    onSelected: value => root.delay = parseInt(value)
                }
                ChipButton {
                    icon: "input-mouse-symbolic"
                    text: "Puntero"
                    selected: root.showPointer
                    onClicked: root.showPointer = !root.showPointer
                }
            }

            // ---- Disparo ----
            Item {
                width: parent.width
                height: 64

                Rectangle {
                    id: shutter
                    anchors.centerIn: parent
                    width: 56
                    height: 56
                    radius: width / 2
                    color: "transparent"
                    border.width: 3
                    border.color: shutterMouse.containsMouse ? Theme.accentHover : Theme.accent
                    scale: shutterMouse.pressed ? 0.94 : 1
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        radius: width / 2
                        color: shutterMouse.containsMouse ? Theme.accentHover : Theme.accent
                        Behavior on color { ColorAnimation { duration: 100 } }
                        SymbolicIcon {
                            anchors.centerIn: parent
                            name: "camera-photo-symbolic"
                            size: 18
                            tint: Theme.accentFg
                        }
                    }
                    MouseArea {
                        id: shutterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.capture()
                    }
                }

                Text {
                    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    text: "Enter para capturar\nEsc para cerrar"
                    horizontalAlignment: Text.AlignRight
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    lineHeight: 1.2
                }
            }
        }
    }
}
