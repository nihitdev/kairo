import QtQuick
import QtQuick.Controls.Basic

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.Base || "#191724"
    readonly property color ink: config.Text || "#e0def4"
    readonly property color muted: config.Muted || "#908caa"
    readonly property color accent: config.Accent || "#c4a7e7"
    readonly property color foam: config.Foam || "#9ccfd8"
    readonly property string typeface: config.Font || "monospace"
    property date now: new Date()
    property bool busy: false
    property string notice: ""

    function login() {
        if (busy || !username.currentText || sessions.currentIndex < 0) return;
        notice = "";
        busy = true;
        sddm.login(username.currentText, password.text, sessions.currentIndex);
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.notice = "Login failed. Please try again.";
            password.clear();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() { password.clear(); root.notice = "Welcome back."; }
    }

    Image {
        anchors.fill: parent
        source: config.Background || "background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: "#66191724" }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#f2191724" }
            GradientStop { position: 0.5; color: "#99191724" }
            GradientStop { position: 1; color: "#00191724" }
        }
    }

    component Label: Text {
        color: root.ink
        font.family: root.typeface
        font.pixelSize: 14
    }
    component Action: Button {
        id: control
        property bool primary: false
        implicitHeight: 44
        implicitWidth: 108
        font.family: root.typeface
        font.pixelSize: 13
        hoverEnabled: true
        contentItem: Text {
            text: control.text
            font: control.font
            color: control.primary ? "#191724" : root.ink
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 10
            color: control.primary ? (control.down ? root.foam : root.accent) : (control.hovered ? "#80393552" : "#b31f1d2e")
            border.color: control.activeFocus ? root.foam : "#66393552"
            border.width: control.activeFocus ? 2 : 1
            opacity: control.enabled ? 1 : 0.45
        }
    }
    component Field: TextField {
        id: field
        height: 48
        color: root.ink
        placeholderTextColor: root.muted
        selectionColor: root.accent
        selectedTextColor: "#191724"
        font.family: root.typeface
        font.pixelSize: 15
        leftPadding: 16
        rightPadding: 16
        background: Rectangle {
            radius: 10
            color: "#aa191724"
            border.width: field.activeFocus ? 2 : 1
            border.color: field.activeFocus ? root.accent : "#393552"
        }
        enabled: !root.busy
        selectByMouse: true
    }

    Item {
        anchors.fill: parent
        anchors.margins: Math.max(18, Math.min(root.width, root.height) * 0.045)
        Label {
            text: "A R C H N E M E S I S"
            color: root.foam
            font.pixelSize: 13
        }
        Label {
            anchors.right: parent.right
            text: sddm.hostName
            color: root.muted
            font.pixelSize: 12
        }

        Column {
            width: Math.min(380, parent.width)
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.width > 1000 ? root.width * 0.065 : 0
            spacing: 12

            Label { text: Qt.formatDateTime(root.now, "HH:mm"); font.pixelSize: root.height < 700 ? 54 : 78 }
            Label { text: Qt.formatDateTime(root.now, "dddd, dd MMMM"); color: root.accent; font.pixelSize: 15 }
            Item { width: 1; height: root.height < 700 ? 2 : 20 }
            Label { text: "Welcome back."; font.pixelSize: 24 }
            Label { text: "Your space is waiting."; color: root.muted; font.pixelSize: 13 }
            Item { width: 1; height: 4 }
            ComboBox {
                id: username
                objectName: "username"
                width: parent.width
                height: 48
                model: userModel
                textRole: "name"
                currentIndex: count > 0 ? (userModel.lastIndex >= 0 && userModel.lastIndex < count ? userModel.lastIndex : 0) : -1
                enabled: !root.busy && count > 0
                Accessible.name: "Choose user"
                font.family: root.typeface
                font.pixelSize: 15
                palette.text: root.ink
                palette.buttonText: root.accent
                palette.base: "#1f1d2e"
                palette.window: "#1f1d2e"
                palette.highlight: "#393552"
                palette.highlightedText: root.accent
                contentItem: Text {
                    text: username.count > 0 ? username.displayText : "No users available"
                    font: username.font
                    color: root.ink
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 16
                    rightPadding: 30
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: 10
                    color: "#aa191724"
                    border.width: username.activeFocus ? 2 : 1
                    border.color: username.activeFocus ? root.accent : "#393552"
                }
                onCurrentIndexChanged: {
                    password.clear();
                    root.notice = "";
                }
                onActivated: password.forceActiveFocus()
                KeyNavigation.tab: password
            }
            Field {
                id: password
                objectName: "password"
                width: parent.width
                placeholderText: "Password"
                Accessible.name: "Password"
                echoMode: TextInput.Password
                passwordCharacter: "●"
                onAccepted: root.login()
                KeyNavigation.tab: sessions
            }
            ComboBox {
                id: sessions
                objectName: "sessions"
                width: parent.width
                height: 42
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                enabled: !root.busy
                font.family: root.typeface
                font.pixelSize: 13
                Accessible.name: "Desktop session"
                palette.text: root.ink
                palette.buttonText: root.ink
                palette.base: "#1f1d2e"
                palette.window: "#1f1d2e"
                palette.highlight: "#393552"
                palette.highlightedText: root.accent
                contentItem: Text {
                    text: sessions.displayText
                    font: sessions.font
                    color: root.muted
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 16
                    rightPadding: 30
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: 10
                    color: "#b31f1d2e"
                    border.color: sessions.activeFocus ? root.accent : "#393552"
                }
                KeyNavigation.tab: signIn
            }
            Action {
                id: signIn
                width: parent.width
                primary: true
                text: root.busy ? "Signing in…" : "Sign in  →"
                enabled: !root.busy && username.currentText.length > 0 && sessions.currentIndex >= 0
                onClicked: root.login()
            }
            Label {
                width: parent.width
                height: 20
                text: root.notice || (keyboard.capsLock ? "Caps Lock is on" : "")
                color: root.notice ? "#eb6f92" : "#f6c177"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 10
            Action { text: "Suspend"; visible: sddm.canSuspend; onClicked: sddm.suspend() }
            Action { text: "Restart"; visible: sddm.canReboot; onClicked: { powerDialog.action = "restart"; powerDialog.open(); } }
            Action { text: "Power off"; visible: sddm.canPowerOff; onClicked: { powerDialog.action = "power off"; powerDialog.open(); } }
        }
    }

    Popup {
        id: powerDialog
        property string action: ""
        anchors.centerIn: parent
        width: Math.min(360, root.width - 32)
        height: 150
        modal: true
        focus: true
        padding: 22
        background: Rectangle { color: "#1f1d2e"; radius: 12; border.color: root.accent }
        Column {
            width: parent.width
            spacing: 24
            Label { text: "Really " + powerDialog.action + "?"; font.pixelSize: 16 }
            Row {
                spacing: 12
                Action { text: "Cancel"; onClicked: powerDialog.close() }
                Action {
                    text: "Confirm"
                    primary: true
                    onClicked: {
                        powerDialog.close();
                        if (powerDialog.action === "restart") sddm.reboot();
                        else sddm.powerOff();
                    }
                }
            }
        }
    }
    Component.onCompleted: {
        if (username.currentText.length) password.forceActiveFocus();
        else username.forceActiveFocus();
    }
}
