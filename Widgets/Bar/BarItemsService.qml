pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var items: [
        {
            id: "systray",
            label: "System Tray",
            src: "SystrayItems.qml"
        },
        {
            id: "sysmon",
            label: "System Monitor",
            src: "../SysMon/SysMonItem.qml"
        },
        {
            id: "theme",
            label: "Theme Switcher",
            src: "../ThemeSwitcher/ThemeSwitcherItem.qml"
        },
        {
            id: "keybinds",
            label: "Keybinds",
            src: "../Keybinds/KeybindsItem.qml"
        },
        {
            id: "bluetooth",
            label: "Bluetooth",
            src: "../Bluetooth/BluetoothItem.qml"
        },
        {
            id: "airpods",
            label: "AirPods",
            src: "../AirPods/AirPods.qml"
        },
        {
            id: "wifi",
            label: "Wi-Fi",
            src: "../Wifi/WifiItem.qml"
        },
        {
            id: "weather",
            label: "Weather",
            src: "../Weather/WeatherItem.qml"
        },
        {
            id: "brightness",
            label: "Brightness",
            src: "../Brightness/BrightnessItem.qml"
        },
        {
            id: "sound",
            label: "Sound",
            src: "../Sound/SoundItem.qml"
        },
        {
            id: "mic",
            label: "Microphone",
            src: "../Mic/MicItem.qml"
        },
        {
            id: "notifications",
            label: "Notifications",
            src: "../Notifications/NotificationsItem.qml"
        },
        {
            id: "config",
            label: "Config",
            src: "../Config/ConfigItem.qml"
        },
        {
            id: "battery",
            label: "Battery",
            src: "../Battery/BatteryItem.qml"
        },
        {
            id: "record",
            label: "Record",
            src: "../Record/RecordItem.qml"
        },
        {
            id: "home",
            label: "Home",
            icon: ""
        },
        {
            id: "lock",
            label: "Lock",
            icon: "󰌾"
        },
        {
            id: "clock",
            label: "Clock",
            src: "../Clock/ClockItem.qml"
        },
    ]

    property var _state: {
        const s = {};
        for (const item of items)
            s[item.id] = true;
        return s;
    }

    readonly property bool anyEnabled: {
        const s = _state;
        return items.some(item => s[item.id] !== false);
    }

    function isEnabled(id) {
        return _state[id] !== false;
    }

    function toggle(id) {
        const s = Object.assign({}, _state);
        s[id] = !isEnabled(id);
        _state = s;
        BarConfig.writeItemStates(s);
    }

    function _merge() {
        const raw = BarConfig.itemStates;
        const s = Object.assign({}, raw);
        let dirty = false;
        for (const item of items) {
            if (!(item.id in s)) {
                s[item.id] = true;
                dirty = true;
            }
        }
        const known = new Set(items.map(x => x.id));
        for (const id of Object.keys(s)) {
            if (!known.has(id)) {
                delete s[id];
                dirty = true;
            }
        }
        _state = s;
        if (dirty)
            BarConfig.writeItemStates(s);
    }

    Connections {
        target: BarConfig
        function onItemStatesChanged() {
            root._merge();
        }
    }
}
