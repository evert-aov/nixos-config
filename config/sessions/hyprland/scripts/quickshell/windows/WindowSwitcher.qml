import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../"

Item {
    id: root
    focus: true

    // Main.qml supplies these common widget properties.
    property var notifModel
    property var liveNotifs
    property real layoutWidth: width
    property real layoutHeight: height
    property string widgetArg: ""
    signal closeRequested()

    readonly property real uiScale: Math.max(0.35, layoutHeight / 650)
    function s(value) { return Math.round(value * uiScale); }
    MatugenColors { id: theme }

    property string selectedAddress: ""
    property bool initialized: false
    property bool activating: false
    readonly property int selectedIndex: windows.findIndex(w => w.address === selectedAddress)

    // Keep the objects live (title, workspace and Wayland handle can change).
    // Hyprland includes windows on other monitors and special workspaces.
    readonly property var windows: {
        let result = Hyprland.toplevels.values.filter(w => w && w.address);
        return result.sort((a, b) => {
            const ar = a.lastIpcObject.focusHistoryID;
            const br = b.lastIpcObject.focusHistoryID;
            const rankA = ar >= 0 ? ar : 2147483647;
            const rankB = br >= 0 ? br : 2147483647;
            return rankA - rankB || a.address.localeCompare(b.address);
        });
    }

    onWindowsChanged: Qt.callLater(reconcileSelection)
    Component.onCompleted: {
        Hyprland.refreshToplevels();
        Qt.callLater(reconcileSelection);
    }

    function reconcileSelection() {
        if (windows.length === 0) {
            selectedAddress = "";
            return;
        }
        if (!initialized) {
            const index = widgetArg === "next" ? 1 % windows.length
                        : widgetArg === "previous" ? windows.length - 1 : 0;
            selectedAddress = windows[index].address;
            initialized = true;
        } else if (selectedIndex < 0) {
            selectedAddress = windows[0].address;
        }
    }

    function cycle(step) {
        if (!windows.length) return;
        const index = ((Math.max(0, selectedIndex) + step) % windows.length + windows.length) % windows.length;
        selectedAddress = windows[index].address;
    }

    function activateSelected() {
        const target = windows[selectedIndex];
        if (!target || activating) return;
        activating = true;
        // Hide the layer surface before requesting focus on the application.
        closeRequested();
        Qt.callLater(() => {
            if (!target) return;
            if (target.wayland) {
                target.wayland.activate();
            } else if (/^0x[0-9a-f]+$/i.test(target.address)) {
                // A newly mapped client may not have its Wayland handle yet.
                Hyprland.dispatch(Hyprland.usingLua
                    ? "hl.dsp.focus({ window = 'address:" + target.address + "' })"
                    : "focuswindow address:" + target.address);
            }
        });
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Tab: cycle(event.modifiers & Qt.ShiftModifier ? -1 : 1); break;
        case Qt.Key_Backtab: cycle(-1); break;
        case Qt.Key_Right: cycle(1); break;
        case Qt.Key_Left: cycle(-1); break;
        case Qt.Key_Down: cycle(1); break;
        case Qt.Key_Up: cycle(-1); break;
        case Qt.Key_Return:
        case Qt.Key_Enter: activateSelected(); break;
        case Qt.Key_Escape: closeRequested(); break;
        default: return;
        }
        event.accepted = true;
    }

    readonly property real centerWidth: Math.min(s(600), width * 0.58)
    readonly property real sideWidth: s(200)
    readonly property real cardGap: s(10)
    readonly property real skew: -0.35
    readonly property var selectedWindow: selectedIndex >= 0 ? windows[selectedIndex] : null
    readonly property string selectedAppId: selectedWindow
        ? (selectedWindow.wayland ? selectedWindow.wayland.appId : selectedWindow.lastIpcObject.class || "") : ""
    readonly property var selectedEntry: DesktopEntries.heuristicLookup(selectedAppId)
    readonly property string selectedAppName: selectedEntry ? selectedEntry.name : selectedAppId || "Aplicación"
    property real wheelAccum: 0

    // Match the wallpaper picker's full-width, transparent, skewed carousel.
    Item {
        id: carousel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: toolbar.bottom
        anchors.topMargin: root.s(20)
        anchors.bottom: caption.top
        anchors.bottomMargin: root.s(16)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: event => {
                const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                    ? event.angleDelta.x : event.angleDelta.y;
                root.wheelAccum += delta;
                if (Math.abs(root.wheelAccum) >= 120) {
                    root.cycle(root.wheelAccum > 0 ? -1 : 1);
                    root.wheelAccum = 0;
                }
                event.accepted = true;
            }
        }

        Repeater {
            model: root.windows
            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property int offset: index - root.selectedIndex
                readonly property bool selected: offset === 0
                readonly property string appId: modelData.wayland ? modelData.wayland.appId : (modelData.lastIpcObject.class || "")
                readonly property var entry: DesktopEntries.heuristicLookup(appId)
                readonly property string appName: entry ? entry.name : appId || "Aplicación"
                readonly property real skewOverhang: Math.abs(root.skew) * height / 2
                readonly property bool inViewport: root.visible && x + width + skewOverhang > 0 && x - skewOverhang < carousel.width

                width: selected ? root.centerWidth : root.sideWidth
                height: Math.max(1, Math.min(root.s(selected ? 450 : 420), carousel.height - (selected ? 0 : root.s(30))))
                y: (carousel.height - height) / 2
                x: {
                    const left = (carousel.width - root.centerWidth) / 2;
                    if (offset < 0) return left + offset * (root.sideWidth + root.cardGap);
                    if (offset > 0) return left + root.centerWidth + root.cardGap + (offset - 1) * (root.sideWidth + root.cardGap);
                    return left;
                }
                z: selected ? 10 : 1
                opacity: selected ? 1 : (cardMouse.containsMouse ? 0.9 : 0.62)
                visible: inViewport

                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    color: card.selected ? theme.mauve : theme.surface2
                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(1, root.skew, 0, -root.skew * card.height / 2,
                                            0, 1, 0, 0,
                                            0, 0, 1, 0,
                                            0, 0, 0, 1)
                    }

                    Item {
                        id: crop
                        anchors.fill: parent
                        anchors.margins: root.s(3)
                        clip: true
                        Rectangle { anchors.fill: parent; color: theme.crust }

                        // Counter-skew the preview: only the frame tilts, not the app.
                        Item {
                            id: upright
                            anchors.centerIn: parent
                            width: root.centerWidth + Math.abs(root.skew) * height
                            height: crop.height
                            transform: Matrix4x4 {
                                matrix: Qt.matrix4x4(1, -root.skew, 0, root.skew * upright.height / 2,
                                                    0, 1, 0, 0,
                                                    0, 0, 1, 0,
                                                    0, 0, 0, 1)
                            }
                            ScreencopyView {
                                id: preview
                                anchors.centerIn: parent
                                captureSource: card.inViewport ? card.modelData.wayland : null
                                live: card.inViewport
                                paintCursor: false
                                constraintSize: Qt.size(upright.width, upright.height)
                                visible: hasContent
                            }
                            Column {
                                anchors.centerIn: parent
                                spacing: root.s(16)
                                visible: !preview.hasContent
                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: root.s(card.selected ? 72 : 48)
                                    height: width
                                    source: Quickshell.iconPath(card.entry && card.entry.icon ? card.entry.icon : "application-x-executable", "application-x-executable")
                                    fillMode: Image.PreserveAspectFit
                                }
                                Text {
                                    width: Math.max(1, card.width - root.s(35))
                                    text: card.appName
                                    textFormat: Text.PlainText
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: theme.text
                                    font.pixelSize: root.s(16)
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: card.selected
                                    text: "Vista previa no disponible"
                                    color: theme.subtext0
                                    font.pixelSize: root.s(12)
                                }
                            }
                        }
                    }
                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedAddress = card.modelData.address;
                            root.activateSelected();
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: emptyLabel.implicitWidth + root.s(48)
            height: root.s(72)
            radius: root.s(14)
            color: Qt.alpha(theme.mantle, 0.9)
            visible: root.windows.length === 0
            Text {
                id: emptyLabel
                anchors.centerIn: parent
                text: "No hay ventanas abiertas"
                color: theme.text
                font.pixelSize: root.s(18)
            }
        }
    }

    Rectangle {
        id: toolbar
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.s(40)
        width: Math.min(parent.width - root.s(24), toolbarRow.implicitWidth + root.s(24))
        height: root.s(56)
        radius: root.s(14)
        color: Qt.alpha(theme.mantle, 0.9)
        border.color: Qt.alpha(theme.surface2, 0.6)
        z: 20

        RowLayout {
            id: toolbarRow
            anchors.centerIn: parent
            spacing: root.s(12)
            Text {
                text: "▦"
                color: theme.text
                font.pixelSize: root.s(28)
            }
            Text {
                text: "Ventanas"
                color: theme.text
                font.pixelSize: root.s(16)
                font.bold: true
            }
            Text {
                text: (root.selectedIndex + 1) + " / " + root.windows.length
                color: theme.subtext0
                font.pixelSize: root.s(14)
                Layout.minimumWidth: root.s(54)
                horizontalAlignment: Text.AlignHCenter
            }
            Repeater {
                model: ["‹", "›", "×"]
                delegate: Rectangle {
                    id: toolButton
                    required property string modelData
                    required property int index
                    implicitWidth: root.s(36)
                    implicitHeight: root.s(36)
                    radius: root.s(10)
                    color: buttonMouse.containsMouse ? theme.surface1 : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: toolButton.modelData
                        color: theme.text
                        font.pixelSize: root.s(26)
                    }
                    MouseArea {
                        id: buttonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (toolButton.index === 2) root.closeRequested();
                            else root.cycle(toolButton.index === 0 ? -1 : 1);
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: caption
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.s(14)
        width: Math.min(root.width - root.s(32), root.s(740))
        height: root.s(66)
        radius: root.s(14)
        color: Qt.alpha(theme.mantle, 0.9)
        visible: root.windows.length > 0
        RowLayout {
            anchors.fill: parent
            anchors.margins: root.s(12)
            spacing: root.s(12)
            Image {
                Layout.preferredWidth: root.s(32)
                Layout.preferredHeight: root.s(32)
                source: Quickshell.iconPath(root.selectedEntry && root.selectedEntry.icon ? root.selectedEntry.icon : "application-x-executable", "application-x-executable")
                fillMode: Image.PreserveAspectFit
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.s(4)
                Text {
                    Layout.fillWidth: true
                    text: root.selectedWindow ? root.selectedWindow.title || root.selectedAppName : ""
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: theme.text
                    font.pixelSize: root.s(15)
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.selectedAppName + " · Escritorio " + (root.selectedWindow && root.selectedWindow.workspace ? root.selectedWindow.workspace.name : "—")
                        + "   ·   Tab / ← →   ·   Enter: abrir   ·   Esc: cerrar"
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: theme.subtext0
                    font.pixelSize: root.s(12)
                }
            }
        }
    }
}
