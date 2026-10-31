pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// One set of readers for all monitors.
Scope {
    id: barData
    Caching {
        id: paths
    }
    property bool pendingReload: false
    property bool showHelpIcon: ShellSettings.topbarHelpIcon
    property bool isRecording: false
    property bool updateAvailable: false
    property bool forceUpdateShow: false
    property int workspaceCount: ShellSettings.workspaceCount
    property string activeWidget: ""
    property bool isDesktop: false
    property string ethStatus: "Ethernet"
    property bool fastPollerLoaded: false
    property string timeStr: ""
    property string fullDateStr: ""
    property string weatherIcon: ""
    property string weatherTemp: "--°"
    property string weatherHex: Theme.yellow
    property string wifiStatus: "Off"
    property string wifiIcon: "󰤮"
    property string wifiSsid: ""
    property string btStatus: "Off"
    property string btIcon: "󰂲"
    property string btDevice: ""
    property string volPercent: "0%"
    property string volIcon: "󰕾"
    property bool isMuted: false
    property string batPercent: "100%"
    property string batIcon: "󰁹"
    property string batStatus: "Unknown"
    property bool isCoffeeActive: false
    property string kbLayout: "us"
    property string cpuPercent: SysData.cpu + "%"
    property string ramPercent: SysData.ramPercent + "%"
    property var musicData: {
        "status": "Stopped",
        "title": "",
        "artUrl": "",
        "timeStr": ""
    }
    readonly property bool isSettingsOpen: activeWidget === "settings"
    readonly property string displayArtUrl: musicData.artUrl || ""
    property int artRetries: 0
    readonly property string artRetryKey: (musicData.title || "") + "|" + displayArtUrl
    onArtRetryKeyChanged: artRetries = 0
    property alias workspaces: workspacesModel
    function refreshMusic() {
        musicForceRefresh.running = true;
    }
    function updateWorkspaces(data) {
        if (!Array.isArray(data))
            return;
        while (workspacesModel.count > data.length)
            workspacesModel.remove(workspacesModel.count - 1);
        while (workspacesModel.count < data.length)
            workspacesModel.append({
                wsId: "",
                wsState: ""
            });
        for (let i = 0; i < data.length; i++) {
            workspacesModel.setProperty(i, "wsId", String(data[i].id));
            workspacesModel.setProperty(i, "wsState", data[i].state);
            if (data[i].state === "active")
                workspacesModel.activeIndex = i;
        }
    }
    Connections {
        target: ShellSettings
        function onWorkspaceCountChanged() {
            wsDaemon.running = false;
            workspaceRestart.restart();
        }
    }
    Timer {
        id: workspaceRestart
        interval: 100
        onTriggered: wsDaemon.running = true
    }
    ListModel {
        id: workspacesModel
        property int activeIndex: 0
    }

    IpcHandler {
        target: "topbar"
        function forceReload() {
            Quickshell.reload(true);
        }
        function queueReload() {
            if (!barData.isSettingsOpen) {
                Quickshell.reload(true);
            } else {
                barData.pendingReload = true;
            }
        }
        function toggleUpdate() {
            barData.forceUpdateShow = !barData.forceUpdateShow;
        }
    }

    onIsSettingsOpenChanged: {
        if (!barData.isSettingsOpen && barData.pendingReload) {
            barData.pendingReload = false;
            Quickshell.reload(true);
        }
    }

    FileView {
        id: activeWidgetFile
        path: paths.runDir + "/current_widget"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: barData.activeWidget = text().trim()
    }
    Timer {
        interval: 2000
        running: !activeWidgetFile.loaded
        repeat: true
        onTriggered: activeWidgetFile.reload()
    }

    Process {
        id: recPoller
        running: true
        command: ["bash", "-c", "if [ -s " + paths.getCacheDir("recording") + "/rec_pid ] && kill -0 $(cat " + paths.getCacheDir("recording") + "/rec_pid) 2>/dev/null; then echo '1'; else echo '0'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                barData.isRecording = (this.text.trim() === "1");
            }
        }
    }

    Process {
        id: recWatcher
        running: true
        command: ["bash", "-c", "inotifywait -qq -e create,delete,modify,close_write " + paths.getCacheDir("recording") + "/ 2>/dev/null || sleep 2"]
        onExited: {
            recPoller.running = false;
            recPoller.running = true;
            running = false;
            running = true;
        }
    }
    Process {
        id: updatePoller
        command: ["bash", "-c", "if [ -f " + paths.getCacheDir("updater") + "/update_pending ]; then echo '1'; else echo '0'; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                barData.updateAvailable = (this.text.trim() === "1");
            }
        }
    }

    Process {
        id: updateWatcher
        running: true
        command: ["bash", "-c", "inotifywait -qq -e create,delete,close_write " + paths.getCacheDir("updater") + "/ 2>/dev/null || sleep 5"]
        onExited: {
            updatePoller.running = false;
            updatePoller.running = true;
            running = false;
            running = true;
        }
    }

    Process {
        id: coffeePoller
        running: true
        command: ["bash", "-c", "if [ -f " + paths.getRunDir("coffee") + "/active ]; then echo '1'; else echo '0'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                barData.isCoffeeActive = (this.text.trim() === "1");
            }
        }
    }

    Process {
        id: coffeeWatcher
        running: true
        command: ["bash", "-c", "mkdir -p " + paths.getRunDir("coffee") + " && inotifywait -qq -e create,delete,modify,close_write " + paths.getRunDir("coffee") + "/ 2>/dev/null || sleep 2"]
        onExited: {
            coffeePoller.running = false;
            coffeePoller.running = true;
            running = false;
            running = true;
        }
    }

    Process {
        id: chassisDetector
        running: true
        command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                barData.isDesktop = (this.text.trim() === "desktop");
            }
        }
    }

    Process {
        id: wsDaemon
        command: ["bash", "-c", "~/.config/hypr/scripts/workspaces.sh"]
        running: true
    }

    WatchedJson {
        id: workspaceFile
        path: paths.getRunDir("workspaces") + "/workspaces.json"
        allowArray: true
        onValueChanged: barData.updateWorkspaces(value)
    }

    Process {
        id: musicForceRefresh
        running: true
        command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee " + paths.getRunDir("music") + "/music_info.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        barData.musicData = JSON.parse(txt);
                    } catch (e) {}
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: barData.musicData !== null && barData.musicData.status === "Playing"
        repeat: true
        onTriggered: {
            if (!barData.musicData || barData.musicData.status !== "Playing")
                return;
            if (!barData.musicData.timeStr || barData.musicData.timeStr === "")
                return;

            let parts = barData.musicData.timeStr.split(" / ");
            if (parts.length !== 2)
                return;

            let posParts = parts[0].split(":").map(Number);
            let lenParts = parts[1].split(":").map(Number);

            let posSecs = (posParts.length === 3) ? (posParts[0] * 3600 + posParts[1] * 60 + posParts[2]) : (posParts[0] * 60 + posParts[1]);

            let lenSecs = (lenParts.length === 3) ? (lenParts[0] * 3600 + lenParts[1] * 60 + lenParts[2]) : (lenParts[0] * 60 + lenParts[1]);

            if (isNaN(posSecs) || isNaN(lenSecs))
                return;

            posSecs++;
            if (posSecs > lenSecs)
                posSecs = lenSecs;

            let newPosStr = "";
            if (posParts.length === 3) {
                let h = Math.floor(posSecs / 3600);
                let m = Math.floor((posSecs % 3600) / 60);
                let s = posSecs % 60;
                newPosStr = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
            } else {
                let m = Math.floor(posSecs / 60);
                let s = posSecs % 60;
                newPosStr = (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
            }

            let newData = Object.assign({}, barData.musicData);
            newData.timeStr = newPosStr + " / " + parts[1];
            newData.positionStr = newPosStr;
            if (lenSecs > 0)
                newData.percent = (posSecs / lenSecs) * 100;

            barData.musicData = newData;
        }
    }

    Process {
        id: mprisWatcher
        running: true
        command: ["bash", "-c", "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" \"type='signal',interface='org.mpris.MediaPlayer2.Player',member='Seeked'\" 2>/dev/null | grep -m 1 'member=' > /dev/null || sleep 2"]
        onExited: {
            musicForceRefresh.running = false;
            musicForceRefresh.running = true;
            running = false;
            running = true;
        }
    }

    Timer {
        id: artRetryTimer
        interval: 2000
        repeat: true
        running: barData.artRetries < 5 && barData.displayArtUrl.indexOf("placeholder_blank.png") !== -1
        onTriggered: {
            barData.artRetries++;
            musicForceRefresh.running = false;
            musicForceRefresh.running = true;
        }
    }

    Process {
        id: kbPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && barData.kbLayout !== txt)
                    barData.kbLayout = txt;
                kbWaiter.running = false;
                kbWaiter.running = true;
                barData.fastPollerLoaded = true;
            }
        }
    }
    Process {
        id: kbWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_wait.sh"]
        onExited: {
            kbPoller.running = false;
            kbPoller.running = true;
        }
    }

    Process {
        id: audioPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        let newVol = data.volume.toString() + "%";
                        if (barData.volPercent !== newVol)
                            barData.volPercent = newVol;
                        if (barData.volIcon !== data.icon)
                            barData.volIcon = data.icon;
                        let newMuted = (data.is_muted === "true");
                        if (barData.isMuted !== newMuted)
                            barData.isMuted = newMuted;
                    } catch (e) {}
                }
                audioWaiter.running = false;
                audioWaiter.running = true;
            }
        }
    }
    Process {
        id: audioWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_wait.sh"]
        onExited: {
            audioPoller.running = false;
            audioPoller.running = true;
        }
    }

    Process {
        id: networkPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        if (barData.wifiStatus !== data.status)
                            barData.wifiStatus = data.status;
                        if (barData.wifiIcon !== data.icon)
                            barData.wifiIcon = data.icon;
                        if (barData.wifiSsid !== data.ssid)
                            barData.wifiSsid = data.ssid;
                        if (barData.ethStatus !== data.eth_status)
                            barData.ethStatus = data.eth_status;
                    } catch (e) {}
                }
                networkWaiter.running = false;
                networkWaiter.running = true;
            }
        }
    }
    Process {
        id: networkWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_wait.sh"]
        onExited: {
            networkPoller.running = false;
            networkPoller.running = true;
        }
    }

    Process {
        id: btPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        if (barData.btStatus !== data.status)
                            barData.btStatus = data.status;
                        if (barData.btIcon !== data.icon)
                            barData.btIcon = data.icon;
                        if (barData.btDevice !== data.connected)
                            barData.btDevice = data.connected;
                    } catch (e) {}
                }
                btWaiter.running = false;
                btWaiter.running = true;
            }
        }
    }
    Process {
        id: btWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_wait.sh"]
        onExited: {
            btPoller.running = false;
            btPoller.running = true;
        }
    }

    Process {
        id: batteryPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        let newBat = data.percent.toString() + "%";
                        if (barData.batPercent !== newBat)
                            barData.batPercent = newBat;
                        if (barData.batIcon !== data.icon)
                            barData.batIcon = data.icon;
                        if (barData.batStatus !== data.status)
                            barData.batStatus = data.status;
                    } catch (e) {}
                }
                batteryWaiter.running = false;
                batteryWaiter.running = true;
            }
        }
    }
    Process {
        id: batteryWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]
        onExited: {
            batteryPoller.running = false;
            batteryPoller.running = true;
        }
    }

    Process {
        id: weatherPoller
        command: ["bash", "-c", `
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 3) {
                    barData.weatherIcon = lines[0];
                    barData.weatherTemp = lines[1];
                    barData.weatherHex = lines[2] || Theme.yellow;
                }
            }
        }
    }
    Timer {
        interval: 150000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            weatherPoller.running = false;
            weatherPoller.running = true;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            barData.timeStr = Qt.formatDateTime(d, "HH:mm:ss");
            barData.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
        }
    }
}
