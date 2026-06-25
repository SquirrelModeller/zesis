import QtQuick
import QtQuick.Layouts
import "../Shared"
import "../../"

Item {
    id: root

    property int activeTab: 0
    property bool _hourlyExpanded: false
    property bool _showSettings: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: root._showSettings ? "WEATHER / SETTINGS" : (WeatherService.locationName !== "" ? WeatherService.locationName.toUpperCase() : "WEATHER")
            title: root._showSettings ? "Settings" : WeatherService.conditionText(WeatherService.weatherCode)
        }

        WeatherDisplay {
            Layout.fillWidth: true
            visible: !root._showSettings
        }

        // Tab bar
        Item {
            Layout.fillWidth: true
            implicitHeight: Math.round(32 * UIScale.value)
            visible: !root._showSettings

            Row {
                anchors.centerIn: parent
                spacing: UIScale.spacingXs

                Rectangle {
                    implicitWidth: hourlyLabel.implicitWidth + Math.round(18 * UIScale.value)
                    implicitHeight: Math.round(26 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: root.activeTab === 0 ? Colors.withAlpha(Colors.accent, 0.15) : "transparent"
                    border.color: root.activeTab === 0 ? Colors.withAlpha(Colors.accent, 0.3) : "transparent"
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        id: hourlyLabel
                        anchors.centerIn: parent
                        text: "Hourly"
                        font.pixelSize: UIScale.fontSmall
                        font.weight: root.activeTab === 0 ? Font.DemiBold : Font.Normal
                        color: root.activeTab === 0 ? Colors.accent : Colors.textDim
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = 0
                    }
                }

                Rectangle {
                    implicitWidth: weeklyLabel.implicitWidth + Math.round(18 * UIScale.value)
                    implicitHeight: Math.round(26 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: root.activeTab === 1 ? Colors.withAlpha(Colors.accent, 0.15) : "transparent"
                    border.color: root.activeTab === 1 ? Colors.withAlpha(Colors.accent, 0.3) : "transparent"
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        id: weeklyLabel
                        anchors.centerIn: parent
                        text: "Weekly"
                        font.pixelSize: UIScale.fontSmall
                        font.weight: root.activeTab === 1 ? Font.DemiBold : Font.Normal
                        color: root.activeTab === 1 ? Colors.accent : Colors.textDim
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = 1
                    }
                }
            }
        }

        // Tab content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root._showSettings

            // Hourly list + "more" row
            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                visible: root.activeTab === 0

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    topMargin: UIScale.spacingXs
                    bottomMargin: UIScale.spacingXs
                    clip: true
                    model: root._hourlyExpanded ? WeatherService.hourly : WeatherService.hourly.slice(0, 5)
                    spacing: Math.round(2 * UIScale.value)

                    delegate: Item {
                        id: hourRow
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        implicitHeight: Math.round(42 * UIScale.value)

                        Rectangle {
                            anchors {
                                fill: parent
                                leftMargin: UIScale.spacingMd
                                rightMargin: UIScale.spacingMd
                            }
                            radius: UIScale.radiusSm
                            color: hourRow.modelData.isCurrent ? Colors.withAlpha(Colors.accent, 0.08) : "transparent"

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: UIScale.spacingSm
                                    rightMargin: UIScale.spacingSm
                                }
                                spacing: UIScale.spacingSm

                                Text {
                                    text: hourRow.modelData.timeLabel
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: hourRow.modelData.isCurrent ? Font.DemiBold : Font.Normal
                                    color: hourRow.modelData.isCurrent ? Colors.accent : Colors.text
                                    Layout.preferredWidth: Math.round(52 * UIScale.value)
                                }

                                Text {
                                    text: WeatherService.weatherIcon(hourRow.modelData.weatherCode, hourRow.modelData.hour >= 6 && hourRow.modelData.hour < 20)
                                    font.pixelSize: Math.round(18 * UIScale.value)
                                    color: Colors.text
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    visible: hourRow.modelData.precipProb > 10
                                    implicitWidth: hourPrecipTxt.implicitWidth + Math.round(8 * UIScale.value)
                                    implicitHeight: Math.round(16 * UIScale.value)
                                    radius: Math.round(4 * UIScale.value)
                                    color: Colors.withAlpha("#4A9EFF", 0.15)

                                    Text {
                                        id: hourPrecipTxt
                                        anchors.centerIn: parent
                                        text: hourRow.modelData.precipProb + "%"
                                        font.pixelSize: UIScale.fontTiny
                                        color: "#4A9EFF"
                                    }
                                }

                                Text {
                                    text: hourRow.modelData.temperature + "°"
                                    font.pixelSize: UIScale.fontSmall
                                    color: Colors.text
                                    Layout.preferredWidth: Math.round(36 * UIScale.value)
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }

                // "More" row
                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * UIScale.value)
                    visible: !root._hourlyExpanded && WeatherService.hourly.length > 5

                    Text {
                        anchors.centerIn: parent
                        text: "+" + (WeatherService.hourly.length - 5) + " more hours"
                        font.pixelSize: UIScale.fontTiny
                        font.weight: Font.DemiBold
                        color: moreHov.hovered ? Colors.text : Colors.textDim
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    HoverHandler {
                        id: moreHov
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._hourlyExpanded = true
                    }
                }
            }

            // Weekly list
            ListView {
                anchors.fill: parent
                anchors.topMargin: UIScale.spacingXs
                anchors.bottomMargin: UIScale.spacingXs
                visible: root.activeTab === 1
                clip: true
                model: WeatherService.daily
                spacing: Math.round(2 * UIScale.value)

                delegate: Item {
                    id: dayRow
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    implicitHeight: Math.round(42 * UIScale.value)

                    Rectangle {
                        anchors {
                            fill: parent
                            leftMargin: UIScale.spacingMd
                            rightMargin: UIScale.spacingMd
                        }
                        radius: UIScale.radiusSm
                        color: dayRow.index === 0 ? Colors.withAlpha(Colors.accent, 0.08) : "transparent"

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: UIScale.spacingSm
                                rightMargin: UIScale.spacingSm
                            }
                            spacing: UIScale.spacingSm

                            Text {
                                text: dayRow.modelData.label
                                font.pixelSize: UIScale.fontSmall
                                font.weight: dayRow.index === 0 ? Font.DemiBold : Font.Normal
                                color: Colors.text
                                Layout.preferredWidth: Math.round(72 * UIScale.value)
                            }

                            Text {
                                text: WeatherService.weatherIcon(dayRow.modelData.weatherCode, true)
                                font.pixelSize: Math.round(18 * UIScale.value)
                                color: Colors.text
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: dayRow.modelData.precipProb > 10
                                implicitWidth: dayPrecipTxt.implicitWidth + Math.round(8 * UIScale.value)
                                implicitHeight: Math.round(16 * UIScale.value)
                                radius: Math.round(4 * UIScale.value)
                                color: Colors.withAlpha("#4A9EFF", 0.15)

                                Text {
                                    id: dayPrecipTxt
                                    anchors.centerIn: parent
                                    text: dayRow.modelData.precipProb + "%"
                                    font.pixelSize: UIScale.fontTiny
                                    color: "#4A9EFF"
                                }
                            }

                            Text {
                                text: dayRow.modelData.tempMax + "° / " + dayRow.modelData.tempMin + "°"
                                font.pixelSize: UIScale.fontSmall
                                color: Colors.text
                                Layout.preferredWidth: Math.round(68 * UIScale.value)
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }

        // Settings content
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root._showSettings
            contentWidth: width
            contentHeight: settingsCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            TapHandler {
                onTapped: root.forceActiveFocus()
            }

            ColumnLayout {
                id: settingsCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                Text {
                    text: "LOCATION"
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: UIScale.panelPad
                }

                OptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    model: ["Auto", "Manual"]
                    currentIndex: WeatherService.locationMode === "manual" ? 1 : 0
                    onActivated: index => {
                        WeatherService.saveLocationMode(index === 1 ? "manual" : "auto");
                        if (index === 0)
                            WeatherService.refresh();
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    visible: WeatherService.locationMode === "manual"
                    spacing: UIScale.spacingXs

                    Text {
                        text: "City"
                        color: Colors.text
                        font.pixelSize: UIScale.fontSmall
                        font.weight: Font.DemiBold
                    }

                    StyledTextInput {
                        Layout.fillWidth: true
                        placeholder: "e.g. London"
                        text: WeatherService.manualCity
                        onAccepted: {
                            var city = field.text.trim();
                            if (city.length > 0) {
                                WeatherService.saveManualCity(city);
                                WeatherService.refresh();
                            }
                            root.forceActiveFocus();
                        }
                        field.onActiveFocusChanged: {
                            if (!field.activeFocus) {
                                var city = field.text.trim();
                                if (city.length > 0) {
                                    WeatherService.saveManualCity(city);
                                    WeatherService.refresh();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Error strip
        Text {
            text: WeatherService.error
            color: Colors.textDim
            font.pixelSize: UIScale.fontTiny
            visible: WeatherService.error !== ""
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: UIScale.spacingSm
        }
    }

    // Action buttons overlaid on the header area, outside any Component so root is in scope
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: UIScale.panelPad
        height: Math.round(72 * UIScale.value)
        spacing: Math.round(14 * UIScale.value)
        z: 1

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            font.pixelSize: Math.round(16 * UIScale.value)
            color: root._showSettings ? Colors.accent : (settingsHov.hovered ? Colors.text : Colors.textDim)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            HoverHandler {
                id: settingsHov
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root._showSettings = !root._showSettings
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰑓"
            font.pixelSize: Math.round(16 * UIScale.value)
            color: refreshHov.hovered ? Colors.text : Colors.textDim
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            RotationAnimator on rotation {
                running: WeatherService.loading
                from: 0
                to: 360
                duration: 800
                loops: Animation.Infinite
            }
            HoverHandler {
                id: refreshHov
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: WeatherService.refresh()
            }
        }
    }
}
