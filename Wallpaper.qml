pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Fondo de pantalla (awww): recuerda el último elegido en un archivo de
// estado y lo re-aplica al iniciar la shell, levantando awww-daemon si
// no está corriendo.
QtObject {
    id: root
    property string current: ""

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME")
        || ((Quickshell.env("HOME") || "/home/luis") + "/.local/state")) + "/quickshell"

    function apply(path) {
        if (path.length === 0) return
        root.current = path
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$1\"; printf '%s' \"$2\" > \"$1/wallpaper\"; " +
            "awww query >/dev/null 2>&1 || setsid -f awww-daemon >/dev/null 2>&1; " +
            "for i in 1 2 3 4 5 6 7 8 9 10; do " +
            "awww img \"$2\" --transition-type simple --transition-duration 1 >/dev/null 2>&1 && exit 0; " +
            "sleep 0.3; done",
            "sh", root.stateDir, path])
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
