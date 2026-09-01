pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"
import "../workspaceindicator/disc"

// This is the entire bar layout.
// It consists of "zones" laid which are divided out into fractions.
// Zone 0, 1 and 2 are always allocated, no matter what.
// Zone 0 and N-1 are always flush to the edge of the monitor.
// Each zone has an island, and each island atoms.
Item {
    id: root

    // Screen name this bar instance renders on
    property string screenName: ""

    // TODO Make this variable available to adjust in settings
    readonly property real _pad: 1 * Math.round(12 * UIScale.value)
    // TODO Make this variable available to adjust in settings
    readonly property real _gap: 4
    readonly property real _pillGap: Math.round(10 * UIScale.value)
    // Gap between adjacent zones
    readonly property real _zoneGap: Math.round(72 * UIScale.value)
    readonly property real _chevronWidth: Math.round(30 * UIScale.value)
    readonly property int _spawnHoldMs: 500

    readonly property int _spawnChevronHoldMs: 1000
    readonly property int _spawnZoneHoldMs: 400
    readonly property real _zoneTickRadius: Math.round(24 * UIScale.value)
    readonly property real _emptyZoneCatchmentHalfWidth: Math.round(40 * UIScale.value)

    // Manual chevrons, they inline their contents instead of a popup.
    property var _expandedChevrons: ({})
    function _isChevronExpanded(id) {
        return root._expandedChevrons[id] === true;
    }
    function _toggleChevronExpanded(id) {
        var m = Object.assign({}, root._expandedChevrons);
        if (m[id])
            delete m[id];
        else
            m[id] = true;
        root._expandedChevrons = m;
    }

    // >0 while one or more atom slots are morphing
    property int _atomResizing: 0
    // Returns value the caller should assign to _atomResizing.
    function _atomResizingAfter(delta) {
        return Math.max(0, root._atomResizing + delta);
    }

    // False while the bar is loading its config.
    property bool _morphReady: false
    Timer {
        interval: 900
        running: true
        onTriggered: root._morphReady = true
    }

    // Snapshot of BarConfig, UIScale, workspace disc, pinned
    readonly property var _cfg: ({
            isVertical: BarConfig.isVertical,
            endGap: BarConfig.endGap,
            pad: root._pad,
            gap: root._gap,
            pillGap: root._pillGap,
            zoneGap: root._zoneGap,
            chevronWidth: root._chevronWidth,
            zoneTickRadius: root._zoneTickRadius,
            emptyZoneCatchmentHalfWidth: root._emptyZoneCatchmentHalfWidth,
            totalRaw: BarItemsService.zones.length,
            pinnedIds: BarItemsService.pinnedIds,
            wsPadSuppressed: WorkspaceDiscService.tuckEnabled || !WorkspaceDiscService.showIslandBackground
        })

    readonly property var _catalogById: {
        var m = {};
        var arr = BarItemsService.orderedItems;
        for (var i = 0; i < arr.length; i++)
            m[arr[i].id] = arr[i];
        return m;
    }
    function _catalogItem(id) {
        return root._catalogById[id];
    }

    // Pushed by each TrayItemSlot by onItemAvailableChanged
    property var _availabilityMap: ({})

    function _isAvailable(id) {
        return root._availabilityMap[id] !== false;
    }

    // We need to measure width after mount, so for example Airpods or
    // battery etc. Otherwise they are stale values.
    property var _widthMap: ({})
    property var _heightMap: ({})

    // These functions are pure in the sense that they only perform reads
    // on root. They never mutate variables, they only return and let the caller
    // mutate. This let's us stay sane, and have deterministic behavior.

    function _isChevron(m) {
        return BarItemsService._memberIsChevron(m);
    }
    function _canPin(rawIndex) {
        return rawIndex !== 0 && rawIndex !== root._cfg.totalRaw - 1;
    }

    // Manual chevrons which are expanded cannot be compressed.
    function _idsHaveExpandedChevron(ids) {
        for (var i = 0; i < ids.length; i++)
            if (root._isChevron(ids[i]) && root._expandedChevrons[ids[i].chevron] === true)
                return true;
        return false;
    }

    // ids present for layout
    function _availableIdsIn(ids) {
        var out = [];
        for (var i = 0; i < ids.length; i++)
            if (root._isChevron(ids[i]) || root._availabilityMap[ids[i]] !== false)
                out.push(ids[i]);
        return out;
    }

    // All atoms are measured the same. TrayItemSlot eases and quantizes its
    // size which publishes the one integer into _widthMap / _heightMap.
    // Those two maps are what GrudLayout and all layout fn read from. One
    // source of truth.
    function _memberAxisSize(m) {
        var id = root._isChevron(m) ? m.chevron : m;
        var s = (root._cfg.isVertical ? root._heightMap[id] : root._widthMap[id]) || 0;
        return (s > 0) ? s : (root._isChevron(m) ? root._cfg.chevronWidth : 0);
    }

    // Enabled + chevron normalized zones
    readonly property var _renderZones: BarItemsService.renderZones()

    // Zones which hold at least 1 enabled island, index tagged.
    readonly property var _liveZones: {
        var out = [];
        for (var zi = 0; zi < root._renderZones.length; zi++)
            if (root._renderZones[zi].length > 0)
                out.push({
                    rawIndex: zi,
                    islandGroups: root._renderZones[zi]
                });
        return out;
    }

    function _islandNaturalWidth(ids) {
        var avail = root._availableIdsIn(ids);
        var used = 0;
        for (var i = 0; i < avail.length; i++)
            used += (i > 0 ? root._cfg.gap : 0) + root._memberAxisSize(avail[i]);
        return used;
    }

    function _fitCountFor(members, budget) {
        if (budget < 0)
            return members.length;
        var innerBudget = budget - root._cfg.pad;

        var totalNatural = 0;
        for (var t = 0; t < members.length; t++)
            totalNatural += (t > 0 ? root._cfg.gap : 0) + root._memberAxisSize(members[t]);
        if (totalNatural <= innerBudget)
            return members.length;

        var used = 0;
        var count = 0;
        for (var i = members.length - 1; i >= 0; i--) {
            var w = root._memberAxisSize(members[i]);
            var next = used + (count > 0 ? root._cfg.gap : 0) + w;
            var reserve = (i > 0) ? (root._cfg.gap + root._cfg.chevronWidth) : 0;
            if (next + reserve > innerBudget)
                break;
            used = next;
            count++;
        }
        return count;
    }

    // Is this idlands pill background and padding suppressed?
    function _islandPad(ids) {
        var isWorkspaceOnly = ids.length === 1 && ids[0] === "workspace";
        return (isWorkspaceOnly && root._cfg.wsPadSuppressed) ? 0 : root._cfg.pad;
    }

    // Minimum width of a non-empty island when fully collapsed.
    // NOTE An island holding an unfolded manual chevron is incompressible!
    function _islandMinWidth(ids) {
        var avail = root._availableIdsIn(ids);
        if (avail.length === 0)
            return 0;
        var pad = root._islandPad(ids);
        var natural = root._islandNaturalWidth(ids) + pad;
        if (root._idsHaveExpandedChevron(ids))
            return natural;
        return Math.min(natural, pad + root._cfg.chevronWidth);
    }

    function _islandRenderedWidth(ids, budget) {
        var avail = root._availableIdsIn(ids);
        if (avail.length === 0)
            return 0;
        var pad = root._islandPad(ids);
        // We freeze any overflow state while the island is morphing.
        if (budget < 0 || root._atomResizing > 0)
            return root._islandNaturalWidth(ids) + pad;
        var fitCount = root._fitCountFor(avail, budget);
        var hasOverflow = fitCount < avail.length;
        var used = 0;
        for (var i = avail.length - fitCount; i < avail.length; i++)
            used += (used > 0 ? root._cfg.gap : 0) + root._memberAxisSize(avail[i]);
        if (hasOverflow)
            used += (used > 0 ? root._cfg.gap : 0) + root._cfg.chevronWidth;
        return Math.max(used + pad, root._islandMinWidth(ids));
    }

    // Per island width budget within a zone, given that zone's own width.
    function _islandBudgetsForZone(rawIndex, zoneWidth) {
        var groups = root._renderZones[rawIndex] || [];
        var n = groups.length;
        var budgets = new Array(n);
        if (zoneWidth < 0) {
            for (var i0 = 0; i0 < n; i0++)
                budgets[i0] = -1;
            return budgets;
        }
        var mins = new Array(n);
        var naturals = new Array(n);
        var totalMin = 0;
        var visibleCount = 0;
        for (var i = 0; i < n; i++) {
            var ids = groups[i];
            if (root._availableIdsIn(ids).length === 0) {
                mins[i] = 0;
                naturals[i] = 0;
                budgets[i] = 0;
                continue;
            }
            mins[i] = root._islandMinWidth(ids);
            naturals[i] = Math.max(mins[i], root._islandNaturalWidth(ids) + root._islandPad(ids));
            totalMin += mins[i];
            budgets[i] = mins[i];
            visibleCount++;
        }
        var available = zoneWidth - Math.max(0, visibleCount - 1) * root._cfg.pillGap;
        var bonus = Math.max(0, available - totalMin);
        for (var j = n - 1; j >= 0; j--) {
            var extra = naturals[j] - mins[j];
            if (extra <= 0)
                continue;
            var give = Math.min(extra, bonus);
            budgets[j] += give;
            bonus -= give;
            if (budgets[j] >= naturals[j])
                budgets[j] = -1;
        }
        return budgets;
    }

    // Island x offset (relative to zone center) and width, in islandGroups
    // order. Pinned items move to the center of a zone.
    function _islandLayout(rawIndex, budgetWidth) {
        var groups = root._renderZones[rawIndex] || [];
        var canPin = root._canPin(rawIndex);
        var n = groups.length;
        var widths = new Array(n).fill(0);
        var visible = new Array(n).fill(false);
        var anchorIdx = -1;
        var budgets = (budgetWidth !== undefined && budgetWidth >= 0) ? root._islandBudgetsForZone(rawIndex, budgetWidth) : null;
        for (var i = 0; i < n; i++) {
            var avail = root._availableIdsIn(groups[i]);
            if (avail.length === 0)
                continue;
            visible[i] = true;
            widths[i] = budgets ? root._islandRenderedWidth(groups[i], budgets[i]) : Math.max(root._islandMinWidth(groups[i]), root._islandNaturalWidth(groups[i]) + root._islandPad(groups[i]));
            if (canPin && anchorIdx < 0)
                for (var j = 0; j < avail.length; j++)
                    if (!root._isChevron(avail[j]) && root._cfg.pinnedIds.indexOf(avail[j]) >= 0) {
                        anchorIdx = i;
                        break;
                    }
        }

        var xs = new Array(n).fill(0);
        var totalWidth = 0;

        if (anchorIdx < 0) {
            var flowW = 0;
            for (var k = 0; k < n; k++)
                if (visible[k])
                    flowW += (flowW > 0 ? root._cfg.pillGap : 0) + widths[k];
            // We round to prevent jitter. xs[] computes to a whole pixel.
            var cursor = -Math.round(flowW / 2);
            var started = false;
            for (var m = 0; m < n; m++) {
                if (!visible[m])
                    continue;
                if (started)
                    cursor += root._cfg.pillGap;
                xs[m] = cursor;
                cursor += widths[m];
                started = true;
            }
            totalWidth = flowW;
        } else {
            var leftW = 0, rightW = 0;
            for (var l = 0; l < anchorIdx; l++)
                if (visible[l])
                    leftW += (leftW > 0 ? root._cfg.pillGap : 0) + widths[l];
            for (var r = anchorIdx + 1; r < n; r++)
                if (visible[r])
                    rightW += (rightW > 0 ? root._cfg.pillGap : 0) + widths[r];
            var side = Math.max(leftW, rightW);
            totalWidth = widths[anchorIdx] + 2 * (side + root._cfg.pillGap);

            // Rounding is critical to prevent jitter
            var anchorX = -Math.round(widths[anchorIdx] / 2);
            xs[anchorIdx] = anchorX;

            var leftEdge = anchorX - root._cfg.pillGap;
            for (var li = anchorIdx - 1; li >= 0; li--) {
                if (!visible[li])
                    continue;
                leftEdge -= widths[li];
                xs[li] = leftEdge;
                leftEdge -= root._cfg.pillGap;
            }

            var rightEdge = anchorX + widths[anchorIdx] + root._cfg.pillGap;
            for (var ri = anchorIdx + 1; ri < n; ri++) {
                if (!visible[ri])
                    continue;
                xs[ri] = rightEdge;
                rightEdge += widths[ri] + root._cfg.pillGap;
            }
        }

        return {
            xs: xs,
            widths: widths,
            visible: visible,
            anchorIdx: anchorIdx,
            totalWidth: totalWidth
        };
    }

    function _zoneNaturalWidth(rawIndex) {
        return root._islandLayout(rawIndex).totalWidth;
    }

    // Minimum rendered width of a non empty zone. Every island collapsed to
    // its own floor.
    function _zoneMinWidth(rawIndex) {
        var groups = root._renderZones[rawIndex] || [];
        var sum = 0, count = 0;
        for (var i = 0; i < groups.length; i++) {
            var avail = root._availableIdsIn(groups[i]);
            if (avail.length === 0)
                continue;
            sum += (count > 0 ? root._cfg.pillGap : 0) + root._islandMinWidth(groups[i]);
            count++;
        }
        return sum;
    }

    readonly property real _mainSize: BarConfig.isVertical ? root.height : root.width

    // Absolute pos and width for every live zone in their fractions.
    readonly property var _zoneLayout: {
        var renderZones = root._renderZones;
        var cfg = root._cfg;
        var usable = Math.max(0, root._mainSize - 2 * cfg.endGap);

        var liveRaw = [];
        for (var z = 0; z < renderZones.length; z++) {
            if (renderZones[z].length === 0)
                continue;
            if (root._zoneNaturalWidth(z) > 0)
                liveRaw.push(z);
        }
        var n = liveRaw.length;
        if (n === 0)
            return [];

        var totalRaw = cfg.totalRaw;

        var mins = new Array(n), naturals = new Array(n);
        for (var i = 0; i < n; i++) {
            mins[i] = root._zoneMinWidth(liveRaw[i]);
            naturals[i] = root._zoneNaturalWidth(liveRaw[i]);
        }

        var positions = new Array(n), widths = new Array(n);

        // Interior zones first. Fixed center, full width always!
        var centerIdxs = [];
        for (var k = 0; k < n; k++) {
            var rawIdx = liveRaw[k];
            if (rawIdx !== 0 && rawIdx !== totalRaw - 1)
                centerIdxs.push(k);
        }
        for (var c = 0; c < centerIdxs.length; c++) {
            var ci = centerIdxs[c];
            var frac = (totalRaw > 1) ? (liveRaw[ci] / (totalRaw - 1)) : 0.5;
            widths[ci] = naturals[ci];
            positions[ci] = frac * usable - widths[ci] / 2;
            if (c > 0) {
                var prev = centerIdxs[c - 1];
                var prevEdge = positions[prev] + widths[prev] + cfg.zoneGap;
                if (positions[ci] < prevEdge)
                    positions[ci] = prevEdge;
            }
        }

        var leftIdx = liveRaw.indexOf(0);
        var rightIdx = liveRaw.indexOf(totalRaw - 1);

        if (centerIdxs.length > 0) {
            var firstC = centerIdxs[0];
            var lastC = centerIdxs[centerIdxs.length - 1];
            if (leftIdx >= 0) {
                var leftRoom = Math.max(0, positions[firstC] - cfg.zoneGap);
                widths[leftIdx] = Math.max(mins[leftIdx], Math.min(naturals[leftIdx], leftRoom));
                positions[leftIdx] = 0;
            }
            if (rightIdx >= 0) {
                var farEdge = positions[lastC] + widths[lastC] + cfg.zoneGap;
                var rightRoom = Math.max(0, usable - farEdge);
                widths[rightIdx] = Math.max(mins[rightIdx], Math.min(naturals[rightIdx], rightRoom));
                positions[rightIdx] = usable - widths[rightIdx];
            }
        } else {
            var edgeIdxs = [];
            if (leftIdx >= 0)
                edgeIdxs.push(leftIdx);
            if (rightIdx >= 0)
                edgeIdxs.push(rightIdx);
            var totalGap = Math.max(0, edgeIdxs.length - 1) * cfg.zoneGap;
            var availableForZones = Math.max(0, usable - totalGap);
            var totalMin = 0;
            for (var e = 0; e < edgeIdxs.length; e++) {
                widths[edgeIdxs[e]] = mins[edgeIdxs[e]];
                totalMin += mins[edgeIdxs[e]];
            }
            var bonus = Math.max(0, availableForZones - totalMin);
            for (var e2 = edgeIdxs.length - 1; e2 >= 0; e2--) {
                var idx = edgeIdxs[e2];
                var extra = naturals[idx] - mins[idx];
                if (extra > 0) {
                    var give = Math.min(extra, bonus);
                    widths[idx] += give;
                    bonus -= give;
                }
            }
            if (leftIdx >= 0)
                positions[leftIdx] = 0;
            if (rightIdx >= 0)
                positions[rightIdx] = usable - widths[rightIdx];
        }

        var out = [];
        for (var mm = 0; mm < n; mm++)
            out.push({
                rawIndex: liveRaw[mm],
                pos: positions[mm],
                width: widths[mm],
                budget: widths[mm]
            });
        return out;
    }

    // keyed by rawIndex, I.e. brrrrr speeds
    readonly property var _zoneLayoutByRaw: {
        var m = ({});
        var zl = root._zoneLayout;
        for (var i = 0; i < zl.length; i++)
            m[zl[i].rawIndex] = zl[i];
        return m;
    }

    function _zoneWidthFor(rawIndex) {
        var e = root._zoneLayoutByRaw[rawIndex];
        return e ? e.budget : -1;
    }

    // Effective bounds for every raw zone, in raw index order. Live zones use
    // their rendered pos/width.
    readonly property var _allZoneBounds: {
        var cfg = root._cfg;
        var totalRaw = cfg.totalRaw;
        if (totalRaw === 0)
            return [];
        var usable = Math.max(0, root._mainSize - 2 * cfg.endGap);
        var byRaw = root._zoneLayoutByRaw;
        var out = [];
        for (var idx = 0; idx < totalRaw; idx++) {
            var entry = byRaw[idx];
            if (entry) {
                out.push({
                    rawIndex: idx,
                    start: entry.pos,
                    end: entry.pos + entry.width
                });
            } else {
                var frac = (totalRaw > 1) ? (idx / (totalRaw - 1)) : 0.5;
                var anchor = frac * usable;
                out.push({
                    rawIndex: idx,
                    start: anchor - cfg.emptyZoneCatchmentHalfWidth,
                    end: anchor + cfg.emptyZoneCatchmentHalfWidth
                });
            }
        }
        return out;
    }

    // The N+1 candidate zone-insertion slots, at the midpoint of each gap.
    // rawAt is the index to splice a new zone at in BarItemsService.zones.
    readonly property var _zoneGapCandidates: {
        var bounds = root._allZoneBounds;
        var n = bounds.length;
        var cfg = root._cfg;
        var usable = Math.max(0, root._mainSize - 2 * cfg.endGap);
        var totalRaw = cfg.totalRaw;
        var out = [];
        if (n === 0) {
            out.push({
                pos: usable / 2,
                rawAt: totalRaw,
                wide: true
            });
            return out;
        }
        out.push({
            pos: bounds[0].start / 2,
            rawAt: bounds[0].rawIndex,
            wide: false
        });
        for (var i = 1; i < n; i++) {
            out.push({
                pos: (bounds[i - 1].end + bounds[i].start) / 2,
                rawAt: bounds[i].rawIndex,
                wide: false
            });
        }
        out.push({
            pos: (bounds[n - 1].end + usable) / 2,
            rawAt: totalRaw,
            wide: false
        });
        return out;
    }

    function _zoneItemForRaw(rawIndex) {
        for (var i = 0; i < zonesRepeater.count; i++) {
            var z = zonesRepeater.itemAt(i);
            if (z && z.rawIndex === rawIndex)
                return z;
        }
        return null;
    }

    // Cross-zone geometry lookups. Searching every zone's own island Repeater
    function _pillFor(id) {
        for (var i = 0; i < zonesRepeater.count; i++) {
            var zoneItem = zonesRepeater.itemAt(i);
            if (!zoneItem)
                continue;
            var p = zoneItem.pillFor(id);
            if (p)
                return p;
        }
        return null;
    }

    function _slotFor(id) {
        var pill = root._pillFor(id);
        return pill ? pill.slotFor(id) : null;
    }

    function _isVisibleInRow(id) {
        var pill = root._pillFor(id);
        return pill ? pill.isVisibleInRow(id) : false;
    }

    // Item.mapToItem only works between items in the same window.
    // mapToGlobal/mapFromGlobal round-trip through screen coordinates, which
    // works whether item is in the same window as root or a different one.
    function _mapToRoot(item, x, y) {
        var g = item.mapToGlobal(x, y);
        return root.mapFromGlobal(g.x, g.y);
    }

    // Point-in-bounds test across every rendered island pill in every
    // zone. Returns { pill } or null. Strict bounds test, no tolerance.
    function _islandHitAt(pos) {
        for (var zi = 0; zi < zonesRepeater.count; zi++) {
            var zoneItem = zonesRepeater.itemAt(zi);
            if (!zoneItem || !zoneItem.visible)
                continue;
            var rep = zoneItem.islandsRepeater;
            for (var ii = 0; ii < rep.count; ii++) {
                var pill = rep.itemAt(ii);
                if (!pill || !pill.visible)
                    continue;
                var tl = pill.mapToItem(root, 0, 0);
                if (pos.x >= tl.x && pos.x <= tl.x + pill.width && pos.y >= tl.y && pos.y <= tl.y + pill.height)
                    return {
                        pill: pill
                    };
            }
        }
        return null;
    }

    // Zone catchment and gap-tick hit-testing.
    function _zoneIndexAtPos(pos) {
        var coord = BarConfig.isVertical ? pos.y : pos.x;
        var origin = root._cfg.endGap;
        var bounds = root._allZoneBounds;
        var cands = root._zoneGapCandidates;
        for (var i = 0; i < bounds.length; i++) {
            var loCand = cands[i];
            var hiCand = cands[i + 1];
            var lo = Math.min(origin + bounds[i].start, origin + loCand.pos + root._cfg.zoneTickRadius);
            var hi = Math.max(origin + bounds[i].end, origin + hiCand.pos - root._cfg.zoneTickRadius);
            if (coord >= lo && coord <= hi)
                return bounds[i].rawIndex;
        }
        return -1;
    }

    function _zoneGapCandidateAt(pos) {
        var coord = BarConfig.isVertical ? pos.y : pos.x;
        var origin = root._cfg.endGap;
        var cands = root._zoneGapCandidates;
        for (var i = 0; i < cands.length; i++) {
            if (cands[i].wide)
                return cands[i];
            if (Math.abs(coord - (origin + cands[i].pos)) <= root._cfg.zoneTickRadius)
                return cands[i];
        }
        return null;
    }

    // Nearest island-boundary insertion index within one zone (by raw
    // index), for both the island-spawn anchor and whole-island moves.
    function _islandInsertionIndexInZone(rawIndex, pos) {
        var zoneItem = root._zoneItemForRaw(rawIndex);
        if (!zoneItem)
            return 0;
        var coord = BarConfig.isVertical ? pos.y : pos.x;
        var rep = zoneItem.islandsRepeater;
        for (var i = 0; i < rep.count; i++) {
            var pill = rep.itemAt(i);
            if (!pill)
                continue;
            var c = pill.mapToItem(root, pill.width / 2, pill.height / 2);
            var cc = BarConfig.isVertical ? c.y : c.x;
            if (coord < cc)
                return i;
        }
        return rep.count;
    }

    // Merge target when the pointer is directly over a specific island
    // pill. It's unambiguous, resolved straight from pointer position.
    function _computeMergeTarget(draggedId, pos, pill) {
        var coord = BarConfig.isVertical ? pos.y : pos.x;
        var beforeId = "";
        for (var i = 0; i < pill.ids.length; i++) {
            var id = BarItemsService._memberId(pill.ids[i]);
            if (id === draggedId || !root._isVisibleInRow(id))
                continue;
            var slot = root._slotFor(id);
            if (!slot)
                continue;
            var center = slot.mapToItem(root, slot.width / 2, slot.height / 2);
            var centerCoord = BarConfig.isVertical ? center.y : center.x;
            if (coord < centerCoord) {
                beforeId = id;
                break;
            }
        }
        return {
            zoneRawIdx: pill.zoneRawIndex,
            islandIds: pill._memberIds.filter(function (x) {
                return x !== draggedId;
            }),
            beforeId: beforeId
        };
    }

    // Drag-to-reorder / merge / spawn-island / spawn-zone state.

    property var _dragItemData: null
    property real _dragItemW: 0
    property real _dragItemH: 0
    property point _dragPos: Qt.point(0, 0)
    property var _dragGrab: null

    property string _dropBeforeId: ""
    property int _dropTargetZoneRawIdx: -1
    // Non-null while hovering directly over a specific pill. That pill's
    // member ids (dragged id excluded). Null here means not over a pill. The
    // three-way gap disambiguation below (zone catchment / zone-insertion
    // tick / dead space) only runs when this is null.
    property var _dropTargetIslandIds: null

    property bool _spawnArmed: false
    property int _spawnTargetZoneRawIdx: -1
    property int _spawnBeforeIslandIdx: -1

    property bool _spawnZoneArmed: false
    property int _spawnZoneAtIndex: -1
    property real _spawnZonePos: 0

    property string _dropTargetChevronId: ""
    // When a chevron is ready to be created
    property bool _spawnChevronArmed: false
    property string _chevronHoldTargetAtomId: ""

    // Identifies whichever hold-target the pointer is currently over, or ""
    // for pill-hover/dead-space.
    property string _holdTargetKey: ""

    function _setHoldTarget(key, timer) {
        if (key === root._holdTargetKey)
            return;
        spawnHoldTimer.stop();
        spawnZoneHoldTimer.stop();
        chevronHoldTimer.stop();
        root._spawnArmed = false;
        root._spawnZoneArmed = false;
        root._spawnChevronArmed = false;
        root._holdTargetKey = key;
        if (timer)
            timer.restart();
    }

    // Whole-island drag state.
    property var _dragIslandIds: null
    property real _dragIslandW: 0
    property real _dragIslandH: 0
    property point _islandDragPos: Qt.point(0, 0)
    property var _islandDragGrab: null
    property int _islandDropZoneRawIdx: -1
    property int _islandDropIdx: -1

    readonly property string _dropEndTargetId: {
        if (!root._dragItemData || !root._dropTargetIslandIds || root._dropTargetIslandIds.length === 0)
            return "";
        return root._dropTargetIslandIds[root._dropTargetIslandIds.length - 1];
    }

    // Clear where atoms or islands are dropped to
    function _clearDropTargets() {
        root._dropTargetIslandIds = null;
        root._dropTargetZoneRawIdx = -1;
        root._dropBeforeId = "";
        root._dropTargetChevronId = "";
        root._chevronHoldTargetAtomId = "";
    }

    function _beginDrag(slot) {
        root._dragItemData = slot.itemData;
        root._dragItemW = slot.width;
        root._dragItemH = slot.height;
        root._dragGrab = null;
        root._setHoldTarget("");
        root._clearDropTargets();
        root._dragPos = root._mapToRoot(slot, slot.width / 2, slot.height / 2);
        if (slot.itemRef && slot.itemRef.grabToImage)
            slot.itemRef.grabToImage(function (result) {
                root._dragGrab = result;
            });
    }

    function _updateDragPos(p) {
        root._dragPos = p;

        var draggedId = root._dragItemData.id;
        var draggingChevron = root._dragItemData.chevron === true;
        // We just don't put workspace atoms in chevrons... at some point we can
        // fix the rendering issues that come with it. I just don't have time.
        // In other words: I can't be bothered
        var chevronEligible = !draggingChevron && draggedId !== "workspace";

        var islandHit = root._islandHitAt(p);
        if (islandHit) {
            var mem = islandHit.pill.memberAt(p);

            if (mem && mem.isChevron && mem.id !== draggedId && chevronEligible) {
                root._setHoldTarget("");
                root._dropTargetChevronId = mem.id;
                root._dropTargetZoneRawIdx = islandHit.pill.zoneRawIndex;
                root._dropTargetIslandIds = null;
                root._dropBeforeId = "";
                return;
            }
            root._dropTargetChevronId = "";

            var target = root._computeMergeTarget(draggedId, p, islandHit.pill);
            root._dropTargetZoneRawIdx = target.zoneRawIdx;
            root._dropTargetIslandIds = target.islandIds;
            root._dropBeforeId = target.beforeId;

            if (mem && !mem.isChevron && mem.id !== draggedId && chevronEligible && mem.id !== "workspace") {
                root._chevronHoldTargetAtomId = mem.id;
                root._setHoldTarget("chv:" + mem.id, chevronHoldTimer);
            } else {
                root._setHoldTarget("");
            }
            return;
        }
        root._dropTargetChevronId = "";
        root._dropTargetZoneRawIdx = -1;
        root._dropTargetIslandIds = null;
        root._dropBeforeId = "";

        var rawIdx = root._zoneIndexAtPos(p);
        if (rawIdx >= 0) {
            root._spawnTargetZoneRawIdx = rawIdx;
            root._spawnBeforeIslandIdx = root._islandInsertionIndexInZone(rawIdx, p);
            root._setHoldTarget("zone:" + rawIdx, spawnHoldTimer);
            return;
        }

        var gapCand = root._zoneGapCandidateAt(p);
        if (gapCand) {
            root._spawnZoneAtIndex = gapCand.rawAt;
            root._spawnZonePos = gapCand.pos;
            root._setHoldTarget("gap:" + gapCand.rawAt, spawnZoneHoldTimer);
            return;
        }

        root._setHoldTarget("");
    }

    function _endDrag() {
        spawnHoldTimer.stop();
        spawnZoneHoldTimer.stop();
        chevronHoldTimer.stop();
        if (root._dragItemData) {
            if (root._dropTargetChevronId) {
                BarItemsService.addToChevron(root._dragItemData.id, root._dropTargetChevronId, "");
            } else if (root._spawnChevronArmed && root._chevronHoldTargetAtomId) {
                BarItemsService.spawnChevron(root._dragItemData.id, root._chevronHoldTargetAtomId, false);
            } else if (root._spawnZoneArmed) {
                BarItemsService.spawnZone(root._dragItemData.id, root._spawnZoneAtIndex);
            } else if (root._spawnArmed) {
                var zi = root._spawnTargetZoneRawIdx;
                var groups = root._renderZones[zi] || [];
                var idx = root._spawnBeforeIslandIdx;
                var anchorId = (idx >= 0 && idx < groups.length) ? BarItemsService._memberId(groups[idx][0]) : "";
                BarItemsService.spawnIsland(root._dragItemData.id, zi, anchorId);
            } else if (root._dropTargetIslandIds !== null) {
                BarItemsService.moveIconToIsland(root._dragItemData.id, root._dropTargetZoneRawIdx, root._dropTargetIslandIds, root._dropBeforeId);
            }
            // else released over dead space with nothing armed, no-op.
        }
        root._dragItemData = null;
        root._dragGrab = null;
        root._holdTargetKey = "";
        root._spawnArmed = false;
        root._spawnZoneArmed = false;
        root._spawnChevronArmed = false;
        root._clearDropTargets();
        root._spawnBeforeIslandIdx = -1;
        root._spawnTargetZoneRawIdx = -1;
        root._spawnZoneAtIndex = -1;
    }

    function _beginIslandDrag(pill) {
        root._dragIslandIds = pill.ids.slice();
        root._dragIslandW = pill.width;
        root._dragIslandH = pill.height;
        root._islandDragGrab = null;
        root._islandDropZoneRawIdx = pill.zoneRawIndex;
        root._islandDropIdx = pill.islandIndex;
        root._setHoldTarget("");
        if (pill.grabToImage)
            pill.grabToImage(function (result) {
                root._islandDragGrab = result;
            });
    }

    function _updateIslandDragPos(p) {
        root._islandDragPos = p;

        var rawIdx = root._zoneIndexAtPos(p);
        if (rawIdx >= 0) {
            root._setHoldTarget("");
            root._islandDropZoneRawIdx = rawIdx;
            root._islandDropIdx = root._islandInsertionIndexInZone(rawIdx, p);
            return;
        }

        var gapCand = root._zoneGapCandidateAt(p);
        if (gapCand) {
            root._spawnZoneAtIndex = gapCand.rawAt;
            root._spawnZonePos = gapCand.pos;
            root._setHoldTarget("gap:" + gapCand.rawAt, spawnZoneHoldTimer);
            return;
        }

        root._setHoldTarget("");
        // dead spacem, keep the last valid drop target (zone/idx)
    }

    function _endIslandDrag() {
        spawnZoneHoldTimer.stop();
        if (root._dragIslandIds) {
            if (root._spawnZoneArmed) {
                BarItemsService.spawnZoneWithIsland(root._dragIslandIds, root._spawnZoneAtIndex);
            } else {
                var rawIdx = root._islandDropZoneRawIdx;
                var groups = root._renderZones[rawIdx] || [];
                var idx = root._islandDropIdx;
                var anchorId = (idx >= 0 && idx < groups.length) ? BarItemsService._memberId(groups[idx][0]) : "";
                BarItemsService.moveIsland(root._dragIslandIds, rawIdx, anchorId);
            }
        }
        root._dragIslandIds = null;
        root._islandDragGrab = null;
        root._islandDropZoneRawIdx = -1;
        root._islandDropIdx = -1;
        root._setHoldTarget("");
        root._spawnZoneArmed = false;
        root._spawnZoneAtIndex = -1;
    }

    // The workspace renders beyond the bar for its popup effect.
    // This means its atom has no pixels of its own. PanelWindow is just
    // embedded into it.
    function _publishWorkspaceRect() {
        var slot = root._slotFor("workspace");
        if (!slot || !slot.itemRef)
            return;
        if (!slot.visible) {
            slot.itemRef.clearAtomRect();
            return;
        }
        var tl = slot.mapToItem(root, 0, 0);
        var size = BarConfig.isVertical ? slot.height : slot.width;
        var corner = root._workspaceCorner();
        slot.itemRef.setAtomRect({
            pos: (BarConfig.isVertical ? tl.y : tl.x) + size / 2,
            size: size,
            atCorner: corner.at,
            cornerFlip: corner.flip
        });
    }

    function _workspaceCorner() {
        var raw = BarItemsService.zones;
        if (raw.length === 0)
            return {
                at: false,
                flip: false
            };
        var firstZone = raw[0];
        if (firstZone.length > 0 && firstZone[0].length > 0 && firstZone[0][0] === "workspace")
            return {
                at: true,
                flip: false
            };
        var lastZone = raw[raw.length - 1];
        var lastIsland = lastZone.length > 0 ? lastZone[lastZone.length - 1] : null;
        if (!!lastIsland && lastIsland.length > 0 && lastIsland[lastIsland.length - 1] === "workspace")
            return {
                at: true,
                flip: true
            };
        return {
            at: false,
            flip: false
        };
    }

    on_ZoneLayoutChanged: Qt.callLater(root._publishWorkspaceRect)
    on_WidthMapChanged: Qt.callLater(root._publishWorkspaceRect)
    on_AvailabilityMapChanged: Qt.callLater(root._publishWorkspaceRect)

    Connections {
        target: BarItemsService
        function onZonesChanged() {
            Qt.callLater(root._publishWorkspaceRect);
        }
    }

    function beginWorkspaceDrag(w, h, barLocalX, barLocalY) {
        root._dragItemData = root._catalogItem("workspace");
        root._dragItemW = w;
        root._dragItemH = h;
        root._dragGrab = null;
        root._setHoldTarget("");
        root._clearDropTargets();
        root._dragPos = Qt.point(barLocalX, barLocalY);
    }
    function updateWorkspaceDragPos(barLocalX, barLocalY) {
        root._updateDragPos(Qt.point(barLocalX, barLocalY));
    }
    function setWorkspaceDragGrab(result) {
        root._dragGrab = result;
    }
    function endWorkspaceDrag() {
        root._endDrag();
    }

    onScreenNameChanged: Qt.callLater(root._publishWorkspaceRect)
    Component.onCompleted: Qt.callLater(root._publishWorkspaceRect)

    Timer {
        id: spawnHoldTimer
        interval: root._spawnHoldMs
        onTriggered: root._spawnArmed = true
    }

    Timer {
        id: spawnZoneHoldTimer
        interval: root._spawnZoneHoldMs
        onTriggered: root._spawnZoneArmed = true
    }

    Timer {
        id: chevronHoldTimer
        interval: root._spawnChevronHoldMs
        onTriggered: root._spawnChevronArmed = true
    }

    Component {
        id: chevronComponent
        ChevronAtom {}
    }

    // The inner Loader stays active/visible, the wrapper's own visible is the
    // place overflow/disabled/unavailable state is expressed.
    //
    // Slots own along-flow size animatio. Atoms report its target
    // implicitWidth/Height. Slots ease that delta and are the only ones
    // to report that quantized value to a whole pixel.
    component TrayItemSlot: Item {
        id: slot
        required property var itemData
        property bool forceVisible: false
        property bool reorderable: false
        // Workspace placeholder does not wanna ease sizing
        property bool animateSize: true
        property bool clipToSlot: false

        // Size of the atoms. Drag ghosts, overflow, popup-measurements need
        // this.
        readonly property real itemWidth: content.item ? content.item.implicitWidth : 0
        readonly property real itemHeight: content.item ? content.item.implicitHeight : 0
        readonly property var itemRef: content.item
        readonly property bool itemAvailable: content.item ? content.item.available !== false : true

        readonly property bool _isDragging: root._dragItemData !== null && root._dragItemData.id === slot.itemData.id
        readonly property bool _showDropBefore: root._dragItemData !== null && !slot._isDragging && root._dropBeforeId === slot.itemData.id
        readonly property bool _showDropAfter: root._dragItemData !== null && root._dropBeforeId === "" && root._dropEndTargetId === slot.itemData.id

        // Eased sizes
        property real _animW: slot.itemWidth
        property real _animH: slot.itemHeight
        readonly property int effectiveWidth: Math.round(slot._animW)
        readonly property int effectiveHeight: Math.round(slot._animH)

        property bool _sizeSettled: false
        function _armSettle() {
            if (!slot._sizeSettled && (slot.effectiveWidth > 0 || slot.effectiveHeight > 0))
                settleTimer.restart();
        }
        Timer {
            id: settleTimer
            interval: 0
            onTriggered: slot._sizeSettled = true
        }
        Behavior on _animW {
            enabled: slot.animateSize && root._morphReady && slot._sizeSettled
            NumberAnimation {
                id: wAnim
                duration: Anim.morph
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
                onRunningChanged: root._atomResizing = root._atomResizingAfter(running ? 1 : -1)
            }
        }
        Behavior on _animH {
            enabled: slot.animateSize && root._morphReady && slot._sizeSettled
            NumberAnimation {
                id: hAnim
                duration: Anim.morph
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.standard
                onRunningChanged: root._atomResizing = root._atomResizingAfter(running ? 1 : -1)
            }
        }
        Component.onDestruction: {
            if (wAnim.running)
                root._atomResizing = root._atomResizingAfter(-1);
            if (hAnim.running)
                root._atomResizing = root._atomResizingAfter(-1);
        }

        onItemAvailableChanged: {
            var m = Object.assign({}, root._availabilityMap);
            m[slot.itemData.id] = slot.itemAvailable;
            root._availabilityMap = m;
        }
        onEffectiveWidthChanged: {
            var m = Object.assign({}, root._widthMap);
            m[slot.itemData.id] = slot.effectiveWidth;
            root._widthMap = m;
            slot._armSettle();
        }
        onEffectiveHeightChanged: {
            var m = Object.assign({}, root._heightMap);
            m[slot.itemData.id] = slot.effectiveHeight;
            root._heightMap = m;
            slot._armSettle();
        }

        Layout.alignment: Qt.AlignCenter
        visible: slot.forceVisible || root._isVisibleInRow(slot.itemData.id)
        clip: slot.clipToSlot
        Layout.preferredWidth: slot.effectiveWidth
        Layout.preferredHeight: slot.effectiveHeight
        implicitWidth: slot.effectiveWidth
        implicitHeight: slot.effectiveHeight

        DragHandler {
            id: dragHandler
            enabled: slot.reorderable
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType

            onActiveChanged: {
                if (active)
                    root._beginDrag(slot);
                else
                    root._endDrag();
            }
            onCentroidChanged: {
                if (!active)
                    return;
                var p = root._mapToRoot(slot, centroid.position.x, centroid.position.y);
                root._updateDragPos(p);
            }
        }

        Rectangle {
            visible: slot._showDropBefore
            color: Colors.accent
            radius: 1
            z: 10
            width: BarConfig.isVertical ? parent.width : 2
            height: BarConfig.isVertical ? 2 : parent.height
            x: BarConfig.isVertical ? 0 : -root._gap / 2 - width / 2
            y: BarConfig.isVertical ? -root._gap / 2 - height / 2 : 0
        }
        Rectangle {
            visible: slot._showDropAfter
            color: Colors.accent
            radius: 1
            z: 10
            width: BarConfig.isVertical ? parent.width : 2
            height: BarConfig.isVertical ? 2 : parent.height
            x: BarConfig.isVertical ? 0 : parent.width + root._gap / 2 - width / 2
            y: BarConfig.isVertical ? parent.height + root._gap / 2 - height / 2 : 0
        }

        // Lit while a drag is held over this atom, arming a manual-chevron spawn.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 8
            color: "transparent"
            border.color: Colors.accent
            border.width: 2
            opacity: 0.7
            z: 9
            visible: root._dragItemData !== null && !slot._isDragging && root._holdTargetKey === ("chv:" + slot.itemData.id)
        }

        Loader {
            id: content
            // Renders at items implicit width/height as soon as it loads.
            anchors.centerIn: parent
            active: BarItemsService.isEnabled(slot.itemData.id)
            visible: active && (item == null || item.available !== false)
            opacity: slot._isDragging ? 0.3 : 1

            Component.onCompleted: {
                if (slot.itemData.chevron)
                    content.sourceComponent = chevronComponent;
                else
                    content.source = slot.itemData.src;
            }

            onLoaded: {
                if (content.item && content.item.barAnimatesSize === false)
                    slot.animateSize = false;
                if (slot.itemData.chevron) {
                    slot.clipToSlot = true;
                    content.width = Qt.binding(() => BarConfig.isVertical ? content.implicitWidth : slot.effectiveWidth);
                    content.height = Qt.binding(() => BarConfig.isVertical ? slot.effectiveHeight : content.implicitHeight);
                    content.item.chevronId = slot.itemData.id;
                    content.item.memberIds = Qt.binding(() => slot.itemData.ids);
                } else if (slot.itemData.id === "workspace") {
                    // This is bad practice. But a quick fix.
                    // TODO: We should let widgets declare it themselves.
                    slot.animateSize = false;
                    content.item.screenName = Qt.binding(() => root.screenName);
                    content.item.barZoneRow = root;
                }
            }
        }
    }
    // Manual chevron rendered inline.
    // Clicking it will expand/collapse it.
    // The chevron only reports its target implicitWidth - _toggleExtent
    // collapsed, _toggleExtent + gap + members expanded
    component ChevronAtom: Item {
        id: chAtom
        property string chevronId: ""
        property var memberIds: []
        property bool available: true

        readonly property bool expanded: root._isChevronExpanded(chAtom.chevronId)
        readonly property bool _vert: BarConfig.isVertical
        readonly property real _toggleExtent: root._chevronWidth

        readonly property real _membersExtent: {
            var ids = chAtom.memberIds || [];
            var total = 0;
            var n = 0;
            for (var i = 0; i < ids.length; i++) {
                if (root._availabilityMap[ids[i]] === false)
                    continue;
                var s = (chAtom._vert ? root._heightMap[ids[i]] : root._widthMap[ids[i]]) || 0;
                if (s <= 0)
                    continue;
                total += s + (n > 0 ? root._gap : 0);
                n++;
            }
            return total;
        }

        readonly property real _axisTarget: Math.round((chAtom.expanded && chAtom._membersExtent > 0) ? chAtom._toggleExtent + root._gap + chAtom._membersExtent : chAtom._toggleExtent)

        implicitWidth: chAtom._vert ? chAtom._toggleExtent : chAtom._axisTarget
        implicitHeight: chAtom._vert ? chAtom._axisTarget : chAtom._toggleExtent
        clip: true

        GridLayout {
            id: membersGrid
            rowSpacing: root._gap
            columnSpacing: root._gap
            rows: chAtom._vert ? -1 : 1
            columns: chAtom._vert ? 1 : -1

            anchors.right: chAtom._vert ? undefined : toggleBtn.left
            anchors.rightMargin: chAtom._vert ? 0 : root._gap
            anchors.bottom: chAtom._vert ? toggleBtn.top : undefined
            anchors.bottomMargin: chAtom._vert ? root._gap : 0
            anchors.verticalCenter: chAtom._vert ? undefined : parent.verticalCenter
            anchors.horizontalCenter: chAtom._vert ? parent.horizontalCenter : undefined

            opacity: chAtom.expanded ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                }
            }

            Repeater {
                model: chAtom.memberIds
                delegate: TrayItemSlot {
                    id: chSlot
                    required property string modelData
                    itemData: root._catalogItem(chSlot.modelData)
                    reorderable: true
                    visible: chSlot.itemAvailable
                }
            }
        }

        BarButton {
            id: toggleBtn
            anchors.right: chAtom._vert ? undefined : parent.right
            anchors.bottom: chAtom._vert ? parent.bottom : undefined
            anchors.verticalCenter: chAtom._vert ? undefined : parent.verticalCenter
            anchors.horizontalCenter: chAtom._vert ? parent.horizontalCenter : undefined
            icon: "»"
            active: chAtom.expanded
            onClicked: root._toggleChevronExpanded(chAtom.chevronId)
        }
    }

    // One pill per island. Background, GridLayout of items, overflow chevron,
    // popup, scoped to ids.
    component IslandPill: Item {
        id: pill
        required property int zoneRawIndex
        required property int islandIndex
        required property var ids

        readonly property var _members: pill.ids.map(function (m) {
            return BarItemsService._memberIsChevron(m) ? ({
                    id: m.chevron,
                    chevron: true,
                    ids: m.ids,
                    label: "»"
                }) : m;
        })
        readonly property var _memberIds: pill.ids.map(m => BarItemsService._memberId(m))
        readonly property var _availableMembers: {
            var out = [];
            for (var i = 0; i < pill.ids.length; i++) {
                var m = pill.ids[i];
                if (BarItemsService._memberIsChevron(m) || root._isAvailable(m))
                    out.push(m);
            }
            return out;
        }
        readonly property var _availableMemberIds: pill._availableMembers.map(m => BarItemsService._memberId(m))

        readonly property bool _suppressBackground: root._islandPad(pill.ids) === 0

        visible: pill._availableMemberIds.length > 0
        implicitWidth: BarConfig.isVertical ? BarConfig.islandThickness : (pillLayout.implicitWidth + (pill._suppressBackground ? 0 : root._pad))
        implicitHeight: BarConfig.isVertical ? (pillLayout.implicitHeight + (pill._suppressBackground ? 0 : root._pad)) : BarConfig.islandThickness

        readonly property real _budget: root._islandBudgetsForZone(pill.zoneRawIndex, root._zoneWidthFor(pill.zoneRawIndex))[pill.islandIndex] ?? -1
        // An island with an unfolded chevron is incompressible (_islandMinWidth)
        readonly property int _fitCountLive: root._idsHaveExpandedChevron(pill.ids) ? pill._availableMembers.length : root._fitCountFor(pill._availableMembers, pill._budget)
        // Keeps track of _fitCountLive except for when an atom is
        // mid-size-morph. Then it'll just wait and resyncs when the morph
        // is completed.
        property int _fitCount: pill._fitCountLive
        property var _frozenVisibleIds: []
        function _syncFitCount() {
            if (root._atomResizing <= 0) {
                pill._fitCount = pill._fitCountLive;
                pill._frozenVisibleIds = pill._availableMemberIds.slice(Math.max(0, pill._availableMemberIds.length - pill._fitCount));
                return;
            }
            if (pill._frozenVisibleIds.length === 0)
                return; // nothing was visible pre-morph, leave _fitCount as-is
            var ids = pill._availableMemberIds;
            var minIdx = -1;
            for (var i = 0; i < pill._frozenVisibleIds.length; i++) {
                var k = ids.indexOf(pill._frozenVisibleIds[i]);
                if (k >= 0 && (minIdx < 0 || k < minIdx))
                    minIdx = k;
            }
            if (minIdx >= 0)
                pill._fitCount = ids.length - minIdx;
        }

        Component.onCompleted: {
            pill._fitCount = pill._fitCountLive;
            pill._frozenVisibleIds = pill._availableMemberIds.slice(Math.max(0, pill._availableMemberIds.length - pill._fitCount));
        }
        on_FitCountLiveChanged: pill._syncFitCount()

        readonly property int _availableCount: pill._availableMembers.length
        on_AvailableCountChanged: pill._syncFitCount()
        Connections {
            target: root
            function on_AtomResizingChanged() {
                pill._syncFitCount();
            }
        }
        readonly property bool _hasOverflow: pill._fitCount < pill._availableMembers.length

        function isOverflowed(id) {
            var idx = pill._availableMemberIds.indexOf(id);
            return idx >= 0 && idx < (pill._availableMemberIds.length - pill._fitCount);
        }
        function isVisibleInRow(id) {
            var idx = pill._availableMemberIds.indexOf(id);
            return idx >= 0 && idx >= (pill._availableMemberIds.length - pill._fitCount);
        }
        function slotFor(id) {
            var idx = pill._memberIds.indexOf(id);
            return idx >= 0 ? innerRepeater.itemAt(idx) : null;
        }

        function memberAt(p) {
            for (var i = 0; i < innerRepeater.count; i++) {
                var s = innerRepeater.itemAt(i);
                if (!s || !s.visible)
                    continue;
                var tl = s.mapToItem(root, 0, 0);
                if (p.x >= tl.x && p.x <= tl.x + s.width && p.y >= tl.y && p.y <= tl.y + s.height)
                    return {
                        id: pill._memberIds[i],
                        isChevron: BarItemsService._memberIsChevron(pill.ids[i])
                    };
            }
            return null;
        }

        // Largest uneased size among the currently overflowed members,
        // on the given axis. Sizes the overflow popup rows.
        function _maxOverflowedItem(vertical) {
            var max = 0;
            for (var i = 0; i < pill._availableMemberIds.length - pill._fitCount; i++) {
                var s = pill.slotFor(pill._availableMemberIds[i]);
                if (!s)
                    continue;
                var v = vertical ? s.itemHeight : s.itemWidth;
                if (v > max)
                    max = v;
            }
            return max;
        }
        readonly property real _maxOverflowedItemWidth: pill._maxOverflowedItem(false)
        readonly property real _maxOverflowedItemHeight: pill._maxOverflowedItem(true)

        Surface {
            anchors.fill: parent
            visible: !pill._suppressBackground && BarConfig.showIslands
            cornerRadius: BarConfig.islandRadius
            level: 1
            overrideFill: true

            fillColor: BarConfig.showStrip ? Colors.surfaceHighest : Colors.bg
        }

        // Moves the whole island as a block. Maybe even into another zone.
        // Only receives presses no child claims first.
        DragHandler {
            id: islandDragHandler
            target: null
            onActiveChanged: {
                if (active)
                    root._beginIslandDrag(pill);
                else
                    root._endIslandDrag();
            }
            onCentroidChanged: {
                if (!active)
                    return;
                var p = pill.mapToItem(root, centroid.position.x, centroid.position.y);
                root._updateIslandDragPos(p);
            }
        }

        GridLayout {
            id: pillLayout
            anchors.centerIn: parent
            rowSpacing: root._gap
            columnSpacing: root._gap
            rows: BarConfig.isVertical ? -1 : 1
            columns: BarConfig.isVertical ? 1 : -1

            Loader {
                id: chevronLoader
                Layout.alignment: Qt.AlignCenter
                active: pill._hasOverflow
                visible: active
                sourceComponent: BarButton {
                    icon: "»"
                    onClicked: islandPopup.visible ? islandPopup.close() : islandPopup.open()
                }
            }

            Repeater {
                id: innerRepeater
                model: pill._members
                delegate: TrayItemSlot {
                    id: traySlot
                    required property var modelData
                    itemData: (typeof traySlot.modelData === "string") ? root._catalogItem(traySlot.modelData) : traySlot.modelData
                    reorderable: true
                }
            }
        }

        AnimatedPopup {
            id: islandPopup
            anchorItem: chevronLoader
            implicitWidth: Math.max(Math.round(180 * UIScale.value), pill._maxOverflowedItemWidth + Math.round(90 * UIScale.value) + UIScale.spacingSm * 4)
            readonly property real _rowHeight: Math.max(Math.round(30 * UIScale.value), pill._maxOverflowedItemHeight)
            implicitHeight: Math.min(Math.round(320 * UIScale.value), Math.max(1, pill._availableMembers.length - pill._fitCount) * (_rowHeight + 2) + Math.round(16 * UIScale.value))
            content: Component {
                Flickable {
                    contentWidth: width
                    contentHeight: overflowCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: overflowCol
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: pill._members
                            delegate: RowLayout {
                                id: ovRow
                                required property var modelData
                                readonly property string _mid: (typeof ovRow.modelData === "string") ? ovRow.modelData : ovRow.modelData.id
                                readonly property var _itemData: (typeof ovRow.modelData === "string") ? root._catalogItem(ovRow.modelData) : ovRow.modelData
                                readonly property bool overflowed: pill.isOverflowed(ovRow._mid)
                                Layout.fillWidth: true
                                Layout.leftMargin: UIScale.spacingSm
                                Layout.rightMargin: UIScale.spacingSm
                                visible: ovRow.overflowed
                                spacing: UIScale.spacingSm

                                TrayItemSlot {
                                    itemData: ovRow._itemData
                                    forceVisible: true
                                    reorderable: true
                                }
                                Text {
                                    text: (ovRow._itemData && ovRow._itemData.label) ? ovRow._itemData.label : ovRow._mid
                                    Layout.fillWidth: true
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component ZoneGroup: Item {
        id: zoneGroup
        required property int rawIndex
        required property var islandGroups

        readonly property alias islandsRepeater: islandsRepeaterInner

        readonly property var _availableIslandGroups: {
            var out = [];
            for (var i = 0; i < islandGroups.length; i++)
                if (root._availableIdsIn(islandGroups[i]).length > 0)
                    out.push(islandGroups[i]);
            return out;
        }

        visible: _availableIslandGroups.length > 0

        // Islands position and width calculate here. A pinned atom has a zone
        // which needs one atom fixed at the exact center with two independent
        // flanking runs around it.
        readonly property var _layout: root._islandLayout(zoneGroup.rawIndex, root._zoneWidthFor(zoneGroup.rawIndex))

        implicitWidth: BarConfig.isVertical ? BarConfig.islandThickness : Math.round(_layout.totalWidth)
        implicitHeight: BarConfig.isVertical ? Math.round(_layout.totalWidth) : BarConfig.islandThickness

        function pillFor(id) {
            for (var i = 0; i < islandsRepeaterInner.count; i++) {
                var p = islandsRepeaterInner.itemAt(i);
                if (p && p._memberIds.indexOf(id) >= 0)
                    return p;
            }
            return null;
        }

        Repeater {
            id: islandsRepeaterInner
            model: zoneGroup.islandGroups
            delegate: IslandPill {
                id: pill
                required property var modelData
                required property int index
                zoneRawIndex: zoneGroup.rawIndex
                islandIndex: index
                ids: modelData

                readonly property var _zoneLayout: zoneGroup._layout
                visible: pill._zoneLayout.visible[pill.index] ?? false

                readonly property real _rawX: BarConfig.isVertical ? (zoneGroup.width - pill.width) / 2 : zoneGroup.width / 2 + (pill._zoneLayout.xs[pill.index] ?? 0)
                readonly property real _rawY: BarConfig.isVertical ? zoneGroup.height / 2 + (pill._zoneLayout.xs[pill.index] ?? 0) : (zoneGroup.height - pill.height) / 2
                x: Math.round(pill._rawX)
                y: Math.round(pill._rawY)
            }
        }
    }

    Surface {
        anchors.fill: parent
        visible: BarConfig.showStrip
    }

    Repeater {
        id: zonesRepeater
        model: root._liveZones
        delegate: ZoneGroup {
            id: zoneDelegate
            required property var modelData
            rawIndex: modelData.rawIndex
            islandGroups: modelData.islandGroups

            readonly property var _layoutEntry: root._zoneLayoutByRaw[zoneDelegate.rawIndex] ?? null

            // Trailing raw zone (e.g. the systray) is anchored to the edge
            // using its own renderedd width/height. _zoneLayout's width for
            // this zone is a budget. _fitCountFor fits a whole number of items
            // into that budget.
            readonly property bool _isTrailing: zoneDelegate.rawIndex === BarItemsService.zones.length - 1

            readonly property real _rawX: {
                if (BarConfig.isVertical)
                    return (root.width - width) / 2;
                if (zoneDelegate._isTrailing)
                    return root.width - BarConfig.endGap - width;
                return BarConfig.endGap + (_layoutEntry ? _layoutEntry.pos : 0);
            }
            readonly property real _rawY: {
                if (!BarConfig.isVertical)
                    return (root.height - height) / 2;
                if (zoneDelegate._isTrailing)
                    return root.height - BarConfig.endGap - height;
                return BarConfig.endGap + (_layoutEntry ? _layoutEntry.pos : 0);
            }
            x: Math.round(zoneDelegate._rawX)
            y: Math.round(zoneDelegate._rawY)
        }
    }

    // Zone insertion markers, visible during atom or islandd drag
    Repeater {
        model: (root._dragItemData !== null || root._dragIslandIds !== null) ? root._zoneGapCandidates : []
        delegate: Rectangle {
            id: tick
            required property var modelData
            required property int index
            visible: !modelData.wide
            readonly property bool _lit: root._holdTargetKey === ("gap:" + modelData.rawAt)
            readonly property real _size: _lit ? Math.round(10 * UIScale.value) : Math.round(5 * UIScale.value)
            width: _size
            height: _size
            radius: _size / 2
            color: _lit ? Colors.accent : Colors.muted
            opacity: _lit ? 0.9 : 0.35
            x: BarConfig.isVertical ? (root.width - width) / 2 : BarConfig.endGap + modelData.pos - width / 2
            y: BarConfig.isVertical ? BarConfig.endGap + modelData.pos - height / 2 : (root.height - height) / 2
            z: 998

            Behavior on width {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
        }
    }

    // Floating snapshot of the dragged item, following the pointer.
    Item {
        id: dragGhost
        visible: root._dragItemData !== null
        z: 1000
        width: root._dragItemW
        height: root._dragItemH
        x: root._dragPos.x - width / 2
        y: root._dragPos.y - height / 2

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Colors.barBg
            border.color: Colors.accent
            border.width: 1
            visible: ghostImage.status !== Image.Ready
        }
        Image {
            id: ghostImage
            anchors.fill: parent
            source: root._dragGrab ? root._dragGrab.url : ""
            visible: status === Image.Ready
            smooth: true
        }
    }

    // Preview shown once a drag-out-and-hold has armed a new-island spawn
    // in an existing zone.
    Rectangle {
        id: spawnPreview
        visible: root._spawnArmed
        z: 999
        radius: 100
        color: Colors.barBg
        opacity: 0.5
        border.color: Colors.accent
        border.width: 2
        width: root._dragItemW + root._pad
        height: root._dragItemH
        x: root._dragPos.x - width / 2
        y: root._dragPos.y - height / 2
    }

    // Preview shown once a hold over a bare atom has armed a manual chevron
    // spawn wrapping that atom together with the dragged one.
    Rectangle {
        id: chevronSpawnPreview
        visible: root._spawnChevronArmed
        z: 999
        radius: 100
        color: Colors.barBg
        opacity: 0.6
        border.color: Colors.accent
        border.width: 2
        width: root._dragItemW + root._pad
        height: root._dragItemH
        x: root._dragPos.x - width / 2
        y: root._dragPos.y - height / 2

        Text {
            anchors.centerIn: parent
            text: "»"
            color: Colors.accent
            font.pixelSize: UIScale.fontLead
            font.bold: true
        }
    }

    // Preview shown once a drag out and hold has armed a brand new zone
    Item {
        id: spawnZonePreview
        visible: root._spawnZoneArmed
        z: 999
        width: (root._dragIslandIds !== null ? root._dragIslandW : root._dragItemW + root._pad)
        height: (root._dragIslandIds !== null ? root._dragIslandH : root._dragItemH)
        x: (BarConfig.isVertical ? (root.width - width) / 2 : BarConfig.endGap + root._spawnZonePos - width / 2)
        y: (BarConfig.isVertical ? BarConfig.endGap + root._spawnZonePos - height / 2 : (root.height - height) / 2)

        Rectangle {
            anchors.fill: parent
            radius: 100
            color: "transparent"
            border.color: Colors.accent
            border.width: 2
        }
        Text {
            anchors.centerIn: parent
            text: "+"
            color: Colors.accent
            font.pixelSize: UIScale.fontLead
            font.bold: true
        }
    }

    // Floating snapshot of a whole island being dragged
    Item {
        id: islandDragGhost
        visible: root._dragIslandIds !== null
        z: 1000
        readonly property real _ghostScale: 0.55
        width: root._dragIslandW * _ghostScale
        height: root._dragIslandH * _ghostScale
        x: root._islandDragPos.x - width / 2
        y: root._islandDragPos.y - height / 2
        opacity: 0.6

        Rectangle {
            anchors.fill: parent
            radius: 100
            color: Colors.barBg
            border.color: Colors.accent
            border.width: 1
            visible: islandGhostImage.status !== Image.Ready
        }
        Image {
            id: islandGhostImage
            anchors.fill: parent
            source: root._islandDragGrab ? root._islandDragGrab.url : ""
            visible: status === Image.Ready
            smooth: true
        }
    }
}
