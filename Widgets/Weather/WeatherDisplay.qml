import QtQuick
import "../../"

Item {
    id: root

    implicitWidth: contentRow.implicitWidth
    implicitHeight: Math.round(80 * UIScale.value)

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
            spacing: Math.round(2 * UIScale.value)

            Text {
                text: WeatherService.temperature + "°C"
                font.pixelSize: Math.round(28 * UIScale.value)
                font.weight: Font.Light
                color: Colors.text
            }

            Text {
                text: WeatherService.conditionText(WeatherService.weatherCode)
                font.pixelSize: UIScale.fontCaption
                color: Colors.textDim
            }

            Row {
                spacing: Math.round(10 * UIScale.value)

                Text {
                    text: "󰖌 " + WeatherService.humidity + "%"
                    font.pixelSize: UIScale.fontCaption
                    color: Colors.textDim
                }

                Text {
                    text: "󰖝 " + WeatherService.windspeed + " km/h"
                    font.pixelSize: UIScale.fontCaption
                    color: Colors.textDim
                }
            }
        }
    }
}
