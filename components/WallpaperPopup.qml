import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".."

// Selector de fondo de pantalla, con dos pestañas:
// - Fondos: vista previa grande del fondo actual (o del que está bajo el
//   puntero) y grilla desplazable con las imágenes de ~/Pictures/Wallpapers.
// - Transición: efecto de awww, dirección/origen, curva y duración, con un
//   botón para probarla sobre el fondo actual.
// Se aplican con awww (ver Wallpaper.qml: recuerda el último elegido y la
// transición, y re-aplica el fondo al iniciar la shell).
PopupCard {
    id: popup
    popupName: "wallpapers"
    align: "right"
    cardWidth: 400

    readonly property string wallpaperDir: (Quickshell.env("HOME") || "/home/luis") + "/Pictures/Wallpapers"
    property var files: []
    property string hovered: ""
    // "fondos" | "transicion"
    property string tab: "fondos"
    readonly property var tr: Wallpaper.transition

    // ---- Opciones de transición ----
    readonly property var effects: [
        { label: "Fundido", value: "fade" },
        { label: "Barrido", value: "wipe" },
        { label: "Ola", value: "wave" },
        { label: "Círculo", value: "grow" },
        { label: "Cierre", value: "outer" },
        { label: "Aleatorio", value: "random" },
        { label: "Ninguno", value: "none" }
    ]
    // Grilla 3×3 compartida: flechas (ángulo de awww: 0 = hacia la
    // izquierda, 90 = hacia abajo) u orígenes del círculo (alias de awww).
    readonly property var directions: [
        { glyph: "↖", angle: 315, pos: "top-left" },    { glyph: "↑", angle: 270, pos: "top" },    { glyph: "↗", angle: 225, pos: "top-right" },
        { glyph: "←", angle: 0,   pos: "left" },        { glyph: "",  angle: -1,  pos: "center" }, { glyph: "→", angle: 180, pos: "right" },
        { glyph: "↙", angle: 45,  pos: "bottom-left" }, { glyph: "↓", angle: 90,  pos: "bottom" }, { glyph: "↘", angle: 135, pos: "bottom-right" }
    ]
    readonly property var curves: [
        { label: "Suave", value: ".54,0,.34,.99" },
        { label: "Lineal", value: "0,0,1,1" },
        { label: "Acelerar", value: ".42,0,1,1" },
        { label: "Frenar", value: "0,0,.58,1" }
    ]
    readonly property bool usesAngle: tr.type === "wipe" || tr.type === "wave"
    readonly property bool usesPos: tr.type === "grow" || tr.type === "outer"
    readonly property bool usesTiming: tr.type !== "none"
    readonly property real minDuration: 0.2
    readonly property real maxDuration: 5
    function effectLabel(v) {
        var e = popup.effects.find(x => x.value === v)
        return e ? e.label : v
    }
    function formatSeconds(s) { return s.toFixed(1).replace(".", ",") + " s" }
    readonly property string previewPath: popup.hovered || Wallpaper.current

    readonly property int columns: 3
    readonly property int gridSpacing: 8
    readonly property real tileWidth: (popup.cardWidth - 24 - popup.gridSpacing * (popup.columns - 1)) / popup.columns
    readonly property real tileHeight: Math.round(popup.tileWidth * 9 / 16)
    readonly property int maxRows: 3

    function prettyName(path) {
        if (!path) return ""
        var name = path.substring(path.lastIndexOf("/") + 1)
        return name.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ")
    }
    function shuffle() {
        var pool = popup.files.filter(f => f !== Wallpaper.current)
        if (pool.length === 0) return
        Wallpaper.apply(pool[Math.floor(Math.random() * pool.length)])
    }

    function refresh() { listProc.running = true }
    onVisibleChanged: {
        popup.hovered = ""
        popup.tab = "fondos"
        if (popup.visible) popup.refresh()
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

    // ---- Cabecera ----
    RowLayout {
        width: parent.width
        spacing: 6

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 0
            Text {
                text: "Fondo de pantalla"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
            }
            Text {
                text: popup.tab === "fondos"
                    ? (popup.files.length === 1 ? "1 imagen" : popup.files.length + " imágenes")
                    : popup.effectLabel(popup.tr.type)
                      + (popup.usesTiming ? " · " + popup.formatSeconds(popup.tr.duration) : "")
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        IconButton {
            icon: "media-playlist-shuffle-symbolic"
            enabled: popup.files.length > 1
            onClicked: popup.shuffle()
        }
        IconButton {
            icon: "folder-symbolic"
            onClicked: { PopupManager.close(); Quickshell.execDetached(["xdg-open", popup.wallpaperDir]) }
        }
    }

    // ---- Pestañas ----
    SegmentedControl {
        width: parent.width
        model: [
            { label: "Fondos", value: "fondos" },
            { label: "Transición", value: "transicion" }
        ]
        current: popup.tab
        onSelected: value => popup.tab = value
    }

    // =================================================================
    // Pestaña: Transición
    // =================================================================
    Column {
        visible: popup.tab === "transicion"
        width: parent.width
        spacing: 10

        SectionLabel { text: "Efecto" }
        Grid {
            width: parent.width
            columns: 4
            spacing: 6
            Repeater {
                model: popup.effects
                delegate: ChipButton {
                    required property var modelData
                    width: (parent.width - 3 * 6) / 4
                    text: modelData.label
                    selected: popup.tr.type === modelData.value
                    onClicked: popup.tr.type = modelData.value
                }
            }
        }

        // Dirección (barrido/ola) u origen (círculo/cierre): misma grilla.
        Row {
            visible: popup.usesAngle || popup.usesPos
            width: parent.width
            spacing: 12

            Grid {
                id: dirGrid
                columns: 3
                spacing: 4
                Repeater {
                    model: popup.directions
                    delegate: ChipButton {
                        required property var modelData
                        readonly property bool isCenter: modelData.angle === -1
                        width: 34
                        implicitHeight: 30
                        // En modo dirección el centro no es una opción.
                        enabled: !(popup.usesAngle && isCenter)
                        text: popup.usesPos ? (isCenter ? "●" : "•") : modelData.glyph
                        selected: popup.usesPos ? popup.tr.pos === modelData.pos : popup.tr.angle === modelData.angle
                        onClicked: {
                            if (popup.usesPos) popup.tr.pos = modelData.pos
                            else popup.tr.angle = modelData.angle
                        }
                    }
                }
            }
            Column {
                anchors.verticalCenter: dirGrid.verticalCenter
                width: parent.width - dirGrid.width - parent.spacing
                spacing: 2
                Text {
                    text: popup.usesPos ? "Origen" : "Dirección"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: popup.usesPos
                        ? (popup.tr.type === "grow" ? "Desde dónde crece el círculo" : "Hacia dónde se cierra el círculo")
                        : "Hacia dónde avanza el " + (popup.tr.type === "wave" ? "frente de la ola" : "barrido")
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        SectionLabel { visible: popup.usesTiming; text: "Curva" }
        SegmentedControl {
            visible: popup.usesTiming
            width: parent.width
            model: popup.curves
            current: popup.tr.bezier
            onSelected: value => popup.tr.bezier = value
        }

        SectionLabel { visible: popup.usesTiming; text: "Duración" }
        Row {
            visible: popup.usesTiming
            width: parent.width
            spacing: 4
            SliderRow {
                id: durSlider
                width: parent.width - durText.width - parent.spacing
                icon: "preferences-system-time-symbolic"
                showValue: false
                value: (popup.tr.duration - popup.minDuration) / (popup.maxDuration - popup.minDuration)
                // Pasos de 0,1 s.
                onValueEdited: v => popup.tr.duration =
                    Math.round((popup.minDuration + v * (popup.maxDuration - popup.minDuration)) * 10) / 10
            }
            Text {
                id: durText
                anchors.verticalCenter: durSlider.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                rightPadding: 6
                text: popup.formatSeconds(popup.tr.duration)
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.features: { "tnum": 1 }
            }
        }

        Text {
            visible: popup.tr.type === "random"
            width: parent.width
            leftPadding: 4
            wrapMode: Text.WordWrap
            text: "Cada cambio usa un efecto distinto, con la curva y la duración elegidas."
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

        // Probar: repinta el fondo actual desde un color liso.
        Rectangle {
            width: parent.width
            height: 36
            radius: height / 2
            enabled: Wallpaper.current.length > 0
            opacity: enabled ? 1 : 0.4
            color: tryMouse.containsMouse ? Theme.accentHover : Theme.accent
            scale: tryMouse.pressed ? 0.97 : 1
            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                SymbolicIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "media-playback-start-symbolic"
                    tint: Theme.accentFg
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Probar transición"
                    color: Theme.accentFg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
            MouseArea {
                id: tryMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Se cierra para ver el escritorio mientras corre.
                    PopupManager.close()
                    Wallpaper.preview(Theme.dark ? "1e1e1e" : "f6f5f4")
                }
            }
        }
    }

    // =================================================================
    // Pestaña: Fondos
    // =================================================================

    // ---- Vista previa ----
    ClippingRectangle {
        visible: popup.tab === "fondos"
        width: parent.width
        height: Math.round(width * 9 / 16)
        radius: Theme.radius - 2
        color: Theme.cardBg

        Image {
            id: preview
            anchors.fill: parent
            source: popup.previewPath ? "file://" + popup.previewPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 800
            sourceSize.height: 450
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Column {
            visible: preview.status !== Image.Ready
            anchors.centerIn: parent
            spacing: 8
            SymbolicIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "preferences-desktop-wallpaper-symbolic"
                size: 32
                tint: Theme.fgDim
            }
            Text {
                visible: popup.files.length > 0
                text: "Pasa el puntero por una imagen para previsualizarla"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        // Pie con el nombre del archivo, sobre un degradado para que se lea
        // encima de cualquier imagen.
        Rectangle {
            visible: popup.previewPath.length > 0
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 40
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.withAlpha("#000000", 0.6) }
            }

            RowLayout {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                anchors.margins: 10
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: popup.prettyName(popup.previewPath)
                    color: "#ffffff"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Rectangle {
                    visible: popup.previewPath === Wallpaper.current
                    implicitWidth: badge.implicitWidth + 14
                    implicitHeight: 18
                    radius: height / 2
                    color: Theme.accent
                    Text {
                        id: badge
                        anchors.centerIn: parent
                        text: "Actual"
                        color: Theme.accentFg
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }

    // ---- Estado vacío ----
    Column {
        visible: popup.files.length === 0 && popup.tab === "fondos"
        width: parent.width
        topPadding: 6
        bottomPadding: 6
        spacing: 4
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "No hay imágenes todavía"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Agrega PNG, JPG o WebP a ~/Pictures/Wallpapers"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }
    }

    // ---- Grilla ----
    Flickable {
        id: flick
        visible: popup.files.length > 0 && popup.tab === "fondos"
        width: parent.width
        readonly property int rows: Math.ceil(popup.files.length / popup.columns)
        height: Math.min(rows, popup.maxRows) * (popup.tileHeight + popup.gridSpacing) - popup.gridSpacing
        contentHeight: grid.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Grid {
            id: grid
            width: parent.width
            columns: popup.columns
            spacing: popup.gridSpacing

            Repeater {
                model: popup.files
                delegate: Item {
                    id: tile
                    required property string modelData
                    readonly property bool current: Wallpaper.current === tile.modelData
                    width: popup.tileWidth
                    height: popup.tileHeight

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: Theme.radius - 6
                        color: Theme.cardBg
                        scale: mouse.pressed ? 0.96 : 1
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + tile.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 240
                            sourceSize.height: 135
                        }
                        // Oscurece levemente los no seleccionados al pasar
                        // el puntero por otro, para dar foco al que se apunta.
                        Rectangle {
                            anchors.fill: parent
                            color: "#000000"
                            opacity: mouse.containsMouse ? 0 : 0.12
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                    }

                    // Anillo de selección / hover (por dentro del tile: el
                    // Flickable recorta lo que sobresalga).
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius - 6
                        color: "transparent"
                        border.width: tile.current ? 3 : 2
                        border.color: tile.current ? Theme.accent : Theme.withAlpha(Theme.fg, 0.5)
                        opacity: tile.current || mouse.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    // Check del fondo actual
                    Rectangle {
                        visible: tile.current
                        anchors { top: parent.top; right: parent.right; margins: 5 }
                        width: 18
                        height: 18
                        radius: 9
                        color: Theme.accent
                        SymbolicIcon {
                            anchors.centerIn: parent
                            name: "object-select-symbolic"
                            size: 11
                            tint: Theme.accentFg
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse) popup.hovered = tile.modelData
                            else if (popup.hovered === tile.modelData) popup.hovered = ""
                        }
                        onClicked: Wallpaper.apply(tile.modelData)
                    }
                }
            }
        }
    }
}
