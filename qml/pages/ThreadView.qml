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
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

Page {
    id: commentpage
    allowedOrientations: Orientation.All
    property int likes: 0
    property int post_id: -1
    property int highest_post_number
    readonly property string source: forumSource.value + "t/" + topicid
    property string loadmore: source + "/posts.json?post_ids[]="
    property int topicid
    property string url
    property int last_post: 0
    property int post_number: -1
    property string aTitle
    property string raw
    property int loggedin: -1
    property string tags: ""
    property int posts_count
    property var reply_to
    property string avatar
    property bool accepted_answer
    property bool tclosed
    property bool cooked_hidden: false
    property bool busy: true
    property int xi
    property int yi
    property int zi


    WorkerScript {
        id: worker
        source: "worker.js"
        onMessage: {
            var data2 = JSON.parse(messageObject.data);
            appendPosts(data2.post_stream.posts)
            busy = !messageObject.last

            if (messageObject.last) busy = false// list.positionViewAtIndex(post_number - 1, ListView.Beginning);
        }
    }

    function getRedirect(link){
        var xhr = new XMLHttpRequest;
        xhr.open("GET", link);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var xhrlocation = xhr.getResponseHeader("location");
                var testo =  new RegExp("^" + forumSource.value +"t\/[\\w-]+\/(\\d+)\/?(\\d+)?$")
                console.log(testo, xhrlocation, link)
                var testa = testo.exec(xhrlocation);

                pageStack.push("ThreadView.qml", { "topicid":  testa[1]});
            }
        }
        xhr.send();
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
    function uncensor(postid, index){
        var xhr3 = new XMLHttpRequest;
        xhr3.open("GET", forumSource.value + "posts/" + postid + "/cooked.json");
        xhr3.onreadystatechange = function() {
            if (xhr3.readyState === XMLHttpRequest.DONE)   var data = JSON.parse(xhr3.responseText);
            list.model.setProperty(index, "cooked", data.cooked);
            list.model.setProperty(index, "cooked_hidden", false);
        }
        xhr3.send();
    }

    function appendPosts(posts) {
        var posts_length = posts.length;
        console.log(posts_length);
        for (var i=0;i<posts_length;i++) {
            var post = posts[i];
            if (post.actions_summary.length > 0){
                var action = post.actions_summary[0];
                likes = action && action.id === 2
                        ? action.count : 0;
                post.cooked_hidden !== undefined ? cooked_hidden = post.cooked_hidden : cooked_hidden = false

            }
            avatar = post.avatar_template
            avatar.indexOf("https") >= 0 ? avatar = avatar : avatar = forumSource.value.substring(0, forumSource.value.length - 1)  +  avatar

            console.log(avatar)
            list.model.append({
                                  cooked: post.cooked,
                                  username: post.username,
                                  avatar: avatar,//.replace("{size}", 2* Theme.paddingLarge),
                                  updated_at: post.updated_at,
                                  likes: likes,
                                  created_at: post.created_at,
                                  version: post.version,
                                  postid: post.id,
                                  user_id: post.user_id,
                                  post_number: post.post_number,
                                  reply_to: post.reply_to_post_number,
                                  last_postid: last_post,
                                  cooked_hidden: cooked_hidden,
                                  accepted_answer: post.accepted_answer
                              });
            likes = 0;

            last_post = post.post_number;
        }
    }

    function getcomments(){
        var xhr = new XMLHttpRequest;
        xhr.open("GET", source + ".json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var data = JSON.parse(xhr.responseText);
                if (data.tags) tags = data.tags.join(" ");
                tclosed = data.closed;
                if (aTitle == "") aTitle = data.title;
                posts_count = data.posts_count;
                var post_stream = data.post_stream;
                list.model.clear();
                appendPosts(post_stream.posts);
                var stream = post_stream.stream;
                if (posts_count >= 20){
                    xi = Math.floor((posts_count - 20) / 400)
                    yi = (posts_count - 20) % 400
                    for( zi = 0;zi<xi;zi++){
                        loadmore =  source + "/posts.json?post_ids[]="
                        for (var v = (20 + (zi * 400)); v < (20 +( (zi+1)*400));v++){
                            loadmore += stream[v] + "&post_ids[]="
                        }
                        busy = true

                        var msg = {
                            'loadmore': loadmore,
                            'last': false
                        };

                        worker.sendMessage(msg)
                    }
                } else {
                    busy = false
                }

                if( zi == xi && posts_count >= 20) {
                    busy = true
                    loadmore =  source + "/posts.json?post_ids[]="
                    for(yi<posts_count - (zi*400);yi>0;yi--){
                        loadmore += stream[posts_count - yi] + "&post_ids[]="
                    }

                    var msg = {
                        'loadmore': loadmore,
                        'last': true
                    };
                    worker.sendMessage(msg)
                }
            }
        }
        xhr.send();
    }


    SilicaListView {
        id: list
        header: PageHeader {
            id: pageHeader
            title: tclosed ? "🔐" + aTitle : aTitle
            description: tags ? qsTr("tags") + ": " + tags : ""

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
            contentHeight:  delegateCol.height + Theme.paddingLarge
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
                        Image {
                            id: ava
                            height:  3* Theme.paddingLarge
                            width:  3* Theme.paddingLarge
                            source:  avatar.replace("{size}", 3* Theme.paddingLarge)
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Item {
                                    width: ava.width
                                    height: ava.height

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Math.min(ava.width, ava.height)
                                        height: ava.height
                                        radius: Math.min(width, height)
                                    }
                                }
                            }
                        }
                    }
                    Column {
                        width: parent.width - subMetadata.width - ava.width
                        Label {
                            id: mainMetadata
                            text: loggedin != "-1" ? "<style>" +
                                                     "a { color: %1 }".arg(Theme.highlightColor) +
                                                     "</style>" + "<a href=\"" + forumSource.value + "u/\"" + username + "/card.json\">" + username + "</a>" : username
                            onLinkActivated: pageStack.push("UserCard.qml", {username: username, loggedin: loggedin.value});
                            textFormat: Text.RichText
                            truncationMode: TruncationMode.Fade
                            elide: Text.ElideRight
                            width: parent.width
                            font.pixelSize: Theme.fontSizeMedium
                        }


                        Label {
                            visible: likes > 0
                            text:  likes + "♥"// : likes + "💘"
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
                    onLinkActivated: {
                        var link0 = new RegExp("^" + forumSource.value.replace(/\//g, "\/") + "t\/([\\w-]*[a-z-]+[\\w-]+\/)?(\\d+)\/?(\\d+)*")
                        console.log(link0)
                        var linko = new RegExp( "^" + forumSource.value.replace(/\//g, "\/")  + "t\/[\\w-]+?\/?")
                        console.log(linko)
                        var link1 =  link0.exec(link)
                        if (!link1 && linko.exec(link)){
                            console.log(link)
                            getRedirect(link);
                        } else if ( !link1){
                            pageStack.push("OpenLink.qml", {link: link});
                        } else {
                            pageStack.push("ThreadView.qml", { "topicid": link1[2], "post_number": link1[3] });
                        }
                    }
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
                MenuItem{
                    visible: cooked_hidden
                    text: qsTr("Uncensor post")
                    onClicked: uncensor(postid, index);
                }
            }
        }


        Component.onCompleted: commentpage.getcomments();
    }
    onBusyChanged: {
        if(busy == false){
            if (post_number < 0) return;
            var comment;

            if (post_id === -1 && post_number >= 0 && post_number !== highest_post_number) {
                for (var j = 0; j < list.count; j++) {
                    comment = list.model.get(j);
                    if (comment && comment.post_number === post_number) {
                        if (highest_post_number){
                            list.positionViewAtIndex(j + 1, ListView.Beginning);
                        } else {
                            list.positionViewAtIndex(j, ListView.Beginning);
                        }
                    }
                }
            } else if (post_id >= 0){
                for(var i=post_number - (highest_post_number - posts_count) - 1;i<=post_number;i++){
                    comment = list.model.get(i)
                    if (post_id && comment && comment.postid === post_id){
                        list.positionViewAtIndex(i, ListView.Beginning);
                    }
                }
            }

        }
    }
}


