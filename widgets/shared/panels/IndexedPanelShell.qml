pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../../../"
import "../"
import "../inputs"

// This indexes all files
Item {
    id: root
    focus: true

    required property var pages // [{id, icon, label, component?, files?}]
    required property var subTabsByPage // {pageId: [{id, icon, label, component, files}]}
    required property RequestableWindowState windowService
    required property string title

    property int currentIndex: 0
    property string searchText: ""

    // Show sub-tabs of category
    onCurrentIndexChanged: root.syncNavModel()

    function matchesSearch(label) {
        return root.searchText === "" || label.toLowerCase().includes(root.searchText.toLowerCase());
    }

    // Enables keywords in the page like 'radius' to be searchable and show
    // Apperance as the page containing the option.
    readonly property var _filesForPage: {
        var out = {};
        for (var i = 0; i < root.pages.length; i++) {
            var page = root.pages[i];
            var subs = root.subTabsByPage[page.id];
            out[page.id] = subs ? subs.reduce((acc, s) => acc.concat(s.files), []) : (page.files || []);
        }
        return out;
    }

    readonly property var _allIndexFiles: {
        var seen = {};
        var out = [];
        for (var pageId in root._filesForPage) {
            var files = root._filesForPage[pageId];
            for (var i = 0; i < files.length; i++) {
                if (seen[files[i]])
                    continue;
                seen[files[i]] = true;
                out.push(files[i]);
            }
        }
        return out;
    }

    PanelContentIndex {
        id: contentIndex
        files: root._allIndexFiles

        onReadyChanged: {
            if (ready)
                root.syncNavModel();
        }
    }

    function pageMatchesIndex(pageId) {
        var files = root._filesForPage[pageId];
        if (!files)
            return false;
        var entries = contentIndex.entries;
        for (var i = 0; i < entries.length; i++) {
            if (files.indexOf(entries[i].file) === -1)
                continue;
            if (root.matchesSearch(contentIndex.labelFor(entries[i])))
                return true;
        }
        return false;
    }

    // For the current search, which one of the sub-tabs owns the index entry
    function subTabIndexMatchingIndex(pageId) {
        var subs = root.subTabsByPage[pageId];
        if (!subs)
            return -1;
        var entries = contentIndex.entries;
        for (var s = 0; s < subs.length; s++) {
            var files = subs[s].files;
            if (!files)
                continue;
            for (var i = 0; i < entries.length; i++) {
                if (files.indexOf(entries[i].file) === -1)
                    continue;
                if (root.matchesSearch(contentIndex.labelFor(entries[i])))
                    return s;
            }
        }
        return -1;
    }

    // Current sub-tab which is showing for the current category which is open
    property int activeSubIndex: 0

    function hasSubTabs(pageId) {
        return !!root.subTabsByPage[pageId];
    }

    function subTabMatches(pageId) {
        var subs = root.subTabsByPage[pageId];
        if (!subs)
            return false;
        for (var i = 0; i < subs.length; i++)
            if (root.matchesSearch(subs[i].label))
                return true;
        return false;
    }

    function pageMatches(page) {
        return root.matchesSearch(page.label) || root.pageMatchesIndex(page.id) || root.subTabMatches(page.id);
    }

    // It is what the function says.
    // Sub-tabs own name is fist, category name is less important
    function bestMatch() {
        if (root.searchText === "")
            return null;
        for (var i = 0; i < root.pages.length; i++) {
            if (root.matchesSearch(root.pages[i].label))
                continue;
            var subs = root.subTabsByPage[root.pages[i].id];
            if (!subs)
                continue;
            for (var s = 0; s < subs.length; s++) {
                if (root.matchesSearch(subs[s].label))
                    return {
                        pageIndex: i,
                        subIndex: s
                    };
            }
        }
        for (var j = 0; j < root.pages.length; j++) {
            if (root.matchesSearch(root.pages[j].label))
                return {
                    pageIndex: j,
                    subIndex: 0
                };
        }
        for (var k = 0; k < root.pages.length; k++) {
            if (root.pageMatchesIndex(root.pages[k].id)) {
                var matchedSub = root.subTabIndexMatchingIndex(root.pages[k].id);
                return {
                    pageIndex: k,
                    subIndex: matchedSub === -1 ? 0 : matchedSub
                };
            }
        }
        return null;
    }

    function isCategoryExpanded(pageIndex) {
        return pageIndex === root.currentIndex || root.windowService.expandAllSubTabs;
    }

    function _currentNavRowIndex() {
        for (var i = 0; i < navModel.count; i++) {
            var row = navModel.get(i);
            if (row.rowKind === "subtab") {
                if (row.pageIndex === root.currentIndex && row.subIndex === root.activeSubIndex)
                    return i;
            } else if (row.pageIndex === root.currentIndex && !root.hasSubTabs(root.pages[row.pageIndex].id)) {
                return i;
            }
        }
        return -1;
    }

    // Let's user use keyboard for walking between sub-tab rows
    function _stepSelection(dir) {
        if (navModel.count === 0)
            return;
        var start = root._currentNavRowIndex();
        var pos = start === -1 ? 0 : start;
        var row;
        for (var i = 0; i < navModel.count; i++) {
            pos = (pos + dir + navModel.count) % navModel.count;
            row = navModel.get(pos);
            if (row.rowKind === "subtab")
                break;
            var subs = root.subTabsByPage[root.pages[row.pageIndex].id];
            if (!subs || !root.isCategoryExpanded(row.pageIndex))
                break;
        }
        if (row.rowKind === "subtab") {
            root.activeSubIndex = row.subIndex;
        } else {
            var landingSubs = root.subTabsByPage[root.pages[row.pageIndex].id];
            root.activeSubIndex = (dir < 0 && landingSubs && !root.isCategoryExpanded(row.pageIndex)) ? landingSubs.length - 1 : 0;
        }
        root.currentIndex = row.pageIndex;
    }

    function activeComponent() {
        var page = root.pages[root.currentIndex];
        var subs = root.subTabsByPage[page.id];
        if (subs)
            return subs[subs[root.activeSubIndex] ? root.activeSubIndex : 0].component;
        return page.component;
    }

    // We have to keep navModels item order synced up with the pages that
    // match the searched fo text.
    function syncNavModel() {
        var wanted = [];
        for (var i = 0; i < root.pages.length; i++) {
            var page = root.pages[i];
            if (!root.pageMatches(page))
                continue;
            wanted.push({
                key: "cat:" + i,
                rowKind: "category",
                pageIndex: i,
                subIndex: -1,
                isFirst: false,
                isLast: false
            });
            var subs = root.subTabsByPage[page.id] || [];
            var isOpenCategory = root.isCategoryExpanded(i);
            for (var s = 0; s < subs.length; s++) {
                var show = isOpenCategory || (root.searchText !== "" && !root.matchesSearch(page.label) && root.matchesSearch(subs[s].label));
                if (show)
                    wanted.push({
                        key: "sub:" + i + ":" + s,
                        rowKind: "subtab",
                        pageIndex: i,
                        subIndex: s,
                        isFirst: s === 0,
                        isLast: s === subs.length - 1
                    });
            }
        }

        for (var r = navModel.count - 1; r >= 0; r--) {
            var existingKey = navModel.get(r).rowKey;
            var stillWanted = wanted.some(w => w.key === existingKey);
            if (!stillWanted)
                navModel.remove(r);
        }
        for (var w = 0; w < wanted.length; w++) {
            var alreadyIn = false;
            for (var j = 0; j < navModel.count; j++) {
                if (navModel.get(j).rowKey === wanted[w].key) {
                    alreadyIn = true;
                    break;
                }
            }
            if (!alreadyIn) {
                navModel.insert(w, {
                    rowKey: wanted[w].key,
                    rowKind: wanted[w].rowKind,
                    pageIndex: wanted[w].pageIndex,
                    subIndex: wanted[w].subIndex,
                    isFirst: !!wanted[w].isFirst,
                    isLast: !!wanted[w].isLast
                });
            }
        }
    }

    onSearchTextChanged: {
        root.syncNavModel();
        var best = root.bestMatch();
        if (best) {
            root.activeSubIndex = best.subIndex;
            root.currentIndex = best.pageIndex;
        }
    }

    Component.onCompleted: {
        root.syncNavModel();
        root._consumeRequest();
        root.opacity = 0;
        entranceAnim.restart();
    }

    Connections {
        target: root.windowService
        function onExpandAllSubTabsChanged() {
            root.syncNavModel();
        }
    }

    // IPC requests consumer
    function _consumeRequest() {
        if (root.windowService.requestedSearch !== "") {
            searchField.text = root.windowService.requestedSearch;
            root.windowService.requestedSearch = "";
            root.windowService.requestedPageId = "";
            root.windowService.requestedSubTabId = "";
            return;
        }
        if (root.windowService.requestedPageId !== "") {
            var idx = root.pages.findIndex(p => p.id === root.windowService.requestedPageId);
            if (idx !== -1) {
                var subs = root.subTabsByPage[root.windowService.requestedPageId];
                var subIdx = 0;
                if (root.windowService.requestedSubTabId !== "" && subs) {
                    var found = subs.findIndex(s => s.id === root.windowService.requestedSubTabId);
                    if (found !== -1)
                        subIdx = found;
                }
                root.activeSubIndex = subIdx;
                root.currentIndex = idx;
            }
            root.windowService.requestedPageId = "";
            root.windowService.requestedSubTabId = "";
        }
    }

    // IPC requests for an already opened window
    Connections {
        target: root.windowService
        function onRequestSeqChanged() {
            root._consumeRequest();
        }
    }

    Keys.onEscapePressed: root.QsWindow.window.visible = false
    Keys.onUpPressed: root._stepSelection(-1)
    Keys.onDownPressed: root._stepSelection(1)
    Keys.onPressed: event => {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_F) {
                searchField.field.forceActiveFocus();
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab) {
                root._stepSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab) {
                root._stepSelection(-1);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Slash) {
            searchField.field.forceActiveFocus();
            event.accepted = true;
        }
    }

    NumberAnimation {
        id: entranceAnim
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: Anim.slow
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anim.emphasizedDecel
    }

    Surface {
        anchors.fill: parent
        opaque: true
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Item {
            Layout.preferredWidth: Math.round(220 * UIScale.value)
            Layout.fillHeight: true

            Surface {
                anchors.fill: parent
                level: 1
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: UIScale.spacingMd
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingMd
                    Layout.topMargin: UIScale.spacingXs
                    spacing: UIScale.spacingSm

                    Item {
                        id: logoSlot
                        Layout.preferredWidth: Math.round(34 * UIScale.value)
                        Layout.preferredHeight: Math.round(34 * UIScale.value)

                        Image {
                            id: logoMask
                            anchors.fill: parent
                            visible: false
                            source: "../../../assets/logo.svg"
                            sourceSize.width: Math.round(68 * UIScale.value)
                            sourceSize.height: Math.round(68 * UIScale.value)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Colors.accent
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: logoMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        color: Colors.text
                        font.pixelSize: UIScale.fontSubhead
                        font.weight: Font.ExtraBold
                    }

                    Rectangle {
                        implicitWidth: Math.round(30 * UIScale.value)
                        implicitHeight: Math.round(30 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: closeHover.hovered ? Colors.withAlpha(Colors.text, 0.08) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: Math.round(14 * UIScale.value)
                            color: closeHover.hovered ? Colors.text : Colors.textDim
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        HoverHandler {
                            id: closeHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.QsWindow.window.visible = false
                        }
                    }
                }

                StyledTextInput {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingMd
                    icon: ""
                    showClearButton: true
                    placeholder: I18n.t("common.windowSearchPlaceholder")
                    onTextChanged: root.searchText = text
                    onEscapePressed: root.QsWindow.window.visible = false
                }

                ListModel {
                    id: navModel
                }

                ListView {
                    id: navList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Math.round(2 * UIScale.value)
                    model: navModel
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        id: navRow
                        required property string rowKind // "category" | "subtab"
                        required property int pageIndex
                        required property int subIndex // -1 for category rows
                        required property bool isFirst // subtab rows
                        required property bool isLast
                        width: navList.width
                        height: navItem.implicitHeight

                        readonly property real indent: Math.round(20 * UIScale.value)

                        readonly property bool isGroupHeader: navRow.rowKind === "category" && root.hasSubTabs(root.pages[navRow.pageIndex].id) && root.isCategoryExpanded(navRow.pageIndex)

                        readonly property bool hasHeaderAbove: navRow.rowKind === "subtab" && root.isCategoryExpanded(navRow.pageIndex)

                        // Draws the subtrabs + header as a collective
                        Rectangle {
                            visible: navRow.rowKind === "subtab" || navRow.isGroupHeader
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: (navRow.hasHeaderAbove || (navRow.rowKind === "subtab" && !navRow.isFirst)) ? -Math.round(navList.spacing / 2) : 0
                            anchors.bottomMargin: (navRow.isGroupHeader || (navRow.rowKind === "subtab" && !navRow.isLast)) ? -Math.round(navList.spacing / 2) : 0
                            color: Colors.withAlpha(Colors.text, 0.035)
                            readonly property bool _topRounded: navRow.isGroupHeader || (navRow.rowKind === "subtab" && navRow.isFirst && !navRow.hasHeaderAbove)
                            readonly property bool _bottomRounded: navRow.rowKind === "subtab" && navRow.isLast
                            topLeftRadius: _topRounded ? UIScale.radiusSm : 0
                            topRightRadius: _topRounded ? UIScale.radiusSm : 0
                            bottomLeftRadius: _bottomRounded ? UIScale.radiusSm : 0
                            bottomRightRadius: _bottomRounded ? UIScale.radiusSm : 0
                        }

                        NavItem {
                            id: navItem
                            x: navRow.rowKind === "subtab" ? navRow.indent : 0
                            width: navRow.width - x
                            navId: navRow.rowKind + ":" + navRow.pageIndex + ":" + navRow.subIndex

                            navLabel: navRow.rowKind === "subtab" ? root.subTabsByPage[root.pages[navRow.pageIndex].id][navRow.subIndex].label : root.pages[navRow.pageIndex].label
                            navIcon: navRow.rowKind === "subtab" ? root.subTabsByPage[root.pages[navRow.pageIndex].id][navRow.subIndex].icon : root.pages[navRow.pageIndex].icon

                            isNavSelected: navRow.rowKind === "subtab" ? (root.currentIndex === navRow.pageIndex && root.activeSubIndex === navRow.subIndex) : (root.currentIndex === navRow.pageIndex && !root.hasSubTabs(root.pages[navRow.pageIndex].id))
                            onActivated: {
                                root.activeSubIndex = navRow.rowKind === "subtab" ? navRow.subIndex : 0;
                                root.currentIndex = navRow.pageIndex;
                            }
                        }
                    }

                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Anim.medium
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Anim.emphasizedDecel
                        }
                    }
                    addDisplaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Anim.medium
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Anim.spatial
                        }
                    }
                    displaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Anim.medium
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Anim.spatial
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingSm
                    spacing: UIScale.spacingSm

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("common.windowExpandAllSubTabs")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        elide: Text.ElideRight
                    }

                    ToggleSwitch {
                        checked: root.windowService.expandAllSubTabs
                        onToggled: root.windowService.writeExpandAllSubTabs(!root.windowService.expandAllSubTabs)
                    }
                }
            }
        }

        // Content area
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Loader {
                id: pageLoader
                anchors.fill: parent
                sourceComponent: root.activeComponent()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 9999
        propagateComposedEvents: true
        onPressed: mouse => {
            root.forceActiveFocus();
            mouse.accepted = false;
        }
    }
}
