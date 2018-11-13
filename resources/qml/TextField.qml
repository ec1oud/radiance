import QtQuick 2.6
import QtQuick.Controls 2.1
import "."

TextField {
    id: control
    font.pointSize: 10

    color: RadianceStyle.tileTextColor
    padding: 3

    background: Rectangle {
        implicitWidth: 60
        implicitHeight: 16
        color: RadianceStyle.tileBackgroundColor
        border.color: control.visualFocus ? RadianceStyle.tileLineHighlightColor : RadianceStyle.tileLineColor
        border.width: 1
    }
}
