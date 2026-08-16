import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import ".."

// Resumen de estado a la derecha de la barra (red, volumen, batería) que
// abre el panel de Quick Settings, como el indicador de la esquina
// superior derecha de GNOME Shell.
BarButton {
    id: pill
    active: PopupManager.current === "quicksettings"
    spacing: 8

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: pill.battery && pill.battery.isPresent
    readonly property bool charging: pill.hasBattery && pill.battery.state === UPowerDeviceState.Charging

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    property var wifiDevice: null
    function findWifiDevice() {
        var devs = Networking.devices.values
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) { pill.wifiDevice = devs[i]; return }
        }
        pill.wifiDevice = null
    }
    Component.onCompleted: pill.findWifiDevice()
    Timer { interval: 5000; running: true; repeat: true; onTriggered: pill.findWifiDevice() }

    function batteryIcon() {
        if (!pill.hasBattery) return ""
        var pct = pill.battery.percentage * 100
        var step = Math.min(100, Math.max(0, Math.round(pct / 10) * 10))
        return "battery-level-" + step + (pill.charging ? "-charging" : "") + "-symbolic"
    }

    SymbolicIcon {
        name: !Networking.wifiEnabled ? "network-wireless-disabled-symbolic"
            : (pill.wifiDevice && pill.wifiDevice.connected) ? "network-wireless-symbolic" : "network-wireless-signal-none-symbolic"
    }
    SymbolicIcon {
        name: !pill.audio ? "audio-volume-muted-symbolic"
            : pill.audio.muted ? "audio-volume-muted-symbolic"
            : pill.audio.volume > 0.5 ? "audio-volume-high-symbolic"
            : pill.audio.volume > 0 ? "audio-volume-medium-symbolic" : "audio-volume-low-symbolic"
    }
    SymbolicIcon {
        visible: pill.hasBattery
        name: pill.batteryIcon()
    }
    Text {
        visible: pill.hasBattery
        text: Math.round(pill.battery.percentage * 100) + "%"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 11
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    onClicked: PopupManager.open("quicksettings")
}
