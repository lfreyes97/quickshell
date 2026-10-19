import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import ".."

// Tarjeta de reproducción (MPRIS) del panel de calendario, como la de
// GNOME: carátula, título, artista y controles. Muestra el reproductor
// que está sonando; si ninguno suena, el primero. Con varios, las flechas
// pequeñas de la cabecera permiten cambiar entre ellos.
Rectangle {
    id: root
    readonly property var players: Mpris.players.values
    // Índice elegido a mano; -1 = automático (el que esté sonando).
    property int manualIndex: -1
    readonly property var player: {
        if (players.length === 0) return null
        if (manualIndex >= 0 && manualIndex < players.length) return players[manualIndex]
        return players.find(p => p.isPlaying) || players[0]
    }
    readonly property int currentIndex: player ? players.indexOf(player) : -1

    function cycle(delta) {
        manualIndex = (currentIndex + delta + players.length) % players.length
    }

    visible: player !== null
    implicitHeight: 84
    radius: Theme.radius - 2
    color: Theme.cardBg

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // ---- Carátula ----
        ClippingRectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: Theme.radius - 6
            color: Theme.cardBg

            Image {
                id: art
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 128
                sourceSize.height: 128
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            SymbolicIcon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: "audio-x-generic-symbolic"
                size: 24
                tint: Theme.fgDim
            }
        }

        // ---- Texto + controles ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.identity || "Reproductor") : ""
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                Repeater {
                    // Solo si hay más de un reproductor.
                    model: root.players.length > 1 ? ["pan-start-symbolic", "pan-end-symbolic"] : []
                    delegate: IconButton {
                        required property string modelData
                        required property int index
                        implicitWidth: 18
                        implicitHeight: 18
                        iconSize: 10
                        flat: true
                        icon: modelData
                        tint: Theme.fgDim
                        onClicked: root.cycle(index === 0 ? -1 : 1)
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackTitle || "Sin título") : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.player ? (root.player.trackArtist || "") : ""
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                IconButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    flat: true
                    icon: "media-skip-backward-symbolic"
                    enabled: root.player && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
                IconButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    checked: true
                    icon: root.player && root.player.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                    tint: Theme.accentFg
                    enabled: root.player && root.player.canTogglePlaying
                    onClicked: root.player.togglePlaying()
                }
                IconButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    flat: true
                    icon: "media-skip-forward-symbolic"
                    enabled: root.player && root.player.canGoNext
                    onClicked: root.player.next()
                }
            }
        }
    }
}
