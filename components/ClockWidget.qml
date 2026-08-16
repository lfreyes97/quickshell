import QtQuick
import ".."

BarButton {
    id: clock
    property var time: new Date()
    active: PopupManager.current === "calendar"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.time = new Date()
    }

    function pad(n) { return n < 10 ? "0" + n : "" + n }

    readonly property var weekdays: ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"]
    readonly property var months: ["ene", "feb", "mar", "abr", "may", "jun",
                                    "jul", "ago", "sep", "oct", "nov", "dic"]

    Text {
        text: clock.weekdays[clock.time.getDay()] + " " + clock.time.getDate() + " " + clock.months[clock.time.getMonth()]
             + "  " + clock.pad(clock.time.getHours()) + ":" + clock.pad(clock.time.getMinutes())
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: Theme.fg
    }

    onClicked: PopupManager.open("calendar")
}
