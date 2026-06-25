import QtQuick
import "../../"

Item {
    id: root

    implicitWidth: contentRow.implicitWidth
    implicitHeight: Math.round(74 * UIScale.value)

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: UIScale.spacingMd

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.weatherIcon(WeatherService.weatherCode, WeatherService.isDay)
            font.pixelSize: Math.round(44 * UIScale.value)
            color: Colors.text
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(3 * UIScale.value)

            Text {
                text: WeatherService.temperature + "°C"
                font.pixelSize: Math.round(28 * UIScale.value)
                font.weight: Font.Light
                color: Colors.text
            }

            Text {
                text: "Wind  " + WeatherService.windspeed + " km/h"
                font.pixelSize: UIScale.fontCaption
                color: Colors.textDim
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(4 * UIScale.value)
        visible: WeatherService.currentPrecipProb > 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰖗"
            font.pixelSize: Math.round(13 * UIScale.value)
            color: "#4A9EFF"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.currentPrecipProb + "%"
            font.pixelSize: UIScale.fontCaption
            color: "#4A9EFF"
        }
    }
}
