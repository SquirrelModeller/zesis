pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../"
import "../shared"
import "../shared/inputs"
import "../bar"
import "../desktop"
import "../workspaceindicator/disc"

Item {
    id: root

    // Overwrite an existing profile could be a missclick, so gaurd it.
    property string _saveArmedFor: ""
    property bool _includeTheme: true

    Timer {
        id: saveArmTimer
        interval: 3000
        onTriggered: root._saveArmedFor = ""
    }

    readonly property string _typedName: nameField.text.trim()

    readonly property int _enabledBarWidgets: {
        var n = 0;
        var items = BarItemsService.orderedItems;
        for (var i = 0; i < items.length; i++) {
            if (BarItemsService.isEnabled(items[i].id))
                n++;
        }
        return n;
    }

    function _basename(p) {
        return p ? p.substring(p.lastIndexOf("/") + 1) : "";
    }

    function _saveProfile() {
        if (ProfileService.busy)
            return;
        var name = root._typedName;
        if (name.length === 0)
            return;
        if (ProfileService.exists(name) && root._saveArmedFor !== name) {
            root._saveArmedFor = name;
            saveArmTimer.restart();
            return;
        }
        ProfileService.save(name, root._includeTheme);
        nameField.text = "";
        root._saveArmedFor = "";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("profiles.breadcrumb")
            title: I18n.t("profiles.title")
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: content.implicitHeight + UIScale.spacingLg * 2
            clip: true
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: content
                x: UIScale.panelPad
                y: UIScale.spacingLg
                width: parent.width - UIScale.panelPad * 2
                spacing: UIScale.spacingMd

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("profiles.description")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    wrapMode: Text.WordWrap
                }

                // Current setup summary

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingXs
                    spacing: UIScale.spacingSm
                    SectionLabel {
                        text: I18n.t("profiles.currentSetup")
                    }
                    InfoTooltip {
                        text: I18n.t("profiles.currentSetupHint")
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }

                SettingCard {

                    SummaryRow {
                        label: I18n.t("profiles.sumBar")
                        value: I18n.t("bar." + BarConfig.side) + " - " + (BarConfig.isVertical ? I18n.t("profiles.vertical") : I18n.t("profiles.horizontal"))
                    }
                    SummaryRow {
                        label: I18n.t("profiles.sumBarWidgets")
                        value: String(root._enabledBarWidgets)
                    }
                    SummaryRow {
                        label: I18n.t("profiles.sumDesktopWidgets")
                        value: String(DesktopWidgetStore.enabledKeys.length)
                    }
                    SummaryRow {
                        label: I18n.t("profiles.sumWorkspaces")
                        value: String(WorkspaceDiscService.workSpaceAmount)
                    }
                    SummaryRow {
                        label: I18n.t("profiles.sumScale")
                        value: I18n.t("appearance.multiplier", [UIScale.value.toFixed(2)])
                    }
                    SummaryRow {
                        label: I18n.t("profiles.sumMaterial")
                        value: SkinState.material
                    }
                    SummaryRow {
                        label: I18n.t("profiles.sumWallpaper")
                        value: root._basename(ThemeState.lastWallpaper) || "-"
                    }
                    SummaryRow {
                        label: I18n.t("profiles.sumPalette")
                        value: ThemeState.palette
                    }
                }

                Divider {}

                // Save new profile

                SectionLabel {
                    text: I18n.t("profiles.saveSection")
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingSm

                    StyledTextInput {
                        id: nameField
                        Layout.fillWidth: true
                        placeholder: I18n.t("profiles.namePlaceholder")
                        onAccepted: root._saveProfile()
                    }
                    ActionButton {
                        readonly property bool _armed: root._saveArmedFor.length > 0 && root._saveArmedFor === root._typedName
                        label: _armed ? I18n.t("profiles.saveConfirm") : I18n.t("profiles.save")
                        enabled: root._typedName.length > 0 && !ProfileService.busy
                        onActivated: root._saveProfile()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingSm
                    Text {
                        text: I18n.t("profiles.includeTheme")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }
                    ToggleSwitch {
                        checked: root._includeTheme
                        onToggled: root._includeTheme = !root._includeTheme
                    }
                }

                Divider {}

                // Saved profiles

                SectionLabel {
                    text: I18n.t("profiles.savedSection")
                }

                Text {
                    Layout.fillWidth: true
                    visible: ProfileService.profiles.length === 0
                    text: I18n.t("profiles.noneSaved")
                    color: Colors.muted
                    font.pixelSize: UIScale.fontCaption
                }

                Repeater {
                    model: ProfileService.profiles

                    delegate: Item {
                        id: profileRow
                        required property var modelData
                        readonly property string slug: profileRow.modelData.slug
                        readonly property bool isActive: ProfileService.activeSlug === profileRow.slug
                        readonly property string wallpaperPath: profileRow.modelData.wallpaper || ""
                        property bool renaming: false

                        function confirmRename() {
                            if (ProfileService.rename(profileRow.slug, renameField.text))
                                profileRow.renaming = false;
                        }

                        Layout.fillWidth: true
                        implicitHeight: rowCard.implicitHeight

                        HoverHandler {
                            id: rowHover
                        }

                        Rectangle {
                            id: rowCard
                            anchors.left: parent.left
                            anchors.right: parent.right
                            radius: UIScale.radiusMd
                            color: Colors.withAlpha(Colors.text, rowHover.hovered ? 0.05 : 0.03)
                            border.color: profileRow.isActive ? Colors.withAlpha(Colors.accent, 0.35) : Colors.withAlpha(Colors.text, 0.06)
                            border.width: 1
                            implicitHeight: rowContent.implicitHeight + UIScale.spacingMd * 2
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                enabled: !profileRow.renaming && !ProfileService.busy
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ProfileService.apply(profileRow.slug)
                            }

                            RowLayout {
                                id: rowContent
                                anchors.fill: parent
                                anchors.margins: UIScale.spacingMd
                                spacing: UIScale.spacingSm

                                Rectangle {
                                    implicitWidth: Math.round(34 * UIScale.value)
                                    implicitHeight: implicitWidth
                                    radius: UIScale.radiusSm
                                    color: Colors.surfaceHigh
                                    clip: true
                                    visible: profileRow.modelData.includesTheme && profileRow.wallpaperPath.length > 0

                                    Image {
                                        id: thumbImg
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        source: profileRow.wallpaperPath.length > 0 ? ("file://" + ThemeState.thumbsDir + "/" + root._basename(profileRow.wallpaperPath) + ".jpg") : ""
                                        onStatusChanged: {
                                            if (status === Image.Error && profileRow.wallpaperPath.length > 0)
                                                source = "file://" + profileRow.wallpaperPath;
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(2 * UIScale.value)

                                    Text {
                                        visible: !profileRow.renaming
                                        text: profileRow.modelData.name
                                        color: profileRow.isActive ? Colors.accent : Colors.text
                                        font.bold: profileRow.isActive
                                        font.pixelSize: UIScale.fontBody
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        visible: !profileRow.renaming
                                        text: {
                                            var d = new Date(profileRow.modelData.updated || profileRow.modelData.created);
                                            var when = isNaN(d.getTime()) ? "" : d.toLocaleDateString(Qt.locale());
                                            return profileRow.modelData.includesTheme ? I18n.t("profiles.metaWithTheme", [when]) : I18n.t("profiles.metaLayoutOnly", [when]);
                                        }
                                        color: Colors.textDim
                                        font.pixelSize: UIScale.fontTiny
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    StyledTextInput {
                                        id: renameField
                                        visible: profileRow.renaming
                                        Layout.fillWidth: true
                                        text: profileRow.modelData.name
                                        onAccepted: profileRow.confirmRename()
                                        onEscapePressed: profileRow.renaming = false
                                        onVisibleChanged: if (visible)
                                            field.forceActiveFocus()
                                    }
                                }

                                ActionButton {
                                    visible: profileRow.renaming
                                    label: I18n.t("profiles.renameConfirm")
                                    onActivated: profileRow.confirmRename()
                                }
                                ActionButton {
                                    visible: profileRow.renaming
                                    ghost: true
                                    label: I18n.t("profiles.renameCancel")
                                    onActivated: profileRow.renaming = false
                                }

                                ActionButton {
                                    visible: !profileRow.renaming
                                    ghost: true
                                    opacity: rowHover.hovered ? 1 : 0
                                    enabled: !ProfileService.busy
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                    label: I18n.t("profiles.rename")
                                    onActivated: profileRow.renaming = true
                                }
                                ActionButton {
                                    visible: !profileRow.renaming
                                    ghost: true
                                    opacity: rowHover.hovered ? 1 : 0
                                    enabled: !ProfileService.busy
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                    label: I18n.t("profiles.update")
                                    onActivated: ProfileService.update(profileRow.slug)
                                }
                                ActionButton {
                                    visible: !profileRow.renaming
                                    ghost: true
                                    destructive: true
                                    opacity: rowHover.hovered ? 1 : 0
                                    enabled: !ProfileService.busy
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                    label: I18n.t("profiles.delete")
                                    onActivated: ProfileService.remove(profileRow.slug)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    component SummaryRow: RowLayout {
        id: srow
        required property string label
        required property string value
        Layout.fillWidth: true
        spacing: UIScale.spacingSm
        Text {
            text: srow.label
            color: Colors.textDim
            font.pixelSize: UIScale.fontSmall
            Layout.fillWidth: true
        }
        Text {
            text: srow.value
            color: Colors.text
            font.pixelSize: UIScale.fontSmall
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
            Layout.maximumWidth: Math.round(200 * UIScale.value)
        }
    }
}
