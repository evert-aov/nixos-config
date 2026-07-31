import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window
import QtCore
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    Caching { id: paths }

    property var notifModel
    property var liveNotifs

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }

    function s(val) { return scaler.s(val); }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2

    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color maroon: _theme.maroon
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color teal: _theme.teal
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    readonly property color accentColor: sapphire
    readonly property color accentColor2: blue

    property real introMain: 0
    property real globalOrbitAngle: 0

    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    ParallelAnimation {
        running: true
        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo }
    }

    Component.onCompleted: SysData.subscribe()
    Component.onDestruction: SysData.unsubscribe()

    readonly property real cpuAngle: SysData.cpu / 100.0 * 2 * Math.PI
    readonly property real ramAngle: SysData.ramPercent / 100.0 * 2 * Math.PI

    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * introMain)
        opacity: introMain
        transform: Translate { y: s(20) * (1 - introMain) }

        Rectangle {
            anchors.fill: parent
            radius: s(20)
            color: base
            border.color: surface0
            border.width: 1
            clip: true

            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(globalOrbitAngle * 2) * s(150)
                y: (parent.height / 2 - height / 2) + Math.sin(globalOrbitAngle * 2) * s(100)
                opacity: 0.06
                color: accentColor
            }

            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(globalOrbitAngle * 1.5) * s(-150)
                y: (parent.height / 2 - height / 2) + Math.cos(globalOrbitAngle * 1.5) * s(-100)
                opacity: 0.04
                color: Qt.lighter(accentColor2, 1.3)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: s(30)
                spacing: s(20)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: s(30)

                    // CPU CARD
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: s(24)
                        color: "#0dffffff"
                        border.color: "#1affffff"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: s(20)
                            spacing: s(12)

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(parent.width, parent.height - s(120))
                                Layout.alignment: Qt.AlignHCenter

                                Rectangle {
                                    id: cpuCircle
                                    width: Math.min(parent.width, parent.height) * 0.85
                                    height: width
                                    anchors.centerIn: parent
                                    radius: width / 2
                                    color: Qt.rgba(mauve.r, mauve.g, mauve.b, 0.06)

                                    Canvas {
                                        id: cpuCanvas
                                        anchors.fill: parent
                                        rotation: -90

                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);
                                            var cx = width / 2, cy = height / 2;
                                            var r = (width / 2) - s(16);
                                            var end = window.cpuAngle;

                                            ctx.lineCap = "round";

                                            ctx.lineWidth = s(10);
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                            ctx.strokeStyle = "#1affffff";
                                            ctx.stroke();

                                            ctx.lineWidth = s(14);
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, r, 0, end);
                                            var grad = ctx.createLinearGradient(0, height, width, 0);
                                            var c = SysData.cpu > 80 ? "#" + red.toString() : (SysData.cpu > 60 ? "#" + yellow.toString() : "#" + mauve.toString());
                                            var cl = SysData.cpu > 80 ? "#" + Qt.lighter(red, 1.15).toString() : (SysData.cpu > 60 ? "#" + Qt.lighter(yellow, 1.15).toString() : "#" + Qt.lighter(mauve, 1.25).toString());
                                            grad.addColorStop(0, c);
                                            grad.addColorStop(1, cl);
                                            ctx.strokeStyle = grad;
                                            ctx.stroke();
                                        }
                                    }

                                    Connections {
                                        target: window
                                        function onCpuAngleChanged() { cpuCanvas.requestPaint() }
                                    }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: s(4)

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: s(28)
                                            color: text
                                            text: "󰘚"
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Black
                                            font.pixelSize: s(28)
                                            color: SysData.cpu > 80 ? red : (SysData.cpu > 60 ? yellow : mauve)
                                            text: SysData.cpu + "%"
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: s(14)
                                            color: overlay0
                                            text: SysData.temp + "°C"
                                        }
                                    }
                                }
                            }

                            // Per-core bars
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: s(6)

                                Text {
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: s(11)
                                    color: overlay0
                                    text: "PER-CORE"
                                }

                                Repeater {
                                    model: SysData.coreCpu

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: s(8)

                                        Text {
                                            Layout.preferredWidth: s(24)
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: s(10)
                                            color: overlay0
                                            text: index
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: s(8)
                                            radius: s(4)
                                            color: "#1affffff"

                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * Math.min(modelData / 100.0, 1.0)
                                                radius: s(4)
                                                color: modelData > 80 ? red : (modelData > 60 ? yellow : mauve)

                                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                                            }
                                        }

                                        Text {
                                            Layout.preferredWidth: s(28)
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: s(10)
                                            color: modelData > 80 ? red : (modelData > 60 ? yellow : overlay0)
                                            horizontalAlignment: Text.AlignRight
                                            text: modelData + "%"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // RAM CARD
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: s(24)
                        color: "#0dffffff"
                        border.color: "#1affffff"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: s(20)
                            spacing: s(12)

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(parent.width, parent.height - s(120))
                                Layout.alignment: Qt.AlignHCenter

                                Rectangle {
                                    id: ramCircle
                                    width: Math.min(parent.width, parent.height) * 0.85
                                    height: width
                                    anchors.centerIn: parent
                                    radius: width / 2
                                    color: Qt.rgba(green.r, green.g, green.b, 0.06)

                                    Canvas {
                                        id: ramCanvas
                                        anchors.fill: parent
                                        rotation: -90

                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);
                                            var cx = width / 2, cy = height / 2;
                                            var r = (width / 2) - s(16);
                                            var end = window.ramAngle;

                                            ctx.lineCap = "round";

                                            ctx.lineWidth = s(10);
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                            ctx.strokeStyle = "#1affffff";
                                            ctx.stroke();

                                            ctx.lineWidth = s(14);
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, r, 0, end);
                                            var grad = ctx.createLinearGradient(0, height, width, 0);
                                            var c = SysData.ramPercent > 80 ? "#" + red.toString() : (SysData.ramPercent > 60 ? "#" + yellow.toString() : "#" + green.toString());
                                            var cl = SysData.ramPercent > 80 ? "#" + Qt.lighter(red, 1.15).toString() : (SysData.ramPercent > 60 ? "#" + Qt.lighter(yellow, 1.15).toString() : "#" + Qt.lighter(green, 1.25).toString());
                                            grad.addColorStop(0, c);
                                            grad.addColorStop(1, cl);
                                            ctx.strokeStyle = grad;
                                            ctx.stroke();
                                        }
                                    }

                                    Connections {
                                        target: window
                                        function onRamAngleChanged() { ramCanvas.requestPaint() }
                                    }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: s(4)

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: s(28)
                                            color: text
                                            text: "󰍛"
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Black
                                            font.pixelSize: s(28)
                                            color: SysData.ramPercent > 80 ? red : (SysData.ramPercent > 60 ? yellow : green)
                                            text: SysData.ramPercent + "%"
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: s(14)
                                            color: overlay0
                                            text: SysData.ramGb.toFixed(1) + " GB"
                                        }
                                    }
                                }
                            }

                            // RAM total info
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: s(8)

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: s(8)
                                    radius: s(4)
                                    color: "#1affffff"

                                    Rectangle {
                                        height: parent.height
                                        width: parent.width * Math.min(SysData.ramPercent / 100.0, 1.0)
                                        radius: s(4)
                                        color: SysData.ramPercent > 80 ? red : (SysData.ramPercent > 60 ? yellow : green)

                                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: s(4)

                                    Text {
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: s(11)
                                        color: overlay0
                                        text: "Total:"
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: s(11)
                                        color: subtext0
                                        horizontalAlignment: Text.AlignRight
                                        text: SysData.ramGb.toFixed(1) + " GB / " + SysData.ramTotalGb.toFixed(1) + " GB"
                                    }
                                }
                            }
                        }
                    }
                }

                // Footer
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: s(30)

                    RowLayout {
                        anchors.fill: parent
                        spacing: s(20)

                        Text {
                            Layout.fillWidth: true
                            font.family: "JetBrains Mono"
                            font.pixelSize: s(11)
                            color: overlay0
                            text: "󰅐  " + Qt.formatDateTime(new Date(), "hh:mm")
                        }

                        Text {
                            Layout.fillWidth: true
                            font.family: "JetBrains Mono"
                            font.pixelSize: s(11)
                            color: overlay0
                            horizontalAlignment: Text.AlignRight
                            text: "󰋁  " + (SysData.cpu > 60 ? "Heavy load" : "Idle")
                        }
                    }
                }
            }
        }
    }
}
