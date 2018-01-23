import QtQuick 2.7
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import radiance 1.0

BaseVideoNodeTile {
    id: tile

    // TODO move most of these to BaseVideoNodeTile.cpp
    property alias view: tile.parent
    property var model
    property var videoNode
    property var inputGridHeights
    property int gridX
    property int gridY
    property var inputHeights
    property string outputName
    property real posX: -1
    property real posY: -1

    property var outputHeight: 400;
    property var outputWidth: 300;
    property var normalHeight: 170;
    property var normalWidth: 150;
    property var minInputHeight: 170

    property int blockWidth: normalWidth
    property var blockHeight: normalHeight;

    property bool selected: false
    property int padding: 2

    property var lastX
    property var lastY
    property var dragCC
    property var dragging

    property var tab: null
    property var backtab: null

    property int bank: 0

    function sum(l) {
        var result = 0;
        for(var i=0; i<l.length; i++) result += l[i];
        return result;
    }

    function min(a, b) {
        return a < b ? a : b;
    }

    function max(a, b) {
        return a > b ? a : b;
    }

    function regrid() {
        // Size

        if (inputHeights) {
            minInputHeight = outputName ? max(normalHeight, outputHeight / inputHeights.length) : normalHeight;

            var shrinkageY = (inputHeights[0] - minInputHeight) / 2;
            var shrinkageHeight = -(inputHeights[0] - minInputHeight) / 2 - (inputHeights[inputHeights.length - 1] - minInputHeight) / 2;
            blockHeight = sum(inputHeights) + shrinkageHeight;
        }

        // Ys
        y = posY + padding + shrinkageY;
        height = blockHeight - 2 * padding;

        // X
        x = posX + padding;
        blockWidth = outputName ? outputWidth : min(blockHeight * 0.6, normalWidth);
        width = blockWidth - 2 * padding
    }

    onOutputNameChanged: {
        if (!dragging) regrid();
    }

    onPosYChanged: {
        if (!dragging) regrid();
    }

    onPosXChanged: {
        if (!dragging) regrid();
    }

    onInputHeightsChanged: {
        if (!dragging) regrid();
    }

    Drag.keys: [ "videonode" ]
    Drag.hotSpot: Qt.point(width / 2, height / 2)
    Drag.active: dragArea.drag.active;

    function dragLift() {
        var ccs = view.selectedConnectedComponents();
        var i;
        for (i=0; i<ccs.length; i++) {
            if (ccs[i].tiles.indexOf(tile) >= 0) break;
        }
        if (i == ccs.length) return; // Drag object was not found in selection??
        dragCC = ccs[i];
        lastX = x;
        lastY = y;
        for (var i=0; i<dragCC.tiles.length; i++) {
            dragCC.tiles[i].dragging = true;
            dragCC.tiles[i].z = 1;
            dragCC.tiles[i].opacity = 0.5;
        }
    }

    function dragDrop() {
        for (var i=0; i<dragCC.tiles.length; i++) {
            dragCC.tiles[i].dragging = false;
            dragCC.tiles[i].z = 0;
            dragCC.tiles[i].opacity = 1;
        }

        var t = Drag.target;
        var me = videoNode;
        if (t !== null
         && dragCC.vertices.indexOf(t.fromNode) < 0
         && dragCC.vertices.indexOf(t.toNode) < 0) {
            var fn = t.fromNode;
            var tn = t.toNode;
            var ti = t.toInput;

            // Step 1. Rewire the nodes surrounding drag source
            // to cut out the dragged blocks

            for (var i=0; i<dragCC.inputEdges.length; i++) {
                var e = dragCC.inputEdges[i];
                model.removeEdge(e.fromVertex, e.toVertex, e.toInput);
            }
            for (var i=0; i<dragCC.outputEdges.length; i++) {
                var e = dragCC.outputEdges[i];
                model.removeEdge(e.fromVertex, e.toVertex, e.toInput);
            }

            // Step 2. Stitch those back together
            if (dragCC.inputEdges.length >= 1) {
                for (var i=0; i<dragCC.outputEdges.length; i++) {
                    var f = dragCC.inputEdges[0];
                    var t = dragCC.outputEdges[i];
                    model.addEdge(f.fromVertex, t.toVertex, t.toInput);
                }
            }

            // Step 3. Cut the connection at the drag target
            if (fn !== null && tn !== null) model.removeEdge(fn, tn, ti);

            // Step 4. Connect up the dragged blocks at the drag target
            if (fn !== null) {
                for (var i=0; i<dragCC.inputPorts.length; i++) {
                    var t = dragCC.inputPorts[i];
                    model.addEdge(fn, t.vertex, t.input);
                    break; // TODO hook this up to every input?
                }
            }
            if (tn !== null) {
                model.addEdge(dragCC.outputNode, tn, ti);
            }
            model.flush();
        }
        for (var i=0; i<dragCC.tiles.length; i++) {
            dragCC.tiles[i].regrid();
        }
    }

    function deleteSelected() {
        for (;;) {
            var ccs = view.selectedConnectedComponents();
            if (ccs.length == 0) break;
            var deleteCC = ccs[0];

            // Step 1. Delete nodes
            for (var i=0; i<deleteCC.vertices.length; i++) {
                var e = deleteCC.vertices[i];
                model.removeVideoNode(e);
            }

            // Step 2. Stitch the surrounding blocks back together
            if (deleteCC.inputEdges.length >= 1) {
                for (var i=0; i<deleteCC.outputEdges.length; i++) {
                    var f = deleteCC.inputEdges[0];
                    var t = deleteCC.outputEdges[i];
                    model.addEdge(f.fromVertex, t.toVertex, t.toInput);
                }
            }
        }
        model.flush();
    }

    function detachOutput() {
        // Remove output edge to detach chain at this node
        var edges = model.edges;
        for (var i = 0; i < edges.length; i++) {
            var edge = edges[i];
            if (edge.fromVertex == videoNode) {
                model.removeEdge(videoNode, edge.toVertex, edge.toInput);
            }
        }
        model.flush();
    }

    function insertAfter(other) {
        // Replace `this -> child` with `this -> other -> child` on input 0
        var edges = model.edges;
        for (var i = 0; i < edges.length; i++) {
            var edge = edges[i];
            if (edge.fromVertex == videoNode) {
                var child = edge.toVertex;
                var childInput = edge.toInput;
                console.log("replacing", videoNode, child, childInput);

                model.removeEdge(videoNode, child, childInput);
                model.addEdge(other, child, childInput);
            }
        }
        model.addEdge(videoNode, other, 0);
        model.flush();
    }

    function setSelectedAsOutput() {
        var output = view.parent.currentOutputName;
        model.connectOutput(output, tile.videoNode);
        model.flush();
    }

    function selectMe() {
        var modifiers = Controls.keyboardModifiers();
        var tiles = [tile];
        if (modifiers & Qt.ShiftModifier && view.parent.lastClickedTile) {
            tiles = view.tilesBetween(view.parent.lastClickedTile, tile);
            if (tiles.length == 0) tiles = [tile];
        }
        if (modifiers & Qt.ControlModifier) {
            view.toggleSelection(tiles);
        } else if (modifiers & Qt.AltModifier) {
            view.removeFromSelection(tiles);
        } else {
            view.select(tiles);
        }
        view.parent.lastClickedTile = tile;
    }

    KeyNavigation.tab: tab;
    KeyNavigation.backtab: backtab;

    onActiveFocusChanged: {
        if (activeFocus) {
            selectMe();
        }
    }

    MouseArea {
        id: dragArea;
        z: -1;
        anchors.fill: parent;

        onClicked: {
            if (mouse.button == Qt.LeftButton) {
                tile.forceActiveFocus();
            }
        }

        drag.onActiveChanged: {
            view.ensureSelected(tile);
            if (drag.active) {
                dragLift();
            } else {
                dragDrop();
            }
        }

        drag.target: tile;
    }

    RadianceTile {
        anchors.fill: parent;
        selected: parent.selected;
        focus: true;
    }

    Behavior on x {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }
    Behavior on y {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }
    Behavior on z {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }

    Behavior on width {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }

    Behavior on height {
        enabled: !dragging
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 500
        }
    }

    Behavior on opacity {
        NumberAnimation {
            easing {
                type: Easing.InOutQuad
                amplitude: 1.0
                period: 0.5
            }
            duration: 100
        }
    }

    onXChanged: {
        if (Drag.active) {
            var deltaX = x - lastX;
            for(var i = 0; i < dragCC.tiles.length; ++i) {
                if (dragCC.tiles[i] != this) {
                    dragCC.tiles[i].x += deltaX;
                }
            }
            lastX = x;
        }
    }

    onYChanged: {
        if (Drag.active) {
            var deltaY = y - lastY;
            for(var i = 0; i < dragCC.tiles.length; ++i) {
                if (dragCC.tiles[i] != this) {
                    dragCC.tiles[i].y += deltaY;
                }
            }
            lastY = y;
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Delete) {
            deleteSelected();
        } else if (event.key == Qt.Key_Return) {
            setSelectedAsOutput();
        } else if (event.key == Qt.Key_Slash) {
            detachOutput();
        }
    }

    Controls.onControlChangedRel: {
        if (control == Controls.Scroll) {
            if (value > 0) {
                tab.forceActiveFocus();
            } else if (value < 0) {
                backtab.forceActiveFocus();
            }
        }
    }
}
