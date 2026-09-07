pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../"

Singleton {
    id: root

    readonly property var items: [
        {
            id: "workspace",
            label: I18n.t("bar.itemWorkspace"),
            src: "../workspaceindicator/WorkspaceIndicator.qml"
        },
        {
            id: "systray",
            label: I18n.t("bar.itemSystray"),
            src: "SystrayItems.qml"
        },
        {
            id: "taskbar",
            label: I18n.t("bar.itemTaskbar"),
            src: "../taskbar/Taskbar.qml"
        },
        {
            id: "music",
            label: I18n.t("bar.itemMusic"),
            src: "../music/MusicChip.qml"
        },
        // The repaint of this widget causes 0.6% hits on the CPU in regular intervals
        {
            id: "sysmon",
            label: I18n.t("bar.itemSysmon"),
            src: "../sysmon/SysMonItem.qml"
        },
        {
            id: "theme",
            label: I18n.t("bar.itemTheme"),
            src: "../themeswitcher/ThemeSwitcherItem.qml"
        },
        {
            id: "keybinds",
            label: I18n.t("bar.itemKeybinds"),
            src: "../keybinds/KeybindsItem.qml"
        },
        {
            id: "bluetooth",
            label: I18n.t("bar.itemBluetooth"),
            src: "../bluetooth/BluetoothItem.qml"
        },
        {
            id: "airpods",
            label: I18n.t("bar.itemAirpods"),
            src: "../audiodevices/airpods/AirPods.qml"
        },
        {
            id: "wifi",
            label: I18n.t("bar.itemWifi"),
            src: "../wifi/WifiItem.qml"
        },
        {
            id: "weather",
            label: I18n.t("bar.itemWeather"),
            src: "../weather/WeatherItem.qml"
        },
        {
            id: "brightness",
            label: I18n.t("bar.itemBrightness"),
            src: "../brightness/BrightnessItem.qml"
        },
        {
            id: "sound",
            label: I18n.t("bar.itemSound"),
            src: "../sound/SoundItem.qml"
        },
        {
            id: "mic",
            label: I18n.t("bar.itemMic"),
            src: "../mic/MicItem.qml"
        },
        {
            id: "notifications",
            label: I18n.t("bar.itemNotifications"),
            src: "../notifications/NotificationsItem.qml"
        },
        {
            id: "config",
            label: I18n.t("bar.itemConfig"),
            src: "../config/ConfigItem.qml"
        },
        {
            id: "battery",
            label: I18n.t("bar.itemBattery"),
            src: "../battery/BatteryItem.qml"
        },
        {
            id: "record",
            label: I18n.t("bar.itemRecord"),
            src: "../record/RecordItem.qml"
        },
        {
            id: "gitupdate",
            label: I18n.t("bar.itemGitupdate"),
            src: "../gitupdate/GitUpdateItem.qml"
        },
        {
            id: "home",
            label: I18n.t("bar.itemHome"),
            src: "../home/HomeBarButton.qml"
        },
        {
            id: "settings",
            label: I18n.t("bar.itemSettings"),
            src: "../settings/SettingsBarButton.qml"
        },
        {
            id: "lock",
            label: I18n.t("bar.itemLock"),
            src: "../lockscreen/LockBarButton.qml"
        },
        {
            id: "clock",
            label: I18n.t("bar.itemClock"),
            src: "../clock/ClockItem.qml"
        },
    ]

    property var _state: {
        const s = {};
        for (const item of items)
            s[item.id] = true;
        return s;
    }

    // Ordered list going from Zones -> Islands -> Atom ids. Atoms are catalog
    // items, tray icons, taskbar and so on.
    property var zones: []

    // Flattened, catalog-object view of zones, for consumers that only care
    // about a flat list.
    readonly property var orderedItems: {
        const byId = {};
        for (const item of items)
            byId[item.id] = item;
        const result = [];
        for (const zone of root.zones)
            for (const group of zone)
                for (const id of root._islandLeafIds(group))
                    if (byId[id])
                        result.push(byId[id]);
        return result;
    }

    // Island member helpers
    //
    // Island is an ordered array. Entries are "atoms" i.e. an id string or
    // manual chevron object { chevron: "<id>", ids: ["atom",...] }
    function _memberIsChevron(m) {
        return !!m && typeof m === "object" && typeof m.chevron === "string";
    }

    function _memberId(m) {
        return root._memberIsChevron(m) ? m.chevron : m;
    }

    // Flat atom-id list for an island, expanding any chevrons.
    function _islandLeafIds(island) {
        var out = [];
        for (var i = 0; i < island.length; i++) {
            var m = island[i];
            if (root._memberIsChevron(m))
                out = out.concat(m.ids);
            else
                out.push(m);
        }
        return out;
    }

    // Index of the top-level member whose member-id is id, or -1.
    function _islandMemberIndex(island, id) {
        for (var i = 0; i < island.length; i++)
            if (root._memberId(island[i]) === id)
                return i;
        return -1;
    }

    function _findIslandInZone(zone, id) {
        for (var i = 0; i < zone.length; i++)
            if (root._islandMemberIndex(zone[i], id) >= 0)
                return zone[i];
        return null;
    }

    function _newChevronId() {
        return "chv-" + Math.random().toString(36).slice(2, 8) + "-" + Date.now().toString(36).slice(-4);
    }

    // Removes whichever member (a bare atom string, or a whole chevron object)
    // resolves to member-id id
    function _extractMember(zonesList, id) {
        for (var zi = 0; zi < zonesList.length; zi++) {
            var zone = zonesList[zi];
            for (var ii = 0; ii < zone.length; ii++) {
                var island = zone[ii];
                var mi = root._islandMemberIndex(island, id);
                if (mi >= 0) {
                    var member = island.splice(mi, 1)[0];
                    if (island.length === 0)
                        zone.splice(ii, 1);
                    return {
                        member: member,
                        zoneIdx: zi
                    };
                }
                for (var ci = 0; ci < island.length; ci++) {
                    var m = island[ci];
                    if (root._memberIsChevron(m)) {
                        var k = m.ids.indexOf(id);
                        if (k >= 0) {
                            m.ids.splice(k, 1);
                            return {
                                member: id,
                                zoneIdx: zi
                            };
                        }
                    }
                }
            }
        }
        return null;
    }

    // Safty check, pull workspace atoms out of chevrons (even automatic ones)
    // It'll still appear as an entry in the automatic chevron...
    // TODO Somehow fix this
    function _evictFloatAtomsFromChevrons(zonesList) {
        var changed = false;
        for (var zi = 0; zi < zonesList.length; zi++)
            for (var ii = 0; ii < zonesList[zi].length; ii++) {
                var island = zonesList[zi][ii];
                for (var mi = 0; mi < island.length; mi++) {
                    var m = island[mi];
                    if (!root._memberIsChevron(m))
                        continue;
                    var k = m.ids.indexOf("workspace");
                    if (k >= 0) {
                        m.ids.splice(k, 1);
                        island.splice(mi, 0, "workspace");
                        mi++; // step past the bare member we just inserted
                        changed = true;
                    }
                }
            }
        return changed;
    }

    function _normalizeChevrons(zonesList) {
        for (var zi = 0; zi < zonesList.length; zi++) {
            var zone = zonesList[zi];
            for (var ii = zone.length - 1; ii >= 0; ii--) {
                var island = zone[ii];
                for (var mi = island.length - 1; mi >= 0; mi--) {
                    var m = island[mi];
                    if (!root._memberIsChevron(m))
                        continue;
                    if (m.ids.length >= 2)
                        continue;
                    if (m.ids.length === 1)
                        island.splice(mi, 1, m.ids[0]);
                    else
                        island.splice(mi, 1);
                }
                if (island.length === 0)
                    zone.splice(ii, 1);
            }
        }
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
        BarConfig.patch({
            itemStates: s
        });
    }

    property var pinnedIds: BarConfig.pinnedIds

    function isPinned(id) {
        return root.pinnedIds.indexOf(id) >= 0;
    }

    function togglePin(id) {
        const next = root.pinnedIds.slice();
        const idx = next.indexOf(id);
        if (idx >= 0)
            next.splice(idx, 1);
        else
            next.push(id);
        root.pinnedIds = next;
        BarConfig.patch({
            pinnedIds: next
        });
    }

    // Clones the current zones structure into mutable arrays (chevron objects
    // deep-copied), for mutation functions to work on before committing via
    // _commitZones.
    function _cloneZones() {
        return root.zones.map(zone => zone.map(island => island.map(m => root._memberIsChevron(m) ? ({
                            chevron: m.chevron,
                            ids: m.ids.slice()
                        }) : m)));
    }

    // Enabled and chevron-normalized view of zones
    function renderZones() {
        var out = root._cloneZones();
        for (var zi = 0; zi < out.length; zi++) {
            var zone = out[zi];
            for (var ii = 0; ii < zone.length; ii++) {
                var island = zone[ii];
                for (var mi = island.length - 1; mi >= 0; mi--) {
                    var m = island[mi];
                    if (root._memberIsChevron(m))
                        m.ids = m.ids.filter(id => root.isEnabled(id));
                    else if (!root.isEnabled(m))
                        island.splice(mi, 1);
                }
            }
        }
        root._normalizeChevrons(out);
        return out;
    }

    // Removes zonesList[rawIdx] if it's now empty and doing so wouldn't
    // bring the total zone count below the floor of 3.
    function _maybePruneEmptyZone(zonesList, rawIdx) {
        if (rawIdx >= 0 && rawIdx < zonesList.length && zonesList[rawIdx].length === 0 && zonesList.length > 3)
            zonesList.splice(rawIdx, 1);
    }

    // Heal degenerate chevrons, then enforce the >= 3 zone floor.
    function _commitZones(zonesList) {
        root._normalizeChevrons(zonesList);
        while (zonesList.length < 3)
            zonesList.push([]);
        root.zones = zonesList;
        BarConfig.patch({
            zones: zonesList
        });
    }

    // Moves id to an explicit position within a specific island in
    // targetZoneIdx. targetIslandIds is a snapshot of that island's other
    // member ids (id itself excluded, whether or not it was already a
    // member there). beforeId is one of targetIslandIds to insert
    // before, or "" to append at that island's own end.
    function moveIconToIsland(id, targetZoneIdx, targetIslandIds, beforeId) {
        if (targetIslandIds.length === 0)
            return; // id dropped back into its own solo island, so no-op
        const zonesList = root._cloneZones();
        const ext = root._extractMember(zonesList, id);
        const sourceZoneIdx = ext ? ext.zoneIdx : -1;
        const member = ext ? ext.member : id;
        const targetZone = zonesList[targetZoneIdx];
        if (!targetZone)
            return;
        const target = root._findIslandInZone(targetZone, targetIslandIds[0]);
        if (!target)
            return;
        const at = beforeId ? root._islandMemberIndex(target, beforeId) : -1;
        target.splice(at < 0 ? target.length : at, 0, member);

        root._maybePruneEmptyZone(zonesList, sourceZoneIdx);
        root._commitZones(zonesList);
    }

    // Removes id from wherever it is and inserts it as a brand-new
    // single-item island in targetZoneIdx, immediately before the island
    // containing beforeIslandAnchorId, or at the end of that zone when "".
    function spawnIsland(id, targetZoneIdx, beforeIslandAnchorId) {
        const zonesList = root._cloneZones();
        const targetZone = zonesList[targetZoneIdx];
        if (!targetZone)
            return;
        let at = beforeIslandAnchorId ? targetZone.findIndex(isl => root._islandMemberIndex(isl, beforeIslandAnchorId) >= 0) : -1;
        let member = id;
        let fromIdx = -1;
        for (let i = 0; i < targetZone.length; i++) {
            const mi = root._islandMemberIndex(targetZone[i], id);
            if (mi >= 0) {
                member = targetZone[i].splice(mi, 1)[0];
                fromIdx = i;
                break;
            }
        }
        if (fromIdx >= 0) {
            if (targetZone[fromIdx].length === 0) {
                targetZone.splice(fromIdx, 1);
                if (at > fromIdx)
                    at--;
            }
        } else {
            const ext = root._extractMember(zonesList, id);
            if (ext)
                member = ext.member;
            root._maybePruneEmptyZone(zonesList, ext ? ext.zoneIdx : -1);
        }
        targetZone.splice(at < 0 ? targetZone.length : at, 0, [member]);
        root._commitZones(zonesList);
    }

    function _extractIsland(zonesList, anchor) {
        for (let zi = 0; zi < zonesList.length; zi++) {
            const idx = zonesList[zi].findIndex(isl => root._islandMemberIndex(isl, anchor) >= 0);
            if (idx >= 0)
                return {
                    island: zonesList[zi].splice(idx, 1)[0],
                    fromZoneIdx: zi
                };
        }
        return null;
    }

    // Moves a whole island (identified by any current member id in
    // islandIds. Its first is used as the anchor) into targetZoneIdx, to
    // sit immediately before the island containing beforeIslandAnchorId, or
    // at the end of that zone when "".
    function moveIsland(islandIds, targetZoneIdx, beforeIslandAnchorId) {
        if (islandIds.length === 0)
            return;
        const zonesList = root._cloneZones();
        const ext = root._extractIsland(zonesList, root._memberId(islandIds[0]));
        if (!ext)
            return;
        const targetZone = zonesList[targetZoneIdx];
        if (!targetZone)
            return;
        const at = beforeIslandAnchorId ? targetZone.findIndex(isl => root._islandMemberIndex(isl, beforeIslandAnchorId) >= 0) : -1;
        targetZone.splice(at < 0 ? targetZone.length : at, 0, ext.island);
        root._maybePruneEmptyZone(zonesList, ext.fromZoneIdx);
        root._commitZones(zonesList);
    }

    // Removes id from wherever it is and inserts it as a brand-new zone
    // (a single island containing just id) at atIndex in the zones list.
    // One of the N+1 candidate insertion slots (before zone 0, between each
    // adjacent pair, or after the last zone), resolved by the caller from
    // live rendered gap geometry.
    function spawnZone(id, atIndex) {
        const zonesList = root._cloneZones();
        const ext = root._extractMember(zonesList, id);
        const member = ext ? ext.member : id;
        const sourceZoneIdx = ext ? ext.zoneIdx : -1;
        let at = atIndex;
        if (sourceZoneIdx >= 0 && zonesList[sourceZoneIdx] && zonesList[sourceZoneIdx].length === 0 && zonesList.length > 3) {
            zonesList.splice(sourceZoneIdx, 1);
            if (at > sourceZoneIdx)
                at--;
        }
        at = Math.max(0, Math.min(at, zonesList.length));
        zonesList.splice(at, 0, [[member]]);
        root._commitZones(zonesList);
    }

    // Whole-island equivalent of spawnZone: removes the whole island
    // (islandIds, identified by its first member) from wherever it is and
    // inserts it as a brand-new zone containing exactly that island (all
    // its members, intact as one block) at atIndex.
    function spawnZoneWithIsland(islandIds, atIndex) {
        if (islandIds.length === 0)
            return;
        const zonesList = root._cloneZones();
        const ext = root._extractIsland(zonesList, root._memberId(islandIds[0]));
        if (!ext)
            return;
        let at = atIndex;
        if (zonesList[ext.fromZoneIdx].length === 0 && zonesList.length > 3) {
            zonesList.splice(ext.fromZoneIdx, 1);
            if (at > ext.fromZoneIdx)
                at--;
        }
        at = Math.max(0, Math.min(at, zonesList.length));
        zonesList.splice(at, 0, [ext.island]);
        root._commitZones(zonesList);
    }

    function spawnChevron(draggedId, targetAtomId, draggedBefore) {
        if (!draggedId || !targetAtomId || draggedId === targetAtomId)
            return;
        // For now we don't let workspaces live in chevrons
        if (draggedId === "workspace" || targetAtomId === "workspace")
            return;
        const zonesList = root._cloneZones();
        const ext = root._extractMember(zonesList, draggedId);
        if (!ext)
            return;
        for (let zi = 0; zi < zonesList.length; zi++) {
            const zone = zonesList[zi];
            for (let ii = 0; ii < zone.length; ii++) {
                const island = zone[ii];
                const mi = root._islandMemberIndex(island, targetAtomId);
                if (mi >= 0 && !root._memberIsChevron(island[mi])) {
                    island.splice(mi, 1, {
                        chevron: root._newChevronId(),
                        ids: draggedBefore ? [draggedId, targetAtomId] : [targetAtomId, draggedId]
                    });
                    root._maybePruneEmptyZone(zonesList, ext.zoneIdx);
                    root._commitZones(zonesList);
                    return;
                }
            }
        }
    }

    function addToChevron(draggedId, chevronId, beforeId) {
        if (!draggedId || !chevronId)
            return;
        if (draggedId === "workspace")
            return;

        const zonesList = root._cloneZones();
        const ext = root._extractMember(zonesList, draggedId);
        if (!ext)
            return;
        for (let zi = 0; zi < zonesList.length; zi++) {
            const zone = zonesList[zi];
            for (let ii = 0; ii < zone.length; ii++) {
                const island = zone[ii];
                for (let mi = 0; mi < island.length; mi++) {
                    const m = island[mi];
                    if (root._memberIsChevron(m) && m.chevron === chevronId) {
                        if (m.ids.indexOf(draggedId) < 0) {
                            const at = beforeId ? m.ids.indexOf(beforeId) : -1;
                            m.ids.splice(at < 0 ? m.ids.length : at, 0, draggedId);
                        }
                        root._maybePruneEmptyZone(zonesList, ext.zoneIdx);
                        root._commitZones(zonesList);
                        return;
                    }
                }
            }
        }
    }

    function _defaultZones() {
        return [[["workspace"]], [["music"], ["taskbar"]], [["systray"], ["sysmon", "theme", "keybinds", "bluetooth", "wifi", "airpods", "weather", "brightness", "sound", "mic", "notifications", "config", "battery", "record", "gitupdate"], ["settings", "home", "lock", "clock"]]];
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
            BarConfig.patch({
                itemStates: s
            });
    }

    function _mergeZones() {
        const known = new Set(items.map(x => x.id));
        let raw = BarConfig.zones;
        let dirty = false;

        if (!raw || raw.length === 0) {
            dirty = true;
            raw = root._defaultZones();
        }

        const seen = new Set();
        const result = [];
        for (const zone of raw) {
            const resultZone = [];
            for (const group of (zone || [])) {
                const filtered = [];
                for (const m of group) {
                    if (root._memberIsChevron(m)) {
                        const kids = m.ids.filter(id => known.has(id) && !seen.has(id));
                        if (kids.length !== m.ids.length)
                            dirty = true;
                        kids.forEach(id => seen.add(id));
                        if (kids.length > 0)
                            filtered.push({
                                chevron: m.chevron || root._newChevronId(),
                                ids: kids
                            });
                    } else if (known.has(m) && !seen.has(m)) {
                        filtered.push(m);
                        seen.add(m);
                    } else {
                        dirty = true;
                    }
                }
                if (filtered.length > 0)
                    resultZone.push(filtered);
            }
            result.push(resultZone);
        }

        if (root._evictFloatAtomsFromChevrons(result))
            dirty = true;

        root._normalizeChevrons(result);

        while (result.length < 3) {
            result.push([]);
            dirty = true;
        }

        const newIds = items.map(i => i.id).filter(id => !seen.has(id));
        if (newIds.length > 0) {
            dirty = true;
            const lastZone = result[result.length - 1];
            if (lastZone.length > 0)
                lastZone[lastZone.length - 1] = lastZone[lastZone.length - 1].concat(newIds);
            else
                lastZone.push(newIds);
        }

        root.zones = result;
        if (dirty)
            BarConfig.patch({
                zones: result
            });
    }

    Connections {
        target: BarConfig
        function onItemStatesChanged() {
            root._merge();
        }
        function onZonesChanged() {
            root._mergeZones();
        }
        function onReadyChanged() {
            if (BarConfig.ready) {
                root._merge();
                root._mergeZones();
            }
        }
    }

    Component.onCompleted: {
        root._merge();
        root._mergeZones();
    }
}
