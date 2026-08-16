import Quickshell
import Quickshell.Io
import QtQuick
import ".."

// Selector de fondo de pantalla: lista las imágenes de ~/Pictures/Wallpapers
// y las aplica con awww (awww-daemon arranca solo, ver
// hypr/modules/autostart.lua).
PopupCard {
    id: popup
    popupName: "wallpapers"
    align: "right"
    cardWidth: 320

    readonly property string wallpaperDir: "/home/home/Pictures/Wallpapers"
    property var files: []
    property string current: ""

    function refresh() {
        listProc.running = true
        queryProc.running = true
    }
    onVisibleChanged: if (popup.visible) popup.refresh()

    function apply(path) {
        popup.current = path
        Quickshell.execDetached(["awww", "img", path, "--transition-type", "simple", "--transition-duration", "1"])
    }

    Process {
        id: listProc
        command: ["find", popup.wallpaperDir, "-maxdepth", "1", "-type", "f"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n").filter(l => /\.(png|jpe?g|webp|bmp|gif)$/i.test(l))
                lines.sort()
                popup.files = lines
            }
        }
    }
    Process {
        id: queryProc
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                var m = text.match(/image:\s*(\S+)/)
                popup.current = m ? m[1] : ""
            }
        }
    }

    Text {
        width: parent.width
        text: "Fondo de pantalla"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.Bold
    }

    Text {
        width: parent.width
        visible: popup.files.length === 0
        text: "No hay imágenes en ~/Pictures/Wallpapers todavía."
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }

    Grid {
        width: parent.width
        columns: 3
        spacing: 8

        Repeater {
            model: popup.files
            delegate: Rectangle {
                id: tile
                required property string modelData
                width: (popup.cardWidth - 24 - 16) / 3
                height: width * 9 / 16
                radius: Theme.radius - 8
                clip: true
                color: Theme.hoverBg
                border.width: popup.current === tile.modelData ? 2 : 0
                border.color: Theme.accent

                Image {
                    anchors.fill: parent
                    source: "file://" + tile.modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 240
                    sourceSize.height: 135
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: popup.apply(tile.modelData)
                }
            }
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.border }

    ActionRow {
        width: parent.width
        icon: "folder-symbolic"
        label: "Abrir carpeta de fondos"
        onClicked: { PopupManager.close(); Quickshell.execDetached(["xdg-open", popup.wallpaperDir]) }
    }
}
