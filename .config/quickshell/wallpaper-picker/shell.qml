import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root
    property var papers: []
    property var history: []
    property string current: ""
    property string filter: "All"
    property string query: ""
    property string output: "all"
    property string message: "Loading wallpapers…"
    readonly property string backend: decodeURIComponent(Qt.resolvedUrl("backend.py").toString().replace(/^file:\/\//, ""))
    function rebuild() {
        cards.clear();
        let list = papers.filter(p => (filter === "All" || (filter === "History" ? history.indexOf(p.path) >= 0 : filter === "Video" ? p.video : p.bucket === filter)) && p.name.toLowerCase().includes(query.toLowerCase()));
        if (filter === "History") list.sort((a,b) => history.indexOf(a.path)-history.indexOf(b.path));
        let selected = 0;
        list.forEach((p,i) => { cards.append(p); if(p.path === current) selected=i; });
        Qt.callLater(() => { carousel.currentIndex = selected; carousel.positionViewAtIndex(selected, ListView.Center); });
        message = cards.count ? "" : "No wallpapers match this filter";
    }
    function select(index) {
        if (!cards.count) return;
        const selected = Math.max(0, Math.min(cards.count - 1, index));
        carousel.currentIndex = selected;
        Qt.callLater(() => carousel.positionViewAtIndex(selected, ListView.Center));
    }
    function step(delta) { select(carousel.currentIndex + delta); }
    function apply() {
        if (setter.running || !cards.count) return;
        let p = cards.get(carousel.currentIndex);
        setter.selectedPath = p.path;
        setter.command = ["python3",backend,"apply",p.path,output];
        message = "Applying " + p.name + "…";
        setter.running = true;
        panel.visible = false;
    }
    IpcHandler {
        target: "picker"
        function close(): void { Qt.quit(); }
        function next(): void { root.step(1); }
        function apply(): void { root.apply(); }
        function status(): string { return JSON.stringify({count: cards.count, current:root.current, message:root.message}); }
    }
    ListModel { id: cards }
    Process {
        id: scanner
        command: ["python3",root.backend,"index"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            try {
                let data=JSON.parse(text);
                if(data.error) {root.message=data.error;return;}
                root.papers=data.items; root.history=data.history; root.current=data.current;
                let focused=data.monitors.find(m=>m.focused);
                if(focused) panel.screen=Quickshell.screens.find(s=>s.name===focused.name) || panel.screen;
                root.rebuild();
            } catch(e) {root.message="Could not read wallpaper library: " + e;}
        } }
    }
    Process {
        id: setter
        property string selectedPath: ""
        stdout: StdioCollector { onStreamFinished: {
            try { let data=JSON.parse(text); if(data.error) { root.message=data.error; panel.visible=true; }
                else if (data.ok) {root.current=setter.selectedPath;root.history=data.history;Qt.quit();}
            } catch(e) {root.message="Wallpaper application failed";panel.visible=true;}
        } }
    }
    PanelWindow {
        id: panel
        anchors {top:true;bottom:true;left:true;right:true}
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "wallpaper-carousel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "#fa191724"
        readonly property real unit: Math.min(width/1366,height/768)
        contentItem.focus: true
        Shortcut {sequence:"Escape";onActivated:Qt.quit()}
        Shortcut {sequence:"Left";enabled:!search.activeFocus;onActivated:root.step(-1)}
        Shortcut {sequence:"Right";enabled:!search.activeFocus;onActivated:root.step(1)}
        Shortcut {sequence:"Return";enabled:!search.activeFocus;onActivated:root.apply()}
        Column {
            anchors.top:parent.top;anchors.topMargin:42*panel.unit
            anchors.horizontalCenter:parent.horizontalCenter;spacing:18*panel.unit
            Text {anchors.horizontalCenter:parent.horizontalCenter;text:"WALLPAPERS";color:"#e0def4";font.pixelSize:18; font.letterSpacing:5}
            Row {
                anchors.horizontalCenter:parent.horizontalCenter;spacing:7
                Repeater {
                    model:["All","History","Video","Red","Orange","Yellow","Green","Blue","Purple","Pink","Mono"]
                    delegate: Rectangle {
                        required property string modelData
                        readonly property var colors: ({Red:"#eb6f92",Orange:"#ea9a70",Yellow:"#f6c177",Green:"#9ccf9a",Blue:"#9ccfd8",Purple:"#c4a7e7",Pink:"#ebbcba",Mono:"#908caa"})
                        width:colors[modelData]?30:72;height:32;radius:10
                        color:colors[modelData] || (root.filter===modelData?"#524f67":"#26233a")
                        border.width:root.filter===modelData?2:0;border.color:"#e0def4"
                        Text {anchors.centerIn:parent;text:parent.colors[parent.modelData]?"":parent.modelData;color:"#e0def4";font.pixelSize:12}
                        MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{root.filter=parent.modelData;root.rebuild();}}
                        ToolTip.visible: hover.hovered
                        ToolTip.text:modelData
                        HoverHandler {id:hover}
                    }
                }
                TextField {
                    id:search;width:190;height:32;placeholderText:"Search wallpapers";placeholderTextColor:"#908caa";color:"#e0def4"
                    background:Rectangle {color:"#26233a";radius:10}
                    onTextChanged:{root.query=text;root.rebuild();}
                    onAccepted:{focus=false;root.apply();}
                }
                ComboBox {
                    width:110;height:32;model:["all"].concat(Quickshell.screens.map(s=>s.name))
                    contentItem: Text {text:parent.displayText;color:"#e0def4";verticalAlignment:Text.AlignVCenter;leftPadding:10;font.pixelSize:12}
                    background:Rectangle {color:"#26233a";radius:10}
                    onActivated:root.output=currentText
                    ToolTip.text:"Target monitor";ToolTip.visible:hovered
                }
            }
        }
        ListView {
            id:carousel
            anchors.left:parent.left;anchors.right:parent.right
            anchors.verticalCenter:parent.verticalCenter;anchors.verticalCenterOffset:18*panel.unit
            height:410*panel.unit;orientation:ListView.Horizontal;spacing:12*panel.unit
            model:cards;clip:false
            highlightRangeMode:ListView.NoHighlightRange
            preferredHighlightBegin:(width-570*panel.unit)/2
            preferredHighlightEnd:(width+570*panel.unit)/2
            highlightMoveDuration:350
            ScrollBar.horizontal: ScrollBar {
                policy:ScrollBar.AlwaysOn
                interactive:true
                height:10
                z:200
                background:Rectangle {implicitHeight:8;radius:4;color:"#393552"}
                contentItem:Rectangle {implicitHeight:8;radius:4;color:parent.pressed?"#e0def4":"#c4a7e7"}
            }
            header:Item {width:(carousel.width-570*panel.unit)/2}
            footer:Item {width:(carousel.width-570*panel.unit)/2}
            delegate:Item {
                id:card
                required property int index
                required property string name
                required property string path
                required property string thumb
                required property bool video
                readonly property bool selected:ListView.isCurrentItem
                readonly property int distance:Math.abs(index-carousel.currentIndex)
                width:(selected?570:150*Math.max(.65,Math.pow(.9,distance-1)))*panel.unit
                height:(selected?390:330*Math.max(.72,Math.pow(.94,distance-1)))*panel.unit
                anchors.verticalCenter:parent ? parent.verticalCenter : undefined
                z:selected?100:50-distance
                Behavior on width {NumberAnimation {duration:350;easing.type:Easing.OutCubic}}
                Behavior on height {NumberAnimation {duration:350;easing.type:Easing.OutCubic}}
                Item {
                    anchors.fill:parent
                    transform:Matrix4x4 {matrix:Qt.matrix4x4(1,-.28,0,.14*card.height, 0,1,0,0, 0,0,1,0, 0,0,0,1)}
                    Rectangle {anchors.fill:parent;color:"#26233a";radius:18}
                    Rectangle {id:mask;anchors.fill:parent;radius:18;visible:false;layer.enabled:true}
                    Item {
                        anchors.fill:parent
                        layer.enabled:true
                        layer.effect:MultiEffect {maskEnabled:true;maskSource:mask}
                        Image {
                            anchors.centerIn:parent;width:680*panel.unit;height:410*panel.unit
                            source:card.thumb;fillMode:Image.PreserveAspectCrop;asynchronous:true
                            transform:Matrix4x4 {matrix:Qt.matrix4x4(1,.28,0,-.14*height, 0,1,0,0, 0,0,1,0, 0,0,0,1)}
                        }
                    }
                    Rectangle {anchors.fill:parent;radius:18;color:"transparent";border.width:card.selected?3:0;border.color:"#c4a7e7"}
                    MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{if(card.selected)root.apply();else root.select(card.index);}}
                }
            }
            MouseArea {
                anchors.fill:parent;acceptedButtons:Qt.NoButton
                onWheel:wheel=>{
                    const delta=wheel.angleDelta.y || wheel.pixelDelta.y || wheel.angleDelta.x || wheel.pixelDelta.x;
                    if(delta && !wheelDelay.running){root.step(delta>0?-1:1);wheelDelay.start();}
                    wheel.accepted=true;
                }
            }
            Timer {id:wheelDelay;interval:130}
        }
        Column {
            anchors.bottom:parent.bottom;anchors.bottomMargin:40*panel.unit
            anchors.horizontalCenter:parent.horizontalCenter;spacing:12
            Text {
                anchors.horizontalCenter:parent.horizontalCenter
                text:cards.count && carousel.currentIndex >= 0 && carousel.currentIndex < cards.count ? cards.get(carousel.currentIndex).name : ""
                color:"#e0def4";font.pixelSize:18;width:panel.width*.8;horizontalAlignment:Text.AlignHCenter;elide:Text.ElideMiddle
            }
            Text {anchors.horizontalCenter:parent.horizontalCenter;text:root.message || ((carousel.currentIndex+1)+" / "+cards.count+"   ·   scroll / ← → browse   ·   Enter / click selected to apply   ·   Esc close");color:"#908caa";font.pixelSize:12}
        }
    }
}
