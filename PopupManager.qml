pragma Singleton
import QtQuick

// Controla qué popup de la barra está abierto: "calendar", "quicksettings" o "".
// Solo puede haber uno abierto a la vez, como en GNOME Shell.
QtObject {
    id: mgr
    property string current: ""
    function open(name) { mgr.current = (mgr.current === name) ? "" : name }
    function close() { mgr.current = "" }
}
