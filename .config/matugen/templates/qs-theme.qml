pragma Singleton
import QtQuick

QtObject {
    readonly property color base: "{{colors.surface.default.hex}}"
    readonly property color mantle: "{{colors.surface_container_lowest.default.hex}}"
    readonly property color surface: "{{colors.surface_container.default.hex}}"
    readonly property color surface1: "{{colors.surface_container_high.default.hex}}"
    readonly property color text: "{{colors.on_surface.default.hex}}"
    readonly property color subtext: "{{colors.on_surface_variant.default.hex}}"
    readonly property color mauve: "{{colors.primary.default.hex}}"
    readonly property color red: "{{colors.error.default.hex}}"
    readonly property color panel: "{{colors.surface_container_lowest.default.hex_alpha | set_alpha: 0.96}}"
    readonly property string font: "Noto Sans"
    readonly property string mono: "JetBrainsMono Nerd Font"
}
