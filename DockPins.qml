pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Apps fijadas en el dock (ids de .desktop, en orden). Se guardan en
// $XDG_STATE_HOME/quickshell/dock-pinned.json, igual que el fondo de
// pantalla; si el archivo no existe se usan unos favoritos por defecto
// (los que no estén instalados simplemente no se muestran).
QtObject {
    id: root
    property var pinned: []

    readonly property var defaults: [
        "google-chrome", "firefox", "org.gnome.Nautilus", "kitty", "code", "codium"
    ]
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME")
        || ((Quickshell.env("HOME") || "/home/luis") + "/.local/state")) + "/quickshell"

    function isPinned(id) { return root.pinned.indexOf(id) !== -1 }
    function pin(id) {
        if (!id || isPinned(id)) return
        root.pinned = root.pinned.concat([id])
        save()
    }
    function unpin(id) {
        root.pinned = root.pinned.filter(p => p !== id)
        save()
    }
    function save() {
        Quickshell.execDetached(["mkdir", "-p", root.stateDir])
        file.setText(JSON.stringify(root.pinned))
    }

    property FileView file: FileView {
        path: root.stateDir + "/dock-pinned.json"
        // La primera vez el archivo no existe: no es un error.
        printErrors: false
        onLoaded: {
            try {
                var list = JSON.parse(text())
                root.pinned = Array.isArray(list) ? list : root.defaults
            } catch (e) { root.pinned = root.defaults }
        }
        onLoadFailed: root.pinned = root.defaults
    }
}
