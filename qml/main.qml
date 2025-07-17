import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Window {
    id: mainWindow
    width: 1000
    height: 700
    visible: true
    title: "Piano Roll Demo"
    color: "#f0f0f0"
    
    // 导入Piano Roll组件
    Loader {
        id: pianoRollLoader
        anchors.fill: parent
        anchors.margins: 10
        source: "qrc:/qml/piano-roll/PianoRoll.qml"
    }
}