pragma Singleton
import Quickshell
import Quickshell.Wayland
import QtQuick

// "Caffeine": mientras está activo inhibe el idle de la sesión (pantalla
// encendida, sin bloqueo ni suspensión). hypridle respeta el inhibidor
// zwp_idle_inhibitor_v1 de Wayland. Se controla desde Quick Settings.
QtObject {
    id: root
    property bool enabled: false

    property IdleInhibitor inhibitor: IdleInhibitor {
        enabled: root.enabled
    }
}
