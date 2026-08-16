pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Estado compartido de los switchers estilo Alt+Tab (ventanas, orden de
// uso más reciente) y Super+Tab (workspaces, orden numérico). Hyprland
// (hypr/modules/binds.lua) llama a esto en vivo vía
// `quickshell ipc call winswitch|wsswitch next|prev|confirm`, disparado
// por ALT+Tab / SUPER+Tab (repeating) y por soltar ALT / SUPER (release).
QtObject {
    id: switcher

    // TEMP DEBUG: log en /tmp/switcher-debug.log (mismo archivo que
    // hypr/modules/binds.lua) para cazar el bug del swap final.
    function dbg(msg) {
        Quickshell.execDetached(["sh", "-c", "echo \"$(date +%s.%N) QML: " + msg + "\" >> /tmp/switcher-debug.log"])
    }

    // ---- Alt+Tab: ventanas ----
    property bool winActive: false
    property var winList: []
    property int winIndex: 0
    property int winShowDelta: 1
    // El primer "next" dispara un fetch async de `hyprctl clients -j`.
    // Si ALT+Tab se toca y suelta rápido, "confirm"/"cancel" (que llegan
    // por un IPC call aparte, disparado por el release de ALT) pueden
    // llegar ANTES de que ese fetch termine — sin esto, la confirmación
    // se perdía en silencio (winActive todavía era false) y la ventana
    // nunca se enfocaba. Lo encolamos y lo aplicamos apenas llega la lista.
    property string winPendingAction: "" // "" | "confirm" | "cancel"

    function winStep(delta) {
        if (!switcher.winActive) {
            switcher.winShowDelta = delta
            switcher.winPendingAction = ""
            winProc.running = true
            return
        }
        if (switcher.winList.length === 0) return
        switcher.winIndex = (switcher.winIndex + delta + switcher.winList.length) % switcher.winList.length
    }
    function winConfirm() {
        switcher.dbg("winConfirm called, active=" + switcher.winActive + " procRunning=" + winProc.running)
        if (!switcher.winActive) {
            if (winProc.running) switcher.winPendingAction = "confirm"
            return
        }
        switcher._winFinish(true)
    }
    function winCancel() {
        switcher.dbg("winCancel called, active=" + switcher.winActive)
        if (!switcher.winActive) {
            if (winProc.running) switcher.winPendingAction = "cancel"
            return
        }
        switcher._winFinish(false)
    }
    function _winFinish(apply) {
        switcher.dbg("_winFinish apply=" + apply + " listLen=" + switcher.winList.length + " index=" + switcher.winIndex)
        if (apply && switcher.winList.length > 0) {
            var w = switcher.winList[switcher.winIndex]
            switcher.dbg("_winFinish dispatching focus to " + w.address + " (" + w.class + ")")
            Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + w.address + "\" })")
        }
        switcher.winActive = false
        switcher.winPendingAction = ""
    }

    property Process winProc: Process {
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var all = JSON.parse(text).filter(c => !c.hidden)
                    all.sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                    switcher.winList = all
                    switcher.winIndex = all.length > 1 ? (switcher.winShowDelta > 0 ? 1 : all.length - 1) : 0
                    switcher.winActive = all.length > 0
                } catch (e) { switcher.winActive = false }

                if (switcher.winPendingAction === "confirm") switcher._winFinish(true)
                else if (switcher.winPendingAction === "cancel") switcher._winFinish(false)
            }
        }
    }

    property IpcHandler winIpc: IpcHandler {
        target: "winswitch"
        function next(): void { switcher.dbg("winIpc.next"); switcher.winStep(1) }
        function prev(): void { switcher.dbg("winIpc.prev"); switcher.winStep(-1) }
        function confirm(): void { switcher.winConfirm() }
        function cancel(): void { switcher.winCancel() }
    }

    // Red de seguridad: si por lo que sea nunca llega el "confirm" (el
    // release del modificador), no dejar el overlay pegado en pantalla.
    property Timer winTimeout: Timer {
        interval: 8000
        running: switcher.winActive
        onTriggered: switcher.winCancel()
    }

    // ---- Super+Tab: workspaces ----
    property bool wsActive: false
    property var wsList: []
    property int wsIndex: 0

    function wsStep(delta) {
        if (!switcher.wsActive) {
            var all = Hyprland.workspaces.values.filter(w => w.id > 0).slice().sort((a, b) => a.id - b.id)
            if (all.length === 0) return
            var curIdx = 0
            for (var i = 0; i < all.length; i++) if (all[i].active) curIdx = i
            switcher.wsList = all
            switcher.wsIndex = (curIdx + delta + all.length) % all.length
            switcher.wsActive = true
            return
        }
        if (switcher.wsList.length === 0) return
        switcher.wsIndex = (switcher.wsIndex + delta + switcher.wsList.length) % switcher.wsList.length
    }
    function wsConfirm() {
        switcher.dbg("wsConfirm called, active=" + switcher.wsActive + " listLen=" + switcher.wsList.length)
        if (switcher.wsActive && switcher.wsList.length > 0) {
            var w = switcher.wsList[switcher.wsIndex]
            switcher.dbg("wsConfirm dispatching focus to ws " + w.id)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + w.id + " })")
        }
        switcher.wsActive = false
    }
    function wsCancel() { switcher.dbg("wsCancel called"); switcher.wsActive = false }

    property IpcHandler wsIpc: IpcHandler {
        target: "wsswitch"
        function next(): void { switcher.wsStep(1) }
        function prev(): void { switcher.wsStep(-1) }
        function confirm(): void { switcher.wsConfirm() }
        function cancel(): void { switcher.wsCancel() }
    }

    property Timer wsTimeout: Timer {
        interval: 8000
        running: switcher.wsActive
        onTriggered: switcher.wsCancel()
    }
}
