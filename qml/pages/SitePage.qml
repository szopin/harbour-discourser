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
            ListElement { url: "https://forums.puri.sm/"; title: "PureOS"}
            ListElement { url: "https://forum.f-droid.org/"; title: "FDroid - Categories bugged"}
            ListElement { url: "https://discourse.ubuntu.com/"; title: "Ubuntu"}
            ListElement { url: "https://forum.sailfishos.org/"; title: "SFOS Forum"}

        }

        header: PageHeader {
            id: pageHeader
            title: "Select site"
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
