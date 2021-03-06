import QtQuick 2.12
import QtMultimedia 5.13
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.4
import QtQml.Models 2.2
import Qt.labs.folderlistmodel 2.2
import Qt.labs.platform 1.1
import radiance 1.0
import "."

Item {
    id: settingsWidget
    property alias modelName: modelNameField.text
    signal doubleTapped

    ColumnLayout {
        anchors.fill: parent

        Label {
            text: "Input device:"
            color: RadianceStyle.mainTextColor
            visible: window.hasMidi
        }
        ComboBox {
            id: devicesCB
            Layout.fillWidth: true
            model: QtMultimedia.availableAudioInputDevices
            textRole: "deviceId"
            function setDefault() {
                devicesCB.currentIndex = model.findIndex(i => i.deviceId === QtMultimedia.defaultAudioInputDevice.deviceId);
            }
            onModelChanged: setDefault()
            onCurrentTextChanged: defaultContext.inputDeviceId = currentText
        }

        Label {
            text: "MIDI controller:"
            color: RadianceStyle.mainTextColor
            visible: window.hasMidi
        }
        Loader {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillWidth: true

            source: window.hasMidi ? "MidiMappingSelector.qml" : ""
            onLoaded: item.target = graph.view;
        }

        Label {
            text: "Default output:"
            color: RadianceStyle.mainTextColor
            visible: window.hasMidi
        }
        ComboBox {
            id: screensCB
            Layout.fillWidth: true
            model: Qt.application.screens
            textRole: "name"
            onCurrentTextChanged: defaultContext.defaultScreenId = currentText
        }

        Item { height: 10 }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillWidth: true

            Label {
                text: "Model File:"
                color: RadianceStyle.mainTextColor
            }

            TextField {
                id: modelNameField
                text: "model.json"
                selectByMouse: true
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "Save"
                Layout.fillWidth: true
                onClicked: save()
            }
            Button {
                text: "Load"
                Layout.fillWidth: true
                onClicked: load()
            }
            Button {
                text: "Clear"
                Layout.fillWidth: true
                onClicked: {
                    model.clear();
                    model.flush();
                }
            }
        }

        ListView {
            Layout.fillHeight: true
            model: FolderListModel {
                folder: StandardPaths.writableLocation(StandardPaths.AppDataLocation) + "/library"
                Component.onCompleted: "dir " + folder
            }
            delegate: Text {
                color: RadianceStyle.mainTextColor
                text: fileName
                TapHandler {
                    onTapped: modelNameField.text = text
                    onDoubleTapped: {
                        modelNameField.text = text
                        settingsWidget.doubleTapped()
                    }
                }
            }
        }
    }
}
