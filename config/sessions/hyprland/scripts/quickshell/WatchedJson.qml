import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property alias path: file.path
    property var value: ({})
    property bool allowArray: false
    // Retain the last valid object during a partial write or temporary removal.
    FileView {
        id: file
        watchChanges: true
        printErrors: false
        onFileChanged: reloadDelay.restart()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object" && (root.allowArray || !Array.isArray(parsed))
                        && JSON.stringify(parsed) !== JSON.stringify(root.value))
                    root.value = parsed;
            } catch (error) { /* Wait for the writer to finish. */ }
        }
    }
    Timer {
        id: reloadDelay
        interval: 40
        onTriggered: file.reload()
    }
    // Also recover if the file or its directory did not exist at shell startup.
    Timer {
        interval: 2000
        running: !file.loaded
        repeat: true
        onTriggered: file.reload()
    }
}
