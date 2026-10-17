pragma Singleton
import QtQuick
import Quickshell.Io

// Paleta y tokens visuales al estilo GNOME/Adwaita.
// Sigue el esquema claro/oscuro y el color de acento del sistema
// (org.gnome.desktop.interface color-scheme / accent-color) en vivo.
QtObject {
    id: theme

    // ---------------------------------------------------------------
    // CONTROLES DE BLUR/TRANSPARENCIA — ajusta aquí el look de la barra
    // y los popups. El desenfoque real lo hace Hyprland (layerrule blur
    // en hyprland.lua); estos valores solo controlan cuánta transparencia
    // deja ver ese blur.
    // ---------------------------------------------------------------
    property real barAlpha: 0.55     // 0 = totalmente transparente, 1 = opaco
    property real popupAlpha: 0.78
    property real hoverAlphaDark: 0.10
    property real hoverAlphaLight: 0.06
    property real activeAlpha: 0.30

    // ---------------------------------------------------------------
    // Layout
    // ---------------------------------------------------------------
    property int barHeight: 32
    property int radius: 14
    property int pillRadius: 999
    property int iconSize: 15
    property string fontFamily: "Adwaita Sans"
    property string monoFontFamily: "Adwaita Mono"

    // ---------------------------------------------------------------
    // Estado en vivo del sistema (gsettings)
    // ---------------------------------------------------------------
    property bool dark: true
    property string accentName: "blue"

    readonly property var accentMap: ({
        blue:   "#3584e4",
        teal:   "#2190a4",
        green:  "#3a944a",
        yellow: "#c88800",
        orange: "#ed5b00",
        red:    "#e62d42",
        pink:   "#d56199",
        purple: "#9141ac",
        slate:  "#6f8396"
    })
    readonly property color accent: accentMap[accentName] || accentMap.blue

    function withAlpha(colorStr, alpha) {
        var c = Qt.color(colorStr)
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    // ---------------------------------------------------------------
    // Paleta derivada (Adwaita claro / oscuro)
    // ---------------------------------------------------------------
    readonly property color fg:        dark ? "#ffffff" : "#1e1e1e"
    readonly property color fgDim:      dark ? "#9a9996" : "#77767b"
    readonly property color danger:     "#e01b24"
    readonly property color ok:         "#26a269"

    readonly property color barBg:     withAlpha(dark ? "#1e1e1e" : "#ffffff", theme.barAlpha)
    readonly property color popupBg:   withAlpha(dark ? "#2d2d2d" : "#ffffff", theme.popupAlpha)
    // Los toasts flotan directo sobre el escritorio (sin popup detrás), así
    // que necesitan una tarjeta propia casi opaca, como en GNOME.
    readonly property color toastBg:   withAlpha(dark ? "#2d2d2d" : "#ffffff", 0.94)
    readonly property color border:    withAlpha(dark ? "#ffffff" : "#000000", dark ? 0.08 : 0.10)
    readonly property color hoverBg:   withAlpha(dark ? "#ffffff" : "#000000", dark ? theme.hoverAlphaDark : theme.hoverAlphaLight)
    readonly property color activeBg:  withAlpha(theme.accent, theme.activeAlpha)
    readonly property color trackBg:   withAlpha(dark ? "#ffffff" : "#000000", dark ? 0.16 : 0.12)

    // ---------------------------------------------------------------
    // Watchers de gsettings (color-scheme + accent-color), en vivo
    // ---------------------------------------------------------------
    function _applyScheme(line) {
        theme.dark = line.indexOf("prefer-dark") !== -1
    }
    function _applyAccent(line) {
        var m = line.match(/'([a-z]+)'/)
        if (m) theme.accentName = m[1]
    }

    property Process schemeInit: Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        running: true
        stdout: SplitParser { onRead: data => theme._applyScheme(data) }
    }
    property Process schemeWatch: Process {
        command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
        running: true
        stdout: SplitParser { onRead: data => theme._applyScheme(data) }
    }
    property Process accentInit: Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "accent-color"]
        running: true
        stdout: SplitParser { onRead: data => theme._applyAccent(data) }
    }
    property Process accentWatch: Process {
        command: ["gsettings", "monitor", "org.gnome.desktop.interface", "accent-color"]
        running: true
        stdout: SplitParser { onRead: data => theme._applyAccent(data) }
    }
}
