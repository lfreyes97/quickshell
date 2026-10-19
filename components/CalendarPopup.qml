import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

// Panel combinado de calendario + notificaciones, como el que abre GNOME
// Shell al hacer click en la hora.
PopupCard {
    id: popup
    popupName: "calendar"
    align: "center"
    cardWidth: 300

    Text {
        width: parent.width
        text: {
            var now = new Date()
            var wd = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
            var d = ["enero", "febrero", "marzo", "abril", "mayo", "junio",
                     "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
            return wd[(now.getDay() + 6) % 7] + ", " + now.getDate() + " de " + d[now.getMonth()]
        }
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.Bold
        color: Theme.fg
        horizontalAlignment: Text.AlignHCenter
    }

    RowLayout {
        width: parent.width
        spacing: 4

        BarButton {
            spacing: 0
            SymbolicIcon { name: "pan-start-symbolic"; size: 12 }
            onClicked: cal.prevMonth()
        }
        Text {
            Layout.fillWidth: true
            text: cal.monthLabel
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Theme.fg
            horizontalAlignment: Text.AlignHCenter
        }
        BarButton {
            spacing: 0
            SymbolicIcon { name: "pan-end-symbolic"; size: 12 }
            onClicked: cal.nextMonth()
        }
    }

    Rectangle {
        width: parent.width
        height: 224
        color: "transparent"
        Calendar { id: cal; anchors.fill: parent }
    }

    MediaPlayer { width: parent.width }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    RowLayout {
        width: parent.width
        Text {
            text: "Notificaciones"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.fg
            Layout.fillWidth: true
        }
        Text {
            visible: Notifications.history.length > 0
            text: "Limpiar todo"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 11
            MouseArea { anchors.fill: parent; onClicked: Notifications.clear() }
        }
    }

    Text {
        width: parent.width
        visible: Notifications.history.length === 0
        text: "No hay notificaciones"
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
    }

    Item {
        width: parent.width
        height: Math.min(280, notifList.contentHeight)
        visible: Notifications.history.length > 0

        ListView {
            id: notifList
            anchors.fill: parent
            spacing: 6
            clip: true
            model: Notifications.history
            delegate: NotificationRow {
                width: notifList.width
                appName: modelData.appName
                summary: modelData.summary
                body: modelData.body || ""
                appIcon: modelData.appIcon || ""
                time: modelData.time
                onDismissRequested: {
                    var arr = Notifications.history.slice()
                    arr.splice(index, 1)
                    Notifications.history = arr
                }
            }
        }
    }
}
