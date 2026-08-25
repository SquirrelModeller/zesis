pragma ComponentBehavior: Bound
import QtQuick
import "../shared/panels"
import "../config"
import "../themeswitcher"
import "../clock"
import "../appswitcher"
import "../workspaceindicator"
import "../display"
import "../bluetooth"
import "../wifi"
import "../sound"
import "../mic"
import "../user"
import "../about"
import "../../"

IndexedPanelShell {
    id: root
    anchors.fill: parent
    windowService: SettingsWindowService
    title: I18n.t("settings_chrome.title")

    pages: [
        {
            id: "appearance",
            icon: "󰘮",
            label: I18n.t("settings_chrome.navAppearance")
        },
        {
            id: "barWidgets",
            icon: "󰕪",
            label: I18n.t("settings_chrome.navBarWidgets")
        },
        {
            id: "devices",
            icon: "",
            label: I18n.t("settings_chrome.navDevices")
        },
        {
            id: "account",
            icon: "",
            label: I18n.t("settings_chrome.navAccount"),
            component: userPanelComp,
            files: ["user/UserPanel.qml"]
        },
        {
            id: "about",
            icon: "",
            label: I18n.t("settings_chrome.navAbout"),
            component: aboutComp,
            files: ["about/About.qml"]
        }
    ]

    subTabsByPage: ({
            "appearance": [
                {
                    id: "appearance",
                    icon: "󰘮",
                    label: I18n.t("settings_chrome.navAppearance"),
                    component: appearancePanelComp,
                    files: ["config/AppearancePanel.qml"]
                },
                {
                    id: "wallpaper",
                    icon: "",
                    label: I18n.t("settings_chrome.navWallpaper"),
                    component: wallpaperPanelComp,
                    files: ["themeswitcher/WallpaperPanel.qml"]
                }
            ],
            "barWidgets": [
                {
                    id: "bar",
                    icon: "󰕪",
                    label: I18n.t("settings_chrome.navBar"),
                    component: barPanelComp,
                    files: ["config/BarPanel.qml"]
                },
                {
                    id: "clock",
                    icon: "",
                    label: I18n.t("settings_chrome.navClock"),
                    component: clockPanelComp,
                    files: ["clock/ClockPanel.qml"]
                },
                {
                    id: "appswitcher",
                    icon: "",
                    label: I18n.t("settings_chrome.navAppSwitcher"),
                    component: appSwitcherPanelComp,
                    files: ["appswitcher/AppSwitcherPanel.qml"]
                },
                {
                    id: "workspace",
                    icon: "",
                    label: I18n.t("settings_chrome.navWorkspace"),
                    component: workspaceIndicatorPanelComp,
                    files: ["workspaceindicator/WorkspaceIndicatorPanel.qml", "workspaceindicator/disc/WorkspaceDiscPanel.qml"]
                }
            ],
            "devices": [
                {
                    id: "display",
                    icon: "",
                    label: I18n.t("settings_chrome.navDisplay"),
                    component: displayPanelComp,
                    files: ["display/DisplayPanel.qml"]
                },
                {
                    id: "bluetooth",
                    icon: "󰂯",
                    label: I18n.t("settings_chrome.navBluetooth"),
                    component: bluetoothPanelComp,
                    files: ["bluetooth/BluetoothPanel.qml"]
                },
                {
                    id: "wifi",
                    icon: "󰤨",
                    label: I18n.t("settings_chrome.navWifi"),
                    component: wifiPanelComp,
                    files: ["wifi/WifiPanel.qml"]
                },
                {
                    id: "sound",
                    icon: "󰕾",
                    label: I18n.t("settings_chrome.navSound"),
                    component: soundPanelComp,
                    files: ["sound/Sound.qml"]
                },
                {
                    id: "microphone",
                    icon: "󰍬",
                    label: I18n.t("settings_chrome.navMicrophone"),
                    component: micPanelComp,
                    files: ["mic/Mic.qml"]
                }
            ]
        })

    Component {
        id: appearancePanelComp
        AppearancePanel {}
    }
    Component {
        id: wallpaperPanelComp
        WallpaperPanel {}
    }
    Component {
        id: barPanelComp
        BarPanel {}
    }
    Component {
        id: clockPanelComp
        ClockPanel {}
    }
    Component {
        id: appSwitcherPanelComp
        AppSwitcherPanel {}
    }
    Component {
        id: workspaceIndicatorPanelComp
        WorkspaceIndicatorPanel {}
    }
    Component {
        id: displayPanelComp
        DisplayPanel {}
    }
    Component {
        id: bluetoothPanelComp
        BluetoothPanel {}
    }
    Component {
        id: wifiPanelComp
        WifiPanel {}
    }
    Component {
        id: soundPanelComp
        Sound {}
    }
    Component {
        id: micPanelComp
        Mic {}
    }
    Component {
        id: userPanelComp
        UserPanel {}
    }
    Component {
        id: aboutComp
        About {}
    }
}
