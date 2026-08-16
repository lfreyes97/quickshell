import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import ".."

// Panel de Quick Settings, como el que abre GNOME al hacer click en los
// indicadores de la derecha: redes, bluetooth, no molestar, volumen,
// brillo y el menú de energía, todo en un solo lugar.
PopupCard {
    id: popup
    popupName: "quicksettings"
    align: "right"
    cardWidth: 300

    property var wifiDevice: null
    property string wifiNetworkName: ""
    function findWifiDevice() {
        popup.wifiNetworkName = ""
        var devs = Networking.devices.values
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) {
                popup.wifiDevice = devs[i]
                var nets = popup.wifiDevice.networks.values
                for (var j = 0; j < nets.length; j++) {
                    if (nets[j].connected) { popup.wifiNetworkName = nets[j].name; break }
                }
                return
            }
        }
        popup.wifiDevice = null
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: popup.findWifiDevice() }

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    property real brightness: 0.5
    function refreshBrightness() { brightnessRead.running = true }
    Process {
        id: brightnessRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(",")
                if (parts.length >= 4) {
                    var pct = parseInt(parts[3].replace("%", ""))
                    if (!isNaN(pct)) popup.brightness = pct / 100
                }
            }
        }
    }
    Component.onCompleted: {
        popup.findWifiDevice()
        popup.refreshBrightness()
    }

    // ---- Wi-Fi / Bluetooth / No molestar ----
    ToggleRow {
        width: parent.width
        icon: Networking.wifiEnabled ? "network-wireless-symbolic" : "network-wireless-disabled-symbolic"
        label: "Wi-Fi"
        sublabel: popup.wifiDevice && popup.wifiDevice.connected ? popup.wifiNetworkName : ""
        checked: Networking.wifiEnabled
        onToggled: value => Networking.wifiEnabled = value
    }
    ToggleRow {
        width: parent.width
        icon: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
        label: "Bluetooth"
        checked: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
        onToggled: value => { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = value }
    }
    ToggleRow {
        width: parent.width
        icon: "notifications-disabled-symbolic"
        label: "No molestar"
        checked: Notifications.dnd
        onToggled: value => Notifications.dnd = value
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    // ---- Volumen / Brillo ----
    SliderRow {
        width: parent.width
        icon: !popup.audio ? "audio-volume-muted-symbolic"
            : popup.audio.muted ? "audio-volume-muted-symbolic"
            : popup.audio.volume > 0.5 ? "audio-volume-high-symbolic"
            : popup.audio.volume > 0 ? "audio-volume-medium-symbolic" : "audio-volume-low-symbolic"
        value: popup.audio ? popup.audio.volume : 0
        onValueEdited: v => Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)])
    }
    SliderRow {
        width: parent.width
        icon: "display-brightness-symbolic"
        value: popup.brightness
        onValueEdited: v => {
            popup.brightness = v
            Quickshell.execDetached(["brightnessctl", "set", Math.round(v * 100) + "%"])
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    // ---- Energía ----
    ActionRow {
        width: parent.width
        icon: "preferences-system-symbolic"
        label: "Configuración"
        onClicked: { PopupManager.close(); Quickshell.execDetached(["gnome-control-center"]) }
    }
    ActionRow {
        width: parent.width
        icon: "system-lock-screen-symbolic"
        label: "Bloquear"
        onClicked: { PopupManager.close(); Quickshell.execDetached(["hyprlock"]) }
    }
    ActionRow {
        width: parent.width
        icon: "weather-clear-night-symbolic"
        label: "Suspender"
        onClicked: { PopupManager.close(); Quickshell.execDetached(["systemctl", "suspend"]) }
    }
    ActionRow {
        width: parent.width
        icon: "system-reboot-symbolic"
        label: "Reiniciar"
        onClicked: { PopupManager.close(); Quickshell.execDetached(["systemctl", "reboot"]) }
    }
    ActionRow {
        width: parent.width
        icon: "system-log-out-symbolic"
        label: "Cerrar sesión"
        onClicked: { PopupManager.close(); Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
    }
    ActionRow {
        width: parent.width
        icon: "system-shutdown-symbolic"
        label: "Apagar"
        tint: Theme.danger
        onClicked: { PopupManager.close(); Quickshell.execDetached(["systemctl", "poweroff"]) }
    }
}
