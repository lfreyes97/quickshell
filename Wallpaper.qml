pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Fondo de pantalla (awww): recuerda el último elegido en un archivo de
// estado y lo re-aplica al iniciar la shell, levantando awww-daemon si
// no está corriendo. También guarda la transición configurada en el
// popup (efecto, dirección/origen, curva y duración).
QtObject {
    id: root
    property string current: ""

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME")
        || ((Quickshell.env("HOME") || "/home/luis") + "/.local/state")) + "/quickshell"

    // ---- Transición ----
    // Se persiste sola: cada cambio en `transition` se escribe al JSON.
    property JsonAdapter transition: JsonAdapter {
        // fade | wipe | wave | grow | outer | random | none
        property string type: "fade"
        // wipe/wave, en grados: 0 = hacia la izquierda, 90 = hacia abajo…
        property int angle: 45
        // grow/outer: alias de awww (center, top-left, …)
        property string pos: "center"
        property string bezier: ".54,0,.34,.99"
        property real duration: 1.5
    }
    property FileView transitionFile: FileView {
        path: root.stateDir + "/wallpaper-transition.json"
        // La primera vez no existe: se crea con los valores por defecto.
        printErrors: false
        adapter: root.transition
        // Bloqueante: restore() al iniciar ya necesita la transición guardada.
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", root.stateDir])
                writeAdapter()
            }
        }
    }

    function transitionArgs() {
        var t = root.transition
        var a = ["--transition-type", t.type, "--transition-fps", "60"]
        if (t.type !== "none")
            a.push("--transition-duration", String(t.duration), "--transition-bezier", t.bezier)
        if (t.type === "wipe" || t.type === "wave")
            a.push("--transition-angle", String(t.angle))
        if (t.type === "grow" || t.type === "outer")
            a.push("--transition-pos", t.pos)
        return a
    }

    // $1 = stateDir, $2 = imagen, $3 = color para "probar" (vacío si no),
    // resto = argumentos de transición para `awww img`.
    readonly property string applyScript:
        "d=\"$1\"; p=\"$2\"; c=\"$3\"; shift 3; " +
        "mkdir -p \"$d\"; printf '%s' \"$p\" > \"$d/wallpaper\"; " +
        "awww query >/dev/null 2>&1 || setsid -f awww-daemon >/dev/null 2>&1; " +
        "for i in 1 2 3 4 5 6 7 8 9 10; do " +
        "if [ -n \"$c\" ]; then awww clear \"$c\" >/dev/null 2>&1 && sleep 0.2; fi; " +
        "awww img \"$p\" \"$@\" >/dev/null 2>&1 && exit 0; " +
        "sleep 0.3; done"

    function apply(path) {
        if (path.length === 0) return
        root.current = path
        Quickshell.execDetached(["sh", "-c", root.applyScript, "sh", root.stateDir, path, ""]
            .concat(root.transitionArgs()))
    }

    // Vuelve a pintar el fondo actual desde un color liso para ver la
    // transición configurada (re-aplicar la misma imagen no se nota).
    function preview(color) {
        if (root.current.length === 0) return
        Quickshell.execDetached(["sh", "-c", root.applyScript, "sh", root.stateDir, root.current, color]
            .concat(root.transitionArgs()))
    }

    // Re-aplica el último fondo guardado; la llama shell.qml al iniciar.
    function restore() { restoreProc.running = true }

    property Process restoreProc: Process {
        command: ["sh", "-c", "cat \"" + root.stateDir + "/wallpaper\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim()
                if (p.length > 0) root.apply(p)
            }
        }
    }
}
