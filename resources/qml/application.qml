import QtQuick 2.7
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.4
import QtGraphicalEffects 1.0
import radiance 1.0
import "."

ApplicationWindow {
    id: window
    visible: true
    color: RadianceStyle.mainBackgroundColor
    width: 800
    height: 530
    title: "Radiance"
    property bool hasMidi: false
    property string modelName: settings.modelName

    PreviewAdapter {
        id: previewAdapter;
        model: model;
        previewWindow: window;
    }

    Registry {
        id: registry;
    }

    Model {
        id: model;
        onGraphChanged: {
            var changeset = "+" + verticesAdded.length + " -" + verticesRemoved.length + " vertices, ";
            changeset += "+" + edgesAdded.length + " -" + edgesRemoved.length + " edges";
            console.log("Graph changed!", changeset);
        }

        onMessage: errorConsole.message(vdeoNode, str)
        onWarning: errorConsole.warning(videoNode, str)
        onError: errorConsole.error(videoNode, str)
    }

    Timer {
        repeat: true
        running: true
        interval: 10 * 1000
        onTriggered: model.saveDefault();
    }

    Component.onCompleted: {
        Globals.previewAdapter = previewAdapter;
        console.log("Setting preview adapter to", Globals.previewAdapter)
        model.loadDefault(defaultContext, registry);
        model.flush();
    }

    ColumnLayout {
        anchors.fill: parent

        DropArea {
            id: mainCanvas
            Layout.fillWidth: true;
            Layout.fillHeight: true;
            onDropped: {
                // for dropping from external apps only
                console.log("dropped " + drag.source.text)
            }

            Graph {
                id: graph
                model: model
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    spacing: 20

                    Item {
                        width: 1
                    }
                    Waveform {
                        opacity: .9
                        context: defaultContext
                    }
                    BeatIndicator {
                        opacity: .9
                        context: defaultContext
                    }
                    Spectrum {
                        opacity: .9
                        context: defaultContext
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    PopOut {
                        id: libraryContainer
                        openSize: 150
                        side: "left"
                        open: true

                        LibraryWidget {
                            id: libraryWidget
                            graph: graph;
                            registry: registry
                            context: defaultContext

                            anchors.fill: parent

                            onSearchStarted: {
                                libraryContainer.open = true
                            }
                            onSearchStopped: {
                                libraryContainer.open = false
                            }
                        }
                    }
                    PopOut {
                        id: settingsContainer
                        side: "right"

                        SettingsWidget {
                            id: settings
                            anchors.fill: parent
                            onDoubleTapped: {
                                console.log("Loading state from " + modelName);
                                model.clear();
                                model.load(defaultContext, registry, modelName);
                                model.flush();
                            }
                        }
                    }
                    PopOut {
                        id: consoleContainer
                        side: "bottom"
                        openSize: 80
                        opacity: errorConsole.count > 0 ? 1 : 0
                        active: errorConsole.count > 0
                        Behavior on opacity {
                            NumberAnimation {
                                easing {
                                    type: Easing.InOutQuad
                                    amplitude: 1.0
                                    period: 0.5
                                }
                                duration: 300
                            }
                        }

                        ConsoleWidget {
                            graph: graph
                            id: errorConsole
                            anchors.fill: parent
                            onPopOut: consoleContainer.open = true
                            onPopIn: consoleContainer.open = false
                        }
                    }
                }
            }

            Label {
                id: messages
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 7
                color: RadianceStyle.mainTextColor
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        messages.text = "";
                    }
                }
            }
        }
    }

    function save() {
        if (model.vertices.length >= 0) {
            console.log("Saving state to " + modelName)
            model.save(modelName);
        }
    }

    function load() {
        console.log("Importing state from " + modelName);
        model.load(defaultContext, registry, modelName);
        model.flush();
    }

    function quit() {
        model.saveDefault()
        Qt.quit()
    }

    Shortcut {
        sequence: "Ctrl+S"
        onActivated: save()
    }

    Shortcut {
        sequence: "Ctrl+R"
        onActivated: load()
    }

    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: quit()
    }

    onClosing: quit()
}
