import QtQuick
import QtTest
import ".." as Theme
TestCase {
 id: test
 name: "ARCHNEMESIS"
 width: 1280; height: 720
 when: windowShown
 property var config: ({Base: '#191724', Text: '#e0def4', Muted: '#908caa', Accent: '#c4a7e7', Foam: '#9ccfd8', Font: 'Iosevka Nerd Font Mono', Background: Qt.resolvedUrl('../background.png').toString()})
 QtObject { id: sddm; property string hostName: "test-host"; property bool canSuspend: true; property bool canReboot: true; property bool canPowerOff: true; property int calls: 0; property string lastUser: ""; property int session: -1; signal loginFailed(); signal loginSucceeded(); function login(u,p,s) { calls++; lastUser=u; session=s; } function suspend() {} function reboot() {} function powerOff() {} }
 ListModel { id: userModel; property int lastIndex: 1; ListElement { name: "guest" } ListElement { name: "test-account" } }
 QtObject { id: keyboard; property bool capsLock: false }
 ListModel { id: sessionModel; property int lastIndex: 0; ListElement { name: "Hyprland" } ListElement { name: "Sway" } }
 Theme.Main { id: theme; width: test.width; height: test.height }
 function test_login() {
  let u=findChild(theme,"username"), p=findChild(theme,"password"), s=findChild(theme,"sessions");
  verify(u); verify(p); verify(s);
  compare(u.currentText,"test-account"); compare(s.currentIndex,0);
  u.currentIndex=-1; theme.login(); compare(sddm.calls,0);
  u.currentIndex=1; p.text="dummy"; s.currentIndex=1;
  theme.login(); compare(sddm.calls,1); compare(sddm.lastUser,"test-account"); compare(sddm.session,1); verify(theme.busy);
  theme.login(); compare(sddm.calls,1);
  sddm.loginFailed(); compare(p.text,""); verify(!theme.busy); verify(p.activeFocus); verify(theme.notice.length>0);
  p.text="old password"; u.currentIndex=0; compare(p.text, ""); compare(theme.notice, "");
  p.text="dummy"; theme.login(); compare(sddm.lastUser,"guest"); sddm.loginSucceeded(); compare(p.text,""); compare(theme.notice,"Welcome back.");
 }
}
