pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../clock"
import "../weather"
import "../sysmon"
import "../globe2d"
import "../power"
import "../cava"
import "../../"

Singleton {
    id: root

    readonly property var entries: [
        {
            key: "desktop-clock",
            label: I18n.t("desktop.desktopClockLabel"),
            description: I18n.t("desktop.desktopClockDescription"),
            component: _desktopClockComp
        },
        {
            key: "bar-clock",
            label: I18n.t("desktop.barClockLabel"),
            description: I18n.t("desktop.barClockDescription"),
            component: _barClockComp
        },
        {
            key: "weather",
            label: I18n.t("desktop.weatherLabel"),
            description: I18n.t("desktop.weatherDescription"),
            component: _weatherComp
        },
        {
            key: "sysmon",
            label: I18n.t("desktop.sysmonLabel"),
            description: I18n.t("desktop.sysmonDescription"),
            component: _sysmonComp
        },
        {
            key: "globe2d",
            label: I18n.t("desktop.globe2dLabel"),
            description: I18n.t("desktop.globe2dDescription"),
            component: _globe2dComp
        },
        {
            key: "vending",
            label: I18n.t("desktop.vendingLabel"),
            description: I18n.t("desktop.vendingDescription"),
            component: _vendingComp
        },
        {
            key: "cava",
            label: I18n.t("desktop.cavaLabel"),
            description: I18n.t("desktop.cavaDescription"),
            component: _cavaComp
        },
        {
            key: "cava-left",
            label: I18n.t("desktop.cavaLeftLabel"),
            description: I18n.t("desktop.cavaLeftDescription"),
            component: _cavaLeftComp
        },
        {
            key: "cava-right",
            label: I18n.t("desktop.cavaRightLabel"),
            description: I18n.t("desktop.cavaRightDescription"),
            component: _cavaRightComp
        }
    ]

    function componentFor(key) {
        for (var i = 0; i < entries.length; i++)
            if (entries[i].key === key)
                return entries[i].component;
        return null;
    }

    Component {
        id: _desktopClockComp
        DesktopClock {}
    }
    Component {
        id: _barClockComp
        Clock {}
    }
    Component {
        id: _weatherComp
        WeatherDisplay {}
    }

    Component {
        id: _sysmonComp
        SysMonDesktopWidget {}
    }
    Component {
        id: _globe2dComp
        Globe2DDesktopWidget {}
    }
    Component {
        id: _vendingComp
        VendingMachine {}
    }
    Component {
        id: _cavaComp
        CavaVisualizer {}
    }
    Component {
        id: _cavaLeftComp
        CavaVisualizer {
            channel: "left"
        }
    }
    Component {
        id: _cavaRightComp
        CavaVisualizer {
            channel: "right"
        }
    }
}
