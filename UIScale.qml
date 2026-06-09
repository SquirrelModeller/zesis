pragma Singleton
import Quickshell

Singleton {
    property real value: 1

    readonly property real fontXs: 8 * value
    readonly property real fontSm: 9 * value
    readonly property real fontMd: 10 * value
    readonly property real fontLg: 11 * value

    readonly property real spacingSm: 8 * value
    readonly property real spacingMd: 14 * value
    readonly property real spacingLg: 20 * value

    readonly property real radiusSm: 6 * value
    readonly property real radiusMd: 10 * value
    readonly property real radiusLg: 14 * value
}
