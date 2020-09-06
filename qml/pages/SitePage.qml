import QtQuick 2.0
import Sailfish.Silica 1.0


Dialog {
    id: dialog
    property string site

    function findFirstPage() {
        return pageStack.find(function(page) { return (page._depth === 0); });
    }
    SilicaListView {
        id: sitelist
        anchors.fill: parent

        model: ListModel {


            ListElement { url: "https://discuss.codecademy.com/"; title: "Code academy"}
            ListElement { url: "https://forums.docker.com/"; title: "Docker"}
            ListElement { url: "https://community.e.foundation/"; title: "/e/ Foundation"}
            ListElement { url: "https://discuss.emberjs.com/"; title: "Ember.js"}
            ListElement { url: "https://forum.f-droid.org/"; title: "FDroid"}
            ListElement { url: "https://discussion.fedoraproject.org/"; title: "Fedora"}
            ListElement { url: "https://discuss.atom.io/"; title: "Github Atom"}
            ListElement { url: "https://we.incognito.org/"; title: "Incognito"}
            ListElement { url: "https://forum.manjaro.org/"; title: "Manjaro"}
            ListElement { url: "https://discuss.ocaml.org/"; title: "OCaml"}
            ListElement { url: "https://forum.openwrt.org/"; title: "OpenWrt"}
            ListElement { url: "https://discuss.pixls.us/"; title: "PIXLS.US"}
            ListElement { url: "https://forums.puri.sm/"; title: "PureOS"}
            ListElement { url: "https://users.rust-lang.org/"; title: "Rust"}
            ListElement { url: "https://discuss.tindie.com/"; title: "Tindie"}
            ListElement { url: "https://discourse.ubuntu.com/"; title: "Ubuntu"}
            ListElement { url: "https://forum.sailfishos.org/"; title: "SFOS Forum"}


        }

        header: headercomponent
        Component {
            id: headercomponent
            Column {
                id: column
                width: parent.width
                height: childrenRect.height
                spacing: Theme.paddingMedium
                PageHeader {
                    id: pageHeader
                    title: "Select site"
                }
                TextField {
                    id: customUrl

                    anchors { left: parent.left; right: parent.right }
                    placeholderText: qsTr("Custom URL")
                    label: qsTr("Just part between second and third slash\n(no \"https:\/\/\" and no trailing slash)")
                    labelVisible: true
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
                    validator: RegExpValidator { regExp: /^[A-Za-z0-9_\-.:]{1,200}/ }

                    errorHighlight: activeFocus && !acceptableInput
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: {
                        application.source = "https:\/\/" + text + "\/"
                        categories.fetch();

                        findFirstPage().showLatest();
                        dialog.accept()
                    }
                }
            }
        }


        delegate: ListItem {
            contentHeight: column.height + (2* Theme.paddingMedium)
            Column {
                anchors {
                    left: parent.left;
                    right: parent.right;
                    top: parent.top
                    margins: Theme.paddingMedium
                }
                id: column
                height: childrenRect.height

                Label {
                    anchors { left: parent.left; right: parent.right; }
                    font.bold: true
                    text: title
                }
                Label {
                    anchors { left: parent.left; right: parent.right; }
                    text: url
                }

            }
            onClicked: {
                application.source = url
                categories.fetch();

                findFirstPage().showLatest();
                dialog.accept()
            }
        }

        VerticalScrollDecorator {}
    }


}
