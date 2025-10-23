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
import Nemo.Configuration 1.0


Page {
    id: firstPage
    allowedOrientations: Orientation.All
    property string tid
    property int pageno: 0
    property string viewmode
    property string textname
    property string category
    property string topic_template
    property var tags: ""
    property var ttags: ""
    property var forconf: forumSource.value.replace(/\./g, "").replace(/\//g, "").replace(/https:/g, "")
    property string combined: forumSource.value + (tid ? "c/" + tid : viewmode) + ".json?page=" + pageno
    property bool networkError: false
    property bool loadedMore: false
    property string login
    property bool remorseActive: false

    function logout() {
        remorseActive = true
        remorsePopup.execute(
                    //   firstPage,
                    qsTr("Logging out"),
                    function() { mainConfig.setValue("key", "-1") }
                    )
    }

    function newtopic(raw, title, category){
        var xhr = new XMLHttpRequest;
        const json = {
            "raw": raw,
            "title": title,
            "category": category
        };
        xhr.open("POST", forumSource.value + "posts/");
        xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortitle: xhr.status + " " + xhr.statusText, errortext: xhr.responseText});
                } else {

                    console.log(xhr.responseText);
                    clearview();
                }
            }
        }
        xhr.send(JSON.stringify(json));
    }

    function newPM(raw, title, target_recipients){
        var xhr = new XMLHttpRequest;
        const json = {
            "raw": raw,
            "title": title,
            "target_recipients": target_recipients,
            "archetype": "private_message"
        };
        xhr.open("POST", forumSource.value + "posts/");
        xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortitle: xhr.status + " " + xhr.statusText, errortext: xhr.responseText});
                } else {
                    var data = JSON.parse(xhr.responseText);
                    pageStack.push("ThreadView.qml", {
                                       "topicid": data.topic_id,
                                       "post_number": 0,
                                       "forconf": forconf
                                   });
                }
            }
        }
        xhr.send(JSON.stringify(json));
    }

    function clearview(){
        list.model.clear();
        pageno = 0;
        loadedMore = false;
        updateview();
    }
    function updateview() {
        var xhr = new XMLHttpRequest;


        xhr.open("GET", combined);
        if (loggedin.value !== "-1" && loggedin.value) xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.responseText === "") {
                    list.model.clear();
                    networkError = true;
                    return;
                } else {
                    networkError = false;
                }
                var data = JSON.parse(xhr.responseText);
                var topics = data.topic_list.topics;

                // Filter bumped if required
                if (viewmode === "latest" && tid === ""){
                    topics = topics.filter(function(t) {
                        return t.bumped
                    })
                }

                var topics_length = topics.length;
                for (var i=0;i<topics_length;i++) {

                    var topic = topics[i];
                    tags = ""
                    if (topic.tags) tags = topic.tags.join(" ");
                    tags ?  ttags = tags : ttags = ""
                    list.model.append({ title: topic.title,
                                          topicid: topic.id,
                                          has_accepted_answer: topic.has_accepted_answer,
                                          posts_count: topic.posts_count,
                                          bumped: topic.bumped_at,
                                          ttags: ttags,
                                          category_id: topic.category_id,
                                          highest_post_number: topic.highest_post_number,
                                          notification_level: topic.notification_level !== undefined ? topic.notification_level : 1
                                      });
                }

                if (data.topic_list.more_topics_url){
                    pageno++;
                } else {
                    pageno = 0;
                }
            }
        }

        xhr.send();
    }

    function showLatest() {
        tid = "";
        textname = qsTr("Latest");
        viewmode = "latest";
        login = mainConfig.value("key", "-1");
        mainConfig.setValue("key", login);
        clearview();
    }

    function showTop() {
        viewmode = "top";
        tid = "";
        textname = qsTr("Top");
        clearview();
    }


    function showCategory(showTopic, showTextname, template, cat) {
        viewmode = "";
        tid = showTopic;
        textname = showTextname;
        topic_template = template;
        category = cat;
        clearview();
    }
    readonly property var watchlevel: [
        { "name": qsTr("Muted",    "Topic watch level (state)"),
            "action": qsTr("Mute",   "Topic watch action (verb)"),
            "smallicon": "image://theme/icon-m-speaker-mute",
            "icon": "image://theme/icon-m-speaker-mute"
        },
        { "name": qsTr("Normal",   "Topic watch level (state)"),
            "action": qsTr("Normal", "Topic watch action (verb)"),
            "smallicon": "",
            "icon": "image://theme/icon-m-favorite"
        },
        { "name": qsTr("Tracking", "Topic watch level (state)"),
            "action": qsTr("Track",  "Topic watch action (verb)"),
            "smallicon": "image://theme/icon-m-favorite",
            "icon": "image://theme/icon-m-favorite-selected"
        },
        { "name": qsTr("Watching", "Topic watch level (state)"),
            "action": qsTr("Watch",  "Topic watch action (verb)"),
            "smallicon": "image://theme/icon-m-alarm",
            "icon": "image://theme/icon-m-alarm"
        }
    ]
    // level being one of 0, 1, 2, 3; representing muted, normal, tracking, watching
    // !! payload wants a string so "0", not 0
    function setNotificationLevel(index, topicid, level){
        if (loggedin.value == "-1") return
        console.debug("Setting watch level to", level, ",", watchlevel[Number(level)].name)
        var xhr = new XMLHttpRequest;
        const json = {
            "notification_level": level
        };
        xhr.open("POST", forumSource.value + "/t/" + topicid + "/notifications.json");
        xhr.setRequestHeader("User-Api-Key", loggedin.value);
        xhr.setRequestHeader("Content-Type", 'application/json');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE){
                if(xhr.statusText !== "OK"){
                    pageStack.completeAnimation();
                    pageStack.push("Error.qml", {errortitle: xhr.status + " " + xhr.statusText, errortext: xhr.responseText});
                } else {
                    // update the topic properties
                    list.model.setProperty(index, "notification_level", level)
                }
            }
        }
        xhr.send(JSON.stringify(json));
    }

    onStatusChanged: {
        if (status === PageStatus.Active){
            pageStack.pushAttached(Qt.resolvedUrl("CategorySelect.qml"));
        }
    }

    onForconfChanged: {
        login = mainConfig.value("key", "-1");
        mainConfig.setValue("key", login);
    }
    Connections {
        target: application
        onReload: {
            if (!loadedMore || viewmode === "latest"){
                pageno = 0;
                list.model.clear();
                firstPage.updateview();
            }
        }
    }

    ConfigurationGroup {
        id: mainConfig
        path: "/org/szopin/harbour-discourser/" + forconf

        ConfigurationGroup {
            id: postCountConfig
            path: "/highest_post_number"
        }
    }
    ConfigurationValue {
        id: loggedin
        key: "/org/szopin/harbour-discourser/" + forconf  + "/key"
    }
    RemorsePopup {
        id: remorsePopup
        onCanceled: remorseActive = false
        onTriggered: remorseActive = false
    }

    SilicaListView {
        id:list
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: textname === "" ? viewmode : textname
            description: forumTitle.value || forumSource.value
        }

        footer: Item {
            width: parent.width
            height: Theme.horizontalPageMargin
        }

        PullDownMenu {
            id: pulley
            busy: application.fetching
            MenuItem {
                text: qsTr("Login")
                visible:  loggedin.value != "-1" ? false : true
                onClicked: pageStack.push("LoginPage.qml", {"forconf": forconf});
            }

            MenuItem {
                text: qsTr("Logout")
                visible: loggedin.value != "-1" ? true : false
                onClicked: logout();
            }
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push("About.qml");
            }
            MenuItem {
                text: qsTr("Change forum")
                onClicked: pageStack.push("SitePage.qml");
            }
            MenuItem {
                text: qsTr("New thread")
                visible: !remorseActive &&loggedin.value != "-1" && tid ? true : false
                onClicked: pageStack.push("NewThread.qml", {category: category, raw: topic_template});
            }

            MenuItem {
                text: qsTr("Search")
                onClicked: pageStack.push("SearchPage.qml", { "forconf": forconf});

            }
            MenuItem {
                text: qsTr("Notifications")
                visible: !remorseActive && loggedin.value != "-1"
                onClicked: pageStack.push("Notifications.qml", {loggedin: loggedin.value, "forconf": forconf});
            }
            MenuItem {
                text: qsTr("Reload")
                onClicked: {
                    pulley.close()
                    clearview()
                }
            }
        }

        BusyIndicator {
            visible: running
            running: model.count === 0 && !networkError
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }

        ViewPlaceholder {
            enabled: model.count === 0 && networkError
            text: qsTr("Nothing to show")
            hintText: qsTr("Is the network enabled?")
        }

        model: ListModel { id: model}
        VerticalScrollDecorator {}
        Component.onCompleted: {

            login = mainConfig.value("key", "-1");
            mainConfig.setValue("key", login);
            showLatest();
        }

        delegate: ListItem {
            id: item
            width: parent.width
            contentHeight: normrow.height + Theme.paddingLarge
            property int lastPostNumber: postCountConfig.value(topicid, -1)
            property bool hasNews: (lastPostNumber > 0 && lastPostNumber < highest_post_number)

            Column {
                id: delegateCol
                height: childrenRect.height
                width: parent.width - 2*Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }

                Row {
                    id: normrow
                    width: parent.width
                    spacing: 1.5*Theme.paddingMedium

                    Column {
                        width: postsLabel.width
                        height: childrenRect.height
                        spacing: Theme.paddingSmall

                        Label {
                            id: postsLabel
                            text: posts_count
                            minimumPixelSize: Theme.fontSizeTiny
                            fontSizeMode: "Fit"
                            font.pixelSize: Theme.fontSizeSmall
                            color: item.lastPostNumber < 0 ?
                                       Theme.primaryColor :
                                       (item.hasNews ?
                                            Theme.highlightColor :
                                            Theme.secondaryColor)

                            opacity: Theme.opacityHigh
                            height: 1.2*Theme.fontSizeSmall; width: height
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width+Theme.paddingSmall; height: parent.height
                                radius: 20
                                opacity: item.lastPostNumber < highest_post_number ?
                                             Theme.opacityLow :
                                             Theme.opacityFaint

                                color: item.hasNews ?
                                           Theme.secondaryHighlightColor :
                                           Theme.secondaryColor
                            }
                        }

                        Icon {
                            //visible: has_accepted_answer
                            //source: "image://theme/icon-s-accept"
                            visible: source != ""
                            source: has_accepted_answer
                                    ? "image://theme/icon-s-accept?" + Theme.highlightFromColor(Theme.presenceColor(Theme.PresenceAvailable), Theme.colorScheme )
                                    : ((notification_level >= 0 && loggedin.value !== "-1")
                                       ? watchlevel[notification_level].smallicon
                                       : "")
                            width: Theme.iconSizeSmall
                            height: width
                            opacity: has_accepted_answer ? Theme.opacityLow : 1.0
                        }
                    }
                    Column {
                        width: parent.width - postsLabel.width - parent.spacing

                        Label {
                            text: title
                            width: parent.width
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.fontSizeSmall

                            color: highlighted || item.hasNews
                                   ? Theme.highlightColor
                                   : (item.lastPostNumber < highest_post_number
                                      ? Theme.primaryColor
                                      : Theme.secondaryColor)
                        }

                        Row {
                            width: parent.width
                            spacing: 1.5*Theme.paddingMedium

                            Label {
                                id: dateLabel
                                text: formatJsonDate(bumped)
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                width: (parent.width - 2*parent.spacing - catRect.width)/2
                                color: highlighted || item.hasNews ? Theme.secondaryHighlightColor
                                                                   : Theme.secondaryColor

                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignLeft
                            }


                            Label {
                                visible: catRect.visible
                                text: categories.lookup[category_id].name
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                width: dateLabel.width
                                color: highlighted || item.hasNews ? Theme.secondaryHighlightColor
                                                                   : Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignRight
                            }


                            Rectangle {
                                id: catRect
                                visible: tid === ""
                                color: '#'+categories.lookup[category_id].color
                                width: 2*Theme.horizontalPageMargin
                                height: Theme.horizontalPageMargin/3
                                radius: 45
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: Theme.opacityLow
                            }
                        }
                        Row {
                            visible: ttags
                            width: parent.width
                            spacing: 1.5* Theme.paddingMedium
                            Label {
                                id: tags
                                visible: ttags
                                text: qsTr("tags") + ": " + ttags
                                color: highlighted || item.hasNews ? Theme.secondaryHighlightColor
                                                                   : Theme.secondaryColor
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }



                    }
                }
            }

            menu: ContextMenu { id: ctxmenu
                hasContent: lastPostNumber > 0 || (!remorseActive && loggedin.value !== "-1")
                property int wantLevel: notification_level
                onClosed: if (wantLevel != notification_level) {
                              setNotificationLevel(index, topicid, wantLevel)
                          }
                MenuItem { text: qsTr("Mark as read")
                    visible: lastPostNumber > 0 && lastPostNumber < highest_post_number
                    onDelayedClick: {
                        postCountConfig.setValue(topicid, highest_post_number);
                        lastPostNumber = highest_post_number;
                    }
                }
                MenuLabel { height: buttons.height
                    visible: !remorseActive && loggedin.value !== "-1"
                    anchors.horizontalCenter: parent.horizontalCenter
                    Grid{ id: buttons
                        rows: 1
                        columns: watchlevel.length
                        spacing: Theme.paddingLarge
                        anchors.centerIn: parent
                        Repeater { id: rep
                            model: watchlevel
                            delegate: BackgroundItem { id: bitem
                                height: iconcol.height + Theme.paddingSmall
                                width: iconcol.height
                                Column { id: iconcol
                                    width: parent.width
                                    spacing: Theme.paddingSmall
                                    anchors.verticalCenter: parent.verticalCenter
                                    Icon { id: icon
                                        width: Theme.iconSizeSmallPlus
                                        height: width
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: modelData.icon + "?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)
                                        highlighted: bitem.down || (index == ctxmenu.wantLevel)
                                    }
                                    Label {
                                        anchors.horizontalCenter: icon.horizontalCenter
                                        text: modelData.action
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        color: icon.highlighted ? Theme.highlightColor : Theme.primaryColor
                                        highlighted: icon.highlighted
                                    }
                                }
                                // only change value when menu is closed
                                onClicked: ctxmenu.wantLevel = index
                            }
                        }
                    }
                }
                MenuItem { text: qsTr("Don't track (local)")
                    visible: lastPostNumber > 0
                    onDelayedClick: {
                        postCountConfig.setValue(topicid, "-1");
                        lastPostNumber = -1;
                    }
                }

            }
            onClicked: {
                if(!remorseActive){
                    var name = list.model.get(index).name
                    postCountConfig.setValue(topicid, highest_post_number);
                    var oldLast = lastPostNumber;
                    lastPostNumber = highest_post_number;
                    pageStack.push("ThreadView.qml", {
                                       "aTitle": title,
                                       "topicid": topicid,
                                       "posts_count": posts_count,
                                       "post_number": oldLast,
                                       "highest_post_number": highest_post_number,
                                       "forconf": forconf
                                   });

                }
            }

        }

        PushUpMenu {
            id: pupmenu
            visible: pageno != 0;
            MenuItem {
                text: qsTr("Load more")
                onClicked: {
                    pupmenu.close();
                    loadedMore = true;
                    firstPage.updateview();
                }
            }

        }
    }
}
