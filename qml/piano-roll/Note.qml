import QtQuick 2.15

Rectangle {
    id: noteItem
    width: 80  // 默认宽度，会在创建时被覆盖
    height: 20 // 默认高度，会在创建时被覆盖
    color: selected ? "#80a0ff" : "#60b0ff"
    border.color: selected ? "#4080ff" : "#3090ff"
    border.width: selected ? 2 : 1
    radius: 3
    
    // 属性
    property string noteName: "C4"  // 音符名称，如C4, D#5等
    property bool selected: false   // 是否被选中
    
    // 显示音符名称的文本
    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 5
        text: noteName
        color: "white"
        font.pixelSize: 10
        font.bold: true
    }
    
    // 右侧调整大小的区域
    Rectangle {
        id: resizeHandle
        width: 8
        height: parent.height
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        
        MouseArea {
            id: resizeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            
            property int startX
            property int startWidth
            
            onPressed: function(mouse) {
                startX = mouse.x
                startWidth = noteItem.width
                mouse.accepted = true
            }
            
            onPositionChanged: function(mouse) {
                if (pressed) {
                    // 计算新宽度并吸附到网格
                    var gridWidth = 40 // 与PianoRoll中的gridWidth保持一致
                    var newWidth = startWidth + mouse.x - startX
                    newWidth = Math.max(gridWidth, Math.round(newWidth / gridWidth) * gridWidth)
                    noteItem.width = newWidth
                }
            }
        }
    }
}