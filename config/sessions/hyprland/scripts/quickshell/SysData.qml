pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property int cpu: 0
    property int ramPercent: 0
    property real ramGb: 0
    property real ramTotalGb: 0
    property int temp: 0
    property real netRx: 0
    property real netTx: 0
    property var coreCpu: []
    property int subscribers: 0

    function subscribe() { subscribers++; }
    function unsubscribe() { subscribers = Math.max(0, subscribers - 1); }
    function sendMode() {
        if (sampler.running) sampler.write("details " + (subscribers > 0 ? "1" : "0") + "\n");
    }
    onSubscribersChanged: sendMode()

    Process {
        id: sampler
        command: ["python3", "-u", decodeURIComponent(Qt.resolvedUrl("watchers/system_metrics.py").toString().replace(/^file:\/\//, ""))]
        stdinEnabled: true
        running: true
        onStarted: root.sendMode()
        onExited: retry.restart()
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    for (const name of ["cpu", "ramPercent", "ramGb", "ramTotalGb", "temp", "netRx", "netTx"])
                        if (typeof data[name] === "number" && isFinite(data[name])) root[name] = data[name];
                    if (Array.isArray(data.coreCpu)) root.coreCpu = data.coreCpu;
                } catch (error) { console.warn("Invalid system metrics:", error); }
            }
        }
    }
    Timer {
        id: retry
        interval: 2000
        onTriggered: sampler.running = true
    }
}
