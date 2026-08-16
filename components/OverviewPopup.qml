import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import ".."

// Overview estilo GNOME Activities / Mission Control: mosaico con todos
// los workspaces y sus ventanas (posición y tamaño reales, escalados).
// Click en una ventana la enfoca; click en área vacía cambia de workspace;
// arrastrar una ventana la mueve a otro workspace sin perder el foco actual.
PanelWindow {
    id: overview
    WlrLayershell.namespace: "quickshell:popup:overview"
    WlrLayershell.layer: WlrLayer.Overlay
    visible: PopupManager.current === "overview"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"

    property var clients: []
    property string activeAddress: ""
    property var wsList: Hyprland.workspaces.values.filter(w => w.id > 0)

    function refresh() { clientsProc.running = true; activeProc.running = true }
    function cardAt(px, py) {
        for (var i = 0; i < wsRow.children.length; i++) {
            var c = wsRow.children[i]
            if (c.modelData === undefined) continue
            var cx = wsRow.x + c.x
            var cy = wsRow.y + c.y
            if (px >= cx && px <= cx + c.width && py >= cy && py <= cy + c.height) return c
        }
        return null
    }

    onVisibleChanged: if (overview.visible) overview.refresh()
    Timer { interval: 1000; running: overview.visible; repeat: true; onTriggered: overview.refresh() }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { overview.clients = JSON.parse(text) } catch (e) { overview.clients = [] }
            }
        }
    }
    Process {
        id: activeProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { overview.activeAddress = JSON.parse(text).address || "" } catch (e) { overview.activeAddress = "" }
            }
        }
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Theme.withAlpha("#000000", 0.45)

        MouseArea { anchors.fill: parent; onClicked: PopupManager.close() }

        Text {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 18 }
            text: "Arrastrá para mover · click para enfocar · click afuera para cerrar"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 11
            opacity: 0.8
        }

        Grid {
            id: wsRow
            anchors.centerIn: parent
            columns: 5
            spacing: 16

            Repeater {
                model: overview.wsList
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property real aspect: modelData.monitor ? (modelData.monitor.width / modelData.monitor.scale) / (modelData.monitor.height / modelData.monitor.scale) : (16 / 9)
                    height: 170
                    width: height * aspect
                    radius: Theme.radius - 4
                    color: Theme.popupBg
                    border.width: modelData.active ? 2 : 1
                    border.color: modelData.active ? Theme.accent : Theme.border
                    clip: true

                    Rectangle {
                        id: label
                        anchors { top: parent.top; left: parent.left; margins: 5 }
                        z: 1000
                        radius: Theme.radius - 8
                        color: Theme.withAlpha("#000000", 0.45)
                        width: labelRow.implicitWidth + 12
                        height: labelRow.implicitHeight + 6

                        Row {
                            id: labelRow
                            anchors.centerIn: parent
                            spacing: 4
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: card.modelData.active ? Theme.accent : "#ffffff"
                            }
                            Text {
                                text: card.modelData.name
                                color: card.modelData.active ? Theme.accent : "#ffffff"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: card.modelData.active ? Font.DemiBold : Font.Normal
                            }
                        }
                    }

                    readonly property var winsHere: overview.clients.filter(c => c.workspace.id === card.modelData.id && !c.hidden)

                    Text {
                        anchors.centerIn: parent
                        visible: card.winsHere.length === 0
                        text: "Vacío"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        opacity: 0.6
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + card.modelData.id + " })")
                            PopupManager.close()
                        }
                    }

                    Repeater {
                        model: card.winsHere
                        delegate: Rectangle {
                            id: winBox
                            required property var modelData
                            readonly property real mx: card.modelData.monitor ? card.modelData.monitor.x : 0
                            readonly property real my: card.modelData.monitor ? card.modelData.monitor.y : 0
                            readonly property real mw: card.modelData.monitor ? card.modelData.monitor.width / card.modelData.monitor.scale : 1920
                            readonly property real mh: card.modelData.monitor ? card.modelData.monitor.height / card.modelData.monitor.scale : 1080

                            x: Math.max(2, (modelData.at[0] - mx) / mw * card.width)
                            y: Math.max(2, (modelData.at[1] - my) / mh * card.height)
                            width: Math.max(6, Math.min(card.width - x - 2, modelData.size[0] / mw * card.width))
                            height: Math.max(6, Math.min(card.height - y - 2, modelData.size[1] / mh * card.height))
                            radius: 4
                            clip: true
                            opacity: winBox.dragging ? 0.25 : 1
                            color: modelData.address === overview.activeAddress ? Theme.activeBg : Theme.hoverBg
                            border.width: 1
                            border.color: (dragArea.containsMouse || modelData.address === overview.activeAddress) ? Theme.accent : Theme.border

                            property bool dragging: false

                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 2
                                visible: winBox.width > 24 && winBox.height > 24

                                IconImage {
                                    source: Quickshell.iconPath(winBox.modelData.class, false)
                                    implicitSize: Math.min(24, winBox.height - 16, winBox.width - 8)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: status === Image.Ready
                                }
                                Text {
                                    width: parent.width
                                    visible: winBox.height > 40
                                    text: winBox.modelData.title
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                property point pressPos

                                onPressed: mouse => {
                                    dragArea.pressPos = Qt.point(mouse.x, mouse.y)
                                    winBox.dragging = false
                                }
                                onPositionChanged: mouse => {
                                    if (!pressed) return
                                    var dx = mouse.x - dragArea.pressPos.x
                                    var dy = mouse.y - dragArea.pressPos.y
                                    if (!winBox.dragging && (Math.abs(dx) > 6 || Math.abs(dy) > 6)) {
                                        winBox.dragging = true
                                        var p = winBox.mapToItem(backdrop, 0, 0)
                                        ghost.x = p.x
                                        ghost.y = p.y
                                        ghost.width = winBox.width
                                        ghost.height = winBox.height
                                        ghost.title = winBox.modelData.title
                                        ghost.visible = true
                                    }
                                    if (winBox.dragging) {
                                        var abs = dragArea.mapToItem(backdrop, mouse.x, mouse.y)
                                        ghost.x = abs.x - ghost.width / 2
                                        ghost.y = abs.y - ghost.height / 2
                                    }
                                }
                                onReleased: {
                                    if (winBox.dragging) {
                                        ghost.visible = false
                                        var target = overview.cardAt(ghost.x + ghost.width / 2, ghost.y + ghost.height / 2)
                                        if (target && target.modelData.id !== card.modelData.id) {
                                            Hyprland.dispatch("hl.dsp.window.move({ workspace = " + target.modelData.id +
                                                ", window = \"address:" + winBox.modelData.address + "\", follow = false })")
                                            overview.refresh()
                                        }
                                    } else {
                                        Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + winBox.modelData.address + "\" })")
                                        PopupManager.close()
                                    }
                                    winBox.dragging = false
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: ghost
            visible: false
            z: 100
            radius: 4
            color: Theme.activeBg
            border.width: 1
            border.color: Theme.accent
            opacity: 0.85
            property string title: ""

            Text {
                anchors.centerIn: parent
                width: parent.width - 8
                text: ghost.title
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
