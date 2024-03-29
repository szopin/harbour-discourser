/*
 * This file is part of harbour-sfos-forum-viewer.
 *
 * MIT License
 *
 * Copyright (c) 2020 szopin
 * Copyright (C) 2020 Mirian Margiani
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: commentpage
    allowedOrientations: Orientation.All
    property int likes
    property int post_id
    property int highest_post_number
    //property int post_number
    readonly property string source: forumSource.value + "t/" + topicid
    property string loadmore: source + "/posts.json?post_ids[]="
    property int topicid
    property string url
    property int last_post: 0
    property int post_number: -1
    property string aTitle
    property string raw
    property int posts_count
    property var reply_to
    property bool accepted_answer

    function appendPosts(posts) {
        var posts_length = posts.length;
        for (var i=0;i<posts_length;i++) {
            var post = posts[i];
            var action = post.actions_summary[0];
            likes = action && action.id === 2
                ? action.count : 0;
            list.model.append({
                cooked: post.cooked,
                username: post.username,
                updated_at: post.updated_at,
                likes: likes,
                created_at: post.created_at,
                version: post.version,
                postid: post.id,
                last_postid: last_post,
                post_number: post.post_number,
                reply_to: post.reply_to_post_number,
                accepted_answer: post.accepted_answer
            });
            last_post = post.post_number;
        }
    }
    function getraw(postid, oper){
            var xhr = new XMLHttpRequest;
            xhr.open("GET", forumSource.value + "posts/" + postid + ".json");
                       xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE){   var data = JSON.parse(xhr.responseText);
                    raw = data["raw"];
                    if (oper == 1) Clipboard.text = raw;
                    return raw;
                }
            }
            xhr.send();
        }
    function findOP(filter){
        console.log(commodel.count)
        for (var j=0; j < commodel.count; j++){
            if (commodel.get(j).post_number == filter){
                pageStack.push(Qt.resolvedUrl("PostView.qml"), {postid: commodel.get(j).postid, aTitle: "Replied to post", cooked: commodel.get(j).cooked, username: commodel.get(j).username});
            }
        }
    }
    function getcomments(){
        var xhr = new XMLHttpRequest;
        xhr.open("GET", source + ".json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var data = JSON.parse(xhr.responseText);
                var post_stream = data.post_stream;
                if (posts_count >= 20){
                    var stream = post_stream.stream;
                    for(var j=20;j<posts_count;j++)
                        loadmore += stream[j] + "&post_ids[]="
                }
                var xhr2 = new XMLHttpRequest;
                xhr2.open("GET", loadmore);
                xhr2.onreadystatechange = function() {
                    if (xhr2.readyState === XMLHttpRequest.DONE) {
                        list.model.clear();

                        appendPosts(post_stream.posts);

                        var data2 = JSON.parse(xhr2.responseText);
                        appendPosts(data2.post_stream.posts)
                    }
                }
                xhr2.send();
            }
        }
        xhr.send();
    }

    SilicaListView {
        id: list
        header: PageHeader {
            id: pageHeader
            title: aTitle
            wrapMode: Text.Wrap
        }
        footer: Item {
            width: parent.width
            height: Theme.horizontalPageMargin
        }
        width: parent.width
        height: parent.height
        anchors.top: header.bottom
        VerticalScrollDecorator {}
        PullDownMenu{
            MenuItem {
                text: qsTr("Open in external browser")
                onClicked: Qt.openUrlExternally(source)
            }
            MenuItem {
                text: qsTr("Open directly")
                onClicked: pageStack.push("webView.qml", {"pageurl": source});

            }
            MenuItem {
                text: qsTr("Search thread")
                onClicked: pageStack.push("SearchPage.qml", {"searchid": topicid, "aTitle": aTitle });

            }
        }

        BusyIndicator {
            id: vplaceholder
            running: commodel.count == 0
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }

        model: ListModel { id: commodel}
        delegate: ListItem {
            enabled: menu.hasContent
            width: parent.width
            contentHeight: delegateCol.height + Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                id: delegateCol
                width: parent.width - 2*Theme.horizontalPageMargin
                height: childrenRect.height
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingMedium

                Separator {
                    color: Theme.highlightColor
                    width: parent.width
                    horizontalAlignment: Qt.AlignHCenter
                }

                Row {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Column {
                        width: parent.width - subMetadata.width

                        Label {
                            id: mainMetadata
                            text: username
                            textFormat: Text.RichText
                            truncationMode: TruncationMode.Fade
                            elide: Text.ElideRight
                            width: parent.width
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        Label {
                            visible: likes > 0
                            text: qsTr("%n like(s)", "", likes)
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Column {
                        id: subMetadata
                        Label {
                            text: formatJsonDate(created_at)
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.right: parent.right
                        }
                        Label {
                            text: (version > 1 && updated_at !== created_at) ?
                                      qsTr("✍️: %1").arg(formatJsonDate(updated_at)) : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.right: parent.right
                        }
                        Label {
                            text: reply_to >0 && reply_to !== last_postid ?  "💬"  : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.right: parent.right
                        }
                        Icon {
                            visible: accepted_answer
                            source: "image://theme/icon-s-accept"
                            width: Theme.iconSizeSmall
                            height: width
                            anchors.right: parent.right
                            opacity: Theme.opacityLow
                        }
                    }
                }

                Label {
                    text: "<style>" +
                          "a { color: %1 }".arg(Theme.highlightColor) +
                          "</style>" +
                          "<p>" + cooked + "</p>"
                    width: parent.width
                    baseUrl: forumSource.value
                    textFormat: Text.RichText
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    onLinkActivated: pageStack.push("OpenLink.qml", {link: link});
                }
            }
            menu: ContextMenu {
                MenuItem{
                    text: qsTr("Copy to clipboard");
                    onClicked: getraw(postid, 1);
                }
                MenuItem {
                    text: qsTr("Copy link to clipboard")
                    onClicked: Clipboard.text = source + "/" + post_number
                }
                MenuItem {
                    visible: version > 1 && updated_at !== created_at
                    text: qsTr("Revision history")
                    onClicked: pageStack.push(Qt.resolvedUrl("PostView.qml"), {postid: postid, aTitle: aTitle, curRev: version});
                }
                MenuItem {
                    visible: cooked.indexOf("<code") !== -1
                    text: qsTr("Alternative formatting")
                    onClicked: pageStack.push(Qt.resolvedUrl("PostView.qml"), {postid: postid, aTitle: aTitle, curRev: version, cooked: cooked});
                }
                MenuItem {
                    visible: reply_to > 0 && reply_to !== last_postid
                    text: qsTr("Show replied to post")
                    onClicked: findOP(reply_to);

                }
            }
        }


        Component.onCompleted: commentpage.getcomments();
        onCountChanged: {
            for(var i=post_number - (highest_post_number - posts_count) - 1;i<=post_number;i++){
                var comment = list.model.get(i)
                if (post_id && comment && comment.postid === post_id){
                    positionViewAtIndex(i, ListView.Beginning);
                }
            }
        }
    }
}


