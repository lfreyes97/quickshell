import Quickshell
import Quickshell.Wayland
import ".."
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar
    property var modelData

    WlrLayershell.namespace: "quickshell:bar"
    anchors { top: true; left: true; right: true }
    exclusiveZone: Theme.barHeight
    focusable: false
    color: "transparent"

    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.barBg

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            ActivitiesButton {}
            OverviewButton {}
            WindowMenuButton {}

            Item { Layout.fillWidth: true }

            ClockWidget {}

            Item { Layout.fillWidth: true }

            Tray {}
            WallpaperButton {}
            StatusPill {}
        }
    }

    DismissLayer {}
    CalendarPopup {}
    QuickSettingsPanel {}
    WindowControlPopup {}
    OverviewPopup {}
    AltTabPopup {}
    SuperTabPopup {}
    WallpaperPopup {}
    NotificationToasts {}
}
