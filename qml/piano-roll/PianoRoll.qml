import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: pianoRoll
    width: 800
    height: 600
    clip: true

    // 可配置属性
    property int keyWidth: 40
    property int keyHeight: 20
    property int gridWidth: 40
    property int gridHeight: 20
    property int octaves: 7  // 默认显示7个八度音阶
    property int startOctave: 1  // 起始八度
    property int measures: 16  // 小节数
    property int beatsPerMeasure: 4  // 每小节的拍数
    property var selectedNotes: []  // 当前选中的音符
    property var notes: []  // 所有音符
    
    // 音符名称数组
    readonly property var noteNames: ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    // 计算总键数
    readonly property int totalKeys: octaves * 12
    
    // 计算总高度和宽度
    readonly property int totalHeight: totalKeys * keyHeight
    readonly property int totalWidth: measures * beatsPerMeasure * gridWidth
    
    // 滚动区域
    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: pianoKeyboard.width + gridArea.width
        contentHeight: totalHeight
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        
        // 主容器
        Row {
            id: mainContainer
            
            // 钢琴键盘区域
            Rectangle {
                id: pianoKeyboard
                width: keyWidth
                height: totalHeight
                color: "#f0f0f0"
                
                // 绘制钢琴键
                Column {
                    id: keysColumn
                    width: parent.width
                    height: parent.height
                    
                    // 使用Repeater创建钢琴键
                    Repeater {
                        model: totalKeys
                        
                        Rectangle {
                            id: pianoKey
                            width: keyWidth
                            height: keyHeight
                            color: isBlackKey(index) ? "black" : "white"
                            border.color: "#888"
                            border.width: 1
                            
                            // 显示音符名称
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 5
                                text: getNoteNameWithOctave(index)
                                color: isBlackKey(index) ? "white" : "black"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
            
            // 网格区域
            Rectangle {
                id: gridArea
                width: totalWidth
                height: totalHeight
                color: "#ffffff"
                
                // 绘制网格线
                Canvas {
                    id: gridCanvas
                    anchors.fill: parent
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.strokeStyle = "#dddddd";
                        ctx.lineWidth = 1;
                        
                        // 绘制水平线
                        for (var i = 0; i <= totalKeys; i++) {
                            var y = i * keyHeight;
                            ctx.beginPath();
                            ctx.moveTo(0, y);
                            ctx.lineTo(width, y);
                            ctx.stroke();
                            
                            // 为C音符绘制更明显的线
                            if (i % 12 === 0) {
                                ctx.strokeStyle = "#aaaaaa";
                                ctx.beginPath();
                                ctx.moveTo(0, y);
                                ctx.lineTo(width, y);
                                ctx.stroke();
                                ctx.strokeStyle = "#dddddd";
                            }
                        }
                        
                        // 绘制垂直线
                        for (var j = 0; j <= measures * beatsPerMeasure; j++) {
                            var x = j * gridWidth;
                            ctx.beginPath();
                            ctx.moveTo(x, 0);
                            ctx.lineTo(x, height);
                            ctx.stroke();
                            
                            // 为小节开始绘制更明显的线
                            if (j % beatsPerMeasure === 0) {
                                ctx.strokeStyle = "#aaaaaa";
                                ctx.beginPath();
                                ctx.moveTo(x, 0);
                                ctx.lineTo(x, height);
                                ctx.stroke();
                                ctx.strokeStyle = "#dddddd";
                            }
                        }
                    }
                }
                
                // 音符容器
                Item {
                    id: notesContainer
                    anchors.fill: parent
                    
                    // 这里将动态添加音符
                }
                
                // 选择区域
                Rectangle {
                    id: selectionRect
                    visible: false
                    color: Qt.rgba(100/255, 150/255, 255/255, 0.3)
                    border.color: Qt.rgba(100/255, 150/255, 255/255, 0.8)
                    border.width: 1
                    x: 0
                    y: 0
                    width: 0
                    height: 0
                }
                
                // 处理鼠标事件
                MouseArea {
                    id: gridMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    
                    property point startPoint
                    property bool isDragging: false
                    property bool isSelecting: false
                    property bool isMovingNotes: false
                    property var draggedNotes: []
                    property point dragOffset
                    
                    onPressed: function(mouse) {
                        startPoint = Qt.point(mouse.x, mouse.y);

                        var clickedNote = null;
                        for (var i = 0; i < notesContainer.children.length; i++) {
                            var note = notesContainer.children[i];
                            if (mouse.x >= note.x && mouse.x <= note.x + note.width &&
                                mouse.y >= note.y && mouse.y <= note.y + note.height) {
                                clickedNote = note;
                                break;
                            }
                        }
                        
                        if (clickedNote) {
                            // 如果按住Ctrl键，则切换选中状态
                            if (mouse.modifiers & Qt.ControlModifier) {
                                if (clickedNote.selected) {
                                    // 取消选中
                                    var index = selectedNotes.indexOf(clickedNote);
                                    if (index !== -1) {
                                        selectedNotes.splice(index, 1);
                                    }
                                    clickedNote.selected = false;
                                } else {
                                    // 添加到选中
                                    selectedNotes.push(clickedNote);
                                    clickedNote.selected = true;
                                }
                            } else {
                                // 如果点击的音符未被选中，则清除当前选择并选中该音符
                                if (!clickedNote.selected) {
                                    clearSelection();
                                    selectedNotes.push(clickedNote);
                                    clickedNote.selected = true;
                                }
                                
                                // 准备移动音符
                                isMovingNotes = true;
                                draggedNotes = selectedNotes.slice();
                                dragOffset = Qt.point(mouse.x - clickedNote.x, mouse.y - clickedNote.y);
                            }
                        } else {
                            // 点击空白区域，开始选择或创建新音符
                            if (mouse.modifiers & Qt.ControlModifier) {
                                // 按住Ctrl键，开始框选
                                isSelecting = true;
                                selectionRect.x = startPoint.x;
                                selectionRect.y = startPoint.y;
                                selectionRect.width = 0;
                                selectionRect.height = 0;
                                selectionRect.visible = true;
                            } else {
                                // 清除当前选择并创建新音符
                                clearSelection();
                                createNote(mouse.x, mouse.y);
                            }
                        }
                    }
                    
                    onPositionChanged: function(mouse) {
                        if (isSelecting) {
                            // 更新选择框
                            var x = Math.min(startPoint.x, mouse.x);
                            var y = Math.min(startPoint.y, mouse.y);
                            var width = Math.abs(mouse.x - startPoint.x);
                            var height = Math.abs(mouse.y - startPoint.y);
                            
                            selectionRect.x = x;
                            selectionRect.y = y;
                            selectionRect.width = width;
                            selectionRect.height = height;
                        } else if (isMovingNotes && draggedNotes.length > 0) {
                            // 移动选中的音符
                            var dx = mouse.x - dragOffset.x;
                            var dy = mouse.y - dragOffset.y;
                            
                            // 吸附到网格
                            dx = Math.round(dx / gridWidth) * gridWidth;
                            dy = Math.round(dy / keyHeight) * keyHeight;
                            
                            // 确保不超出边界
                            dx = Math.max(0, Math.min(dx, totalWidth - draggedNotes[0].width));
                            dy = Math.max(0, Math.min(dy, totalHeight - keyHeight));
                            
                            // 更新所有选中音符的位置
                            for (var i = 0; i < draggedNotes.length; i++) {
                                var note = draggedNotes[i];
                                var originalX = note.originalX !== undefined ? note.originalX : note.x;
                                var originalY = note.originalY !== undefined ? note.originalY : note.y;
                                
                                if (note.originalX === undefined) {
                                    note.originalX = originalX;
                                    note.originalY = originalY;
                                }
                                
                                // 计算相对于第一个音符的偏移
                                var relativeX = originalX - draggedNotes[0].originalX;
                                var relativeY = originalY - draggedNotes[0].originalY;
                                
                                note.x = dx + relativeX;
                                note.y = dy + relativeY;
                                
                                // 更新音符名称
                                var noteIndex = Math.floor(note.y / keyHeight);
                                note.noteName = getNoteNameWithOctave(noteIndex);
                            }
                        }
                    }
                    
                    onReleased: function(mouse) {
                        if (isSelecting) {
                            // 完成选择，选中框内的所有音符
                            for (var i = 0; i < notesContainer.children.length; i++) {
                                var note = notesContainer.children[i];
                                if (note.x + note.width >= selectionRect.x && note.x <= selectionRect.x + selectionRect.width &&
                                    note.y + note.height >= selectionRect.y && note.y <= selectionRect.y + selectionRect.height) {
                                    note.selected = true;
                                    if (selectedNotes.indexOf(note) === -1) {
                                        selectedNotes.push(note);
                                    }
                                }
                            }
                            
                            selectionRect.visible = false;
                            isSelecting = false;
                        } else if (isMovingNotes) {
                            // 完成移动音符
                            for (var i = 0; i < draggedNotes.length; i++) {
                                delete draggedNotes[i].originalX;
                                delete draggedNotes[i].originalY;
                            }
                            isMovingNotes = false;
                            draggedNotes = [];
                        }
                    }
                    
                    onDoubleClicked: function(mouse) {
                        // 双击删除音符
                        for (var i = 0; i < notesContainer.children.length; i++) {
                            var note = notesContainer.children[i];
                            if (mouse.x >= note.x && mouse.x <= note.x + note.width &&
                                mouse.y >= note.y && mouse.y <= note.y + note.height) {
                                deleteNote(note);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 键盘事件处理
    Keys.onPressed: function(event) {
        // 删除选中的音符
        if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            deleteSelectedNotes();
            event.accepted = true;
        }
        // 全选
        else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
            selectAllNotes();
            event.accepted = true;
        }
    }
    
    // 判断是否为黑键
    function isBlackKey(index) {
        var noteIndex = index % 12;
        return (noteIndex === 1 || noteIndex === 3 || noteIndex === 6 || noteIndex === 8 || noteIndex === 10);
    }
    
    // 获取带八度的音符名称
    function getNoteNameWithOctave(index) {
        var noteIndex = (totalKeys - 1 - index) % 12; // 反转索引，使得最低音在底部
        var octave = startOctave + Math.floor((totalKeys - 1 - index) / 12);
        return noteNames[noteIndex] + octave;
    }
    
    // 创建新音符
    function createNote(x, y) {
        // 吸附到网格
        var snapX = Math.floor(x / gridWidth) * gridWidth;
        var snapY = Math.floor(y / keyHeight) * keyHeight;
        
        // 计算音符索引和名称
        var noteIndex = Math.floor(snapY / keyHeight);
        var noteName = getNoteNameWithOctave(noteIndex);
        
        // 创建音符组件
        var noteComponent = Qt.createComponent("Note.qml");
        if (noteComponent.status === Component.Ready) {
            var note = noteComponent.createObject(notesContainer, {
                x: snapX,
                y: snapY,
                width: gridWidth * 2, // 默认长度为2个网格
                height: keyHeight,
                noteName: noteName
            });
            
            // 添加到音符列表
            notes.push(note);
            return note;
        } else if (noteComponent.status === Component.Error) {
            // 输出错误信息
            console.error("Error creating note component:", noteComponent.errorString());
        } else if (noteComponent.status === Component.Loading) {
            // 组件正在加载
            console.log("Note component is still loading");
        } else {
            // 其他状态
            console.log("Note component status:", noteComponent.status);
        }
        return null;
    }
    
    // 删除音符
    function deleteNote(note) {
        var index = notes.indexOf(note);
        if (index !== -1) {
            notes.splice(index, 1);
        }
        
        index = selectedNotes.indexOf(note);
        if (index !== -1) {
            selectedNotes.splice(index, 1);
        }
        
        note.destroy();
    }
    
    // 删除选中的音符
    function deleteSelectedNotes() {
        while (selectedNotes.length > 0) {
            deleteNote(selectedNotes[0]);
        }
    }
    
    // 清除选择
    function clearSelection() {
        for (var i = 0; i < selectedNotes.length; i++) {
            selectedNotes[i].selected = false;
        }
        selectedNotes = [];
    }
    
    // 选择所有音符
    function selectAllNotes() {
        clearSelection();
        for (var i = 0; i < notesContainer.children.length; i++) {
            var note = notesContainer.children[i];
            note.selected = true;
            selectedNotes.push(note);
        }
    }
    
    // 焦点设置，使键盘事件生效
    Component.onCompleted: {
        forceActiveFocus();
    }
}