import QtQuick
import QtQuick.Layouts
import ".."

// Una notificación individual: usada tanto en el historial (calendario)
// como en los banners emergentes (NotificationToasts).
Item {
    id: root
    property string appName: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property string image: ""
    property var time: null
    signal dismissRequested

    implicitHeight: layout.implicitHeight + 16
    implicitWidth: 280

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius - 6
        color: Theme.withAlpha(Theme.dark ? "#ffffff" : "#000000", Theme.dark ? 0.06 : 0.04)
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        SymbolicIcon {
            name: root.appIcon.length > 0 ? root.appIcon : "notification-symbolic"
            Layout.alignment: Qt.AlignTop
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.appName
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    Layout.fillWidth: true
                }
                Text {
                    visible: root.time !== null
                    text: root.time ? Qt.formatTime(root.time, "hh:mm") : ""
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
            Text {
                text: root.summary
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Text {
                visible: root.body.length > 0
                text: root.body
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        BarButton {
            spacing: 0
            implicitWidth: 22
            implicitHeight: 22
            Layout.alignment: Qt.AlignTop
            SymbolicIcon { name: "window-close-symbolic"; size: 11; tint: Theme.fgDim }
            onClicked: root.dismissRequested()
        }
    }
}
