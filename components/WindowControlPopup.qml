import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

// Gestión de la ventana activa (flotante, monocle, pantalla completa,
// cerrar, pseudo-tile, mover de workspace) más un asistente para el motor
// de tiling dwindle (bsp) de Hyprland: preselección de split, orientación
// e intercambio.
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
    cardWidth: 290

    property var activeWin: ({})
    property string currentLayout: "dwindle"
    readonly property bool hasWin: popup.activeWin && popup.activeWin.address !== undefined

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

    // ---- Ventana activa ----
    RowLayout {
        width: parent.width
        spacing: 8
        IconImage {
            source: popup.hasWin ? Quickshell.iconPath(popup.activeWin.class, false) : ""
            implicitSize: 22
            visible: status === Image.Ready
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: popup.hasWin ? popup.activeWin.title : "Sin ventana activa"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: popup.hasWin
                text: popup.hasWin ? popup.activeWin.class + " · ws " + popup.activeWin.workspace.name : ""
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    // ---- Estado de la ventana ----
    ToggleRow {
        width: parent.width
        enabled: popup.hasWin
        icon: "window-restore-symbolic"
        label: "Flotante"
        checked: popup.hasWin && popup.activeWin.floating === true
        onToggled: popup.act("hl.dsp.window.float({ action = \"toggle\" })")
    }
    ToggleRow {
        width: parent.width
        visible: popup.hasWin && popup.activeWin.floating === true
        icon: "view-pin-symbolic"
        label: "Fijada encima (pin)"
        checked: popup.hasWin && popup.activeWin.pinned === true
        onToggled: popup.act("hl.dsp.window.pin()")
    }
    ToggleRow {
        width: parent.width
        enabled: popup.hasWin
        icon: "window-maximize-symbolic"
        label: "Maximizar (monocle)"
        checked: popup.hasWin && popup.activeWin.fullscreen === 1
        onToggled: popup.toggleFullscreenMode(1)
    }
    ToggleRow {
        width: parent.width
        enabled: popup.hasWin
        icon: "view-fullscreen-symbolic"
        label: "Pantalla completa"
        checked: popup.hasWin && popup.activeWin.fullscreen === 2
        onToggled: popup.toggleFullscreenMode(2)
    }
    ActionRow {
        width: parent.width
        enabled: popup.hasWin
        icon: "view-dual-symbolic"
        label: "Pseudo-tile"
        onClicked: popup.act("hl.dsp.window.pseudo()")
    }
    ActionRow {
        width: parent.width
        enabled: popup.hasWin
        icon: "window-close-symbolic"
        label: "Cerrar ventana"
        tint: Theme.danger
        onClicked: { Hyprland.dispatch("hl.dsp.window.close()"); PopupManager.close() }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    // ---- Motor de tiling ----
    Text {
        text: "Motor de tiling"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }
    Row {
        width: parent.width
        spacing: 6
        ChipButton { text: "Dwindle (bsp)"; selected: popup.currentLayout === "dwindle"; onClicked: popup.setLayout("dwindle") }
        ChipButton { text: "Master"; selected: popup.currentLayout === "master"; onClicked: popup.setLayout("master") }
    }

    // ---- Asistente dwindle (bsp) ----
    Text {
        visible: popup.currentLayout === "dwindle"
        text: "Asistente dwindle (bsp)"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }
    Text {
        width: parent.width
        visible: popup.currentLayout === "dwindle"
        text: "Preseleccioná el lado por donde entra la próxima ventana:"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: 10
        wrapMode: Text.WordWrap
    }
    Row {
        width: parent.width
        visible: popup.currentLayout === "dwindle"
        spacing: 6
        ChipButton { icon: "pan-start-symbolic"; onClicked: popup.act("hl.dsp.layout(\"preselect l\")") }
        ChipButton { icon: "pan-up-symbolic"; onClicked: popup.act("hl.dsp.layout(\"preselect u\")") }
        ChipButton { icon: "pan-down-symbolic"; onClicked: popup.act("hl.dsp.layout(\"preselect d\")") }
        ChipButton { icon: "pan-end-symbolic"; onClicked: popup.act("hl.dsp.layout(\"preselect r\")") }
    }
    ActionRow {
        width: parent.width
        visible: popup.currentLayout === "dwindle"
        icon: "object-flip-horizontal-symbolic"
        label: "Cambiar orientación del split"
        onClicked: popup.act("hl.dsp.layout(\"togglesplit\")")
    }
    ActionRow {
        width: parent.width
        visible: popup.currentLayout === "dwindle"
        icon: "view-refresh-symbolic"
        label: "Intercambiar split"
        onClicked: popup.act("hl.dsp.layout(\"swapsplit\")")
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    // ---- Mover a workspace ----
    Text {
        opacity: popup.hasWin ? 1 : 0.4
        text: "Mover ventana a workspace"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }
    Grid {
        width: parent.width
        enabled: popup.hasWin
        opacity: popup.hasWin ? 1 : 0.4
        columns: 5
        spacing: 6
        Behavior on opacity { NumberAnimation { duration: 100 } }
        Repeater {
            model: 10
            delegate: ChipButton {
                required property int index
                readonly property int wsId: index + 1
                readonly property bool here: popup.hasWin && popup.activeWin.workspace && popup.activeWin.workspace.id === wsId
                text: "" + ((index + 1) % 10)
                selected: here
                enabled: !here
                onClicked: popup.moveTo(wsId)
            }
        }
    }
}
