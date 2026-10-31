pragma Singleton
import QtQuick
import Quickshell

Scope {
    WatchedJson { id: palette; path: "/tmp/qs_colors.json" }
    readonly property color base: palette.value.base || "#1e1e2e"
    readonly property color mantle: palette.value.mantle || "#181825"
    readonly property color crust: palette.value.crust || "#11111b"
    readonly property color text: palette.value.text || "#cdd6f4"
    readonly property color subtext0: palette.value.subtext0 || "#a6adc8"
    readonly property color subtext1: palette.value.subtext1 || "#bac2de"
    readonly property color surface0: palette.value.surface0 || "#313244"
    readonly property color surface1: palette.value.surface1 || "#45475a"
    readonly property color surface2: palette.value.surface2 || "#585b70"
    readonly property color overlay0: palette.value.overlay0 || "#6c7086"
    readonly property color overlay1: palette.value.overlay1 || "#7f849c"
    readonly property color overlay2: palette.value.overlay2 || "#9399b2"
    readonly property color blue: palette.value.blue || "#89b4fa"
    readonly property color sapphire: palette.value.sapphire || "#74c7ec"
    readonly property color peach: palette.value.peach || "#fab387"
    readonly property color green: palette.value.green || "#a6e3a1"
    readonly property color red: palette.value.red || "#f38ba8"
    readonly property color mauve: palette.value.mauve || "#cba6f7"
    readonly property color pink: palette.value.pink || "#f5c2e7"
    readonly property color yellow: palette.value.yellow || "#f9e2af"
    readonly property color maroon: palette.value.maroon || "#eba0ac"
    readonly property color teal: palette.value.teal || "#94e2d5"

    // Alpha belongs to surfaces, never to the container or foreground palette.
    readonly property real panelOpacity: 0.72
    readonly property real raisedOpacity: 0.82
    readonly property real barOpacity: 0.62
    readonly property real toolbarOpacity: 0.76
    readonly property color panelBackground: Qt.alpha(base, panelOpacity)
    readonly property color raisedBackground: Qt.alpha(base, raisedOpacity)
    readonly property color barBackground: Qt.alpha(base, barOpacity)
    readonly property color toolbarBackground: Qt.alpha(mantle, toolbarOpacity)
}
