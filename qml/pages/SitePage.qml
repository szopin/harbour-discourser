import QtQuick 2.0
import Sailfish.Silica 1.0
import '../forums.js' as Forums

Dialog {
    id: dialog
    property string site

    function findFirstPage() {
        return pageStack.find(function(page) { return (page._depth === 0); });
    }
    SilicaListView {
        id: sitelist
        anchors.fill: parent

        model: Forums.list

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
                        forumTitle.value = ""
                        forumSource.value = "https:\/\/" + text + "\/"
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
                    text: modelData.title
                }
                Label {
                    anchors { left: parent.left; right: parent.right; }
                    text: modelData.url
                }

            }
            onClicked: {
                forumTitle.value = modelData.title
                forumSource.value = modelData.url
                categories.fetch();

                findFirstPage().showLatest();
                dialog.accept()
            }
        }

        VerticalScrollDecorator {}
    }


}
