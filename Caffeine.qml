pragma Singleton
import QtQuick

// "Caffeine": mientras está activo inhibe el idle de la sesión (pantalla
// encendida, sin bloqueo ni suspensión). Aquí solo vive el estado; el
// IdleInhibitor real está en Bar.qml, porque el protocolo de Wayland
// (zwp_idle_inhibitor_v1) liga el inhibidor a una superficie visible y un
// singleton no tiene ventana. Se controla desde Quick Settings.
QtObject {
    id: root
    property bool enabled: false
}
