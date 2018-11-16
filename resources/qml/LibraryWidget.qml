import QtQuick 2.12
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQml.Models 2.2
import radiance 1.0
import "."

Item {
    id: libraryWidget
    property var graph
    property var registry
    property var context

    signal searchStarted
    signal searchStopped

    TreeView {
        id: librarytree
        anchors.fill: parent

        selection: ItemSelectionModel {
            id: selModel
            model: librarytree.model
        }

        model: registry.library
        backgroundVisible: false
        headerVisible: false
        alternatingRowColors: false
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

        TableViewColumn {
            role: "name"
        }
        TextMetrics {
            font.pointSize: 10
            id: tm
            text: "MM"
        }
        style: TreeViewStyle {
            indentation: tm.width;
            branchDelegate: Text {
                font.pointSize: 10
                width: tm.width
                text: styleData.isExpanded ? "▼" : "▶"
                color: RadianceStyle.mainTextColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            frame: Item {}
        }
        itemDelegate: Text {
            id: row
            color: styleData.selected ? RadianceStyle.mainTextHighlightColor : RadianceStyle.mainTextColor
            font.bold: styleData.selected
            font.pointSize: 10
            text: styleData.value
            verticalAlignment: Text.AlignVCenter

            function selectThisRow() {
                selModel.clearCurrentIndex();
                selModel.setCurrentIndex(styleData.index, ItemSelectionModel.SelectCurrent);
            }

            DragHandler {
                id: dragHandler
                enabled: !styleData.hasChildren
                target: null
                onTargetChanged: console.log("set target to " + target)
                onActiveChanged: if (active) {
                        selectThisRow()
                        target = addSelected()
                        target.externalDragActive = true
                    } else if (target) {
                        target.externalDragActive = false
                    }
            }

            TapHandler {
                // DragHandler interferes with tap and double-click detection
                // so work around that by detecting those gestures here
                onDoubleTapped: addSelected()
                onTapped: selectThisRow()
            }
        }
        rowDelegate: null

        Connections {
            target: librarytree.model

            onFilterChanged: {
                if (!filter) return;
                selModel.clearCurrentIndex();
                function selectOrExpand(index) {
                    if (librarytree.model.hasChildren(index)) {
                        librarytree.expand(index);
                        selectOrExpand(librarytree.model.index(0, 0, index));
                    } else {
                        selModel.setCurrentIndex(index, 0x0002 | 0x0010);
                    }
                }
                selectOrExpand(librarytree.model.index(0, 0));
            }
        }

        TextField {
            id: searchBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 3
            visible: false
            onAccepted: {
                addSelected();
                stopSearching();
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Escape) {
                    stopSearching();
                }
            }
            Component.onCompleted: {
                registry.library.filter = Qt.binding(function() { return text; });
            }
        }
    }

    Action {
        id: nodeAddAction
        onTriggered: {
            addSelected();
        }
    }

    function search() {
        searchBox.visible = true;
        searchBox.focus = true;
        searchBox.forceActiveFocus();
        searchStarted();
    }

    function stopSearching() {
        if (searchBox.visible) {
            searchBox.text = "";
            searchBox.visible = false;
            searchBox.focus = false;
            searchStopped();
        }
    }

    function finishCreation() {
    }

    function addSelected() {
        var ret = null;
        var filename = librarytree.model.data(librarytree.selection.currentIndex, Library.FileRole);

        if (filename.substr(-4) === ".qml") {
            var comp = Qt.createComponent("Instantiators/" + filename);

            function finishCreation() {
                if (comp.status === Component.Ready) {
                    var obj = comp.createObject(libraryWidget, {"graph": graph, "registry": registry, "context": context});
                    if (obj === null) {
                        // Error Handling
                        console.log("Error creating object");
                    }
                } else if (comp.status === Component.Error) {
                    // Error Handling
                    console.log("Error loading component:", comp.errorString());
                }
            }

            if (comp.status === Component.Ready) {
                finishCreation();
            } else if (comp.status === Component.Loading) {
                comp.statusChanged.connect(finishCreation);
            } else if (comp.status === Component.Error) {
                console.log("Error loading component:", comp.errorString());
            }
        } else {
            var vn = registry.createFromFile(context, filename);
            if (vn) {
                ret = graph.insertVideoNode(vn);
            }
        }
        stopSearching();
        return ret;
    }

    Action {
        id: searchAction
        shortcut: ":"
        onTriggered: search()
    }
}
