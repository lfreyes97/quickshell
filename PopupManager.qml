pragma Singleton
import QtQuick
import Quickshell.Io

// Controla qué popup de la barra está abierto: "calendar", "quicksettings" o "".
// Solo puede haber uno abierto a la vez, como en GNOME Shell.
QtObject {
    id: mgr
    property string current: ""
    function open(name) { mgr.current = (mgr.current === name) ? "" : name }
    function close() { mgr.current = "" }

    // Para atajos de Hyprland, p. ej. Super → `qs ipc call overview toggle`.
    property IpcHandler overviewIpc: IpcHandler {
        target: "overview"
        function toggle(): void { mgr.open("overview") }
        function open(): void { mgr.current = "overview" }
        function close(): void { if (mgr.current === "overview") mgr.close() }
    }
}
