pragma Singleton
import QtQuick
import Quickshell

Scope {
    readonly property alias values: settings.value
    readonly property real uiScale: Number(values.uiScale) > 0 ? Number(values.uiScale) : 1.0
    readonly property int workspaceCount: Number(values.workspaceCount) > 0 ? Math.floor(Number(values.workspaceCount)) : 8
    readonly property bool topbarHelpIcon: values.topbarHelpIcon !== false
    WatchedJson {
        id: settings
        path: Quickshell.env("HOME") + "/.config/hypr/settings.json"
    }
}
