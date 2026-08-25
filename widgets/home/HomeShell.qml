pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../shared/panels"
import "../community"
import "../network"
import "../sysmon"
import "../nixpurity"
import "../notifications"
import "../calendar"
import "../globe3d"
import "../../"

IndexedPanelShell {
    id: root
    anchors.fill: parent
    windowService: HomeWindowService
    title: I18n.t("home.title")
    subTabsByPage: ({})

    readonly property bool _devMode: !!Quickshell.env("ZESIS_DEV")

    pages: {
        var base = [
            {
                id: "home",
                icon: "",
                label: I18n.t("home.navHome"),
                component: dashboardComp
            },
            {
                id: "community",
                icon: "",
                label: I18n.t("home.navCommunity"),
                component: communityPanelComp,
                files: ["community/CommunityPanel.qml"]
            },
            {
                id: "network",
                icon: "",
                label: I18n.t("home.navNetwork"),
                component: networkPanelComp,
                files: ["network/NetworkPanel.qml"]
            },
            {
                id: "sysmon",
                icon: "",
                label: I18n.t("home.navSysMon"),
                component: sysMonPanelComp,
                files: ["sysmon/SysMonPanel.qml"]
            }
        ];
        if (NixPurityService.isNixOS)
            base.push({
                id: "nixpurity",
                icon: "󱄅",
                label: I18n.t("home.navNixPurity"),
                component: nixPurityComp,
                files: ["nixpurity/NixPurity.qml"]
            });
        base.push({
            id: "notifs",
            icon: "",
            label: I18n.t("home.navNotifications"),
            component: notifHistComp,
            files: ["notifications/NotifHistory.qml"]
        });
        base.push({
            id: "calendar",
            icon: "󰺻",
            label: I18n.t("home.navCalendar"),
            component: calendarPanelComp,
            files: ["calendar/CalendarPanel.qml"]
        });
        if (root._devMode) {
            base.push({
                id: "responsivetest",
                icon: "󰙨",
                label: I18n.t("home.navResponsiveTest"),
                component: responsiveTestComp
            });
            base.push({
                id: "assemblytest",
                icon: "󰙨",
                label: I18n.t("home.navAssemblyTest"),
                component: assemblyTestComp
            });
        }
        return base;
    }

    Component {
        id: dashboardComp
        DashboardPanel {}
    }
    Component {
        id: communityPanelComp
        CommunityPanel {}
    }
    Component {
        id: networkPanelComp
        NetworkPanel {}
    }
    Component {
        id: sysMonPanelComp
        SysMonPanel {}
    }
    Component {
        id: nixPurityComp
        NixPurity {}
    }
    Component {
        id: notifHistComp
        NotifHistory {}
    }
    Component {
        id: calendarPanelComp
        CalendarPanel {}
    }
    Component {
        id: responsiveTestComp
        ResponsiveTestPanel {}
    }
    Component {
        id: assemblyTestComp
        Globe3DGate {
            panelSource: "AssemblyTest.qml"
        }
    }
}
