import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

// Gestión de la ventana activa (flotante, pin, pseudo-tile, monocle,
// pantalla completa, cerrar, mover de workspace) más un asistente para el
// motor de tiling dwindle (bsp) de Hyprland: preselección de split,
// orientación e intercambio.
//
// Nota sobre la sintaxis: este Hyprland usa config en Lua (hl.*) y el
// socket de "dispatch" evalúa el string recibido como código Lua
// (hl.dispatch(<string>)), no como el clásico "dispatcher arg". Por eso
// todo acá se manda como "hl.dsp.xxx(...)" en vez de "xxx arg" — ver
// https://wiki.hypr.land (config Lua) o probar con `hyprctl repl`.
PopupCard {
    id: popup
    popupName: "windowctl"
    align: "left"
    cardWidth: 320

    property var activeWin: ({})
    property string currentLayout: "dwindle"
    readonly property bool hasWin: popup.activeWin && popup.activeWin.address !== undefined
    readonly property bool isFloating: popup.hasWin && popup.activeWin.floating === true

    // Workspaces que tienen al menos una ventana (para marcarlos con un punto).
    readonly property var occupied: {
        var set = {}
        var ws = Hyprland.workspaces.values
        for (var i = 0; i < ws.length; i++) {
            var w = ws[i]
            if (w.toplevels && w.toplevels.values.length > 0) set[w.id] = true
        }
        return set
    }

    function refreshActive() { activeProc.running = true }
    function refreshLayout() { layoutProc.running = true }
    function refreshAll() { popup.refreshActive(); popup.refreshLayout() }

    // Dispara un dispatcher (sintaxis hl.dsp.*) y refresca el estado poco
    // después, para que los toggles reflejen el nuevo estado real.
    function act(luaDispatcher) {
        Hyprland.dispatch(luaDispatcher)
        settleTimer.restart()
    }
    function toggleFullscreenMode(mode) {
        var cur = popup.hasWin ? popup.activeWin.fullscreen : 0
        var target = (cur === mode) ? 0 : mode
        popup.act("hl.dsp.window.fullscreen_state({ internal = " + target + ", client = " + target + " })")
    }
    function setLayout(name) {
        // hl.config(...) no es un dispatcher: no pasa por Hyprland.dispatch(),
        // se manda vía `hyprctl repl` (equivalente al `keyword` clásico, que
        // esta versión de Hyprland ya no acepta: "can't work with non-legacy
        // parsers").
        popup.currentLayout = name
        Quickshell.execDetached(["hyprctl", "repl", "hl.config({ general = { layout = \"" + name + "\" } })"])
        settleTimer.restart()
    }
    function moveTo(ws) {
        popup.act("hl.dsp.window.move({ workspace = " + ws + " })")
        PopupManager.close()
    }

    onVisibleChanged: if (popup.visible) popup.refreshAll()

    Timer { id: settleTimer; interval: 150; onTriggered: popup.refreshAll() }
    Timer { interval: 1000; running: popup.visible; repeat: true; onTriggered: popup.refreshAll() }

    Process {
        id: activeProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { popup.activeWin = JSON.parse(text) } catch (e) { popup.activeWin = {} }
            }
        }
    }
    Process {
        id: layoutProc
        command: ["hyprctl", "getoption", "general:layout", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { popup.currentLayout = JSON.parse(text).str || "dwindle" } catch (e) {}
            }
        }
    }

    // =================================================================
    // Ventana activa
    // =================================================================
    Rectangle {
        width: parent.width
        implicitHeight: 60
        radius: Theme.radius - 2
        color: Theme.cardBg

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 12

            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: 10
                color: Theme.cardBg

                IconImage {
                    id: appIcon
                    anchors.centerIn: parent
                    source: popup.hasWin ? Quickshell.iconPath(popup.activeWin.class, true) : ""
                    implicitSize: 28
                    visible: status === Image.Ready
                }
                SymbolicIcon {
                    visible: !appIcon.visible
                    anchors.centerIn: parent
                    name: "view-app-grid-symbolic"
                    size: 18
                    tint: Theme.fgDim
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: popup.hasWin ? popup.activeWin.title : "Sin ventana activa"
                    color: popup.hasWin ? Theme.fg : Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: popup.hasWin
                        ? popup.activeWin.class + "  ·  Workspace " + popup.activeWin.workspace.name
                        : "Enfoca una ventana para gestionarla"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }
    }

    // =================================================================
    // Estado de la ventana
    // =================================================================
    GridLayout {
        width: parent.width
        columns: 3
        columnSpacing: 6
        rowSpacing: 6
        enabled: popup.hasWin

        TileButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "focus-windows-symbolic"
            label: "Flotante"
            checked: popup.isFloating
            onClicked: popup.act("hl.dsp.window.float({ action = \"toggle\" })")
        }
        TileButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            // Pin solo tiene sentido en ventanas flotantes.
            enabled: popup.isFloating
            icon: "view-pin-symbolic"
            label: "Fijar encima"
            checked: popup.hasWin && popup.activeWin.pinned === true
            onClicked: popup.act("hl.dsp.window.pin()")
        }
        TileButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            enabled: !popup.isFloating
            icon: "view-dual-symbolic"
            label: "Pseudo-tile"
            checked: popup.hasWin && popup.activeWin.pseudo === true
            onClicked: popup.act("hl.dsp.window.pseudo()")
        }
        TileButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "zoom-fit-best-symbolic"
            label: "Monocle"
            checked: popup.hasWin && popup.activeWin.fullscreen === 1
            onClicked: popup.toggleFullscreenMode(1)
        }
        TileButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "view-fullscreen-symbolic"
            label: "Completa"
            checked: popup.hasWin && popup.activeWin.fullscreen === 2
            onClicked: popup.toggleFullscreenMode(2)
        }
        TileButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "window-close-symbolic"
            label: "Cerrar"
            tint: Theme.danger
            onClicked: { Hyprland.dispatch("hl.dsp.window.close()"); PopupManager.close() }
        }
    }

    // =================================================================
    // Motor de tiling
    // =================================================================
    SectionLabel { text: "Disposición" }

    SegmentedControl {
        width: parent.width
        model: [
            { label: "Dwindle (bsp)", value: "dwindle" },
            { label: "Master", value: "master" }
        ]
        current: popup.currentLayout
        onSelected: value => popup.setLayout(value)
    }

    // ---- Asistente dwindle: preselección (d-pad) + split ----
    RowLayout {
        visible: popup.currentLayout === "dwindle"
        width: parent.width
        spacing: 10

        GridLayout {
            columns: 3
            columnSpacing: 3
            rowSpacing: 3

            Item { implicitWidth: 32; implicitHeight: 32 }
            ChipButton { icon: "pan-up-symbolic"; onClicked: popup.act("hl.dsp.layout(\"preselect u\")") }
            Item { implicitWidth: 32; implicitHeight: 32 }
            ChipButton { icon: "pan-start-symbolic"; onClicked: popup.act("hl.dsp.layout(\"preselect l\")") }
            Item {
                implicitWidth: 32
                implicitHeight: 32
                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 3
                    color: "transparent"
                    border.width: 1.5
                    border.color: Theme.fgDim
                }
            }
            ChipButton { icon: "pan-end-symbolic"; onClicked: popup.act("hl.dsp.layout(\"preselect r\")") }
            Item { implicitWidth: 32; implicitHeight: 32 }
            ChipButton { icon: "pan-down-symbolic"; onClicked: popup.act("hl.dsp.layout(\"preselect d\")") }
            Item { implicitWidth: 32; implicitHeight: 32 }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                text: "Preselecciona dónde se abrirá la próxima ventana"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radius - 6
                color: Theme.cardBg
                ActionRow {
                    anchors.fill: parent
                    icon: "object-flip-horizontal-symbolic"
                    label: "Rotar split"
                    onClicked: popup.act("hl.dsp.layout(\"togglesplit\")")
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radius - 6
                color: Theme.cardBg
                ActionRow {
                    anchors.fill: parent
                    icon: "view-refresh-symbolic"
                    label: "Intercambiar"
                    onClicked: popup.act("hl.dsp.layout(\"swapsplit\")")
                }
            }
        }
    }

    // =================================================================
    // Mover a workspace
    // =================================================================
    SectionLabel {
        text: "Mover a workspace"
        opacity: popup.hasWin ? 1 : 0.4
    }

    GridLayout {
        width: parent.width
        columns: 5
        columnSpacing: 6
        rowSpacing: 6
        enabled: popup.hasWin
        opacity: popup.hasWin ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: 100 } }

        Repeater {
            model: 10
            delegate: ChipButton {
                required property int index
                readonly property int wsId: index + 1
                readonly property bool here: popup.hasWin && popup.activeWin.workspace && popup.activeWin.workspace.id === wsId
                Layout.fillWidth: true
                text: "" + (wsId % 10)
                selected: here
                enabled: !here
                dot: popup.occupied[wsId] === true
                onClicked: popup.moveTo(wsId)
            }
        }
    }
}
