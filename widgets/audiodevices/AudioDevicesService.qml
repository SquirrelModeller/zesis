pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "airpods"
import "gamebuds"

// Unified view over whichever earbud backend is currently connected
Singleton {
    id: root

    // "airpods" | "gamebuds" | ""
    readonly property string source: AirPodsService.connected ? "airpods" : (GameBudsService.connected ? "gamebuds" : "")
    readonly property bool connected: source !== ""

    readonly property string deviceName: {
        if (source === "airpods")
            return AirPodsService.deviceName || "AirPods";
        if (source === "gamebuds")
            return GameBudsService.deviceName || "GameBuds";
        return "";
    }

    readonly property int leftLevel: source === "airpods" ? AirPodsService.leftLevel : (source === "gamebuds" ? GameBudsService.leftLevel : 0)
    readonly property int rightLevel: source === "airpods" ? AirPodsService.rightLevel : (source === "gamebuds" ? GameBudsService.rightLevel : 0)
    readonly property int caseLevel: source === "airpods" ? AirPodsService.caseLevel : (source === "gamebuds" ? GameBudsService.caseLevel : 0)
    readonly property bool hasCase: caseLevel > 0

    // GameBuds doesn't report charge state per component
    readonly property bool leftCharging: source === "airpods" && AirPodsService.leftCharging
    readonly property bool rightCharging: source === "airpods" && AirPodsService.rightCharging
    readonly property bool caseCharging: source === "airpods" && AirPodsService.caseCharging

    readonly property bool leftEar: {
        if (source === "airpods")
            return AirPodsService.leftEar;
        if (source === "gamebuds")
            return GameBudsService.wearSenseStatus !== false;
        return false;
    }
    readonly property bool rightEar: {
        if (source === "airpods")
            return AirPodsService.rightEar;
        if (source === "gamebuds")
            return GameBudsService.wearSenseStatus !== false;
        return false;
    }
}
