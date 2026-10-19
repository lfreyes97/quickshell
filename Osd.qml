pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Estado del OSD (indicador en pantalla) de volumen y brillo, como el de
// GNOME. No escucha teclas: vigila los valores reales (Pipewire y sysfs),
// así que aparece igual si el cambio viene de las teclas multimedia de
// hyprland.lua, de wpctl/brightnessctl en una terminal o de otra app.
// Lo dibuja components/OsdPopup.qml.
QtObject {
    id: osd

    // "volume" | "brightness"
    property string kind: "volume"
    property real value: 0
    property bool muted: false
    property bool shown: false

    // Los primeros valores al arrancar la shell no son cambios del usuario.
    property bool ready: false
    property Timer readyTimer: Timer { interval: 1500; running: true; onTriggered: osd.ready = true }
    property Timer hideTimer: Timer { interval: 1500; onTriggered: osd.shown = false }

    function show(kind, value, muted) {
        osd.kind = kind
        osd.value = value
        osd.muted = muted
        // Con los ajustes rápidos abiertos el slider ya muestra el valor.
        if (!osd.ready || PopupManager.current === "quicksettings") return
        osd.shown = true
        osd.hideTimer.restart()
    }

    // ---- Volumen ----
    readonly property var sink: Pipewire.defaultAudioSink
    property PwObjectTracker tracker: PwObjectTracker { objects: osd.sink ? [osd.sink] : [] }
    property Connections audioWatch: Connections {
        target: osd.sink ? osd.sink.audio : null
        function onVolumeChanged() { osd.show("volume", osd.sink.audio.volume, osd.sink.audio.muted) }
        function onMutedChanged() { osd.show("volume", osd.sink.audio.volume, osd.sink.audio.muted) }
    }

    // ---- Brillo ----
    // Escribir el archivo de sysfs (brightnessctl) dispara inotify, así que
    // FileView con watchChanges alcanza; no hace falta sondear.
    property string backlight: ""
    property real maxBrightness: 0
    property Process findBacklight: Process {
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -e \"$d/brightness\" ] && echo \"$d\" && break; done"]
        running: true
        stdout: StdioCollector { onStreamFinished: osd.backlight = text.trim() }
    }
    property FileView maxFile: FileView {
        path: osd.backlight ? osd.backlight + "/max_brightness" : ""
        onLoaded: osd.maxBrightness = parseInt(text())
    }
    property FileView brightnessFile: FileView {
        path: osd.backlight ? osd.backlight + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var cur = parseInt(text())
            if (osd.maxBrightness > 0 && !isNaN(cur)) osd.show("brightness", cur / osd.maxBrightness, false)
        }
    }
}
